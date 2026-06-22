-- =============================================================================
-- Surgery notes: per-surgeon ownership + personal templates
-- =============================================================================

-- Tighten surgery_procedure_notes to creator-only access
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
    and created_by = current_profile_id()
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
    and created_by = current_profile_id()
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
    and created_by = current_profile_id()
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and created_by = current_profile_id()
    and exists (
      select 1
      from patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );

-- Per-surgeon surgery note templates
create table if not exists surgery_note_templates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  profile_id uuid not null references profiles (id) on delete cascade,
  name text not null,
  description text not null default '',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table surgery_note_templates is
  'Cerraha özel ameliyat / girişim notu şablonları — payload form varsayılanları.';

create index if not exists surgery_note_templates_tenant_profile_idx
  on surgery_note_templates (tenant_id, profile_id)
  where deleted_at is null;

drop trigger if exists surgery_note_templates_updated_at on surgery_note_templates;
create trigger surgery_note_templates_updated_at
  before update on surgery_note_templates
  for each row execute function set_updated_at();

alter table surgery_note_templates enable row level security;

drop policy if exists surgery_note_templates_select_own_v1 on surgery_note_templates;
create policy surgery_note_templates_select_own_v1
  on surgery_note_templates
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and profile_id = current_profile_id()
  );

drop policy if exists surgery_note_templates_insert_own_v1 on surgery_note_templates;
create policy surgery_note_templates_insert_own_v1
  on surgery_note_templates
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and profile_id = current_profile_id()
  );

drop policy if exists surgery_note_templates_update_own_v1 on surgery_note_templates;
create policy surgery_note_templates_update_own_v1
  on surgery_note_templates
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and profile_id = current_profile_id()
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and profile_id = current_profile_id()
  );

drop policy if exists surgery_note_templates_delete_own_v1 on surgery_note_templates;
create policy surgery_note_templates_delete_own_v1
  on surgery_note_templates
  for delete
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and profile_id = current_profile_id()
  );
