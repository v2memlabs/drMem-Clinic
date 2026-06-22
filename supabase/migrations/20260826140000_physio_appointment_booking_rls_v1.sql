-- Fizyoterapist FTR randevu planlama — INSERT policy eksikti; UPDATE yalnızca edit_appointments istiyordu.
-- UI: canBookReferralAppointments ↔ edit_physiotherapy; DB faz2 yalnızca edit_appointments (fizyoya kapalı).

drop policy if exists appointments_insert_physio_own_v1 on public.appointments;
create policy appointments_insert_physio_own_v1
  on public.appointments
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and created_by = current_profile_id()
    and assigned_physiotherapist_profile_id = current_profile_id()
    and (
      public.has_role_access(tenant_id, 'edit_physiotherapy')
      or public.has_role_access(tenant_id, 'edit_appointments')
    )
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
    and (
      public.has_role_access(tenant_id, 'edit_physiotherapy')
      or public.has_role_access(tenant_id, 'edit_appointments')
    )
  )
  with check (
    tenant_id = current_tenant_id()
    and assigned_physiotherapist_profile_id = current_profile_id()
    and (
      public.has_role_access(tenant_id, 'edit_physiotherapy')
      or public.has_role_access(tenant_id, 'edit_appointments')
    )
  );
