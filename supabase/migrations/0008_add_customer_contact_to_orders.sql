-- 0008_add_customer_contact_to_orders.sql
--
-- The checkout form has always had a *required* phone field, but startCheckout never read it
-- and create-payment had nowhere to put it — so the buyer's name and phone number were
-- collected and thrown away on every order. Both are needed for the "you have a sale"
-- notification e-mail, and for actually contacting the buyer.
--
-- owner_notified_at records when that notification was successfully sent, so a paid order
-- that failed to notify is findable:
--   select * from orders where status='paid' and owner_notified_at is null;

alter table public.orders
  add column if not exists customer_name     text,
  add column if not exists customer_phone    text,
  add column if not exists owner_notified_at timestamptz;

comment on column public.orders.customer_name  is 'Buyer name as typed at checkout (or the account''s full_name).';
comment on column public.orders.customer_phone is 'Buyer contact number as typed at checkout. Free-form — not validated or normalised.';
comment on column public.orders.owner_notified_at is 'When the sale-notification e-mail to the store owner was sent. Null on a paid order = notification failed.';

-- No RLS policy changes: orders are already service-role only for writes, and the existing
-- select policies (own user_id, or guest access_token) continue to govern reads. These
-- columns carry personal data, so they must never become anon-readable.
