-- =============================================================================
-- Staging Remote RLS / Auth Context Smoke Checks v1
--
-- TWO MODES (see runbook):
--   A) Structural / data — SQL Editor with service_role (this file sections 1–4)
--   B) JWT context — Flutter client + PostgREST OR supabase-js with user JWT
--
-- WARNING: In SQL Editor, auth.uid() is typically NULL unless using
-- Supabase "Run as user" / authenticated request. Helper results below
-- will be NULL in service_role context — that is EXPECTED for section 5.
-- =============================================================================

-- Tenant A / B constants (seed)
-- Tenant A: a0000001-0001-4001-8001-000000000001
-- Tenant B: a0000001-0001-4001-8001-000000000002

-- -----------------------------------------------------------------------------
-- 1) Demo profiles — auth_user_id linkage (CRITICAL for current_profile_id)
-- -----------------------------------------------------------------------------

select
  p.id as profile_id,
  p.email,
  p.display_name,
  p.auth_user_id,
  case
    when p.auth_user_id is null then 'FAIL — Auth user not linked'
    else 'OK'
  end as auth_link_status
from profiles p
where p.email in (
  'doctor-a@example.test',
  'assistant-a@example.test',
  'physio-a@example.test',
  'nurse-a@example.test',
  'doctor-b@example.test',
  'assistant-b@example.test',
  'physio-b@example.test'
)
order by p.email;

-- -----------------------------------------------------------------------------
-- 2) Memberships — role + status + tenant
-- -----------------------------------------------------------------------------

select
  p.email,
  m.tenant_id,
  t.name as tenant_name,
  t.status as tenant_status,
  m.role,
  m.status as membership_status,
  case
    when m.status <> 'active' then 'FAIL — membership not active'
    when t.status <> 'active' then 'WARN — tenant suspended'
    when p.auth_user_id is null then 'FAIL — profile not linked to Auth'
    else 'OK'
  end as chain_status
from memberships m
join profiles p on p.id = m.profile_id
join tenants t on t.id = m.tenant_id
where p.email in (
  'doctor-a@example.test',
  'assistant-a@example.test',
  'physio-a@example.test',
  'nurse-a@example.test',
  'doctor-b@example.test'
)
order by p.email;

-- Expected roles:
-- doctor-a → doctor_admin @ Tenant A
-- assistant-a → assistant_secretary @ Tenant A
-- physio-a → physiotherapist @ Tenant A
-- nurse-a → nurse @ Tenant A
-- doctor-b → doctor_admin @ Tenant B

-- -----------------------------------------------------------------------------
-- 3) Seed patient availability (FK targets for inserts)
-- -----------------------------------------------------------------------------

select
  tenant_id,
  count(*) filter (where deleted_at is null) as active_patients
from patients
where tenant_id in (
  'a0000001-0001-4001-8001-000000000001',
  'a0000001-0001-4001-8001-000000000002'
)
group by tenant_id;

-- Sample patient for Tenant A smoke inserts:
select id, tenant_id, file_number, first_name, last_name
from patients
where tenant_id = 'a0000001-0001-4001-8001-000000000001'
  and deleted_at is null
order by created_at
limit 3;

-- -----------------------------------------------------------------------------
-- 4) Auth helper functions exist + compile
-- -----------------------------------------------------------------------------

select
  public.current_auth_user_id() as current_auth_user_id,
  public.current_profile_id() as current_profile_id,
  public.current_tenant_id() as current_tenant_id;

-- In SQL Editor (service_role): expect ALL NULL — not a failure by itself.
-- With authenticated JWT (doctor-a): expect non-null profile + tenant A.

-- Optional membership probe when tenant known (replace UUID after login test):
-- select public.is_tenant_member('a0000001-0001-4001-8001-000000000001'::uuid);
-- select public.has_tenant_role(
--   'a0000001-0001-4001-8001-000000000001'::uuid,
--   array['doctor_admin']
-- );

-- -----------------------------------------------------------------------------
-- 5) Flutter / JWT verification checklist (manual — not SQL)
-- -----------------------------------------------------------------------------
-- After login as doctor-a in Flutter (DATA_BACKEND=supabase):
-- 1) DevTools network: GET rest/v1/physiotherapy_referrals → 200 or 403/401?
-- 2) Response body: [] vs error code PGRST205 / 42501 / column error
-- 3) ActiveTenantContextStore: tenant_id = a0000001-...001
-- 4) SessionReadiness.bootstrapStatus = ready
--
-- Maintenance bootstrap (if enabled): /maintenance → Auth/Profil zinciri yeşil

-- -----------------------------------------------------------------------------
-- 6) Cross-tenant data isolation (structural — service_role sees all)
-- Use for Flutter manual: doctor-a must NOT see tenant B rows via API
-- -----------------------------------------------------------------------------

select 'patients' as entity, tenant_id, count(*) as row_count
from patients where deleted_at is null
group by tenant_id
union all
select 'physiotherapy_referrals', tenant_id, count(*)
from physiotherapy_referrals where deleted_at is null
group by tenant_id
union all
select 'payments', tenant_id, count(*)
from payments where deleted_at is null
group by tenant_id
union all
select 'consents', tenant_id, count(*)
from consents where deleted_at is null
group by tenant_id
union all
select 'inventory_items', tenant_id, count(*)
from inventory_items where deleted_at is null
group by tenant_id
order by entity, tenant_id;

-- -----------------------------------------------------------------------------
-- 7) Orphan auth users (profiles without membership)
-- -----------------------------------------------------------------------------

select p.id, p.email, p.auth_user_id
from profiles p
left join memberships m on m.profile_id = p.id and m.status = 'active'
where p.email like '%@example.test'
  and m.id is null
  and p.email not in ('no-membership@example.test');
