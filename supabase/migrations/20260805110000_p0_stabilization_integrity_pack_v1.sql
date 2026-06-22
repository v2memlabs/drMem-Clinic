-- =============================================================================
-- P0 Stabilization & Migration Integrity Pack v1
--
-- Scope:
--   1) Invitation invited→active / disabled→invited guards on status RPC
--   2) Audit actor_profile_id tenant-scoped profile resolution
--   3) Storage object SELECT aligned with patient_files/pdf_outputs visibility
--   4) FTR session INSERT policy consolidation (remove permissive OR)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Invitation guard — restore update_tenant_membership_status_v1 contract
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

  if v_before_status = 'disabled' and p_status = 'invited' then
    raise exception 'invitation_flow_required' using errcode = 'P0001';
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
-- 2) Audit actor — tenant-scoped profile via auth_user_id
-- -----------------------------------------------------------------------------

create or replace function record_audit_access_event(
  p_action text,
  p_module text,
  p_record_id uuid default null,
  p_patient_id uuid default null,
  p_metadata jsonb default '{}'::jsonb,
  p_success boolean default true,
  p_failure_category text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_actor_profile_id uuid;
  v_meta jsonb;
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  v_tenant_id := current_tenant_id();
  if v_tenant_id is null then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if not is_tenant_member(v_tenant_id) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if not exists (
    select 1 from tenants t
    where t.id = v_tenant_id and t.status = 'active'
  ) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  select p.id into v_actor_profile_id
  from profiles p
  where p.auth_user_id = auth.uid()
    and exists (
      select 1
      from memberships m
      where m.profile_id = p.id
        and m.tenant_id = v_tenant_id
        and m.status in ('active', 'invited')
    )
  limit 1;

  v_meta := _sanitize_audit_metadata(coalesce(p_metadata, '{}'::jsonb));
  v_meta := v_meta || jsonb_build_object(
    'success', coalesce(p_success, true),
    'source', coalesce(v_meta ->> 'source', 'rpc')
  );
  if p_failure_category is not null and length(trim(p_failure_category)) > 0 then
    v_meta := v_meta || jsonb_build_object(
      'failure_category', trim(p_failure_category)
    );
  end if;

  insert into audit_logs (
    tenant_id,
    actor_profile_id,
    action,
    module,
    record_id,
    patient_id,
    metadata
  )
  values (
    v_tenant_id,
    v_actor_profile_id,
    trim(p_action),
    trim(p_module),
    p_record_id,
    p_patient_id,
    v_meta
  )
  returning id into v_id;

  return v_id;
end;
$$;

comment on function record_audit_access_event(text, text, uuid, uuid, jsonb, boolean, text) is
  'Append-only KVKK access audit. Actor resolved via profiles.auth_user_id scoped to current tenant.';

revoke all on function record_audit_access_event(text, text, uuid, uuid, jsonb, boolean, text)
  from public;
grant execute on function record_audit_access_event(text, text, uuid, uuid, jsonb, boolean, text)
  to authenticated;

-- -----------------------------------------------------------------------------
-- 3) Storage visibility — metadata parity for object SELECT
-- -----------------------------------------------------------------------------

create or replace function public._storage_object_metadata_visible(p_object_name text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    exists (
      select 1
      from patient_files pf
      where pf.deleted_at is null
        and pf.status <> 'deleted'
        and pf.tenant_id = current_tenant_id()
        and pf.storage_bucket = 'patient-files-private'
        and pf.storage_path = p_object_name
        and is_tenant_member(pf.tenant_id)
        and (
          has_tenant_role(pf.tenant_id, array['doctor_admin'])
          or (
            pf.visibility_scope = 'clinic_operations'
            and has_tenant_role(pf.tenant_id, array['assistant_secretary'])
          )
          or (
            pf.visibility_scope = 'physiotherapy'
            and has_tenant_role(pf.tenant_id, array['physiotherapist'])
          )
        )
    )
    or exists (
      select 1
      from pdf_outputs po
      where po.deleted_at is null
        and po.tenant_id = current_tenant_id()
        and po.storage_bucket = 'patient-files-private'
        and po.storage_path = p_object_name
        and is_tenant_member(po.tenant_id)
        and has_tenant_role(po.tenant_id, array['doctor_admin'])
        and (
          po.visibility_scope = 'doctor_admin'
          or po.visibility_scope is null
        )
    );
$$;

revoke all on function public._storage_object_metadata_visible(text) from public;
revoke all on function public._storage_object_metadata_visible(text) from authenticated;

drop policy if exists patient_files_storage_select_v1 on storage.objects;
create policy patient_files_storage_select_v1
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'patient-files-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and is_tenant_member(current_tenant_id())
    and public._storage_object_metadata_visible(name)
  );

-- INSERT unchanged: nurse excluded; metadata row created before upload in app flow.

-- -----------------------------------------------------------------------------
-- 4) FTR session INSERT policy consolidation
-- -----------------------------------------------------------------------------

drop policy if exists physiotherapy_sessions_insert_doctor_v1 on physiotherapy_sessions;
drop policy if exists physiotherapy_sessions_insert_physio_v1 on physiotherapy_sessions;
drop policy if exists physiotherapy_sessions_insert_doctor_physio_hardened_v1 on physiotherapy_sessions;

create policy physiotherapy_sessions_insert_doctor_physio_hardened_v1
  on physiotherapy_sessions
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and (
      has_tenant_role(tenant_id, array['doctor_admin'])
      or (
        has_tenant_role(tenant_id, array['physiotherapist'])
        and physiotherapist_profile_id = current_profile_id()
      )
    )
    and exists (
      select 1
      from physiotherapy_referrals r
      where r.id = physiotherapy_sessions.referral_id
        and r.tenant_id = current_tenant_id()
        and r.deleted_at is null
        and r.patient_id = physiotherapy_sessions.patient_id
    )
  );

-- assistant_secretary and nurse: no INSERT policy (deny by default)
