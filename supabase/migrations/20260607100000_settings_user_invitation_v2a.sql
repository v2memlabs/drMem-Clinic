-- =============================================================================
-- Settings User Invitation v2a — Send Invite + Accept Lifecycle
-- Tenant-scoped doctor_admin invite bootstrap + self-accept + status guard
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Helper: assert tenant active/trial for current tenant context
-- -----------------------------------------------------------------------------

create or replace function public._invite_v2a_assert_tenant_active(p_tenant_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_tenant_status text;
begin
  select t.status
  into v_tenant_status
  from public.tenants t
  where t.id = p_tenant_id;

  if not found then
    raise exception 'no_active_tenant' using errcode = 'P0001';
  end if;

  if v_tenant_status not in ('active', 'trial') then
    raise exception 'tenant_inactive' using errcode = 'P0001';
  end if;
end;
$$;

revoke all on function public._invite_v2a_assert_tenant_active(uuid) from public;

-- -----------------------------------------------------------------------------
-- bootstrap_tenant_invited_user_v2
-- -----------------------------------------------------------------------------

create or replace function public.bootstrap_tenant_invited_user_v2(
  p_auth_user_id uuid,
  p_email text,
  p_display_name text,
  p_role text
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
    insert into public.memberships (tenant_id, profile_id, role, status)
    values (v_tenant_id, v_profile_id, p_role, 'invited')
    returning id into v_membership_id;

    v_membership_created := true;
    v_operation := 'created';
  elsif v_existing_status = 'active' then
    raise exception 'membership_already_active' using errcode = 'P0001';
  elsif v_existing_status = 'invited' and v_existing_role = p_role then
    v_operation := 'invitation_already_pending';
  elsif v_existing_status = 'invited' and v_existing_role <> p_role then
    update public.memberships
    set role = p_role,
        updated_at = now()
    where id = v_membership_id;

    v_operation := 'invitation_already_pending';
  elsif v_existing_status = 'disabled' then
    update public.memberships
    set role = p_role,
        status = 'invited',
        updated_at = now()
    where id = v_membership_id;

    v_operation := 'reinvited';
  else
    raise exception 'membership_conflict' using errcode = 'P0001';
  end if;

  if v_profile_created or v_profile_linked or v_membership_created or v_operation = 'reinvited' then
    perform public._user_mgmt_write_audit(
      'user.invite.send',
      v_membership_id,
      jsonb_build_object(
        'target_profile_id', v_profile_id,
        'target_membership_id', v_membership_id,
        'role', p_role,
        'status', 'invited',
        'operation_result', v_operation,
        'source', 'settings_invitation_v2a'
      )
    );

    if v_membership_created or v_operation = 'reinvited' then
      perform public._user_mgmt_write_audit(
        'membership.invited',
        v_membership_id,
        jsonb_build_object(
          'target_profile_id', v_profile_id,
          'target_membership_id', v_membership_id,
          'role', p_role,
          'status', 'invited',
          'operation_result', v_operation,
          'source', 'settings_invitation_v2a'
        )
      );
    end if;
  end if;

  return jsonb_build_object(
    'ok', true,
    'operation_result', v_operation,
    'target_profile_id', v_profile_id,
    'target_membership_id', v_membership_id,
    'role', p_role,
    'status', 'invited'
  );
end;
$$;

-- -----------------------------------------------------------------------------
-- accept_my_tenant_invitation_v2
-- -----------------------------------------------------------------------------

create or replace function public.accept_my_tenant_invitation_v2(
  p_membership_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_uid uuid;
  v_profile_id uuid;
  v_membership_id uuid;
  v_tenant_id uuid;
  v_role text;
  v_tenant_status text;
  v_invited_count int;
begin
  v_auth_uid := auth.uid();
  if v_auth_uid is null then
    raise exception 'unauthorized' using errcode = 'P0001';
  end if;

  select p.id
  into v_profile_id
  from public.profiles p
  where p.auth_user_id = v_auth_uid
    and coalesce(p.maintenance_operator, false) = false
  limit 1;

  if v_profile_id is null then
    raise exception 'no_active_profile' using errcode = 'P0001';
  end if;

  if p_membership_id is not null then
    select m.id, m.tenant_id, m.role, t.status
    into v_membership_id, v_tenant_id, v_role, v_tenant_status
    from public.memberships m
    join public.tenants t on t.id = m.tenant_id
    where m.id = p_membership_id
      and m.profile_id = v_profile_id
      and m.status = 'invited'
    for update;

    if not found then
      raise exception 'invitation_not_found' using errcode = 'P0001';
    end if;
  else
    select count(*)::int
    into v_invited_count
    from public.memberships m
    join public.tenants t on t.id = m.tenant_id
    where m.profile_id = v_profile_id
      and m.status = 'invited'
      and t.status in ('active', 'trial');

    if v_invited_count = 0 then
      raise exception 'invitation_not_found' using errcode = 'P0001';
    end if;

    if v_invited_count > 1 then
      raise exception 'multiple_pending_invitations' using errcode = 'P0001';
    end if;

    select m.id, m.tenant_id, m.role, t.status
    into v_membership_id, v_tenant_id, v_role, v_tenant_status
    from public.memberships m
    join public.tenants t on t.id = m.tenant_id
    where m.profile_id = v_profile_id
      and m.status = 'invited'
      and t.status in ('active', 'trial')
    order by m.created_at asc
    limit 1
    for update;
  end if;

  if v_tenant_status not in ('active', 'trial') then
    raise exception 'tenant_inactive' using errcode = 'P0001';
  end if;

  update public.memberships
  set status = 'active',
      updated_at = now()
  where id = v_membership_id;

  perform public._user_mgmt_write_audit(
    'invitation.accepted',
    v_membership_id,
    jsonb_build_object(
      'target_membership_id', v_membership_id,
      'role', v_role,
      'status', 'active',
      'operation_result', 'accepted',
      'source', 'settings_invitation_v2a'
    )
  );

  return jsonb_build_object(
    'ok', true,
    'membership_id', v_membership_id,
    'tenant_id', v_tenant_id,
    'role', v_role,
    'status', 'active'
  );
end;
$$;

-- -----------------------------------------------------------------------------
-- update_tenant_membership_status_v1 — block invited → active manual update
-- -----------------------------------------------------------------------------

create or replace function public.update_tenant_membership_status_v1(
  p_membership_id uuid,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_profile_id uuid;
  v_target_profile uuid;
  v_before_role text;
  v_before_status text;
  v_active_doctor_count int;
begin
  v_tenant_id := public._user_mgmt_assert_doctor_admin();
  v_profile_id := public.current_profile_id();

  if not public._user_mgmt_is_valid_status(p_status) then
    raise exception 'invalid_status' using errcode = 'P0001';
  end if;

  select m.role, m.status, m.profile_id
  into v_before_role, v_before_status, v_target_profile
  from public.memberships m
  where m.id = p_membership_id
    and m.tenant_id = v_tenant_id
  for update;

  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if v_before_status = 'invited' and p_status = 'active' then
    raise exception 'invitation_acceptance_required' using errcode = 'P0001';
  end if;

  if v_target_profile = v_profile_id and p_status = 'disabled' then
    raise exception 'self_update_blocked' using errcode = 'P0001';
  end if;

  if v_before_role = 'doctor_admin'
     and v_before_status = 'active'
     and p_status = 'disabled' then
    select count(*)::int
    into v_active_doctor_count
    from public.memberships m
    where m.tenant_id = v_tenant_id
      and m.role = 'doctor_admin'
      and m.status = 'active';

    if v_active_doctor_count <= 1 then
      raise exception 'last_admin_blocked' using errcode = 'P0001';
    end if;
  end if;

  update public.memberships
  set status = p_status,
      updated_at = now()
  where id = p_membership_id;

  perform public._user_mgmt_write_audit(
    'membership.status_update',
    p_membership_id,
    jsonb_build_object(
      'membership_id', p_membership_id,
      'field', 'status',
      'before', v_before_status,
      'after', p_status
    )
  );

  return jsonb_build_object('ok', true, 'membership_id', p_membership_id);
end;
$$;

-- -----------------------------------------------------------------------------
-- Grants
-- -----------------------------------------------------------------------------

grant execute on function public.bootstrap_tenant_invited_user_v2(uuid, text, text, text) to authenticated;
grant execute on function public.accept_my_tenant_invitation_v2(uuid) to authenticated;
