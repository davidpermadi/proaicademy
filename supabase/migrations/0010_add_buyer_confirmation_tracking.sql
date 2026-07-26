-- 0010_add_buyer_confirmation_tracking.sql
--
-- A successful payment now sends TWO e-mails: the sale notification to the store owner
-- (0008) and a purchase confirmation to the buyer. They are tracked separately on purpose —
-- one can succeed while the other fails, and each must stay independently visible and
-- retryable. Sharing a single flag would let a buyer confirmation failure hide behind a
-- successful owner notification.
--
--   select midtrans_order_id, buyer_notify_error
--   from orders where status='paid' and buyer_notified_at is null;
--
-- customer_lang records which language the buyer was browsing in at checkout ('en' | 'id'),
-- so the confirmation arrives in that language rather than defaulting everyone to English.

alter table public.orders
  add column if not exists customer_lang      text,
  add column if not exists buyer_notified_at  timestamptz,
  add column if not exists buyer_notify_error text;

comment on column public.orders.customer_lang is
  'Site language at checkout: ''en'' or ''id''. Drives the buyer confirmation e-mail language. Null = en.';
comment on column public.orders.buyer_notified_at is
  'When the purchase-confirmation e-mail to the buyer was sent. Null on a paid order = not sent.';
comment on column public.orders.buyer_notify_error is
  'Why the buyer confirmation last failed. Cleared on a successful send.';
