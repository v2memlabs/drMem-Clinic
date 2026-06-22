-- =============================================================================
-- Draft RLS policies v1 — review before applying
-- Not executed automatically. Apply only to dev/staging after manual review.
-- Idempotent: DROP POLICY IF EXISTS before CREATE; DROP VIEW IF EXISTS (no CASCADE).
--
-- Prerequisite: 20260521100000_draft_saas_schema_rls_v1.sql (tables + RLS enabled)
-- Flutter: remains mock until policies reviewed and connection Go/No-Go passes.
-- service_role: server-side seed/admin only — never in Flutter client.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Role keys (DB memberships.role)
--   doctor_admin | assistant_secretary | physiotherapist | nurse
-- -----------------------------------------------------------------------------

-- =============================================================================
-- 1) RLS helper functions (auth.uid + profiles + memberships)
-- =============================================================================

create or replace function current_auth_user_id()
returns uuid
language sql
stable
as $$
  select auth.uid();
$$;

comment on function current_auth_user_id is
  'Supabase Auth user id (auth.users). Client uses anon key only.';

create or replace function current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    nullif(auth.jwt() ->> 'profile_id', '')::uuid,
    (
      select p.id
      from profiles p
      where p.auth_user_id = auth.uid()
      limit 1
    )
  );
$$;

create or replace function current_tenant_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    nullif(auth.jwt() ->> 'tenant_id', '')::uuid,
    (
      select m.tenant_id
      from memberships m
      where m.profile_id = current_profile_id()
        and m.status = 'active'
      order by m.created_at
      limit 1
    )
  );
$$;

create or replace function is_tenant_member(target_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from memberships m
    where m.tenant_id = target_tenant_id
      and m.profile_id = current_profile_id()
      and m.status = 'active'
  );
$$;

create or replace function has_tenant_role(target_tenant_id uuid, allowed_roles text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from memberships m
    where m.tenant_id = target_tenant_id
      and m.profile_id = current_profile_id()
      and m.status = 'active'
      and m.role = any (allowed_roles)
  );
$$;

create or replace function has_permission(target_tenant_id uuid, permission_key text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from memberships m
    join role_permissions rp on rp.role = m.role
    where m.tenant_id = target_tenant_id
      and m.profile_id = current_profile_id()
      and m.status = 'active'
      and rp.permission_key = permission_key
  );
$$;

-- =============================================================================
-- 2) Reference tables: permissions, role_permissions
-- =============================================================================

alter table permissions enable row level security;
alter table role_permissions enable row level security;

drop policy if exists permissions_select_authenticated_draft_v1 on permissions;
create policy permissions_select_authenticated_draft_v1
  on permissions for select
  to authenticated
  using (current_auth_user_id() is not null);

drop policy if exists role_permissions_select_authenticated_draft_v1 on role_permissions;
create policy role_permissions_select_authenticated_draft_v1
  on role_permissions for select
  to authenticated
  using (current_auth_user_id() is not null);

-- =============================================================================
-- 3) tenants
-- =============================================================================

drop policy if exists tenants_select_member_draft_v1 on tenants;
create policy tenants_select_member_draft_v1
  on tenants for select
  to authenticated
  using (
    is_tenant_member(id)
    and status = 'active'
  );

-- =============================================================================
-- 4) profiles
-- =============================================================================

drop policy if exists profiles_select_own_draft_v1 on profiles;
create policy profiles_select_own_draft_v1
  on profiles for select
  to authenticated
  using (
    auth_user_id = current_auth_user_id()
    or id = current_profile_id()
  );

drop policy if exists profiles_update_own_draft_v1 on profiles;
create policy profiles_update_own_draft_v1
  on profiles for update
  to authenticated
  using (auth_user_id = current_auth_user_id())
  with check (auth_user_id = current_auth_user_id());

-- =============================================================================
-- 5) memberships
-- =============================================================================

drop policy if exists memberships_select_own_draft_v1 on memberships;
create policy memberships_select_own_draft_v1
  on memberships for select
  to authenticated
  using (profile_id = current_profile_id());

drop policy if exists memberships_select_tenant_peer_draft_v1 on memberships;
create policy memberships_select_tenant_peer_draft_v1
  on memberships for select
  to authenticated
  using (
    is_tenant_member(tenant_id)
    and status = 'active'
  );

-- =============================================================================
-- 6) patients
-- =============================================================================

drop policy if exists patients_select_member_draft_v1 on patients;
create policy patients_select_member_draft_v1
  on patients for select
  to authenticated
  using (
    deleted_at is null
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary', 'nurse'])
  );

drop policy if exists patients_insert_staff_draft_v1 on patients;
create policy patients_insert_staff_draft_v1
  on patients for insert
  to authenticated
  with check (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
    and tenant_id = current_tenant_id()
  );

drop policy if exists patients_update_staff_draft_v1 on patients;
create policy patients_update_staff_draft_v1
  on patients for update
  to authenticated
  using (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
  )
  with check (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
    and tenant_id = current_tenant_id()
  );

-- =============================================================================
-- 7) appointments
-- =============================================================================

drop policy if exists appointments_select_staff_draft_v1 on appointments;
create policy appointments_select_staff_draft_v1
  on appointments for select
  to authenticated
  using (
    deleted_at is null
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
  );

