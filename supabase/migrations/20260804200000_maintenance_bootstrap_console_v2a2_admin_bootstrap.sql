-- =============================================================================
-- Maintenance Bootstrap Console v2a-2 — Auth Provisioning + Initial Admin
-- Staging/dev only — maintenance operator + maintenance_config.enabled
-- Requires: v2a-1 tenant create foundation
-- =============================================================================

create or replace function public.maintenance_bootstrap_user_v2(
  p_auth_user_id uuid,
  p_email text,
  p_display_name text,
  p_tenant_id uuid,
  p_role text,
  p_membership_status text default 'active',
  p_mode text default 'create'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_profile_auth uuid;
  v_profile_operator boolean;
  v_membership_id uuid;
  v_existing_role text;
  v_existing_status text;
  v_tenant_status text;
  v_profile_created boolean := false;
  v_profile_linked boolean := false;
  v_membership_created boolean := false;
  v_operation text := 'created';
begin
  perform public.maintenance_assert_operator();

  if p_auth_user_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0001';
  end if;

  if p_email is null or length(trim(p_email)) = 0 then
    raise exception 'invalid_email' using errcode = 'P0001';
  end if;

  if p_tenant_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0001';
  end if;

  if p_role is distinct from 'doctor_admin' then
    raise exception 'invalid_role' using errcode = 'P0001';
  end if;

  if not public.maintenance_is_valid_membership_status(p_membership_status) then
    raise exception 'invalid_status' using errcode = 'P0001';
  end if;

  if coalesce(p_mode, 'create') is distinct from 'create' then
    raise exception 'invalid_mode' using errcode = 'P0001';
  end if;

  if not exists (select 1 from auth.users u where u.id = p_auth_user_id) then
    raise exception 'auth_user_not_found' using errcode = 'P0001';
  end if;

  select t.status into v_tenant_status
  from public.tenants t
  where t.id = p_tenant_id
  for update;

  if not found then
    raise exception 'tenant_not_found' using errcode = 'P0001';
  end if;

  if v_tenant_status not in ('active', 'trial') then
    raise exception 'tenant_inactive' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.profiles p
    where p.auth_user_id = p_auth_user_id
      and lower(trim(coalesce(p.email, ''))) <> lower(trim(p_email))
  ) then
    raise exception 'auth_user_already_linked' using errcode = 'P0001';
  end if;

  select p.id, p.auth_user_id, coalesce(p.maintenance_operator, false)
  into v_profile_id, v_profile_auth, v_profile_operator
  from public.profiles p
  where lower(trim(coalesce(p.email, ''))) = lower(trim(p_email))
  limit 1
  for update;

  if v_profile_id is null then
    select p.id, p.auth_user_id, coalesce(p.maintenance_operator, false)
    into v_profile_id, v_profile_auth, v_profile_operator
    from public.profiles p
    where p.auth_user_id = p_auth_user_id
    limit 1
    for update;
  end if;

  if v_profile_id is not null and v_profile_operator then
    raise exception 'maintenance_operator_target_rejected' using errcode = 'P0001';
  end if;

  if v_profile_id is not null
     and v_profile_auth is not null
     and v_profile_auth <> p_auth_user_id then
    raise exception 'profile_conflict' using errcode = 'P0001';
  end if;

  if v_profile_id is null then
    insert into public.profiles (email, display_name, auth_user_id, maintenance_operator)
    values (
      trim(p_email),
      nullif(trim(p_display_name), ''),
      p_auth_user_id,
      false
    )
    returning id into v_profile_id;

    v_profile_created := true;
    v_profile_auth := p_auth_user_id;

    perform public.maintenance_write_audit(
      'maintenance.profile.create',
      v_profile_id,
      p_tenant_id,
      v_profile_id,
      jsonb_build_object(
        'target_profile_id', v_profile_id,
        'target_tenant_id', p_tenant_id,
        'operation_result', 'created',
        'source', 'maintenance_v2a2'
      )
    );
  elsif v_profile_auth is null then
    update public.profiles
    set auth_user_id = p_auth_user_id,
        display_name = coalesce(nullif(trim(p_display_name), ''), display_name),
        updated_at = now()
    where id = v_profile_id;

    v_profile_linked := true;
    v_profile_auth := p_auth_user_id;

    perform public.maintenance_write_audit(
      'maintenance.profile.auth_link',
      v_profile_id,
      p_tenant_id,
      v_profile_id,
      jsonb_build_object(
        'target_profile_id', v_profile_id,
        'target_tenant_id', p_tenant_id,
        'operation_result', 'linked',
        'source', 'maintenance_v2a2'
      )
    );
  else
    if nullif(trim(p_display_name), '') is not null then
      update public.profiles
      set display_name = nullif(trim(p_display_name), ''),
          updated_at = now()
      where id = v_profile_id;
    end if;
  end if;

  select m.id, m.role, m.status
  into v_membership_id, v_existing_role, v_existing_status
  from public.memberships m
  where m.tenant_id = p_tenant_id
    and m.profile_id = v_profile_id
  limit 1
  for update;

  if v_membership_id is null then
    insert into public.memberships (tenant_id, profile_id, role, status)
    values (p_tenant_id, v_profile_id, p_role, p_membership_status)
    returning id into v_membership_id;

    v_membership_created := true;

    perform public.maintenance_write_audit(
      'maintenance.membership.create',
      v_membership_id,
      p_tenant_id,
      v_profile_id,
      jsonb_build_object(
        'target_membership_id', v_membership_id,
        'target_tenant_id', p_tenant_id,
        'target_profile_id', v_profile_id,
        'role', p_role,
        'status', p_membership_status,
        'operation_result', 'created',
        'source', 'maintenance_v2a2'
      )
    );
  elsif v_existing_role = p_role and v_existing_status = p_membership_status then
    v_operation := 'already_exists';
  else
    raise exception 'membership_exists' using errcode = 'P0001';
  end if;

  if not v_profile_created and not v_profile_linked and not v_membership_created then
    v_operation := 'already_exists';
  end if;

  perform public.maintenance_write_audit(
    'maintenance.bootstrap.complete',
    v_profile_id,
    p_tenant_id,
    v_profile_id,
    jsonb_build_object(
      'target_tenant_id', p_tenant_id,
      'target_profile_id', v_profile_id,
      'target_membership_id', v_membership_id,
      'role', p_role,
      'status', p_membership_status,
      'operation_result', v_operation,
      'source', 'maintenance_v2a2'
    )
  );

  return jsonb_build_object(
    'ok', true,
    'profile_id', v_profile_id,
    'membership_id', v_membership_id,
    'auth_user_id', p_auth_user_id,
    'operation_result', v_operation
  );
