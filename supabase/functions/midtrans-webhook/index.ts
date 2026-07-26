// midtrans-webhook — deployed with verify_jwt = false.
//
// Receives Midtrans HTTP(S) payment notifications. Authenticated NOT by a Supabase
// JWT but by Midtrans's signature_key:
//   sha512(order_id + status_code + gross_amount + server_key)
// On a successful payment it flips the order to "paid", grants the buyer their
// entitlements (which is what unlocks paid e-book downloads), and sends two e-mails:
//   1. the sale details to the store owner   (owner_notified_at / notify_error)
//   2. a purchase confirmation to the buyer  (buyer_notified_at / buyer_notify_error)
// Tracked separately so one failing never hides behind the other succeeding.
//
// Config (env secret first, then Supabase Vault):
//   MIDTRANS_SERVER_KEY — required, verifies the notification signature.
//   RESEND_API_KEY      — required for both e-mails. Without it the payment still
//                         processes normally; only the notifications are skipped.
//   SALE_NOTIFY_TO      — owner recipient. Default davidpermadi@proaicademy.id
//   SALE_NOTIFY_FROM    — sender for both. Default "ProAIcademy <sales@proaicademy.id>".
//                         Must be on a domain verified in Resend, or Resend rejects it.
//
// This endpoint ALWAYS returns 200 once the signature checks out, even if the e-mails
// fail. A non-2xx makes Midtrans retry, which would re-run the whole handler — the
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