drop policy if exists appointments_insert_staff_draft_v1 on appointments;
create policy appointments_insert_staff_draft_v1
  on appointments for insert
  to authenticated
  with check (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
    and tenant_id = current_tenant_id()
  );

drop policy if exists appointments_update_staff_draft_v1 on appointments;
create policy appointments_update_staff_draft_v1
  on appointments for update
  to authenticated
  using (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
  )
  with check (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
    and tenant_id = current_tenant_id()
  );

-- =============================================================================
-- 8) clinical_encounters — full table (internal_doctor_note column)
-- =============================================================================

drop policy if exists clinical_encounters_select_doctor_draft_v1 on clinical_encounters;
create policy clinical_encounters_select_doctor_draft_v1
  on clinical_encounters for select
  to authenticated
  using (
    deleted_at is null
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  );

drop policy if exists clinical_encounters_insert_doctor_draft_v1 on clinical_encounters;
create policy clinical_encounters_insert_doctor_draft_v1
  on clinical_encounters for insert
  to authenticated
  with check (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and tenant_id = current_tenant_id()
  );

drop policy if exists clinical_encounters_update_doctor_draft_v1 on clinical_encounters;
create policy clinical_encounters_update_doctor_draft_v1
  on clinical_encounters for update
  to authenticated
  using (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  )
  with check (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and tenant_id = current_tenant_id()
  );

-- =============================================================================
-- 8b) clinical_encounter_operational_summary (VIEW)
-- =============================================================================
-- No ENABLE ROW LEVEL SECURITY or CREATE POLICY on views (PostgreSQL limitation).
-- Narrowing columns: CREATE OR REPLACE fails with 42P16; use DROP + CREATE.
-- No CASCADE — if DROP fails due to dependents, manual review required.

drop view if exists clinical_encounter_operational_summary;

create view clinical_encounter_operational_summary
with (security_invoker = true)
as
select
  id,
  tenant_id,
  patient_id,
  encounter_date,
  visit_type,
  status,
  diagnosis_summary,
  treatment_plan_summary,
  created_at,
  updated_at
from clinical_encounters
where deleted_at is null;

comment on view clinical_encounter_operational_summary is
  'Safe CE projection. No internal_doctor_note, clinical_data, appointment_id. '
  'security_invoker + clinical_encounters RLS (doctor_admin). No view policies.';

-- =============================================================================
-- 9) patient_files
-- =============================================================================

drop policy if exists patient_files_select_staff_draft_v1 on patient_files;
create policy patient_files_select_staff_draft_v1
  on patient_files for select
  to authenticated
  using (
    deleted_at is null
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
  );

drop policy if exists patient_files_insert_staff_draft_v1 on patient_files;
create policy patient_files_insert_staff_draft_v1
  on patient_files for insert
  to authenticated
  with check (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
    and tenant_id = current_tenant_id()
  );

drop policy if exists patient_files_update_staff_draft_v1 on patient_files;
create policy patient_files_update_staff_draft_v1
  on patient_files for update
  to authenticated
  using (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
  )
  with check (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
    and tenant_id = current_tenant_id()
  );

-- =============================================================================
-- 10) pdf_outputs
-- =============================================================================

drop policy if exists pdf_outputs_select_doctor_draft_v1 on pdf_outputs;
create policy pdf_outputs_select_doctor_draft_v1
  on pdf_outputs for select
  to authenticated
  using (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  );

drop policy if exists pdf_outputs_insert_doctor_draft_v1 on pdf_outputs;
create policy pdf_outputs_insert_doctor_draft_v1
  on pdf_outputs for insert
  to authenticated
  with check (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and tenant_id = current_tenant_id()
  );

drop policy if exists pdf_outputs_update_doctor_draft_v1 on pdf_outputs;
create policy pdf_outputs_update_doctor_draft_v1
  on pdf_outputs for update
  to authenticated
  using (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  )
  with check (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and tenant_id = current_tenant_id()
  );

-- =============================================================================
-- 11) audit_logs
-- =============================================================================

drop policy if exists audit_logs_select_doctor_draft_v1 on audit_logs;
create policy audit_logs_select_doctor_draft_v1
  on audit_logs for select
  to authenticated
  using (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  );

-- =============================================================================
-- 12) subscriptions, usage_limits, usage_events
-- =============================================================================

drop policy if exists subscriptions_select_member_draft_v1 on subscriptions;
create policy subscriptions_select_member_draft_v1
  on subscriptions for select
  to authenticated
  using (is_tenant_member(tenant_id));

drop policy if exists usage_limits_select_member_draft_v1 on usage_limits;
create policy usage_limits_select_member_draft_v1
  on usage_limits for select
  to authenticated
  using (is_tenant_member(tenant_id));

drop policy if exists usage_events_select_doctor_draft_v1 on usage_events;
create policy usage_events_select_doctor_draft_v1
  on usage_events for select
  to authenticated
  using (
    is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  );

-- =============================================================================
-- REVIEW NOTES
-- =============================================================================
-- 1. Re-run safe: DROP POLICY IF EXISTS + CREATE OR REPLACE functions.
-- 2. View: DROP VIEW IF EXISTS (no CASCADE) then CREATE — fixes 42P16 column drop.
-- 3. No RLS/policies on views; no ENABLE ROW LEVEL SECURITY on views.
-- 4. internal_doctor_note not in summary view; clinical_encounters doctor_admin only.
-- 5. Assistant/FTR summary via view deferred (security_invoker + table RLS).
