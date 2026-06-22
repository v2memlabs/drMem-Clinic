-- =============================================================================
-- Settings User Invitation v2e — Staging deep-link E2E smoke checks
-- Run:
--   supabase db query --linked -f scripts/staging/settings_user_invitation_v2e_deeplink_smoke_checks.sql
-- =============================================================================

-- 1) v2d migration + bootstrap overload (5-arg with target membership id)
select
  'v2d_migration' as check_group,
  count(*) as found,
  1 as expected
from supabase_migrations.schema_migrations
where version = '20260609100000'
  and name = 'settings_user_invitation_v2d';

select
  'bootstrap_v2d_overload' as check_group,
  count(*) as found,
  1 as expected
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'bootstrap_tenant_invited_user_v2'
  and pg_get_function_identity_arguments(p.oid)
      like '%p_target_membership_id uuid%';

-- 2) Accept RPC accepts membership_id (deep-link path)
select
  'accept_with_membership_id' as check_group,
  has_function_privilege(
    'authenticated',
    'public.accept_my_tenant_invitation_v2(uuid)',
    'EXECUTE'
  ) as accept_exec;

-- 3) Pending invites snapshot (operator E2E target pool)
select
  m.id as membership_id,
  m.status,
  m.last_invited_at,
  m.role,
  t.name as tenant_name,
  p.email is not null as has_profile_email
from public.memberships m
join public.profiles p on p.id = m.profile_id
join public.tenants t on t.id = m.tenant_id
where m.status = 'invited'
  and coalesce(p.maintenance_operator, false) = false
order by m.last_invited_at desc nulls last, m.created_at desc
limit 10;

-- Expected: at least one row after doctor sends invite smoke email

-- 4) Deep-link accept audit trail (post E2E)
select
  action,
  metadata->>'source' as source,
  metadata->>'operation_result' as operation_result,
  metadata ? 'email' as has_email_key,
  metadata ? 'token' as has_token_key,
  metadata->>'target_membership_id' is not null as has_target_membership_id,
  created_at
from public.audit_logs
where action = 'invitation.accepted'
  and metadata->>'source' in ('settings_invitation_v2a', 'settings_invitation_v2d')
order by created_at desc
limit 10;

-- Expected after deep-link E2E: at least one row with source=settings_invitation_v2d

-- 5) Invite send audit (membership id in metadata, no secrets)
select
  action,
  metadata->>'source' as source,
  metadata->>'operation_result' as operation_result,
  metadata->>'target_membership_id' is not null as has_target_membership_id,
  metadata ? 'email' as has_email_key,
  created_at
from public.audit_logs
where action in ('user.invite.send', 'user.invite.resend')
order by created_at desc
limit 10;

-- 6) Cross-check: invited membership with auth user linked (accept pre-condition)
select
  m.id as membership_id,
  p.auth_user_id is not null as auth_linked,
  m.last_invited_at is not null as has_last_invited_at
from public.memberships m
join public.profiles p on p.id = m.profile_id
where m.status = 'invited'
  and coalesce(p.maintenance_operator, false) = false
order by m.last_invited_at desc nulls last
limit 5;
