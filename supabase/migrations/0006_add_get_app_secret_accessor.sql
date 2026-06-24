-- Service-role-only accessor for Supabase Vault secrets, so Edge Functions can read
-- MIDTRANS_SERVER_KEY without it ever touching the browser, the repo, or migration history.
--
-- Store the secret itself (NOT in version control) with:
--   select vault.create_secret('<your Midtrans server key>', 'MIDTRANS_SERVER_KEY', 'Midtrans server key');
create or replace function public.get_app_secret(p_name text)
returns text
language sql
security definer
set search_path = ''
as $$
  select decrypted_secret from vault.decrypted_secrets where name = p_name limit 1;
$$;

-- Lock it down: only the service role (used by Edge Functions) may call it.
revoke execute on function public.get_app_secret(text) from public, anon, authenticated;
grant  execute on function public.get_app_secret(text) to service_role;
