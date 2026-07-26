// midtrans-webhook — deployed with verify_jwt = false.
//
// Receives Midtrans HTTP(S) payment notifications. Authenticated NOT by a Supabase
// JWT but by Midtrans's signature_key:
//   sha512(order_id + status_code + gross_amount + server_key)
// On a successful payment it flips the order to "paid", grants the buyer their
// entitlements (which is what unlocks paid e-book downloads), and e-mails the store
// owner the sale details.
//
// Config (env secret first, then Supabase Vault):
//   MIDTRANS_SERVER_KEY — required, verifies the notification signature.
//   RESEND_API_KEY      — required for the sale e-mail. Without it the payment still
//                         processes normally; only the notification is skipped.
//   SALE_NOTIFY_TO      — recipient. Default davidpermadi@proaicademy.id
//   SALE_NOTIFY_FROM    — sender. Default "ProAIcademy <sales@proaicademy.id>".
//                         Must be on a domain verified in Resend, or Resend rejects it.
//
// This endpoint ALWAYS returns 200 once the signature checks out, even if the e-mail
// fails. A non-2xx makes Midtrans retry, which would re-run the whole handler — the
// payment itself must never be held hostage to the mail provider being up.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.58.0";

async function sha512(s: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-512", new TextEncoder().encode(s));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
async function cfg(admin: any, name: string): Promise<string> {
  const env = Deno.env.get(name);
  if (env) return env;
  try {
    const { data } = await admin.rpc("get_app_secret", { p_name: name });
    return data ?? "";
  } catch (_) { return ""; }
}
const rp = (n: number) => "Rp " + Number(n || 0).toLocaleString("id-ID");
// Order data is buyer-supplied; it lands in an HTML e-mail, so escape it.
const esc = (s: unknown) =>
  String(s ?? "").replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c] as string));

