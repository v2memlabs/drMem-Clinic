-- =============================================================================
-- User Management Helpers Forward Compat v1
--
-- Fresh migration chain fix: invitation v2a/v2b migrations call
-- _user_mgmt_assert_doctor_admin() before 20260803100000_user_membership_management_v1.
-- Canonical definitions are re-applied in 20260803100000 (create or replace).
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

revoke all on function public._user_mgmt_assert_doctor_admin() from public;
revoke all on function public._user_mgmt_write_audit(text, uuid, jsonb) from public;
