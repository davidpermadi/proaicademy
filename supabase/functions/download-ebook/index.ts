// download-ebook — verify_jwt = false (serves guests and signed-in users).
//
// Returns a short-lived signed URL for an e-book file, but only to someone allowed to have it:
//   * free e-book              -> anyone
//   * paid e-book, guest       -> must present the matching paid order_id + access_token
//   * paid e-book, signed-in   -> must have an entitlement (i.e. completed a payment)
// Uses the service role to sign the URL, so it works even without a Supabase session.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.58.0";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function json(obj: unknown, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: { ...cors, "Content-Type": "application/json" } });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
    const admin = createClient(SUPABASE_URL, SERVICE_KEY);

    const body = await req.json().catch(() => ({}));
    const productId = String(body.product_id ?? "");
    const orderId = body.order_id ? String(body.order_id) : "";
    const accessToken = body.access_token ? String(body.access_token) : "";
    if (!productId) return json({ error: "product_id is required" }, 400);

    const { data: ebook } = await admin.from("ebooks").select("id, price, file_path, file_name, is_published").eq("id", productId).maybeSingle();
    if (!ebook || !ebook.is_published) return json({ error: "E-book not found" }, 404);
    if (!ebook.file_path) return json({ error: "No file available for this e-book yet" }, 404);

    let allowed = false;

    if (Number(ebook.price) === 0) {
      allowed = true; // free for everyone
    } else if (orderId && accessToken) {
      // Guest path: a paid order with the matching access token that contains this e-book.
      const { data: order } = await admin.from("orders")
        .select("id, status").eq("id", orderId).eq("access_token", accessToken).maybeSingle();
      if (!order) return json({ error: "Invalid download token" }, 403);
      if (order.status !== "paid") return json({ error: "Payment not confirmed yet. Please try again in a moment." }, 402);
      const { data: item } = await admin.from("order_items")
        .select("id").eq("order_id", orderId).eq("product_type", "ebook").eq("product_id", productId).maybeSingle();
      allowed = !!item;
    } else {
      // Signed-in path: require an entitlement for this user.
      const authHeader = req.headers.get("Authorization") ?? "";
      if (authHeader) {
        const userClient = createClient(SUPABASE_URL, ANON_KEY, { global: { headers: { Authorization: authHeader } } });
        const { data: { user } } = await userClient.auth.getUser();
        if (user) {
          const { data: ent } = await admin.from("entitlements")
            .select("id").eq("user_id", user.id).eq("product_type", "ebook").eq("product_id", productId).maybeSingle();
          allowed = !!ent;
        }
      }
    }

    if (!allowed) return json({ error: "You do not have access to this file. Complete the purchase first." }, 403);

    const { data: signed, error: sErr } = await admin.storage.from("ebook-files")
      .createSignedUrl(ebook.file_path, 300, { download: ebook.file_name || true });
    if (sErr || !signed) return json({ error: "Could not create download link", detail: sErr?.message }, 500);
    return json({ url: signed.signedUrl, file_name: ebook.file_name });
  } catch (e) {
    return json({ error: String((e as Error)?.message ?? e) }, 500);
  }
});
