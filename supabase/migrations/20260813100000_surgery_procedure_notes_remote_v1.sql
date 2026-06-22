-- =============================================================================
-- Surgery procedure notes — surgery_procedure_notes
--
-- Prerequisite: 20260522100000_draft_rls_policies_v1.sql (RLS helpers)
-- =============================================================================

create table if not exists surgery_procedure_notes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  patient_id uuid not null references patients (id) on delete restrict,
  procedure_date date not null,
  procedure_type text not null,
  body_region text not null,
  side text not null,
  diagnosis text not null default '-',
  procedure_name text not null default '-',
  anesthesia_type text not null default '',
  asa_score text not null default '',
  tourniquet_used boolean,
  procedure_details text not null default '',
  complications text not null default '',
  implant_or_material_info text not null default '',
  arthroscopy_findings text not null default '',
  post_op_recommendations text not null default '',
  physiotherapy_start_recommendation text not null default '',
  control_schedule text not null default '',
  surgeon_name text not null default '',
  assistant_info text not null default '',
  notes text not null default '',
  created_by uuid references profiles (id),
  recorded_by_display text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table surgery_procedure_notes is
  'Ameliyat / girişim notları — tenant scoped; soft delete via deleted_at.';

create index if not exists surgery_procedure_notes_tenant_id_idx
  on surgery_procedure_notes (tenant_id);

create index if not exists surgery_procedure_notes_patient_id_idx
  on surgery_procedure_notes (patient_id);

create index if not exists surgery_procedure_notes_procedure_date_idx
  on surgery_procedure_notes (tenant_id, procedure_date desc)
  where deleted_at is null;

create index if not exists surgery_procedure_notes_deleted_at_idx
  on surgery_procedure_notes (tenant_id, deleted_at)
  where deleted_at is null;

drop trigger if exists surgery_procedure_notes_updated_at on surgery_procedure_notes;
create trigger surgery_procedure_notes_updated_at
  before update on surgery_procedure_notes
  for each row execute function set_updated_at();

alter table surgery_procedure_notes enable row level security;

drop policy if exists surgery_procedure_notes_select_doctor_v1 on surgery_procedure_notes;
create policy surgery_procedure_notes_select_doctor_v1
  on surgery_procedure_notes
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  );

drop policy if exists surgery_procedure_notes_insert_doctor_v1 on surgery_procedure_notes;
create policy surgery_procedure_notes_insert_doctor_v1
  on surgery_procedure_notes
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and exists (
      select 1
      from patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );

drop policy if exists surgery_procedure_notes_update_doctor_v1 on surgery_procedure_notes;
create policy surgery_procedure_notes_update_doctor_v1
  on surgery_procedure_notes
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and exists (
      select 1
      from patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );
