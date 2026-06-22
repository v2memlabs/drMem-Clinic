-- =============================================================================
-- Faz 2 Paket 2 — role_access on core clinical tables + summary RPC + storage
-- Prerequisite: 20260824100000_faz2_role_access_financial_helpers_v1.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) patients
-- -----------------------------------------------------------------------------

drop policy if exists patients_select_member_draft_v1 on public.patients;
create policy patients_select_member_draft_v1
  on public.patients
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary', 'nurse']
    )
    and public.has_role_access(tenant_id, 'view_patients')
  );

drop policy if exists patients_select_physio_referred_v1 on public.patients;
create policy patients_select_physio_referred_v1
  on public.patients
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and public.has_role_access(tenant_id, 'view_patients')
    and exists (
      select 1
      from public.physiotherapy_referrals r
      where r.patient_id = patients.id
        and r.tenant_id = patients.tenant_id
        and r.deleted_at is null
        and r.assigned_physiotherapist_profile_id = current_profile_id()
    )
  );

drop policy if exists patients_insert_staff_draft_v1 on public.patients;
create policy patients_insert_staff_draft_v1
  on public.patients
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and public.has_role_access(tenant_id, 'edit_patients')
  );

drop policy if exists patients_update_staff_draft_v1 on public.patients;
create policy patients_update_staff_draft_v1
  on public.patients
  for update
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and public.has_role_access(tenant_id, 'edit_patients')
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and public.has_role_access(tenant_id, 'edit_patients')
  );

-- -----------------------------------------------------------------------------
-- 2) appointments (role-scoped policies from 20260815100000)
-- -----------------------------------------------------------------------------

drop policy if exists appointments_select_doctor_own_v1 on public.appointments;
create policy appointments_select_doctor_own_v1
  on public.appointments
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and assigned_doctor_profile_id = current_profile_id()
    and public.has_role_access(tenant_id, 'view_own_scoped_appointments')
  );

drop policy if exists appointments_select_staff_all_v1 on public.appointments;
create policy appointments_select_staff_all_v1
  on public.appointments
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary', 'nurse'])
    and public.has_role_access(tenant_id, 'view_all_appointments')
  );

drop policy if exists appointments_select_physio_own_v1 on public.appointments;
create policy appointments_select_physio_own_v1
  on public.appointments
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and assigned_physiotherapist_profile_id = current_profile_id()
    and public.has_role_access(tenant_id, 'view_own_scoped_appointments')
  );

drop policy if exists appointments_insert_doctor_own_v1 on public.appointments;
create policy appointments_insert_doctor_own_v1
  on public.appointments
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and created_by = current_profile_id()
    and assigned_doctor_profile_id = current_profile_id()
    and public.has_role_access(tenant_id, 'edit_appointments')
  );

drop policy if exists appointments_insert_staff_v1 on public.appointments;
create policy appointments_insert_staff_v1
  on public.appointments
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary', 'nurse'])
    and created_by = current_profile_id()
    and assigned_doctor_profile_id is not null
    and public.has_role_access(tenant_id, 'edit_appointments')
  );

drop policy if exists appointments_update_doctor_own_v1 on public.appointments;
create policy appointments_update_doctor_own_v1
  on public.appointments
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and assigned_doctor_profile_id = current_profile_id()
    and public.has_role_access(tenant_id, 'edit_appointments')
  )
  with check (
    tenant_id = current_tenant_id()
    and assigned_doctor_profile_id = current_profile_id()
    and public.has_role_access(tenant_id, 'edit_appointments')
  );

drop policy if exists appointments_update_staff_v1 on public.appointments;
create policy appointments_update_staff_v1
  on public.appointments
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary', 'nurse'])
    and public.has_role_access(tenant_id, 'edit_appointments')
  )
  with check (
    tenant_id = current_tenant_id()
    and public.has_role_access(tenant_id, 'edit_appointments')
  );

drop policy if exists appointments_update_physio_own_v1 on public.appointments;
create policy appointments_update_physio_own_v1
  on public.appointments
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and assigned_physiotherapist_profile_id = current_profile_id()
    and public.has_role_access(tenant_id, 'edit_appointments')
  )
  with check (
    tenant_id = current_tenant_id()
    and assigned_physiotherapist_profile_id = current_profile_id()
    and public.has_role_access(tenant_id, 'edit_appointments')
  );

-- -----------------------------------------------------------------------------
-- 3) clinical_encounters (doctor own records)
-- -----------------------------------------------------------------------------

drop policy if exists clinical_encounters_select_doctor_draft_v1 on public.clinical_encounters;
create policy clinical_encounters_select_doctor_draft_v1
  on public.clinical_encounters
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and created_by = current_profile_id()
    and public.has_role_access(tenant_id, 'view_clinical_encounters')
  );

