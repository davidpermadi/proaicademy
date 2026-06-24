-- Payment + entitlement model (Midtrans). Paid e-book files become downloadable
-- only after a completed payment grants the buyer an entitlement.

-- ============ ORDERS (one per Midtrans transaction) ============
create table if not exists public.orders (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users(id) on delete cascade,
  midtrans_order_id text unique not null,           -- order_id sent to Midtrans
  gross_amount      bigint not null,                -- server-computed total (IDR)
  status            text not null default 'pending' -- pending | paid | failed | expired | cancelled | refunded
                    check (status in ('pending','paid','failed','expired','cancelled','refunded')),
  snap_token        text,
  payment_type      text,
  raw_notification  jsonb,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index if not exists orders_user_idx on public.orders(user_id);

create table if not exists public.order_items (
  id           uuid primary key default gen_random_uuid(),
  order_id     uuid not null references public.orders(id) on delete cascade,
  product_type text not null check (product_type in ('course','ebook','consulting')),
  product_id   text not null,
  title        text,
  unit_price   bigint not null default 0,
  qty          int not null default 1,
  created_at   timestamptz not null default now()
);
create index if not exists order_items_order_idx on public.order_items(order_id);

-- ============ ENTITLEMENTS (what a user owns after paying) ============
create table if not exists public.entitlements (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  product_type text not null check (product_type in ('course','ebook','consulting')),
  product_id   text not null,
  order_id     uuid references public.orders(id) on delete set null,
  created_at   timestamptz not null default now(),
  unique (user_id, product_type, product_id)
);
create index if not exists entitlements_user_idx on public.entitlements(user_id);

drop trigger if exists trg_orders_updated on public.orders;
create trigger trg_orders_updated before update on public.orders
  for each row execute function public.set_updated_at();

-- ============ RLS ============
alter table public.orders        enable row level security;
alter table public.order_items   enable row level security;
alter table public.entitlements  enable row level security;

-- Users may READ their own orders / items / entitlements. All writes happen
-- server-side (Edge Functions using the service role), so no write policies here.
create policy "Users read own orders"
  on public.orders for select to authenticated using (auth.uid() = user_id);

create policy "Users read own order items"
  on public.order_items for select to authenticated
  using (exists (select 1 from public.orders o where o.id = order_items.order_id and o.user_id = auth.uid()));

create policy "Users read own entitlements"
  on public.entitlements for select to authenticated using (auth.uid() = user_id);

-- ============ STORAGE: paid e-book files now require a paid entitlement ============
drop policy if exists "Read ebook files" on storage.objects;
create policy "Read ebook files"
  on storage.objects for select
  to anon, authenticated
  using (
    bucket_id = 'ebook-files'
    and exists (
      select 1 from public.ebooks e
      where e.file_path = storage.objects.name
        and e.is_published
        and (
          e.price = 0   -- free e-books: open to everyone
          or exists (   -- paid e-books: only users who completed payment
            select 1 from public.entitlements ent
            where ent.user_id = auth.uid()
              and ent.product_type = 'ebook'
              and ent.product_id = e.id
          )
        )
    )
  );
