// create-payment — verify_jwt = false (handles BOTH signed-in users and guests).
//
// Builds a Midtrans Snap transaction for the items in the cart. Prices are ALWAYS
// recomputed from the database; client amounts are ignored.
//  - Signed-in user (valid JWT): order is tied to user_id; the webhook grants an entitlement.
//  - Guest (no account): caller must supply an email; the order gets a secret access_token
//    that is later exchanged for downloads via the download-ebook function.
//
// The Midtrans SERVER key is read from the MIDTRANS_SERVER_KEY env secret if present,
// otherwise from Supabase Vault via public.get_app_secret('MIDTRANS_SERVER_KEY').
// Sandbox vs production is auto-detected from the key prefix (SB-... = sandbox).
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.58.0";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function json(obj: unknown, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: { ...cors, "Content-Type": "application/json" } });
}
const TABLE_FOR: Record<string, string> = { course: "courses", ebook: "ebooks", consulting: "consulting_packages" };
function isEmail(s: string) { return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s); }

async function resolveServerKey(admin: any): Promise<string> {
  const env = Deno.env.get("MIDTRANS_SERVER_KEY");
  if (env) return env;
  try {
    const { data } = await admin.rpc("get_app_secret", { p_name: "MIDTRANS_SERVER_KEY" });
    return data ?? "";
  } catch (_) { return ""; }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
    const admin = createClient(SUPABASE_URL, SERVICE_KEY);

    const SERVER_KEY = await resolveServerKey(admin);
    const envProd = Deno.env.get("MIDTRANS_IS_PRODUCTION");
    const IS_PROD = envProd != null ? envProd === "true" : (!!SERVER_KEY && !/^SB-/i.test(SERVER_KEY));

    // Optional auth: if a real user JWT is present we attach the order to that user.
    let user: any = null;
    const authHeader = req.headers.get("Authorization") ?? "";
    if (authHeader) {
      const userClient = createClient(SUPABASE_URL, ANON_KEY, { global: { headers: { Authorization: authHeader } } });
      const { data } = await userClient.auth.getUser();
      user = data?.user ?? null; // null when the header is just the anon/publishable key (guest)
    }

    const body = await req.json().catch(() => ({}));
    const items = Array.isArray(body.items) ? body.items : [];
    if (!items.length) return json({ error: "Cart is empty" }, 400);

    const email = String((user && user.email) || body.email || "").trim();
    const fullName = String((user && user.user_metadata && user.user_metadata.full_name) || body.name || "").trim();
    if (!user && !isEmail(email)) return json({ error: "A valid email is required for guest checkout" }, 400);

    // Recompute prices from the database — never trust amounts from the client.
    const lineItems: any[] = [];
    let gross = 0;
    for (const it of items) {
      const table = TABLE_FOR[it.product_type];
      if (!table) continue;
      const { data: row } = await admin.from(table).select("*").eq("id", it.product_id).eq("is_published", true).maybeSingle();
      if (!row) continue;
      const price = Number(row.price) || 0;
      if (price <= 0) continue;
      const qty = Math.max(1, parseInt(String(it.qty ?? 1)) || 1);
      const title = (row.title && row.title.en) || (row.name && row.name.en) || it.product_id;
      lineItems.push({ id: `${it.product_type}:${it.product_id}`.slice(0, 50), price, quantity: qty, name: String(title).slice(0, 50), product_type: it.product_type, product_id: it.product_id });
      gross += price * qty;
    }
    if (!lineItems.length || gross <= 0) return json({ error: "No payable items in cart" }, 400);

    const midOrderId = "PROAI-" + crypto.randomUUID().slice(0, 18);
    const accessToken = user ? null : crypto.randomUUID() + crypto.randomUUID().replace(/-/g, "");

    const { data: order, error: oErr } = await admin.from("orders").insert({
      user_id: user ? user.id : null,
      guest_email: user ? null : email,
      access_token: accessToken,
      midtrans_order_id: midOrderId,
      gross_amount: gross,
      status: "pending",
    }).select().single();
    if (oErr || !order) return json({ error: "Could not create order", detail: oErr?.message }, 500);

    await admin.from("order_items").insert(lineItems.map((li) => ({
      order_id: order.id, product_type: li.product_type, product_id: li.product_id,
      title: li.name, unit_price: li.price, qty: li.quantity,
    })));

    if (!SERVER_KEY) {
      return json({ error: "Midtrans is not configured. Set MIDTRANS_SERVER_KEY (env secret) or store it in Vault.", order_id: order.id, access_token: accessToken }, 503);
    }

    const base = IS_PROD ? "https://app.midtrans.com" : "https://app.sandbox.midtrans.com";
    const snapRes = await fetch(`${base}/snap/v1/transactions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json", "Authorization": "Basic " + btoa(SERVER_KEY + ":") },
      body: JSON.stringify({
        transaction_details: { order_id: midOrderId, gross_amount: gross },
        item_details: lineItems.map((li) => ({ id: li.id, price: li.price, quantity: li.quantity, name: li.name })),
        customer_details: { email, first_name: fullName || email },
        credit_card: { secure: true },
      }),
    });
    const snap = await snapRes.json();
    if (!snapRes.ok) {
      await admin.from("orders").update({ status: "failed", raw_notification: snap }).eq("id", order.id);
      return json({ error: "Midtrans error", detail: snap }, 502);
    }
    await admin.from("orders").update({ snap_token: snap.token }).eq("id", order.id);
    return json({ token: snap.token, redirect_url: snap.redirect_url, order_id: order.id, midtrans_order_id: midOrderId, access_token: accessToken });
  } catch (e) {
    return json({ error: String((e as Error)?.message ?? e) }, 500);
  }
});