async function resendSend(apiKey: string, payload: Record<string, unknown>) {
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { "Authorization": "Bearer " + apiKey, "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error(`resend ${res.status}: ${await res.text()}`);
}

// Shared item table markup for both e-mails.
function itemRows(items: any[]) {
  return items.map((it) =>
    `<tr><td style="padding:6px 12px 6px 0">${esc(it.title)}</td>` +
    `<td style="padding:6px 12px 6px 0;text-align:center">${esc(it.qty)}</td>` +
    `<td style="padding:6px 0;text-align:right">${esc(rp(it.unit_price * it.qty))}</td></tr>`
  ).join("");
}

// ---- 1. Store owner: "you have a sale" ------------------------------------------------
async function sendOwnerEmail(admin: any, order: any, items: any[], buyerEmail: string) {
  const apiKey = await cfg(admin, "RESEND_API_KEY");
  // Throw rather than return: the caller releases its claim on failure, so an unconfigured
  // key leaves the order visibly un-notified — which is the truth. Returning quietly here
  // would mark it notified when nothing was sent.
  if (!apiKey) throw new Error("RESEND_API_KEY not configured");
  const to = (await cfg(admin, "SALE_NOTIFY_TO")) || "davidpermadi@proaicademy.id";
  const from = (await cfg(admin, "SALE_NOTIFY_FROM")) || "ProAIcademy <sales@proaicademy.id>";

  const name = order.customer_name || "(not provided)";
  const phone = order.customer_phone || "(not provided)";

  const html = `<div style="font-family:system-ui,-apple-system,Segoe UI,sans-serif;font-size:15px;color:#111;line-height:1.55">
  <h2 style="margin:0 0 4px">New paid order — ${esc(rp(order.gross_amount))}</h2>
  <p style="margin:0 0 20px;color:#666">Order ${esc(order.midtrans_order_id)}</p>
  <h3 style="margin:0 0 8px;font-size:16px">Customer</h3>
  <table cellpadding="0" cellspacing="0" style="margin-bottom:20px">
    <tr><td style="padding:3px 16px 3px 0;color:#666">Name</td><td><strong>${esc(name)}</strong></td></tr>
    <tr><td style="padding:3px 16px 3px 0;color:#666">Contact number</td><td><strong>${esc(phone)}</strong></td></tr>
    <tr><td style="padding:3px 16px 3px 0;color:#666">Email</td><td>${esc(buyerEmail || "(unknown)")}</td></tr>
    <tr><td style="padding:3px 16px 3px 0;color:#666">Language</td><td>${order.customer_lang === "id" ? "Bahasa Indonesia" : "English"}</td></tr>
    <tr><td style="padding:3px 16px 3px 0;color:#666">Account</td><td>${order.user_id ? "Registered user" : "Guest checkout"}</td></tr>
  </table>
  <h3 style="margin:0 0 8px;font-size:16px">Items</h3>
  <table cellpadding="0" cellspacing="0" style="margin-bottom:20px;border-collapse:collapse">${itemRows(items)}
    <tr><td colspan="2" style="padding:10px 12px 0 0;border-top:1px solid #ddd"><strong>Total</strong></td>
        <td style="padding:10px 0 0;text-align:right;border-top:1px solid #ddd"><strong>${esc(rp(order.gross_amount))}</strong></td></tr>
  </table>
  <p style="margin:0;color:#666;font-size:13px">Paid via ${esc(order.payment_type || "unknown")} · ${esc(new Date().toISOString())}</p>
  <p style="margin:14px 0 0;color:#666;font-size:13px">The buyer has been told your team will contact them shortly.</p>
</div>`;

  const text = [
    `New paid order — ${rp(order.gross_amount)}`,
    `Order ${order.midtrans_order_id}`,
    ``,
    `Name:           ${name}`,
    `Contact number: ${phone}`,
    `Email:          ${buyerEmail || "(unknown)"}`,
    `Language:       ${order.customer_lang === "id" ? "Bahasa Indonesia" : "English"}`,
    `Account:        ${order.user_id ? "Registered user" : "Guest checkout"}`,
    ``,
    ...items.map((it) => `  ${it.qty} x ${it.title} — ${rp(it.unit_price * it.qty)}`),
    ``,
    `Total: ${rp(order.gross_amount)}`,
    `Paid via ${order.payment_type || "unknown"}`,
    ``,
    `The buyer has been told your team will contact them shortly.`,
  ].join("\n");

  await resendSend(apiKey, {
    from, to: [to], subject: `New paid order — ${rp(order.gross_amount)} — ${name}`,
    html, text, reply_to: buyerEmail || undefined,
  });
}

// ---- 2. Buyer: "your purchase is confirmed" -------------------------------------------
const BUYER_COPY = {
  en: {
    subject: (amt: string) => `Your ProAIcademy order is confirmed — ${amt}`,
    heading: "Thank you — your payment was successful",
    greeting: (n: string) => `Hi ${n},`,
    intro: "We've received your payment and your order is confirmed. Here's what you bought:",
    orderLabel: "Order",
    total: "Total",
    paidVia: "Paid via",
    contact: "Our sales team will contact you as soon as possible with your access details and next steps.",
    help: "Questions in the meantime? Just reply to this e-mail.",
    signoff: "— The ProAIcademy team",
    there: "there",
  },
  id: {
    subject: (amt: string) => `Pesanan ProAIcademy kamu dikonfirmasi — ${amt}`,
    heading: "Terima kasih — pembayaranmu berhasil",
    greeting: (n: string) => `Halo ${n},`,
    intro: "Pembayaranmu sudah kami terima dan pesananmu dikonfirmasi. Berikut rinciannya:",
    orderLabel: "Pesanan",
    total: "Total",
    paidVia: "Dibayar via",
    contact: "Tim sales kami akan segera menghubungimu dengan detail akses dan langkah selanjutnya.",
    help: "Ada pertanyaan? Balas saja e-mail ini.",
    signoff: "— Tim ProAIcademy",
    there: "kamu",
  },
} as const;

async function sendBuyerEmail(admin: any, order: any, items: any[], buyerEmail: string) {
  const apiKey = await cfg(admin, "RESEND_API_KEY");
  if (!apiKey) throw new Error("RESEND_API_KEY not configured");
  // No address means nothing to send to. Throw so it stays visible rather than looking sent.
  if (!buyerEmail) throw new Error("no buyer e-mail on order");
  const from = (await cfg(admin, "SALE_NOTIFY_FROM")) || "ProAIcademy <sales@proaicademy.id>";
  const salesTo = (await cfg(admin, "SALE_NOTIFY_TO")) || "davidpermadi@proaicademy.id";
  const t = BUYER_COPY[order.customer_lang === "id" ? "id" : "en"];
  const name = (order.customer_name || "").trim() || t.there;

  const html = `<div style="font-family:system-ui,-apple-system,Segoe UI,sans-serif;font-size:15px;color:#111;line-height:1.6;max-width:560px">
  <h2 style="margin:0 0 16px;font-size:20px">${esc(t.heading)}</h2>
  <p style="margin:0 0 12px">${esc(t.greeting(name))}</p>
  <p style="margin:0 0 20px">${esc(t.intro)}</p>
  <table cellpadding="0" cellspacing="0" style="width:100%;margin-bottom:20px;border-collapse:collapse">${itemRows(items)}
    <tr><td colspan="2" style="padding:10px 12px 0 0;border-top:1px solid #ddd"><strong>${esc(t.total)}</strong></td>
        <td style="padding:10px 0 0;text-align:right;border-top:1px solid #ddd"><strong>${esc(rp(order.gross_amount))}</strong></td></tr>
  </table>
  <p style="margin:0 0 20px;color:#666;font-size:13px">${esc(t.orderLabel)} ${esc(order.midtrans_order_id)} · ${esc(t.paidVia)} ${esc(order.payment_type || "-")}</p>
  <p style="margin:0 0 12px;padding:14px 16px;background:#f4f1ff;border-left:3px solid #7c3aed;border-radius:6px"><strong>${esc(t.contact)}</strong></p>
  <p style="margin:0 0 20px">${esc(t.help)}</p>
  <p style="margin:0;color:#666">${esc(t.signoff)}</p>
</div>`;

  const text = [
    t.heading,
    ``,
    t.greeting(name),
    t.intro,
    ``,
    ...items.map((it) => `  ${it.qty} x ${it.title} — ${rp(it.unit_price * it.qty)}`),
    ``,
    `${t.total}: ${rp(order.gross_amount)}`,
    `${t.orderLabel} ${order.midtrans_order_id} · ${t.paidVia} ${order.payment_type || "-"}`,
    ``,
    t.contact,
    t.help,
    ``,
    t.signoff,
  ].join("\n");

  await resendSend(apiKey, {
    from, to: [buyerEmail], subject: t.subject(rp(order.gross_amount)),
    html, text, reply_to: salesTo,
  });
}

// Claim-then-send: Midtrans legitimately sends several notifications per payment (capture
// then settlement, plus retries), so the claim is a conditional update rather than a
// read-then-write. A failure releases the claim and records why, leaving the order visibly
// un-notified instead of silently marked done.
async function notifyOnce(
  admin: any, orderId: string, sentCol: string, errCol: string,
  send: () => Promise<void>,
) {
  const { data: claimed } = await admin.from("orders")
    .update({ [sentCol]: new Date().toISOString() })
    .eq("id", orderId).is(sentCol, null).select("id").maybeSingle();
  if (!claimed) return;
  try {
    await send();
    await admin.from("orders").update({ [errCol]: null }).eq("id", orderId);
  } catch (e) {
    const why = String((e as Error)?.message ?? e).slice(0, 500);
    console.error(`${sentCol} failed for ${orderId}: ${why}`);
    await admin.from("orders").update({ [sentCol]: null, [errCol]: why }).eq("id", orderId);
  }
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
      const list = items ?? [];

      // Grant the buyer their entitlements (signed-in orders).
      if (order.user_id) {
        const rows = list.map((it: any) => ({ user_id: order.user_id, product_type: it.product_type, product_id: it.product_id, order_id: order.id }));
        if (rows.length) {
          await admin.from("entitlements").upsert(rows, { onConflict: "user_id,product_type,product_id", ignoreDuplicates: true });
        }
      }

      let buyerEmail = order.guest_email ?? "";
      if (!buyerEmail && order.user_id) {
        const { data: u } = await admin.auth.admin.getUserById(order.user_id);
        buyerEmail = u?.user?.email ?? "";
      }

      // Independent: a failure on one must not suppress the other.
      await notifyOnce(admin, order.id, "owner_notified_at", "notify_error",
        () => sendOwnerEmail(admin, order, list, buyerEmail));
      await notifyOnce(admin, order.id, "buyer_notified_at", "buyer_notify_error",
        () => sendBuyerEmail(admin, order, list, buyerEmail));
    }
    return new Response("ok", { status: 200 });
  } catch (e) {
    return new Response("error: " + String((e as Error)?.message ?? e), { status: 500 });
  }
});
