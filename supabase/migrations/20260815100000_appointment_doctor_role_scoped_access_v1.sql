-- =============================================================================
-- Appointments: assigned doctor/physio + role-scoped RLS
-- Clinical encounters: doctor sees own records (created_by)
-- Patients: physiotherapist sees referred patients only
-- =============================================================================

alter table appointments
  add column if not exists assigned_doctor_profile_id uuid references profiles (id) on delete set null;

alter table appointments
  add column if not exists assigned_physiotherapist_profile_id uuid references profiles (id) on delete set null;

create index if not exists appointments_assigned_doctor_profile_id_idx
  on appointments (tenant_id, assigned_doctor_profile_id)
  where deleted_at is null;

create index if not exists appointments_assigned_physio_profile_id_idx
  on appointments (tenant_id, assigned_physiotherapist_profile_id)
  where deleted_at is null;

-- Appointments: replace staff-wide policies with role-scoped policies
drop policy if exists appointments_select_staff_draft_v1 on appointments;
drop policy if exists appointments_insert_staff_draft_v1 on appointments;
drop policy if exists appointments_update_staff_draft_v1 on appointments;

drop policy if exists appointments_select_doctor_own_v1 on appointments;
create policy appointments_select_doctor_own_v1
  on appointments for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and assigned_doctor_profile_id = current_profile_id()
  );

drop policy if exists appointments_select_staff_all_v1 on appointments;
create policy appointments_select_staff_all_v1
  on appointments for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary', 'nurse'])
  );

drop policy if exists appointments_select_physio_own_v1 on appointments;
create policy appointments_select_physio_own_v1
  on appointments for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and assigned_physiotherapist_profile_id = current_profile_id()
  );

drop policy if exists appointments_insert_doctor_own_v1 on appointments;
create policy appointments_insert_doctor_own_v1
  on appointments for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and created_by = current_profile_id()
    and assigned_doctor_profile_id = current_profile_id()
  );

drop policy if exists appointments_insert_staff_v1 on appointments;
create policy appointments_insert_staff_v1
  on appointments for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary', 'nurse'])
    and created_by = current_profile_id()
    and assigned_doctor_profile_id is not null
  );

drop policy if exists appointments_update_doctor_own_v1 on appointments;
create policy appointments_update_doctor_own_v1
  on appointments for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and assigned_doctor_profile_id = current_profile_id()
  )
  with check (
    tenant_id = current_tenant_id()
    and assigned_doctor_profile_id = current_profile_id()
  );

drop policy if exists appointments_update_staff_v1 on appointments;
create policy appointments_update_staff_v1
  on appointments for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary', 'nurse'])
  )
  with check (tenant_id = current_tenant_id());

drop policy if exists appointments_update_physio_own_v1 on appointments;
create policy appointments_update_physio_own_v1
  on appointments for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and assigned_physiotherapist_profile_id = current_profile_id()
  )
  with check (
    tenant_id = current_tenant_id()
    and assigned_physiotherapist_profile_id = current_profile_id()
  );

-- Clinical encounters: doctor sees only own records
drop policy if exists clinical_encounters_select_doctor_draft_v1 on clinical_encounters;
create policy clinical_encounters_select_doctor_draft_v1
  on clinical_encounters for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and created_by = current_profile_id()
  );

drop policy if exists clinical_encounters_insert_doctor_draft_v1 on clinical_encounters;
create policy clinical_encounters_insert_doctor_draft_v1
  on clinical_encounters for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and created_by = current_profile_id()
  );

drop policy if exists clinical_encounters_update_doctor_draft_v1 on clinical_encounters;
create policy clinical_encounters_update_doctor_draft_v1
  on clinical_encounters for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and created_by = current_profile_id()
  )
  with check (
    tenant_id = current_tenant_id()
    and created_by = current_profile_id()
  );

-- Physiotherapist: referred patients only
drop policy if exists patients_select_physio_referred_v1 on patients;
create policy patients_select_physio_referred_v1
  on patients for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and exists (
      select 1
      from physiotherapy_referrals r
      where r.patient_id = patients.id
        and r.tenant_id = patients.tenant_id
        and r.deleted_at is null
        and r.assigned_physiotherapist_profile_id = current_profile_id()
    )
  );
