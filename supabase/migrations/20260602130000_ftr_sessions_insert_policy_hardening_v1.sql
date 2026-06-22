-- =============================================================================
-- FTR Sessions INSERT Policy Hardening v1
--
-- Purpose:
--   Prevent false 42501 for physiotherapist inserts caused by querying
--   patients table under stricter patient SELECT RLS.
--
-- Scope:
--   - Replace INSERT policies for physiotherapy_sessions.
--   - Keep SELECT policies unchanged.
--   - Do not add UPDATE/DELETE policies.
-- =============================================================================

-- Remove legacy role-split insert policies (if present).
drop policy if exists physiotherapy_sessions_insert_doctor_v1 on physiotherapy_sessions;
drop policy if exists physiotherapy_sessions_insert_physio_v1 on physiotherapy_sessions;

-- Hardened insert policy for doctor_admin + physiotherapist.
-- Cross-tenant and referral/patient mismatch are denied by with check.
create policy physiotherapy_sessions_insert_doctor_physio_hardened_v1
  on physiotherapy_sessions
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'physiotherapist'])
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
