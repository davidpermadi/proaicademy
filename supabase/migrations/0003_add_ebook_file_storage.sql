-- E-book file storage: a private bucket for the actual downloadable files,
-- plus file-reference columns on the e-books catalogue.

-- File-reference columns on the e-books catalogue.
alter table public.ebooks
  add column if not exists file_path       text,   -- path of the uploaded file inside the 'ebook-files' bucket
  add column if not exists file_name       text,   -- original filename shown to the user
  add column if not exists file_size_bytes bigint; -- optional, for display

-- Private bucket that holds the actual downloadable e-book files (PDF/EPUB/...).
insert into storage.buckets (id, name, public)
values ('ebook-files', 'ebook-files', false)
on conflict (id) do nothing;

-- READ access to e-book files:
--   * free e-books (price = 0)  -> anyone may download
--   * paid e-books              -> any signed-in user (placeholder for purchase entitlement)
-- Downloads are served through short-lived signed URLs (storage.createSignedUrl).
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
        and (e.price = 0 or auth.role() = 'authenticated')
    )
  );

-- Uploads / updates / deletes are intentionally NOT granted to anon or authenticated.
-- Admins upload e-book files via the Supabase dashboard (or a service-role key),
-- then set ebooks.file_path / file_name to point at the uploaded object.
