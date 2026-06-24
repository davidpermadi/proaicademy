// midtrans-webhook — deployed with verify_jwt = false.
//
// Receives Midtrans HTTP(S) payment notifications. Authenticated NOT by a Supabase
// JWT but by Midtrans's signature_key:
//   sha512(order_id + status_code + gross_amount + server_key)
// On a successful payment it flips the order to "paid" and grants the buyer their
// entitlements (which is what unlocks paid e-book downloads via storage RLS).
//
// Required Edge Function secret: MIDTRANS_SERVER_KEY
// Set this function's URL as the Payment Notification URL in the Midtrans dashboard.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.58.0";

async function sha512(s: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-512", new TextEncoder().encode(s));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const SERVER_KEY = Deno.env.get("MIDTRANS_SERVER_KEY") ?? "";

    const n = await req.json();
    const orderId = String(n.order_id ?? "");
    const statusCode = String(n.status_code ?? "");
    const gross = String(n.gross_amount ?? "");
    const sig = String(n.signature_key ?? "");

    // Verify authenticity.
    if (!SERVER_KEY) return new Response("server key not configured", { status: 503 });
    const expected = await sha512(orderId + statusCode + gross + SERVER_KEY);
    if (expected !== sig) return new Response("invalid signature", { status: 403 });

    const admin = createClient(SUPABASE_URL, SERVICE_KEY);

    const tStatus = String(n.transaction_status ?? "");
    const fraud = String(n.fraud_status ?? "");
    let status = "pending";
    if (tStatus === "capture") status = fraud === "challenge" ? "pending" : (fraud === "deny" ? "failed" : "paid");
    else if (tStatus === "settlement") status = "paid";
    else if (tStatus === "pending") status = "pending";
    else if (tStatus === "deny") status = "failed";
    else if (tStatus === "cancel") status = "cancelled";
    else if (tStatus === "expire") status = "expired";
    else if (tStatus === "refund" || tStatus === "partial_refund" || tStatus === "chargeback") status = "refunded";

    const { data: order, error: uErr } = await admin.from("orders")
      .update({ status, payment_type: n.payment_type, raw_notification: n })
      .eq("midtrans_order_id", orderId).select().maybeSingle();
    if (uErr) return new Response("db error: " + uErr.message, { status: 500 });
    if (!order) return new Response("order not found", { status: 404 });

    // On successful payment, grant the buyer their entitlements.
    if (status === "paid") {
      const { data: items } = await admin.from("order_items").select("*").eq("order_id", order.id);
      const rows = (items ?? []).map((it: any) => ({ user_id: order.user_id, product_type: it.product_type, product_id: it.product_id, order_id: order.id }));
      if (rows.length) {
        await admin.from("entitlements").upsert(rows, { onConflict: "user_id,product_type,product_id", ignoreDuplicates: true });
      }
    }
    return new Response("ok", { status: 200 });
  } catch (e) {
    return new Response("error: " + String((e as Error)?.message ?? e), { status: 500 });
  }
});
