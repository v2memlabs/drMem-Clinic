-- =============================================================================
-- Staging Remote Role Matrix & Operational Smoke Checks v1
--
-- PURPOSE: Map RLS policies → roles; guide per-role SELECT/INSERT smoke.
--
-- LIMITATIONS:
--   SQL Editor (service_role) BYPASSES RLS — section 1 is structural only.
--   Per-role allow/deny MUST be verified via Flutter client (section 4 checklist)
--   or PostgREST with user JWT (anon key + Authorization: Bearer <access_token>).
--
-- Seed tenant A: a0000001-0001-4001-8001-000000000001
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Policy → role matrix (from pg_policies definitions)
-- Compare against expected matrix in runbook section 9.
-- -----------------------------------------------------------------------------

select
  tablename,
  policyname,
  cmd,
  roles::text as policy_roles,
  case tablename
    when 'payments' then 'doctor_admin, assistant_secretary'
    when 'consents' then 'doctor_admin, assistant_secretary'
    when 'inventory_items' then 'doctor_admin, nurse'
    when 'inventory_movements' then 'doctor_admin, nurse (SELECT only; INSERT via RPC)'
    when 'physiotherapy_referrals' then 'doctor_admin (CRU), physiotherapist (SELECT+safe UPDATE)'
    when 'physiotherapy_sessions' then 'doctor_admin (SELECT), physiotherapist (SELECT+INSERT)'
    when 'pdf_outputs' then 'doctor_admin'
    when 'clinical_encounters' then 'doctor_admin (see draft policies)'
    when 'patients' then 'staff roles per base migration'
    else 'verify manually'
  end as expected_roles_note
from pg_policies
where schemaname = 'public'
  and tablename in (
    'payments',
    'consents',
    'inventory_items',
    'inventory_movements',
    'physiotherapy_referrals',
    'physiotherapy_sessions',
    'pdf_outputs',
    'clinical_encounters',
    'patients',
    'appointments'
  )
order by tablename, cmd, policyname;

-- -----------------------------------------------------------------------------
-- 2) Expected pass/fail matrix (reference — not executable)
-- -----------------------------------------------------------------------------
-- Role          | payments | consents | inventory | FTR ref | FTR sess | PDF | clinical | patients
-- --------------|----------|----------|-----------|---------|----------|-----|----------|----------
-- doctor_admin  | S/I/U    | S/I/U    | S/I/U     | S/I/U   | S/I      | S/I | S/I/U    | S
-- assistant     | S/I/U    | S/I/U    | DENY      | DENY    | DENY     | DENY| DENY     | S
-- physiotherapist| DENY    | DENY     | DENY      | S/U*    | S/I      | DENY| DENY     | route DENY**
-- nurse         | DENY     | DENY     | S/I/U+RPC | DENY    | DENY     | DENY| DENY     | S***
-- * physio UPDATE: safe fields only (status, notes_safe) per policy
-- ** physio patients: referred-only RLS + view_patients role_access (Faz 2 Paket 2)
-- *** nurse patient SELECT: patients RLS + view_patients role_access (Faz 2 Paket 2)
-- Maintenance can disable view_patients per role — verify JWT SELECT returns 0 rows

-- -----------------------------------------------------------------------------
-- 3) Operational module smoke — STRUCTURAL (service_role)
-- Replace :tenant_id / :patient_id / :profile_id with seed values from
-- staging_remote_rls_smoke_checks.sql section 3.
-- -----------------------------------------------------------------------------

-- --- 3a) PAYMENTS ---
-- select count(*) from payments where tenant_id = 'a0000001-0001-4001-8001-000000000001' and deleted_at is null;

-- Minimal insert (service_role only — validates schema + FK):
/*
insert into payments (
  tenant_id, patient_id, service_type, total_amount, paid_amount,
  payment_method, payment_status, invoice_status, transaction_date
) values (
  'a0000001-0001-4001-8001-000000000001',
  '<PATIENT_UUID>',
  'muayene',
  100.00, 100.00,
  'nakit', 'odendi', 'fatura_yok', now()
) returning id, tenant_id, payment_status;

-- Soft delete visibility (if column exists):
-- update payments set deleted_at = now() where id = '<ID>';
-- select count(*) from payments where id = '<ID>' and deleted_at is null; -- expect 0 under RLS
*/

-- --- 3b) CONSENTS ---
/*
insert into consents (
  tenant_id, patient_id, consent_type, status, given_at
) values (
  'a0000001-0001-4001-8001-000000000001',
  '<PATIENT_UUID>',
  'bilgilendirilmis_onam', 'bekliyor', null
) returning id, status;

-- Pending count (assistant dashboard):
-- select count(*) from consents
-- where tenant_id = 'a0000001-0001-4001-8001-000000000001'
--   and status = 'bekliyor' and deleted_at is null;
*/

