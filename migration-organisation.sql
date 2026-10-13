-- Only needed if you already ran the first version of schema.sql.
-- If the table holds only test entries, clear them first, otherwise the new rules reject the old rows:
--   delete from public.students;

alter table public.students
  add column placed_session text check (placed_session in ('2021-2022', '2022-2023', '2023-2024', '2024-2025', '2025-2026'));

alter table public.students
  drop constraint appearing_has_no_extras,
  drop constraint ctet_no_has_no_extras,
  drop constraint employer_only_if_working;

alter table public.students
  add constraint appearing_has_no_extras check (
    status <> 'appearing'
    or (session is null and ctet_clear is null and ctet_marks is null and working is null
        and employer is null and placed_session is null)),
  add constraint ctet_no_has_no_extras check (
    ctet_clear is distinct from false
    or (ctet_marks is null and working is null and employer is null and placed_session is null)),
  add constraint organisation_rules check (
    case when working in ('government', 'private')
      then btrim(employer) <> '' and placed_session is not null
      else employer is null and placed_session is null end);
