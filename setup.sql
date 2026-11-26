-- =====================================================================
-- Engineering Workshop Reports — Supabase setup (run once)
-- Supabase dashboard → SQL Editor → New query → paste all → Run
-- Safe to re-run: every step checks before it creates.
-- =====================================================================

-- 1) Jobs: one row per job; the whole job (header, Condition, WIP) is JSON
create table if not exists public.jobs (
  id          text primary key,
  data        jsonb not null,
  updated_at  timestamptz not null default now(),
  updated_by  uuid default auth.uid()
);

-- keep updated_at / updated_by current on every save
create or replace function public.jobs_touch()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$;

drop trigger if exists jobs_touch on public.jobs;
create trigger jobs_touch
  before insert or update on public.jobs
  for each row execute function public.jobs_touch();

-- 2) Access: only signed-in staff can read or change jobs; nobody else
alter table public.jobs enable row level security;

drop policy if exists "staff can read jobs"   on public.jobs;
drop policy if exists "staff can add jobs"    on public.jobs;
drop policy if exists "staff can edit jobs"   on public.jobs;
drop policy if exists "staff can delete jobs" on public.jobs;

create policy "staff can read jobs"   on public.jobs for select to authenticated using (true);
create policy "staff can add jobs"    on public.jobs for insert to authenticated with check (true);
create policy "staff can edit jobs"   on public.jobs for update to authenticated using (true) with check (true);
create policy "staff can delete jobs" on public.jobs for delete to authenticated using (true);

-- 3) Live sync: phones and PCs see each other's changes straight away
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'jobs'
  ) then
    alter publication supabase_realtime add table public.jobs;
  end if;
end;
$$;

-- 4) Photos: private bucket (photos are only reachable by signed-in staff)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', false, 10485760, array['image/jpeg', 'image/png'])
on conflict (id) do nothing;

drop policy if exists "staff can view photos"   on storage.objects;
drop policy if exists "staff can upload photos" on storage.objects;
drop policy if exists "staff can delete photos" on storage.objects;

create policy "staff can view photos"   on storage.objects for select to authenticated using (bucket_id = 'photos');
create policy "staff can upload photos" on storage.objects for insert to authenticated with check (bucket_id = 'photos');
create policy "staff can delete photos" on storage.objects for delete to authenticated using (bucket_id = 'photos');
