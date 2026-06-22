-- =============================================================================
-- Settings User Invitation v2c — Staging smoke checks
-- Run in Supabase SQL Editor (drmem-clinic-dev) or:
--   supabase db query --linked -f scripts/staging/settings_user_invitation_v2c_smoke_checks.sql
-- =============================================================================

-- 1) Schema: invitation RPCs + cooldown column
select
  'invitation_rpcs' as check_group,
  count(*) filter (where proname in (
    'bootstrap_tenant_invited_user_v2',
    'accept_my_tenant_invitation_v2',
    'prepare_tenant_invitation_resend_v2',
    'complete_tenant_invitation_resend_v2',
    'cancel_tenant_invitation_v2',
    'list_tenant_memberships_v1',
    '_user_mgmt_assert_doctor_admin'
  )) as found,
  7 as expected
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public';

select
  'last_invited_at_column' as check_group,
  count(*) as found,
  1 as expected
from information_schema.columns
where table_schema = 'public'
  and table_name = 'memberships'
  and column_name = 'last_invited_at';

-- 2) Grants (authenticated execute)
select
  'rpc_grants' as check_group,
  has_function_privilege(
    'authenticated',
    'public.bootstrap_tenant_invited_user_v2(uuid,text,text,text)',
    'EXECUTE'
  ) as bootstrap_exec,
  has_function_privilege(
    'authenticated',
    'public.accept_my_tenant_invitation_v2(uuid)',
    'EXECUTE'
  ) as accept_exec,
  has_function_privilege(
    'authenticated',
    'public.cancel_tenant_invitation_v2(uuid)',
    'EXECUTE'
  ) as cancel_exec,
  has_function_privilege(
    'authenticated',
    'public.prepare_tenant_invitation_resend_v2(uuid)',
    'EXECUTE'
  ) as prepare_resend_exec,
  has_function_privilege(
    'authenticated',
    'public.complete_tenant_invitation_resend_v2(uuid)',
    'EXECUTE'
  ) as complete_resend_exec;

-- 3) Edge function deploy is CLI/dashboard only — verify separately:
--    supabase functions list --project-ref dgzmybbgrofapjptjspf
--    Expected slug: tenant-invite-user-v2 (verify_jwt=true)

-- 4) Staging doctor admin readiness (seed)
select
  p.email,
  p.auth_user_id is not null as auth_linked,
  coalesce(p.maintenance_operator, false) as maintenance_operator,
  m.role,
  m.status,
  t.name as tenant_name
from public.profiles p
join public.memberships m on m.profile_id = p.id
join public.tenants t on t.id = m.tenant_id
where p.email in ('doctor-a@example.test', 'doctor-b@example.test')
  and m.role = 'doctor_admin'
  and m.status = 'active'
order by p.email, t.name;

-- Expected: auth_linked=true, maintenance_operator=false for demo doctors

-- 5) Maintenance isolation (settings invite must stay separate)
select enabled as maintenance_config_enabled
from public.maintenance_config
where id = 1;

-- Expected for normal settings smoke: enabled=false (maintenance console off)

-- 6) Recent invitation audit events (after manual smoke)
-- Run AFTER operator completes invite/resend/cancel/accept flow.
select
  action,
  metadata->>'source' as source,
  metadata ? 'email' as has_email_key,
  metadata ? 'token' as has_token_key,
  metadata->>'operation_result' as operation_result,
  created_at
from public.audit_logs
where action in (
  'user.invite.send',
  'user.invite.resend',
  'user.invite.cancel',
  'invitation.accepted',
  'membership.invited'
)
order by created_at desc
limit 20;

-- Expected after smoke: rows present; has_email_key=false; has_token_key=false