end;
$$;

create or replace function public.maintenance_bootstrap_status_v2(
  p_tenant_id uuid,
  p_profile_id uuid default null,
  p_auth_user_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_uid uuid;
  v_profile_id uuid;
  v_profile_auth uuid;
  v_tenant_status text;
  v_membership_id uuid;
  v_membership_role text;
  v_membership_status text;
  v_auth_exists boolean := false;
  v_profile_exists boolean := false;
  v_auth_linked boolean := false;
  v_membership_exists boolean := false;
  v_membership_active boolean := false;
  v_tenant_active boolean := false;
  v_chain_ok boolean := false;
  v_gap_code text;
begin
  perform public.maintenance_assert_operator();

  if p_tenant_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0001';
  end if;

  select t.status into v_tenant_status
  from public.tenants t
  where t.id = p_tenant_id;

  if not found then
    raise exception 'tenant_not_found' using errcode = 'P0001';
  end if;

  v_tenant_active := v_tenant_status in ('active', 'trial');
  v_auth_uid := p_auth_user_id;

  if p_profile_id is not null then
    select p.id, p.auth_user_id
    into v_profile_id, v_profile_auth
    from public.profiles p
    where p.id = p_profile_id;
  end if;

  if v_profile_id is null and v_auth_uid is not null then
    select p.id, p.auth_user_id
    into v_profile_id, v_profile_auth
    from public.profiles p
    where p.auth_user_id = v_auth_uid
    limit 1;
  end if;

  if v_auth_uid is null and v_profile_auth is not null then
    v_auth_uid := v_profile_auth;
  end if;

  v_auth_exists := v_auth_uid is not null
    and exists (select 1 from auth.users u where u.id = v_auth_uid);
  v_profile_exists := v_profile_id is not null;
  v_auth_linked := v_profile_exists
    and v_auth_exists
    and v_profile_auth = v_auth_uid;

  if v_profile_id is not null then
    select m.id, m.role, m.status
    into v_membership_id, v_membership_role, v_membership_status
    from public.memberships m
    where m.tenant_id = p_tenant_id
      and m.profile_id = v_profile_id
    limit 1;
  end if;

  v_membership_exists := v_membership_id is not null;
  v_membership_active := v_membership_exists and v_membership_status = 'active';

  v_chain_ok := v_tenant_active
    and v_auth_exists
    and v_profile_exists
    and v_auth_linked
    and v_membership_exists
    and v_membership_active
    and v_membership_role = 'doctor_admin';

  if not v_chain_ok then
    if not v_tenant_active then
      v_gap_code := 'tenant_inactive';
    elsif not v_auth_exists then
      v_gap_code := 'auth_missing';
    elsif not v_profile_exists then
      v_gap_code := 'profile_missing';
    elsif not v_auth_linked then
      v_gap_code := 'auth_not_linked';
    elsif not v_membership_exists then
      v_gap_code := 'membership_missing';
    elsif not v_membership_active then
      v_gap_code := 'membership_inactive';
    elsif v_membership_role is distinct from 'doctor_admin' then
      v_gap_code := 'role_mismatch';
    else
      v_gap_code := 'unknown_gap';
    end if;
  end if;

  return jsonb_build_object(
    'ok', true,
    'tenant_id', p_tenant_id,
    'profile_id', v_profile_id,
    'auth_user_id', v_auth_uid,
    'auth_exists', v_auth_exists,
    'profile_exists', v_profile_exists,
    'auth_linked', v_auth_linked,
    'membership_exists', v_membership_exists,
    'membership_active', v_membership_active,
    'role', v_membership_role,
    'tenant_active', v_tenant_active,
    'chain_ok', v_chain_ok,
    'gap_code', v_gap_code
  );
end;
$$;

grant execute on function public.maintenance_bootstrap_user_v2(uuid, text, text, uuid, text, text, text) to authenticated;
grant execute on function public.maintenance_bootstrap_status_v2(uuid, uuid, uuid) to authenticated;

-- Edge Function partial-failure audit (operator-gated inside function body)
grant execute on function public.maintenance_write_audit(text, uuid, uuid, uuid, jsonb) to authenticated;
