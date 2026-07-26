-- 0009_add_notify_error_to_orders.sql
--
-- owner_notified_at tells you a sale notification failed, but not why — and the Edge
-- Function logs API only exposes request-level entries, not console output, so a failed
-- send was effectively undiagnosable from SQL.
--
-- notify_error records the reason on the order itself:
--   select midtrans_order_id, notify_error
--   from orders where status='paid' and owner_notified_at is null;
--
-- Typical values: "RESEND_API_KEY not configured", "resend 401: ..." (bad key),
-- "resend 403: ..." (from-domain not verified in Resend).

alter table public.orders
  add column if not exists notify_error text;

comment on column public.orders.notify_error is
  'Why the sale-notification e-mail last failed. Cleared on a successful send.';
