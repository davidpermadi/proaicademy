-- Allow guest (anonymous) checkout: a buyer can pay and receive paid files without
-- creating an account. Guest orders carry an email + a secret access_token receipt.

alter table public.orders alter column user_id drop not null;
alter table public.orders add column if not exists guest_email  text;
alter table public.orders add column if not exists access_token text;  -- secret receipt token for guest downloads
create index if not exists orders_access_token_idx on public.orders(access_token);

-- Guests never touch these tables directly (no anon RLS policies exist). They interact
-- only through Edge Functions running with the service role:
--   * create-payment   -> creates a guest order + access_token
--   * midtrans-webhook -> marks it paid
--   * download-ebook   -> exchanges (order_id + access_token) for a signed file URL
