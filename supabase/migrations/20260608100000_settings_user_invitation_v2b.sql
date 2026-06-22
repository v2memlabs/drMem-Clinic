-- =============================================================================
-- Settings User Invitation v2b — Resend + Cancel
-- =============================================================================

alter table public.memberships
  add column if not exists last_invited_at timestamptz;

comment on column public.memberships.last_invited_at is
  'Settings invitation v2b — son davet/resend zamanı (server-side cooldown)';

-- -----------------------------------------------------------------------------
-- bootstrap_tenant_invited_user_v2 — last_invited_at on successful invite
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
    insert into public.memberships (tenant_id, profile_id, role, status, last_invited_at)
    values (v_tenant_id, v_profile_id, p_role, 'invited', now())
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

  update public.memberships
  set last_invited_at = now(),
      updated_at = now()
  where id = v_membership_id;

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
-- prepare_tenant_invitation_resend_v2 — EF internal context + cooldown gate
-- -----------------------------------------------------------------------------

create or replace function public.prepare_tenant_invitation_resend_v2(
  p_membership_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_profile_id uuid;
  v_profile_auth uuid;
  v_profile_operator boolean;
  v_email text;
  v_display_name text;
  v_role text;
  v_status text;
  v_last_invited_at timestamptz;
begin
  v_tenant_id := public._user_mgmt_assert_doctor_admin();
  perform public._invite_v2a_assert_tenant_active(v_tenant_id);

  if p_membership_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0001';
  end if;

  select
    m.profile_id,
    m.role,
    m.status,
    m.last_invited_at,
    p.auth_user_id,
    coalesce(p.maintenance_operator, false),
    p.email,
    p.display_name
  into
    v_profile_id,
    v_role,
    v_status,
    v_last_invited_at,
    v_profile_auth,
    v_profile_operator,
    v_email,
    v_display_name
  from public.memberships m
  join public.profiles p on p.id = m.profile_id
  where m.id = p_membership_id
    and m.tenant_id = v_tenant_id
  for update;

  if not found then
    raise exception 'invitation_not_found' using errcode = 'P0001';
  end if;

  if v_profile_operator then
    raise exception 'maintenance_operator_target_rejected' using errcode = 'P0001';
  end if;

  if v_status is distinct from 'invited' then
    raise exception 'invitation_not_pending' using errcode = 'P0001';
  end if;

  if v_last_invited_at is not null
     and v_last_invited_at > (now() - interval '60 seconds') then
    raise exception 'invite_rate_limited' using errcode = 'P0001';
  end if;

  if v_profile_auth is null then
    raise exception 'profile_conflict' using errcode = 'P0001';
  end if;

  if v_email is null or length(trim(v_email)) = 0 then
    raise exception 'profile_conflict' using errcode = 'P0001';
  end if;

  if not exists (select 1 from auth.users u where u.id = v_profile_auth) then
    raise exception 'auth_user_not_found' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'ok', true,
    'target_profile_id', v_profile_id,
    'target_membership_id', p_membership_id,
    'auth_user_id', v_profile_auth,
    'email', trim(v_email),
    'display_name', coalesce(nullif(trim(v_display_name), ''), 'Kullanıcı'),
    'role', v_role,
    'status', v_status
  );
end;
$$;

revoke all on function public.prepare_tenant_invitation_resend_v2(uuid) from public;
grant execute on function public.prepare_tenant_invitation_resend_v2(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- complete_tenant_invitation_resend_v2
-- -----------------------------------------------------------------------------

create or replace function public.complete_tenant_invitation_resend_v2(
  p_membership_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_profile_id uuid;
  v_role text;
  v_status text;
begin
  v_tenant_id := public._user_mgmt_assert_doctor_admin();
  perform public._invite_v2a_assert_tenant_active(v_tenant_id);

  if p_membership_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0001';
  end if;

  select m.profile_id, m.role, m.status
  into v_profile_id, v_role, v_status
  from public.memberships m
  join public.profiles p on p.id = m.profile_id
  where m.id = p_membership_id
    and m.tenant_id = v_tenant_id
    and coalesce(p.maintenance_operator, false) = false
  for update;

  if not found then
    raise exception 'invitation_not_found' using errcode = 'P0001';
  end if;

  if v_status is distinct from 'invited' then
    raise exception 'invitation_not_pending' using errcode = 'P0001';
  end if;

  update public.memberships
  set last_invited_at = now(),
      updated_at = now()
  where id = p_membership_id;

  perform public._user_mgmt_write_audit(
    'user.invite.resend',
    p_membership_id,
    jsonb_build_object(
      'target_profile_id', v_profile_id,
      'target_membership_id', p_membership_id,
      'role', v_role,
      'status', 'invited',
      'operation_result', 'resent',
      'source', 'settings_invitation_v2b'
    )
  );

  return jsonb_build_object(
    'ok', true,
    'target_profile_id', v_profile_id,
    'target_membership_id', p_membership_id,
    'role', v_role,
    'status', 'invited',
    'operation_result', 'resent'
  );
end;
$$;

grant execute on function public.complete_tenant_invitation_resend_v2(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- cancel_tenant_invitation_v2
-- -----------------------------------------------------------------------------

create or replace function public.cancel_tenant_invitation_v2(
  p_membership_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_profile_id uuid;
  v_role text;
  v_status text;
  v_profile_operator boolean;
begin
  v_tenant_id := public._user_mgmt_assert_doctor_admin();
  perform public._invite_v2a_assert_tenant_active(v_tenant_id);

  if p_membership_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0001';
  end if;

  select m.profile_id, m.role, m.status, coalesce(p.maintenance_operator, false)
  into v_profile_id, v_role, v_status, v_profile_operator
  from public.memberships m
  join public.profiles p on p.id = m.profile_id
  where m.id = p_membership_id
    and m.tenant_id = v_tenant_id
  for update;

  if not found then
    raise exception 'invitation_not_found' using errcode = 'P0001';
  end if;

  if v_profile_operator then
    raise exception 'maintenance_operator_target_rejected' using errcode = 'P0001';
  end if;

  if v_status is distinct from 'invited' then
    raise exception 'invitation_not_pending' using errcode = 'P0001';
  end if;

  update public.memberships
  set status = 'disabled',
      updated_at = now()
  where id = p_membership_id;

  perform public._user_mgmt_write_audit(
    'user.invite.cancel',
    p_membership_id,
    jsonb_build_object(
      'target_profile_id', v_profile_id,
      'target_membership_id', p_membership_id,
      'role', v_role,
      'status', 'disabled',
      'operation_result', 'cancelled',
      'source', 'settings_invitation_v2b'
    )
  );

  return jsonb_build_object(
    'ok', true,
    'membership_id', p_membership_id,
    'status', 'disabled'
  );
end;
$$;

grant execute on function public.cancel_tenant_invitation_v2(uuid) to authenticated;
