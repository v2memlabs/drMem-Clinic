-- =============================================================================
-- Maintenance — tenant rol erişim matrisi (settings_json.role_access)
-- Yalnızca maintenance operator yazar; klinik kullanıcıları oturumda okur.
-- =============================================================================

create or replace function public.maintenance_get_tenant_role_access_settings(
  p_tenant_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role_access jsonb;
begin
  perform public.maintenance_assert_operator();

  if p_tenant_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0001';
  end if;

  select coalesce(t.settings_json -> 'role_access', '{}'::jsonb)
    into v_role_access
  from public.tenants t
  where t.id = p_tenant_id;

  if not found then
    raise exception 'tenant_not_found' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'ok', true,
    'tenant_id', p_tenant_id,
    'role_access', v_role_access
  );
end;
$$;

create or replace function public.maintenance_update_tenant_role_access_settings(
  p_tenant_id uuid,
  p_role_access jsonb
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

  if p_role_access is null or jsonb_typeof(p_role_access) <> 'object' then
    raise exception 'invalid_role_access_settings' using errcode = 'P0001';
  end if;

  select coalesce(t.settings_json -> 'role_access', '{}'::jsonb)
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
      '{role_access}',
      p_role_access,
      true
    ),
    updated_at = now()
  where id = p_tenant_id
  returning settings_json -> 'role_access' into v_after;

  perform public.maintenance_write_audit(
    'maintenance.tenant.role_access_settings_update',
    p_tenant_id,
    p_tenant_id,
    null,
    jsonb_build_object(
      'target_tenant_id', p_tenant_id,
      'before_role_access', v_before,
      'after_role_access', v_after,
      'source', 'maintenance_role_access_v1'
    )
  );

  return jsonb_build_object(
    'ok', true,
    'tenant_id', p_tenant_id,
    'role_access', v_after
  );
end;
$$;

grant execute on function public.maintenance_get_tenant_role_access_settings(uuid)
  to authenticated;
grant execute on function public.maintenance_update_tenant_role_access_settings(uuid, jsonb)
  to authenticated;
