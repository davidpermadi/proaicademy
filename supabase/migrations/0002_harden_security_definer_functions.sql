-- Security hardening flagged by the Supabase advisors.

-- Pin search_path on the updated_at helper.
create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- The signup handler is only meant to run from the auth.users trigger,
-- not as a public RPC. Remove it from the exposed API surface.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
