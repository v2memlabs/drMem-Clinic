-- =============================================================================
-- Tenant user provision — admin creates active user (no invite registration)
-- =============================================================================

create or replace function public.bootstrap_tenant_provisioned_user_v2(
  p_auth_user_id uuid,
  p_email text,
  p_display_name text,
  p_role text,
  p_target_membership_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_caller_profile_id uuid;
  v_caller_email text;
  v_profile_id uuid;
  v_profile_auth uuid;
  v_profile_operator boolean;
  v_membership_id uuid;
  v_existing_role text;
  v_existing_status text;
  v_profile_created boolean := false;
  v_profile_linked boolean := false;
  v_membership_created boolean := false;
  v_operation text := 'created';
begin
  v_tenant_id := public._user_mgmt_assert_doctor_admin();
  v_caller_profile_id := public.current_profile_id();

  perform public._invite_v2a_assert_tenant_active(v_tenant_id);

  if p_auth_user_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0001';
  end if;

  if p_email is null or length(trim(p_email)) = 0 then
    raise exception 'invalid_email' using errcode = 'P0001';
  end if;

  if p_display_name is null or length(trim(p_display_name)) = 0 then
    raise exception 'invalid_display_name' using errcode = 'P0001';
  end if;

  if not public._user_mgmt_is_valid_role(p_role) then
    raise exception 'invalid_role' using errcode = 'P0001';
  end if;

  if p_target_membership_id is not null
     and exists (
       select 1 from public.memberships m
       where m.id = p_target_membership_id
         and m.tenant_id is distinct from v_tenant_id
     ) then
    raise exception 'membership_conflict' using errcode = 'P0001';
  end if;

  select p.email
  into v_caller_email
  from public.profiles p
  where p.id = v_caller_profile_id;

  if lower(trim(coalesce(v_caller_email, ''))) = lower(trim(p_email)) then
    raise exception 'self_invite_blocked' using errcode = 'P0001';
  end if;

  if not exists (select 1 from auth.users u where u.id = p_auth_user_id) then
    raise exception 'auth_user_not_found' using errcode = 'P0001';
  end if;

  if exists (
    select 1
    from public.profiles p
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

  if exists (
    select 1
    from public.profiles p
    where p.auth_user_id = p_auth_user_id
      and p.id is distinct from v_profile_id
  ) then
    raise exception 'auth_user_already_linked' using errcode = 'P0001';
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
  elsif v_profile_auth is null then
    update public.profiles
    set auth_user_id = p_auth_user_id,
        display_name = coalesce(nullif(trim(p_display_name), ''), display_name),
        email = coalesce(nullif(trim(p_email), ''), email),
        updated_at = now()
    where id = v_profile_id;

    v_profile_linked := true;
    v_profile_auth := p_auth_user_id;
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
  where m.tenant_id = v_tenant_id
    and m.profile_id = v_profile_id
  limit 1
  for update;

  if v_membership_id is null then
    insert into public.memberships (
      id,
      tenant_id,
      profile_id,
      role,
      status
    )
    values (
      coalesce(p_target_membership_id, gen_random_uuid()),
      v_tenant_id,
      v_profile_id,
      p_role,
      'active'
    )
    returning id into v_membership_id;

    v_membership_created := true;
    v_operation := 'created';
  elsif v_existing_status = 'active' and v_existing_role = p_role then
    v_operation := 'already_active';
  elsif v_existing_status = 'active' and v_existing_role <> p_role then
    update public.memberships
    set role = p_role,
        updated_at = now()
    where id = v_membership_id;

    v_operation := 'role_updated';
  elsif v_existing_status in ('invited', 'disabled') then
    update public.memberships
    set role = p_role,
        status = 'active',
        updated_at = now()
    where id = v_membership_id;

    v_operation := 'reactivated';
  else
    raise exception 'membership_conflict' using errcode = 'P0001';
  end if;

  if v_profile_created or v_profile_linked or v_membership_created
     or v_operation in ('reactivated', 'role_updated') then
    perform public._user_mgmt_write_audit(
      'user.provision.create',
      v_membership_id,
      jsonb_build_object(
        'target_profile_id', v_profile_id,
        'target_membership_id', v_membership_id,
        'role', p_role,
        'status', 'active',
        'operation_result', v_operation,
        'source', 'settings_provision_v1'
      )
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'operation_result', v_operation,
    'target_profile_id', v_profile_id,
    'target_membership_id', v_membership_id,
    'role', p_role,
    'status', 'active'
  );
end;
$$;

revoke all on function public.bootstrap_tenant_provisioned_user_v2(uuid, text, text, text, uuid) from public;
grant execute on function public.bootstrap_tenant_provisioned_user_v2(uuid, text, text, text, uuid) to authenticated;
