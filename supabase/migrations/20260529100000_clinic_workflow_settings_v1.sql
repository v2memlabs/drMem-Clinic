-- Clinic workflow settings v1 — tenant-scoped mesai / slot / kapalı günler
-- Randevu availability motoru schedule_json ile beslenir.

create table if not exists clinic_workflow_settings (
  tenant_id uuid primary key references tenants (id) on delete cascade,
  schedule_json jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid null
);

comment on table clinic_workflow_settings is
  'Klinik çalışma günleri, öğle arası, slot süresi ve kapalı tarihler (tenant başına tek kayıt).';

create index if not exists idx_clinic_workflow_settings_updated
  on clinic_workflow_settings (tenant_id, updated_at desc);

alter table clinic_workflow_settings enable row level security;

drop policy if exists clinic_workflow_settings_select_member_v1 on clinic_workflow_settings;
create policy clinic_workflow_settings_select_member_v1
  on clinic_workflow_settings
  for select
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
  );

drop policy if exists clinic_workflow_settings_upsert_doctor_v1 on clinic_workflow_settings;
create policy clinic_workflow_settings_upsert_doctor_v1
  on clinic_workflow_settings
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  );

drop policy if exists clinic_workflow_settings_update_doctor_v1 on clinic_workflow_settings;
create policy clinic_workflow_settings_update_doctor_v1
  on clinic_workflow_settings
  for update
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  );
