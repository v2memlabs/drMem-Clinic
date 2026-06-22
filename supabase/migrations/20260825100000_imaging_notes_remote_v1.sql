-- =============================================================================
-- Imaging notes remote v1
--
-- Prerequisite:
--   - 20260522100000_draft_rls_policies_v1.sql (tenant helpers)
--   - 20260824100000_faz2_role_access_financial_helpers_v1.sql
-- =============================================================================

create table if not exists public.imaging_notes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  patient_id uuid not null references public.patients (id) on delete restrict,
  imaging_type text not null,
  imaging_date date not null,
  imaging_center text not null default '',
  body_region text not null,
  side text not null,
  report_summary text not null default '',
  doctor_comment text not null default '',
  comparison_with_previous text not null default '',
  related_diagnosis text not null default '',
  related_visit_date text,
  attached_file_name text,
  created_by uuid references public.profiles (id),
  recorded_by_display text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint imaging_notes_type_check check (
    imaging_type in ('mr', 'bt', 'direktGrafi', 'usg', 'rapor', 'diger')
  ),
  constraint imaging_notes_body_region_check check (
    body_region in (
      'diz',
      'omuz',
      'kalca',
      'ayakBilegi',
      'ayak',
      'dirsek',
      'elBilegi',
      'el',
      'omurga',
      'diger'
    )
  ),
  constraint imaging_notes_side_check check (
    side in ('sag', 'sol', 'bilateral', 'uygunDegil')
  )
);

comment on table public.imaging_notes is
  'Görüntüleme notları — tenant scoped; soft delete via deleted_at.';

create index if not exists imaging_notes_tenant_id_idx
  on public.imaging_notes (tenant_id);

create index if not exists imaging_notes_patient_id_idx
  on public.imaging_notes (patient_id);

create index if not exists imaging_notes_date_idx
  on public.imaging_notes (tenant_id, imaging_date desc)
  where deleted_at is null;

create index if not exists imaging_notes_type_idx
  on public.imaging_notes (tenant_id, imaging_type)
  where deleted_at is null;

create index if not exists imaging_notes_deleted_at_idx
  on public.imaging_notes (tenant_id, deleted_at)
  where deleted_at is null;

drop trigger if exists imaging_notes_updated_at on public.imaging_notes;
create trigger imaging_notes_updated_at
  before update on public.imaging_notes
  for each row execute function public.set_updated_at();

alter table public.imaging_notes enable row level security;

drop policy if exists imaging_notes_select_role_access_v1 on public.imaging_notes;
create policy imaging_notes_select_role_access_v1
  on public.imaging_notes
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_imaging')
  );

drop policy if exists imaging_notes_insert_role_access_v1 on public.imaging_notes;
create policy imaging_notes_insert_role_access_v1
  on public.imaging_notes
  for insert
  to authenticated
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_imaging')
    and exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );

drop policy if exists imaging_notes_update_role_access_v1 on public.imaging_notes;
create policy imaging_notes_update_role_access_v1
  on public.imaging_notes
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_imaging')
  )
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_imaging')
    and exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );
