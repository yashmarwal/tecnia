-- Run once in Supabase: SQL Editor > New query > paste > Run.
-- Before running, replace the admin email(s) in the select policy at the bottom.

create table public.students (
  id           uuid primary key default gen_random_uuid(),
  created_at   timestamptz not null default now(),
  name         text not null check (btrim(name) <> '' and char_length(name) <= 100),
  father_name  text not null check (btrim(father_name) <> '' and char_length(father_name) <= 100),
  address      text not null check (btrim(address) <> '' and char_length(address) <= 300),
  phone        text not null unique check (phone ~ '^[0-9]{10}$'),
  status       text not null check (status in ('appearing', 'appeared')),
  session      text check (session in ('2021-2022', '2022-2023', '2023-2024', '2024-2025', '2025-2026')),
  ctet_clear   boolean,
  ctet_marks   integer check (ctet_marks between 0 and 150),
  working      text check (working in ('government', 'private', 'not_working')),
  employer     text check (char_length(employer) <= 150),
  placed_session text check (placed_session in ('2021-2022', '2022-2023', '2023-2024', '2024-2025', '2025-2026')),

  -- the conditional form flow, enforced again in the database
  constraint appearing_has_no_extras check (
    status <> 'appearing'
    or (session is null and ctet_clear is null and ctet_marks is null and working is null
        and employer is null and placed_session is null)),
  constraint appeared_needs_session_and_ctet check (
    status <> 'appeared' or (session is not null and ctet_clear is not null)),
  constraint ctet_yes_needs_marks_and_working check (
    ctet_clear is not true or (ctet_marks is not null and working is not null)),
  constraint ctet_no_has_no_extras check (
    ctet_clear is distinct from false
    or (ctet_marks is null and working is null and employer is null and placed_session is null)),
  -- working in a government or private job needs the organisation and the session of placement; otherwise neither is stored
  constraint organisation_rules check (
    case when working in ('government', 'private')
      then btrim(employer) <> '' and placed_session is not null
      else employer is null and placed_session is null end)
);

alter table public.students enable row level security;

revoke all on public.students from anon, authenticated;
grant insert on public.students to anon;
grant select on public.students to authenticated;

-- Anyone with the form link can add a row, nobody can read, edit or delete with the public key.
create policy "form can insert" on public.students
  for insert to anon with check (true);

-- Only the listed admin emails can read. Edit this list.
create policy "admins can read" on public.students
  for select to authenticated
  using ((auth.jwt() ->> 'email') = any (array['tecnia@ctet.com']));
