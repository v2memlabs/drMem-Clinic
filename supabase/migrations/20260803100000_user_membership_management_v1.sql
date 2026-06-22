-- User & Membership Management v1 — tenant-scoped doctor_admin settings RPCs.

-- =============================================================================
-- Helpers
-- =============================================================================

create or replace function public._user_mgmt_assert_doctor_admin()
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_profile_id uuid;
begin
  v_profile_id := public.current_profile_id();
  if v_profile_id is null then
    raise exception 'no_active_profile' using errcode = 'P0001';
  end if;

  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'no_active_tenant' using errcode = 'P0001';
  end if;

  if not public.has_tenant_role(v_tenant_id, array['doctor_admin']) then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  return v_tenant_id;
end;
$$;

create or replace function public._user_mgmt_is_valid_role(p_role text)
returns boolean
language sql
immutable
as $$
  select p_role in (
    'doctor_admin',
    'assistant_secretary',
    'physiotherapist',
    'nurse'
  );
$$;

create or replace function public._user_mgmt_is_valid_status(p_status text)
returns boolean
language sql
immutable
as $$
  select p_status in ('active', 'invited', 'disabled');
$$;

create or replace function public._user_mgmt_write_audit(
  p_action text,
  p_membership_id uuid,
  p_metadata jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.record_audit_access_event(
    trim(p_action),
    'user_management',
    p_membership_id,
    null,
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object('source', 'settings_v1'),
    true,
    null
  );
exception
  when others then
    null;
end;
$$;

-- =============================================================================
-- list_tenant_memberships_v1
-- =============================================================================

create or replace function public.list_tenant_memberships_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
begin
  v_tenant_id := public._user_mgmt_assert_doctor_admin();

  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'membership_id', m.id,
        'display_name', coalesce(nullif(trim(p.display_name), ''), 'Kullanıcı'),
        'email', p.email,
        'role', m.role,
        'status', m.status,
        'created_at', m.created_at,
        'updated_at', m.updated_at
      )
      order by coalesce(nullif(trim(p.display_name), ''), p.email, '') asc
    )
    from public.memberships m
    join public.profiles p on p.id = m.profile_id
    where m.tenant_id = v_tenant_id
      and coalesce(p.maintenance_operator, false) = false
  ), '[]'::jsonb);
end;
$$;

-- =============================================================================
-- update_tenant_membership_role_v1
-- =============================================================================

create or replace function public.update_tenant_membership_role_v1(
  p_membership_id uuid,
  p_role text
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

  if not public._user_mgmt_is_valid_role(p_role) then
    raise exception 'invalid_role' using errcode = 'P0001';
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

  if v_target_profile = v_profile_id then
    raise exception 'self_update_blocked' using errcode = 'P0001';
  end if;

  if v_before_role = 'doctor_admin'
     and p_role <> 'doctor_admin'
     and v_before_status = 'active' then
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
  set role = p_role,
      updated_at = now()
  where id = p_membership_id;

  perform public._user_mgmt_write_audit(
    'membership.role_update',
    p_membership_id,
    jsonb_build_object(
      'membership_id', p_membership_id,
      'field', 'role',
      'before', v_before_role,
      'after', p_role
    )
  );

  return jsonb_build_object('ok', true, 'membership_id', p_membership_id);
end;
$$;

-- =============================================================================
-- update_tenant_membership_status_v1
-- =============================================================================

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

-- =============================================================================
-- Grants
-- =============================================================================

revoke all on function public._user_mgmt_assert_doctor_admin() from public;
revoke all on function public._user_mgmt_write_audit(text, uuid, jsonb) from public;

grant execute on function public.list_tenant_memberships_v1() to authenticated;
grant execute on function public.update_tenant_membership_role_v1(uuid, text) to authenticated;
grant execute on function public.update_tenant_membership_status_v1(uuid, text) to authenticated;
