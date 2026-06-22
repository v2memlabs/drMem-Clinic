-- =============================================================================
-- P0.5 Staging Integrity Closure — structural + JWT smoke checklist
-- Project: drmem-clinic-dev (dgzmybbgrofapjptjspf)
--
-- Run structural sections via:
--   supabase db query --linked -f scripts/staging/p0_5_staging_integrity_jwt_smoke_checks.sql
-- JWT sections require authenticated PostgREST/Flutter (service_role bypasses RLS).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) P0 hotfix contract (structural)
-- -----------------------------------------------------------------------------

select 'p0_invitation_guards' as check_group,
  case when pg_get_functiondef('public.update_tenant_membership_status_v1(uuid,text)'::regprocedure)
    like '%invitation_acceptance_required%' then 'pass' else 'fail' end as invited_to_active,
  case when pg_get_functiondef('public.update_tenant_membership_status_v1(uuid,text)'::regprocedure)
    like '%invitation_flow_required%' then 'pass' else 'fail' end as disabled_to_invited;

select 'p0_audit_actor' as check_group,
  case when pg_get_functiondef('public.record_audit_access_event(text,text,uuid,uuid,jsonb,boolean,text)'::regprocedure)
    like '%p.auth_user_id = auth.uid()%' then 'pass' else 'fail' end as uses_auth_user_id,
  case when pg_get_functiondef('public.record_audit_access_event(text,text,uuid,uuid,jsonb,boolean,text)'::regprocedure)
    like '%p.user_id = auth.uid()%' then 'fail' else 'pass' end as no_legacy_user_id;

select 'p0_storage_helper' as check_group,
  to_regprocedure('public._storage_object_metadata_visible(text)') is not null as helper_exists,
  (select qual like '%_storage_object_metadata_visible(name)%'
   from pg_policies
   where schemaname = 'storage' and tablename = 'objects'
     and policyname = 'patient_files_storage_select_v1') as select_uses_helper;

select 'p0_ftr_insert' as check_group,
  count(*) filter (where cmd = 'INSERT') as insert_policy_count,
  string_agg(policyname, ', ') filter (where cmd = 'INSERT') as insert_policies
from pg_policies
where tablename = 'physiotherapy_sessions';

-- Expected: insert_policy_count=1, insert_policies=physiotherapy_sessions_insert_doctor_physio_hardened_v1

-- -----------------------------------------------------------------------------
-- 2) Migration history alignment (remote should match local canonical set)
-- -----------------------------------------------------------------------------

select version, name
from supabase_migrations.schema_migrations
where version in (
  '20260602125000',
  '20260607095900',
  '20260805100000',
  '20260608192058'
)
order by version;

-- Expected: 20260602125000, 20260607095900, 20260805100000 applied; 20260608192058 absent

-- -----------------------------------------------------------------------------
-- 3) Demo auth readiness (no passwords)
-- -----------------------------------------------------------------------------

select
  p.email,
  p.id as profile_id,
  p.auth_user_id is not null as auth_linked,
  m.role,
  m.status,
  t.id as tenant_id
from public.profiles p
join public.memberships m on m.profile_id = p.id
join public.tenants t on t.id = m.tenant_id
where p.email in (
  'doctor-a@example.test',
  'assistant-a@example.test',
  'physio-a@example.test',
  'nurse-a@example.test',
  'doctor-b@example.test'
)
order by p.email;

-- Expected: auth_linked=true for JWT smoke readiness

-- -----------------------------------------------------------------------------
-- 4) Storage parity seed fixtures (Tenant A)
-- -----------------------------------------------------------------------------

select id, visibility_scope, storage_path, patient_id
from patient_files
where tenant_id = 'a0000001-0001-4001-8001-000000000001'
  and deleted_at is null
order by visibility_scope;

-- JWT matrix (authenticated client):
-- doctor-a: all scopes metadata allow
-- assistant-a: clinic_operations allow; physiotherapy deny
-- physio-a: physiotherapy allow; doctor_admin deny
-- nurse-a: all deny
-- doctor-b + tenant B path: cross-tenant deny

-- -----------------------------------------------------------------------------
-- 5) Invitation JWT smoke — operator steps (manual)
-- -----------------------------------------------------------------------------
-- A) doctor-a JWT:
--    RPC update_tenant_membership_status_v1(invited_membership_id, 'active')
--    => invitation_acceptance_required
--    RPC update_tenant_membership_status_v1(disabled_membership_id, 'invited')
--    => invitation_flow_required
-- B) invited user JWT:
--    accept_my_tenant_invitation_v2(own_membership_id) => active
-- C) Cleanup: revert test membership status if mutated

-- -----------------------------------------------------------------------------
-- 6) Audit JWT smoke — operator steps (manual)
-- -----------------------------------------------------------------------------
-- After doctor settings action: audit_logs.actor_profile_id = doctor profile id
-- After maintenance action: actor_profile_id = maintenance operator profile
-- metadata must not contain email/token/password keys

select action, actor_profile_id is not null as actor_populated,
  metadata ? 'email' as has_email,
  metadata ? 'token' as has_token
from audit_logs
where created_at > now() - interval '7 days'
  and module in ('user_management', 'maintenance')
order by created_at desc
limit 10;

-- -----------------------------------------------------------------------------
-- 7) FTR INSERT JWT matrix — operator steps (manual)
-- -----------------------------------------------------------------------------
-- doctor-a: insert session same tenant/referral/patient => allow
-- physio-a: insert with physiotherapist_profile_id=self => allow
-- assistant-a / nurse-a: deny (42501)
-- cross-tenant referral/patient => deny
