-- =============================================================================
-- Patient search pagination + pg_trgm indexes v1
--
-- Adds bounded, keyset-paginated patient list/search RPC for remote UI lists.
-- Function is SECURITY INVOKER by default, so patients RLS still applies.
-- =============================================================================

create schema if not exists extensions;
create extension if not exists pg_trgm with schema extensions;

create index if not exists patients_tenant_active_name_keyset_idx
  on public.patients (
    tenant_id,
    lower(coalesce(last_name, '')),
    lower(coalesce(first_name, '')),
    id
  )
  where deleted_at is null;

create index if not exists patients_first_name_trgm_idx
  on public.patients
  using gin (lower(coalesce(first_name, '')) extensions.gin_trgm_ops)
  where deleted_at is null;

create index if not exists patients_last_name_trgm_idx
  on public.patients
  using gin (lower(coalesce(last_name, '')) extensions.gin_trgm_ops)
  where deleted_at is null;

create index if not exists patients_file_number_trgm_idx
  on public.patients
  using gin (lower(coalesce(file_number, '')) extensions.gin_trgm_ops)
  where deleted_at is null;

create index if not exists patients_phone_trgm_idx
  on public.patients
  using gin (lower(coalesce(phone, '')) extensions.gin_trgm_ops)
  where deleted_at is null;

create index if not exists patients_national_id_trgm_idx
  on public.patients
  using gin (lower(coalesce(national_id, '')) extensions.gin_trgm_ops)
  where deleted_at is null;

create or replace function public.search_patients_page_v1(
  p_query text default null,
  p_after_last_name text default null,
  p_after_first_name text default null,
  p_after_id text default null,
  p_limit integer default 51
)
returns table (
  id uuid,
  tenant_id uuid,
  file_number text,
  first_name text,
  last_name text,
  phone text,
  birth_date date,
  gender text,
  identity_type text,
  national_id text,
  nationality text,
  blood_type text,
  occupation text,
  sports_branch text,
  secondary_phone text,
  email text,
  address text,
  city text,
  district text,
  emergency_contact_name text,
  emergency_contact_relation text,
  emergency_contact_phone text,
  emergency_contact_note text,
  insurance_type text,
  status text,
  created_at timestamptz,
  updated_at timestamptz,
  deleted_at timestamptz
)
language sql
stable
set search_path = public
as $$
  with input as (
    select
      nullif(trim(p_query), '') as q,
      lower(nullif(trim(p_after_last_name), '')) as after_last_name,
      lower(nullif(trim(p_after_first_name), '')) as after_first_name,
      nullif(trim(p_after_id), '') as after_id,
      least(greatest(coalesce(p_limit, 51), 1), 101) as safe_limit
  )
  select
    p.id,
    p.tenant_id,
    p.file_number,
    p.first_name,
    p.last_name,
    p.phone,
    p.birth_date,
    p.gender,
    p.identity_type,
    p.national_id,
    p.nationality,
    p.blood_type,
    p.occupation,
    p.sports_branch,
    p.secondary_phone,
    p.email,
    p.address,
    p.city,
    p.district,
    p.emergency_contact_name,
    p.emergency_contact_relation,
    p.emergency_contact_phone,
    p.emergency_contact_note,
    p.insurance_type,
    p.status,
    p.created_at,
    p.updated_at,
    p.deleted_at
  from public.patients p
  cross join input i
  where p.tenant_id = public.current_tenant_id()
    and p.deleted_at is null
    and (
      i.q is null
      or lower(coalesce(p.file_number, '')) like '%' || lower(i.q) || '%'
      or lower(coalesce(p.first_name, '')) like '%' || lower(i.q) || '%'
      or lower(coalesce(p.last_name, '')) like '%' || lower(i.q) || '%'
      or lower(coalesce(p.phone, '')) like '%' || lower(i.q) || '%'
      or lower(coalesce(p.national_id, '')) like '%' || lower(i.q) || '%'
    )
    and (
      i.after_id is null
      or (
        lower(coalesce(p.last_name, '')),
        lower(coalesce(p.first_name, '')),
        p.id::text
      ) > (
        coalesce(i.after_last_name, ''),
        coalesce(i.after_first_name, ''),
        i.after_id
      )
    )
  order by
    lower(coalesce(p.last_name, '')),
    lower(coalesce(p.first_name, '')),
    p.id
  limit (select safe_limit from input);
$$;

revoke all on function public.search_patients_page_v1(
  text,
  text,
  text,
  text,
  integer
) from public;

grant execute on function public.search_patients_page_v1(
  text,
  text,
  text,
  text,
  integer
) to authenticated;