async function sendSaleEmail(admin: any, order: any, items: any[], buyerEmail: string) {
  const apiKey = await cfg(admin, "RESEND_API_KEY");
  // Throw rather than return: the caller releases its claim on failure, so an unconfigured
  // key leaves owner_notified_at null and the order shows up as un-notified — which is the
  // truth. Returning quietly here would mark it notified when nothing was sent.
  if (!apiKey) throw new Error("RESEND_API_KEY not configured");
  const to = (await cfg(admin, "SALE_NOTIFY_TO")) || "davidpermadi@proaicademy.id";
  const from = (await cfg(admin, "SALE_NOTIFY_FROM")) || "ProAIcademy <sales@proaicademy.id>";

  const name = order.customer_name || "(not provided)";
  const phone = order.customer_phone || "(not provided)";
  const rows = items.map((it) =>
    `<tr><td style="padding:6px 12px 6px 0">${esc(it.title)}</td>` +
    `<td style="padding:6px 12px 6px 0;text-align:center">${esc(it.qty)}</td>` +
    `<td style="padding:6px 0;text-align:right">${esc(rp(it.unit_price * it.qty))}</td></tr>`
  ).join("");

  const html = `<div style="font-family:system-ui,-apple-system,Segoe UI,sans-serif;font-size:15px;color:#111;line-height:1.55">
  <h2 style="margin:0 0 4px">New paid order — ${esc(rp(order.gross_amount))}</h2>
  <p style="margin:0 0 20px;color:#666">Order ${esc(order.midtrans_order_id)}</p>
  <h3 style="margin:0 0 8px;font-size:16px">Customer</h3>
  <table cellpadding="0" cellspacing="0" style="margin-bottom:20px">
    <tr><td style="padding:3px 16px 3px 0;color:#666">Name</td><td><strong>${esc(name)}</strong></td></tr>
    <tr><td style="padding:3px 16px 3px 0;color:#666">Contact number</td><td><strong>${esc(phone)}</strong></td></tr>
    <tr><td style="padding:3px 16px 3px 0;color:#666">Email</td><td>${esc(buyerEmail || "(unknown)")}</td></tr>
    <tr><td style="padding:3px 16px 3px 0;color:#666">Account</td><td>${order.user_id ? "Registered user" : "Guest checkout"}</td></tr>
  </table>
  <h3 style="margin:0 0 8px;font-size:16px">Items</h3>
  <table cellpadding="0" cellspacing="0" style="margin-bottom:20px;border-collapse:collapse">${rows}
    <tr><td colspan="2" style="padding:10px 12px 0 0;border-top:1px solid #ddd"><strong>Total</strong></td>
        <td style="padding:10px 0 0;text-align:right;border-top:1px solid #ddd"><strong>${esc(rp(order.gross_amount))}</strong></td></tr>
  </table>
  <p style="margin:0;color:#666;font-size:13px">Paid via ${esc(order.payment_type || "unknown")} · ${esc(new Date().toISOString())}</p>
</div>`;

  const text = [
    `New paid order — ${rp(order.gross_amount)}`,
    `Order ${order.midtrans_order_id}`,
    ``,
    `Name:           ${name}`,
    `Contact number: ${phone}`,
    `Email:          ${buyerEmail || "(unknown)"}`,
    `Account:        ${order.user_id ? "Registered user" : "Guest checkout"}`,
    ``,
    ...items.map((it) => `  ${it.qty} x ${it.title} — ${rp(it.unit_price * it.qty)}`),
    ``,
    `Total: ${rp(order.gross_amount)}`,
    `Paid via ${order.payment_type || "unknown"}`,
  ].join("\n");

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { "Authorization": "Bearer " + apiKey, "Content-Type": "application/json" },
    body: JSON.stringify({
      from, to: [to], subject: `New paid order — ${rp(order.gross_amount)} — ${name}`,
      html, text, reply_to: buyerEmail || undefined,
    }),
  });
  if (!res.ok) throw new Error(`resend ${res.status}: ${await res.text()}`);
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(SUPABASE_URL, SERVICE_KEY);
    const SERVER_KEY = await cfg(admin, "MIDTRANS_SERVER_KEY");

    const n = await req.json();
    const orderId = String(n.order_id ?? "");
    const statusCode = String(n.status_code ?? "");
    const gross = String(n.gross_amount ?? "");
    const sig = String(n.signature_key ?? "");

    // Verify authenticity.
    if (!SERVER_KEY) return new Response("server key not configured", { status: 503 });
    const expected = await sha512(orderId + statusCode + gross + SERVER_KEY);
    if (expected !== sig) return new Response("invalid signature", { status: 403 });

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

    if (status === "paid") {
      const { data: items } = await admin.from("order_items").select("*").eq("order_id", order.id);

      // Grant the buyer their entitlements (signed-in orders).
      if (order.user_id) {
        const rows = (items ?? []).map((it: any) => ({ user_id: order.user_id, product_type: it.product_type, product_id: it.product_id, order_id: order.id }));
        if (rows.length) {
          await admin.from("entitlements").upsert(rows, { onConflict: "user_id,product_type,product_id", ignoreDuplicates: true });
        }
      }

      // Notify the store owner — exactly once. Midtrans legitimately sends more than one
      // notification per order (capture then settlement, plus retries), so claim the send
      // atomically and hand it back if the mail fails, leaving it visible as unnotified.
      const { data: claimed } = await admin.from("orders")
        .update({ owner_notified_at: new Date().toISOString() })
        .eq("id", order.id).is("owner_notified_at", null).select("id").maybeSingle();
      if (claimed) {
        try {
          let buyerEmail = order.guest_email ?? "";
          if (!buyerEmail && order.user_id) {
            const { data: u } = await admin.auth.admin.getUserById(order.user_id);
            buyerEmail = u?.user?.email ?? "";
          }
          await sendSaleEmail(admin, order, items ?? [], buyerEmail);
          await admin.from("orders").update({ notify_error: null }).eq("id", order.id);
        } catch (e) {
          // Record the reason on the order: the Edge Function logs API only exposes
          // request-level entries, so console output alone leaves this undiagnosable.
          const why = String((e as Error)?.message ?? e).slice(0, 500);
          console.error("sale-email failed for " + orderId + ": " + why);
          await admin.from("orders").update({ owner_notified_at: null, notify_error: why }).eq("id", order.id);
        }
      }
    }
    return new Response("ok", { status: 200 });
  } catch (e) {
    return new Response("error: " + String((e as Error)?.message ?? e), { status: 500 });
  }
});
