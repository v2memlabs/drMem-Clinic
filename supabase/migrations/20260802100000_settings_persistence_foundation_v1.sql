-- Settings Persistence Foundation v1
-- tenants.settings_json for tenant-level preferences (date/time format, week start).
-- tenants UPDATE for doctor_admin (name, specialty, settings_json).

alter table public.tenants
  add column if not exists settings_json jsonb not null default '{}'::jsonb;

comment on column public.tenants.settings_json is
  'Tenant-scoped UI preferences: date_time_format, week_start, etc.';

-- =============================================================================
-- tenants UPDATE — doctor_admin of active tenant only
-- =============================================================================

drop policy if exists tenants_update_doctor_admin_settings_v1 on public.tenants;
create policy tenants_update_doctor_admin_settings_v1
  on public.tenants
  for update
  to authenticated
  using (
    id = current_tenant_id()
    and is_tenant_member(id)
    and has_tenant_role(id, array['doctor_admin'])
    and status = 'active'
  )
  with check (
    id = current_tenant_id()
    and is_tenant_member(id)
    and has_tenant_role(id, array['doctor_admin'])
    and status = 'active'
  );
