-- =============================================================================
-- Maintenance — tenant finansal özellik bayrakları (settings_json.financial)
-- Yalnızca maintenance operator yazar; klinik kullanıcıları okuyabilir.
-- =============================================================================

create or replace function public.maintenance_get_tenant_financial_settings(
  p_tenant_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_financial jsonb;
begin
  perform public.maintenance_assert_operator();

  if p_tenant_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0001';
  end if;

  select coalesce(t.settings_json -> 'financial', '{}'::jsonb)
    into v_financial
  from public.tenants t
  where t.id = p_tenant_id;

  if not found then
    raise exception 'tenant_not_found' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'ok', true,
    'tenant_id', p_tenant_id,
    'financial', v_financial
  );
end;
$$;

create or replace function public.maintenance_update_tenant_financial_settings(
  p_tenant_id uuid,
  p_financial jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_before jsonb;
  v_after jsonb;
begin
  perform public.maintenance_assert_operator();

  if p_tenant_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0001';
  end if;

  if p_financial is null or jsonb_typeof(p_financial) <> 'object' then
    raise exception 'invalid_financial_settings' using errcode = 'P0001';
  end if;

  select coalesce(t.settings_json -> 'financial', '{}'::jsonb)
    into v_before
  from public.tenants t
  where t.id = p_tenant_id
  for update;

  if not found then
    raise exception 'tenant_not_found' using errcode = 'P0001';
  end if;

  update public.tenants
  set
    settings_json = jsonb_set(
      coalesce(settings_json, '{}'::jsonb),
      '{financial}',
      p_financial,
      true
    ),
    updated_at = now()
  where id = p_tenant_id
  returning settings_json -> 'financial' into v_after;

  perform public.maintenance_write_audit(
    'maintenance.tenant.financial_settings_update',
    p_tenant_id,
    p_tenant_id,
    null,
    jsonb_build_object(
      'target_tenant_id', p_tenant_id,
      'before_financial', v_before,
      'after_financial', v_after,
      'source', 'maintenance_financial_v1'
    )
  );

  return jsonb_build_object(
    'ok', true,
    'tenant_id', p_tenant_id,
    'financial', v_after
  );
end;
$$;

grant execute on function public.maintenance_get_tenant_financial_settings(uuid)
  to authenticated;
grant execute on function public.maintenance_update_tenant_financial_settings(uuid, jsonb)
  to authenticated;