-- --- 3c) INVENTORY ---
/*
insert into inventory_items (
  tenant_id, name, category, unit, current_quantity, minimum_quantity
) values (
  'a0000001-0001-4001-8001-000000000001',
  'STAGING-SMOKE-ITEM', 'sarf', 'adet', 10, 2
) returning id, current_quantity;

-- Movement IN:
select record_inventory_movement(
  p_inventory_item_id := '<ITEM_UUID>',
  p_movement_type := 'giris',
  p_quantity := 5
);

-- Movement OUT:
select record_inventory_movement(
  p_inventory_item_id := '<ITEM_UUID>',
  p_movement_type := 'cikis',
  p_quantity := 3
);

-- Oversell deny (expect exception):
-- select record_inventory_movement('<ITEM_UUID>', 'cikis', 99999);

select * from inventory_movements
where inventory_item_id = '<ITEM_UUID>'
order by movement_date desc
limit 5;
*/

-- --- 3d) FTR REFERRALS ---
/*
insert into physiotherapy_referrals (
  tenant_id, patient_id, referred_by_profile_id,
  reason, status, notes_safe
) values (
  'a0000001-0001-4001-8001-000000000001',
  '<PATIENT_UUID>',
  '<DOCTOR_PROFILE_UUID>',
  'STAGING smoke referral', 'bekliyor', 'safe note'
) returning id, status;

-- Physio safe update:
-- update physiotherapy_referrals set status = 'devam_ediyor', notes_safe = 'physio note'
-- where id = '<REFERRAL_UUID>';
*/

-- --- 3e) FTR SESSIONS ---
/*
insert into physiotherapy_sessions (
  tenant_id, referral_id, patient_id, physiotherapist_profile_id,
  session_date, pain_score, doctor_notification_needed
) values (
  'a0000001-0001-4001-8001-000000000001',
  '<REFERRAL_UUID>',
  '<PATIENT_UUID>',
  '<PHYSIO_PROFILE_UUID>',
  now(), 3, false
) returning id;

-- Cross-tenant deny (expect FK/RLS failure with user JWT):
-- insert with patient_id from Tenant B while tenant_id = Tenant A
*/

-- -----------------------------------------------------------------------------
-- 4) Flutter / JWT role matrix checklist (manual)
-- -----------------------------------------------------------------------------
-- For each user, open DevTools → Network → filter rest/v1
--
-- doctor-a@example.test:
--   GET payments → 200 + JSON array
--   POST payments → 201
--   GET physiotherapy_referrals → 200
--   POST physiotherapy_referrals → 201
--   GET inventory_items → 200
--   GET pdf_outputs → 200
--
-- assistant-a@example.test:
--   GET payments → 200; POST → 201
--   GET consents → 200; POST → 201
--   GET physiotherapy_referrals → 200 empty OR 403 (both acceptable if deny)
--   GET clinical_encounters → must NOT return rows (403 or [])
--   GET inventory_items → 403 or empty
--
-- physio-a@example.test:
--   GET physiotherapy_referrals → 200
--   PATCH physiotherapy_referrals (status) → 200
--   GET physiotherapy_sessions → 200; POST → 201
--   GET payments → 403
--   Patient list screen → "hasta listesi yok" (app gate, not necessarily RLS)
--
-- nurse-a@example.test:
--   GET inventory_items → 200; POST → 201
--   RPC record_inventory_movement → 200
--   GET payments → 403
--   GET physiotherapy_referrals → 403
--
-- Cross-tenant (doctor-a):
--   GET patients?tenant_id=eq.<TENANT_B> → 0 rows or 403
--   POST payment with Tenant B patient_id → 403 / FK violation

-- -----------------------------------------------------------------------------
-- 5) Cross-tenant structural probe (service_role — data exists check)
-- -----------------------------------------------------------------------------

select
  p.email,
  m.tenant_id,
  m.role
from memberships m
join profiles p on p.id = m.profile_id
where p.email like '%@example.test'
  and m.status = 'active'
order by m.tenant_id, p.email;

-- Verify Tenant A doctor cannot reference Tenant B patient (FK + RLS):
select
  pa.id as tenant_a_patient,
  pb.id as tenant_b_patient
from patients pa
cross join patients pb
where pa.tenant_id = 'a0000001-0001-4001-8001-000000000001'
  and pb.tenant_id = 'a0000001-0001-4001-8001-000000000002'
  and pa.deleted_at is null
  and pb.deleted_at is null
limit 1;

-- Use IDs above for cross-tenant insert denial test in Flutter.

-- -----------------------------------------------------------------------------
-- 6) PostgREST embed relationship spot check (PGRST200/201 prevention)
-- Tables referenced in Flutter select= embed strings must have FK in DB.
-- -----------------------------------------------------------------------------

select
  tc.table_name,
  kcu.column_name,
  ccu.table_name as foreign_table,
  ccu.column_name as foreign_column
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
  on tc.constraint_name = kcu.constraint_name
join information_schema.constraint_column_usage ccu
  on ccu.constraint_name = tc.constraint_name
where tc.constraint_type = 'FOREIGN KEY'
  and tc.table_schema = 'public'
  and tc.table_name in (
    'payments',
    'consents',
    'physiotherapy_referrals',
    'physiotherapy_sessions',
    'inventory_movements'
  )
order by tc.table_name, kcu.column_name;

-- Expected FKs include:
-- payments.patient_id → patients
-- consents.patient_id → patients
-- physiotherapy_referrals.patient_id → patients
-- physiotherapy_sessions.referral_id → physiotherapy_referrals
-- physiotherapy_sessions.patient_id → patients