drop policy if exists clinical_encounters_insert_doctor_draft_v1 on public.clinical_encounters;
create policy clinical_encounters_insert_doctor_draft_v1
  on public.clinical_encounters
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and created_by = current_profile_id()
    and public.has_role_access(tenant_id, 'edit_clinical_encounters')
  );

drop policy if exists clinical_encounters_update_doctor_draft_v1 on public.clinical_encounters;
create policy clinical_encounters_update_doctor_draft_v1
  on public.clinical_encounters
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and created_by = current_profile_id()
    and public.has_role_access(tenant_id, 'edit_clinical_encounters')
  )
  with check (
    tenant_id = current_tenant_id()
    and created_by = current_profile_id()
    and public.has_role_access(tenant_id, 'edit_clinical_encounters')
  );

-- -----------------------------------------------------------------------------
-- 4) patient_files (visibility_scope preserved)
-- -----------------------------------------------------------------------------

drop policy if exists patient_files_select_metadata_v1 on public.patient_files;
create policy patient_files_select_metadata_v1
  on public.patient_files
  for select
  to authenticated
  using (
    deleted_at is null
    and status <> 'deleted'
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_files')
    and (
      has_tenant_role(tenant_id, array['doctor_admin'])
      or (
        visibility_scope = 'clinic_operations'
        and has_tenant_role(tenant_id, array['assistant_secretary'])
      )
      or (
        visibility_scope = 'physiotherapy'
        and has_tenant_role(tenant_id, array['physiotherapist'])
      )
    )
  );

drop policy if exists patient_files_insert_staff_draft_v1 on public.patient_files;
create policy patient_files_insert_staff_draft_v1
  on public.patient_files
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and public.has_role_access(tenant_id, 'edit_files')
  );

drop policy if exists patient_files_update_staff_draft_v1 on public.patient_files;
create policy patient_files_update_staff_draft_v1
  on public.patient_files
  for update
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and public.has_role_access(tenant_id, 'edit_files')
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and public.has_role_access(tenant_id, 'edit_files')
  );

-- -----------------------------------------------------------------------------
-- 5) Clinical summary RPC gate — role_access on assistant / physio projections
-- -----------------------------------------------------------------------------

create or replace function public._clinical_summary_access_allowed(
  p_tenant_id uuid,
  p_allowed_roles text[]
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    auth.uid() is not null
    and p_tenant_id is not null
    and current_tenant_id() is not null
    and p_tenant_id = current_tenant_id()
    and is_tenant_member(p_tenant_id)
    and has_tenant_role(p_tenant_id, p_allowed_roles)
    and exists (
      select 1
      from public.tenants t
      where t.id = p_tenant_id
        and t.status = 'active'
    )
    and case
      when p_allowed_roles @> array['assistant_secretary']::text[]
        and p_allowed_roles @> array['doctor_admin']::text[]
        then public.has_role_access(p_tenant_id, 'view_clinical_diagnosis_summary')
      when p_allowed_roles @> array['physiotherapist']::text[]
        and p_allowed_roles @> array['doctor_admin']::text[]
        then public.has_role_access(p_tenant_id, 'view_clinical_summary')
      else false
    end;
$$;

comment on function public._clinical_summary_access_allowed(uuid, text[]) is
  'Internal RPC gate. Nurse excluded by role list. Enforces tenant role_access matrix.';

revoke all on function public._clinical_summary_access_allowed(uuid, text[]) from public;
revoke all on function public._clinical_summary_access_allowed(uuid, text[]) from authenticated;

-- -----------------------------------------------------------------------------
-- 6) Storage — metadata parity + edit_files on upload
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
      from public.patient_files pf
      where pf.deleted_at is null
        and pf.status <> 'deleted'
        and pf.tenant_id = current_tenant_id()
        and pf.storage_bucket = 'patient-files-private'
        and pf.storage_path = p_object_name
        and is_tenant_member(pf.tenant_id)
        and public.has_role_access(pf.tenant_id, 'view_files')
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
      from public.pdf_outputs po
      where po.deleted_at is null
        and po.tenant_id = current_tenant_id()
        and po.storage_bucket = 'patient-files-private'
        and po.storage_path = p_object_name
        and is_tenant_member(po.tenant_id)
        and has_tenant_role(po.tenant_id, array['doctor_admin'])
        and public.has_role_access(po.tenant_id, 'view_pdf_outputs')
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

drop policy if exists patient_files_storage_insert_v1 on storage.objects;
create policy patient_files_storage_insert_v1
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'patient-files-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and is_tenant_member(current_tenant_id())
    and public.has_role_access(current_tenant_id(), 'edit_files')
    and (
      has_tenant_role(current_tenant_id(), array['doctor_admin'])
      or has_tenant_role(current_tenant_id(), array['assistant_secretary'])
      or has_tenant_role(current_tenant_id(), array['physiotherapist'])
    )
  );
