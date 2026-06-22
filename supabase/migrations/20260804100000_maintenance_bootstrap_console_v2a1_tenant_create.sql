-- =============================================================================
-- Maintenance Bootstrap Console v2a-1 — Tenant Create Foundation
-- Staging/dev only — maintenance operator + maintenance_config.enabled
-- Requires: settings_persistence_foundation_v1 (tenants.settings_json)
-- =============================================================================

create or replace function public.maintenance_create_tenant_v2(
  p_name text,
  p_specialty text default null,
  p_timezone text default 'Europe/Istanbul',
  p_status text default 'active',
  p_settings_json jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_tz text;
  v_settings jsonb;
begin
  perform public.maintenance_assert_operator();

  if p_name is null or length(trim(p_name)) = 0 then
    raise exception 'empty_tenant_name' using errcode = 'P0001';
  end if;

  if not public.maintenance_is_valid_tenant_status(p_status) then
    raise exception 'invalid_tenant_status' using errcode = 'P0001';
  end if;

  v_tz := coalesce(nullif(trim(p_timezone), ''), 'Europe/Istanbul');
  v_settings := coalesce(p_settings_json, '{}'::jsonb);

  insert into public.tenants (name, specialty, timezone, status, settings_json)
  values (
    trim(p_name),
    nullif(trim(p_specialty), ''),
    v_tz,
    p_status,
    v_settings
  )
  returning id into v_id;

  insert into public.clinic_workflow_settings (tenant_id, schedule_json)
  values (v_id, '{}'::jsonb)
  on conflict (tenant_id) do nothing;

  perform public.maintenance_write_audit(
    'maintenance.tenant.create',
    v_id,
    v_id,
    null,
    jsonb_build_object(
      'target_tenant_id', v_id,
      'after_status', p_status,
      'operation_result', 'created',
      'source', 'maintenance_v2a1'
    )
  );

  return jsonb_build_object(
    'ok', true,
    'tenant_id', v_id,
    'name', trim(p_name),
    'status', p_status
  );
end;
$$;

grant execute on function public.maintenance_create_tenant_v2(text, text, text, text, jsonb) to authenticated;
