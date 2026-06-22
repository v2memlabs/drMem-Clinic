-- =============================================================================
-- Staging Seed Data v1 — LOCAL / STAGING / DEV ONLY
-- =============================================================================
-- DO NOT RUN ON PRODUCTION.
-- Fake/demo data only. No real patient PII. No auth passwords. No signed URLs.
-- Idempotent: deterministic UUIDs + ON CONFLICT (safe re-run; does not wipe data).
-- Auth users: NOT inserted here — see docs/staging_seed_data_v1.md
--
-- UUID prefix map (hex-only — PostgreSQL rejects e.g. "p" in UUID strings):
--   patients A: 10000001-... | patients B: 20000001-...
--   patient_files A: 0f000001-... | patient_files B: 0f000002-...
--   pdf_outputs: 0d000001-...
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1) Tenants
-- -----------------------------------------------------------------------------

insert into tenants (id, name, specialty, timezone, status, created_at, updated_at)
values
  (
    'a0000001-0001-4001-8001-000000000001',
    'DrMem Demo Clinic A',
    'Ortopedi ve Travmatoloji (Seed)',
    'Europe/Istanbul',
    'active',
    '2026-04-01 08:00:00+03',
    '2026-05-20 10:00:00+03'
  ),
  (
    'a0000001-0001-4001-8001-000000000002',
    'DrMem Demo Clinic B',
    'Ortopedi (Seed Cross-Tenant)',
    'Europe/Istanbul',
    'active',
    '2026-04-05 08:00:00+03',
    '2026-05-20 10:00:00+03'
  ),
  (
    'a0000001-0001-4001-8001-000000000003',
    'DrMem Suspended Clinic',
    'Seed Suspended Tenant',
    'Europe/Istanbul',
    'suspended',
    '2026-04-10 08:00:00+03',
    '2026-05-15 10:00:00+03'
  )
on conflict (id) do update set
  name = excluded.name,
  specialty = excluded.specialty,
  timezone = excluded.timezone,
  status = excluded.status,
  updated_at = excluded.updated_at;

-- -----------------------------------------------------------------------------
-- 2) Profiles (auth_user_id null until Auth Admin links — see docs)
-- -----------------------------------------------------------------------------

insert into profiles (id, auth_user_id, display_name, email, created_at, updated_at)
values
  ('b0000001-0001-4001-8001-000000000001', null, 'Demo Doctor A', 'doctor-a@example.test', '2026-04-01 09:00:00+03', '2026-04-01 09:00:00+03'),
  ('b0000001-0001-4001-8001-000000000011', null, 'Demo Assistant A', 'assistant-a@example.test', '2026-04-01 09:00:00+03', '2026-04-01 09:00:00+03'),
  ('b0000001-0001-4001-8001-000000000021', null, 'Demo Physio A', 'physio-a@example.test', '2026-04-01 09:00:00+03', '2026-04-01 09:00:00+03'),
  ('b0000001-0001-4001-8001-000000000031', null, 'Demo Nurse A', 'nurse-a@example.test', '2026-04-01 09:00:00+03', '2026-04-01 09:00:00+03'),
  ('b0000001-0001-4001-8001-000000000002', null, 'Demo Doctor B', 'doctor-b@example.test', '2026-04-05 09:00:00+03', '2026-04-05 09:00:00+03'),
  ('b0000001-0001-4001-8001-000000000012', null, 'Demo Assistant B', 'assistant-b@example.test', '2026-04-05 09:00:00+03', '2026-04-05 09:00:00+03'),
  ('b0000001-0001-4001-8001-000000000022', null, 'Demo Physio B', 'physio-b@example.test', '2026-04-05 09:00:00+03', '2026-04-05 09:00:00+03'),
  ('b0000001-0001-4001-8001-000000000091', null, 'Demo Inactive Member', 'inactive-a@example.test', '2026-04-01 09:00:00+03', '2026-04-01 09:00:00+03'),
  ('b0000001-0001-4001-8001-000000000099', null, 'Demo No Membership', 'no-membership@example.test', '2026-04-01 09:00:00+03', '2026-04-01 09:00:00+03')
on conflict (id) do update set
  display_name = excluded.display_name,
  email = excluded.email,
  updated_at = excluded.updated_at;

-- -----------------------------------------------------------------------------
-- 3) Memberships
-- -----------------------------------------------------------------------------

insert into memberships (id, tenant_id, profile_id, role, status, created_at, updated_at)
values
  ('c0000001-0001-4001-8001-000000000001', 'a0000001-0001-4001-8001-000000000001', 'b0000001-0001-4001-8001-000000000001', 'doctor_admin', 'active', '2026-04-01 09:30:00+03', '2026-04-01 09:30:00+03'),
  ('c0000001-0001-4001-8001-000000000011', 'a0000001-0001-4001-8001-000000000001', 'b0000001-0001-4001-8001-000000000011', 'assistant_secretary', 'active', '2026-04-01 09:30:00+03', '2026-04-01 09:30:00+03'),
  ('c0000001-0001-4001-8001-000000000021', 'a0000001-0001-4001-8001-000000000001', 'b0000001-0001-4001-8001-000000000021', 'physiotherapist', 'active', '2026-04-01 09:30:00+03', '2026-04-01 09:30:00+03'),
  ('c0000001-0001-4001-8001-000000000031', 'a0000001-0001-4001-8001-000000000001', 'b0000001-0001-4001-8001-000000000031', 'nurse', 'active', '2026-04-01 09:30:00+03', '2026-04-01 09:30:00+03'),
  ('c0000001-0001-4001-8001-000000000002', 'a0000001-0001-4001-8001-000000000002', 'b0000001-0001-4001-8001-000000000002', 'doctor_admin', 'active', '2026-04-05 09:30:00+03', '2026-04-05 09:30:00+03'),
  ('c0000001-0001-4001-8001-000000000012', 'a0000001-0001-4001-8001-000000000002', 'b0000001-0001-4001-8001-000000000012', 'assistant_secretary', 'active', '2026-04-05 09:30:00+03', '2026-04-05 09:30:00+03'),
  ('c0000001-0001-4001-8001-000000000022', 'a0000001-0001-4001-8001-000000000002', 'b0000001-0001-4001-8001-000000000022', 'physiotherapist', 'active', '2026-04-05 09:30:00+03', '2026-04-05 09:30:00+03'),
  ('c0000001-0001-4001-8001-000000000091', 'a0000001-0001-4001-8001-000000000001', 'b0000001-0001-4001-8001-000000000091', 'assistant_secretary', 'disabled', '2026-04-01 09:30:00+03', '2026-05-01 09:30:00+03')
on conflict (tenant_id, profile_id) do update set
  role = excluded.role,
  status = excluded.status,
  updated_at = excluded.updated_at;

-- -----------------------------------------------------------------------------
-- 4) Subscriptions & usage limits
-- -----------------------------------------------------------------------------

insert into subscriptions (id, tenant_id, plan_key, status, current_period_start, current_period_end, created_at, updated_at)
values
  ('d0000001-0001-4001-8001-000000000001', 'a0000001-0001-4001-8001-000000000001', 'demo', 'active', '2026-04-01 00:00:00+03', '2027-04-01 00:00:00+03', '2026-04-01 10:00:00+03', '2026-04-01 10:00:00+03'),
  ('d0000001-0001-4001-8001-000000000002', 'a0000001-0001-4001-8001-000000000002', 'demo', 'active', '2026-04-05 00:00:00+03', '2027-04-05 00:00:00+03', '2026-04-05 10:00:00+03', '2026-04-05 10:00:00+03')
on conflict (tenant_id) do update set
  plan_key = excluded.plan_key,
  status = excluded.status,
  updated_at = excluded.updated_at;

insert into usage_limits (id, tenant_id, metric_key, limit_value, period, created_at, updated_at)
values
  ('e0000001-0001-4001-8001-000000000001', 'a0000001-0001-4001-8001-000000000001', 'patient_records', 50, 'lifetime', '2026-04-01 10:00:00+03', '2026-04-01 10:00:00+03'),
  ('e0000001-0001-4001-8001-000000000002', 'a0000001-0001-4001-8001-000000000002', 'patient_records', 50, 'lifetime', '2026-04-05 10:00:00+03', '2026-04-05 10:00:00+03')
on conflict (tenant_id, metric_key, period) do update set
  limit_value = excluded.limit_value,
  updated_at = excluded.updated_at;

-- -----------------------------------------------------------------------------
-- 5) Patients — Tenant A (8 fake) + Tenant B (3 cross-tenant)
-- -----------------------------------------------------------------------------

insert into patients (
  id, tenant_id, file_number, first_name, last_name, phone, birth_date, gender,
  national_id, insurance_type, status, created_at, updated_at, deleted_at
)
values
  ('10000001-0001-4001-8001-000000000001', 'a0000001-0001-4001-8001-000000000001', 'SEED-A-001', 'Demo', 'Sporcu Diz', '+905550000001', '1998-03-15', 'male', null, 'sgk', 'active', '2026-04-10 11:00:00+03', '2026-05-22 14:00:00+03', null),
  ('10000001-0001-4001-8001-000000000002', 'a0000001-0001-4001-8001-000000000001', 'SEED-A-002', 'Demo', 'Diz Agrisi', '+905550000002', '1975-07-22', 'female', null, 'private', 'active', '2026-04-12 11:00:00+03', '2026-05-18 10:00:00+03', null),
  ('10000001-0001-4001-8001-000000000003', 'a0000001-0001-4001-8001-000000000001', 'SEED-A-003', 'Demo', 'Omuz', '+905550000003', '1982-11-08', 'male', null, 'sgk', 'active', '2026-04-15 11:00:00+03', '2026-05-10 09:00:00+03', null),
  ('10000001-0001-4001-8001-000000000004', 'a0000001-0001-4001-8001-000000000001', 'SEED-A-004', 'Demo', 'PostOp', '+905550000004', '1968-01-30', 'female', null, 'sgk', 'active', '2026-04-18 11:00:00+03', '2026-05-23 16:00:00+03', null),
  ('10000001-0001-4001-8001-000000000005', 'a0000001-0001-4001-8001-000000000001', 'SEED-A-005', 'Demo', 'FTR Adayi', '+905550000005', '1990-09-12', 'male', null, 'private', 'active', '2026-04-20 11:00:00+03', '2026-05-21 11:00:00+03', null),
  ('10000001-0001-4001-8001-000000000006', 'a0000001-0001-4001-8001-000000000001', 'SEED-A-006', 'Demo', 'Rutin', '+905550000006', '2001-05-25', 'female', null, 'sgk', 'active', '2026-04-22 11:00:00+03', '2026-05-24 08:00:00+03', null),
  ('10000001-0001-4001-8001-000000000007', 'a0000001-0001-4001-8001-000000000001', 'SEED-A-007', 'Demo', 'Kalca', '+905550000007', '1955-12-03', 'male', null, 'sgk', 'active', '2026-04-25 11:00:00+03', '2026-04-25 11:00:00+03', null),
  ('10000001-0001-4001-8001-000000000008', 'a0000001-0001-4001-8001-000000000001', 'SEED-A-008', 'Demo', 'Ayak Bilegi', '+905550000008', '1995-08-19', 'female', null, 'private', 'active', '2026-05-01 11:00:00+03', '2026-05-19 15:00:00+03', null),
  ('20000001-0001-4001-8001-000000000001', 'a0000001-0001-4001-8001-000000000002', 'SEED-B-001', 'Demo', 'Tenant B Bir', '+905550000101', '1988-04-14', 'male', null, 'sgk', 'active', '2026-04-20 12:00:00+03', '2026-05-15 12:00:00+03', null),
  ('20000001-0001-4001-8001-000000000002', 'a0000001-0001-4001-8001-000000000002', 'SEED-B-002', 'Demo', 'Tenant B Iki', '+905550000102', '1972-06-06', 'female', null, 'private', 'active', '2026-04-22 12:00:00+03', '2026-05-16 12:00:00+03', null),
  ('20000001-0001-4001-8001-000000000003', 'a0000001-0001-4001-8001-000000000002', 'SEED-B-003', 'Demo', 'Tenant B Uc', '+905550000103', '1999-10-01', 'male', null, 'sgk', 'active', '2026-05-05 12:00:00+03', '2026-05-17 12:00:00+03', null)
on conflict (id) do update set
  first_name = excluded.first_name,
  last_name = excluded.last_name,
  phone = excluded.phone,
  birth_date = excluded.birth_date,
  gender = excluded.gender,
  status = excluded.status,
  updated_at = excluded.updated_at;

-- -----------------------------------------------------------------------------
-- 6) Appointments
-- -----------------------------------------------------------------------------

insert into appointments (
  id, tenant_id, patient_id, appointment_at, status, appointment_type, notes,
  created_by, created_at, updated_at, deleted_at
)
values
  -- Tenant A — today / near
  ('f0000001-0001-4001-8001-000000000001', 'a0000001-0001-4001-8001-000000000001', '10000001-0001-4001-8001-000000000001', '2026-05-24 09:00:00+03', 'planned', 'kontrol', 'Seed: bugun planli', 'b0000001-0001-4001-8001-000000000001', '2026-05-20 08:00:00+03', '2026-05-20 08:00:00+03', null),
  ('f0000001-0001-4001-8001-000000000002', 'a0000001-0001-4001-8001-000000000001', '10000001-0001-4001-8001-000000000006', '2026-05-24 11:30:00+03', 'arrived', 'ilk_muayene', 'Seed: bugun geldi', 'b0000001-0001-4001-8001-000000000011', '2026-05-24 07:00:00+03', '2026-05-24 11:35:00+03', null),
  ('f0000001-0001-4001-8001-000000000003', 'a0000001-0001-4001-8001-000000000001', '10000001-0001-4001-8001-000000000002', '2026-05-24 14:00:00+03', 'planned', 'kontrol', 'Seed: bugun ogleden sonra', 'b0000001-0001-4001-8001-000000000001', '2026-05-21 10:00:00+03', '2026-05-21 10:00:00+03', null),
  -- Tenant A — past
  ('f0000001-0001-4001-8001-000000000004', 'a0000001-0001-4001-8001-000000000001', '10000001-0001-4001-8001-000000000003', '2026-05-10 10:00:00+03', 'arrived', 'kontrol', 'Seed: gecmis tamamlandi', 'b0000001-0001-4001-8001-000000000001', '2026-05-01 09:00:00+03', '2026-05-10 10:30:00+03', null),
  ('f0000001-0001-4001-8001-000000000005', 'a0000001-0001-4001-8001-000000000001', '10000001-0001-4001-8001-000000000004', '2026-05-05 15:00:00+03', 'no_show', 'post_op', 'Seed: gelmedi', 'b0000001-0001-4001-8001-000000000011', '2026-04-28 09:00:00+03', '2026-05-05 15:30:00+03', null),
  ('f0000001-0001-4001-8001-000000000006', 'a0000001-0001-4001-8001-000000000001', '10000001-0001-4001-8001-000000000005', '2026-04-28 09:30:00+03', 'arrived', 'ftr', 'Seed: gecmis FTR', 'b0000001-0001-4001-8001-000000000001', '2026-04-20 09:00:00+03', '2026-04-28 10:00:00+03', null),
  -- Tenant A — future / cancelled / postponed
  ('f0000001-0001-4001-8001-000000000007', 'a0000001-0001-4001-8001-000000000001', '10000001-0001-4001-8001-000000000007', '2026-05-28 10:00:00+03', 'planned', 'kontrol', 'Seed: gelecek', 'b0000001-0001-4001-8001-000000000001', '2026-05-22 09:00:00+03', '2026-05-22 09:00:00+03', null),
  ('f0000001-0001-4001-8001-000000000008', 'a0000001-0001-4001-8001-000000000001', '10000001-0001-4001-8001-000000000008', '2026-06-02 16:00:00+03', 'planned', 'kontrol', 'Seed: gelecek hafta', 'b0000001-0001-4001-8001-000000000011', '2026-05-23 09:00:00+03', '2026-05-23 09:00:00+03', null),
  ('f0000001-0001-4001-8001-000000000009', 'a0000001-0001-4001-8001-000000000001', '10000001-0001-4001-8001-000000000002', '2026-05-30 09:00:00+03', 'cancelled', 'kontrol', 'Seed: iptal', 'b0000001-0001-4001-8001-000000000001', '2026-05-15 09:00:00+03', '2026-05-18 12:00:00+03', null),
  ('f0000001-0001-4001-8001-000000000010', 'a0000001-0001-4001-8001-000000000001', '10000001-0001-4001-8001-000000000001', '2026-06-05 11:00:00+03', 'postponed', 'kontrol', 'Seed: ertelendi', 'b0000001-0001-4001-8001-000000000011', '2026-05-19 09:00:00+03', '2026-05-20 14:00:00+03', null),
  -- Tenant B — cross-tenant
  ('f0000002-0001-4001-8001-000000000001', 'a0000001-0001-4001-8001-000000000002', '20000001-0001-4001-8001-000000000001', '2026-05-24 10:00:00+03', 'planned', 'kontrol', 'Seed B: bugun', 'b0000001-0001-4001-8001-000000000002', '2026-05-18 09:00:00+03', '2026-05-18 09:00:00+03', null),
  ('f0000002-0001-4001-8001-000000000002', 'a0000001-0001-4001-8001-000000000002', '20000001-0001-4001-8001-000000000002', '2026-05-12 14:00:00+03', 'arrived', 'kontrol', 'Seed B: gecmis', 'b0000001-0001-4001-8001-000000000002', '2026-05-01 09:00:00+03', '2026-05-12 14:30:00+03', null),
  ('f0000002-0001-4001-8001-000000000003', 'a0000001-0001-4001-8001-000000000002', '20000001-0001-4001-8001-000000000003', '2026-06-01 09:00:00+03', 'planned', 'kontrol', 'Seed B: gelecek', 'b0000001-0001-4001-8001-000000000002', '2026-05-20 09:00:00+03', '2026-05-20 09:00:00+03', null)
on conflict (id) do update set
  appointment_at = excluded.appointment_at,
  status = excluded.status,
  notes = excluded.notes,
  updated_at = excluded.updated_at;

-- -----------------------------------------------------------------------------
-- 7) Clinical encounters
-- internal_doctor_note ONLY in column — never in clinical_data JSONB
-- -----------------------------------------------------------------------------

insert into clinical_encounters (
  id, tenant_id, patient_id, appointment_id, encounter_date, visit_type, status,
  diagnosis_summary, treatment_plan_summary, clinical_data, internal_doctor_note,
  created_by, created_at, updated_at, deleted_at
)
values
  (
    'ce000001-0001-4001-8001-000000000001',
    'a0000001-0001-4001-8001-000000000001',
    '10000001-0001-4001-8001-000000000001',
    'f0000001-0001-4001-8001-000000000004',
    '2026-05-10 10:45:00+03',
    'first_visit',
    'physiotherapy_referred',
    'Seed: ACL sprain suspicion (fake)',
    'Seed: PT referral + home exercise (fake)',
    '{
      "bodyRegion": "knee",
      "side": "right",
      "examination": { "rangeOfMotion": "Flexion 95 deg, extension full" },
      "plan": {
        "controlDate": "2026-06-10T10:00:00+03:00",
        "physiotherapyReferral": true,
        "exerciseRecommendation": "Quad sets 3x15, SLR 3x10",
        "warningNotes": "Avoid pivot sports 6 weeks",
        "surgeryRecommendation": "ACL reconstruction post-op week 4 context"
      },
      "sports": { "returnToSportGoal": "Return to recreational football (seed)" }
    }'::jsonb,
    'SEED TEST ONLY (fake): Internal doctor note for doctor_admin RLS path. Not real clinical data.',
    'b0000001-0001-4001-8001-000000000001',
    '2026-05-10 11:00:00+03',
    '2026-05-22 14:00:00+03',
    null
  ),
  (
    'ce000001-0001-4001-8001-000000000002',
    'a0000001-0001-4001-8001-000000000001',
    '10000001-0001-4001-8001-000000000002',
    'f0000001-0001-4001-8001-000000000003',
    '2026-05-18 14:30:00+03',
    'follow_up',
    'completed',
    'Seed: Patellofemoral pain (fake)',
    'Seed: NSAID + strengthening (fake)',
    '{
      "bodyRegion": "knee",
      "side": "left",
      "examination": { "rangeOfMotion": "Mild patellar grind, flexion 110 deg" },
      "plan": {
        "controlDate": "2026-07-01T09:00:00+03:00",
        "physiotherapyReferral": false,
        "exerciseRecommendation": "VMO strengthening, step-downs",
        "warningNotes": "Limit stairs first 2 weeks"
      }
    }'::jsonb,
    null,
    'b0000001-0001-4001-8001-000000000001',
    '2026-05-18 15:00:00+03',
    '2026-05-18 15:00:00+03',
    null
  ),
  (
    'ce000001-0001-4001-8001-000000000003',
    'a0000001-0001-4001-8001-000000000001',
    '10000001-0001-4001-8001-000000000003',
    null,
    '2026-05-08 09:00:00+03',
    'follow_up',
    'completed',
    'Seed: Rotator cuff tendinopathy (fake)',
    'Seed: Physio + injection option discussed (fake)',
    '{
      "bodyRegion": "shoulder",
      "side": "right",
      "examination": { "rangeOfMotion": "Abduction 140 deg, painful arc" },
      "plan": {
        "controlDate": "2026-05-25T11:00:00+03:00",
        "physiotherapyReferral": true,
        "exerciseRecommendation": "Pendulum, external rotation band",
        "warningNotes": "No heavy overhead lifting 4 weeks"
      }
    }'::jsonb,
    null,
    'b0000001-0001-4001-8001-000000000001',
    '2026-05-08 09:15:00+03',
    '2026-05-10 09:00:00+03',
    null
  ),
  (
    'ce000001-0001-4001-8001-000000000004',
    'a0000001-0001-4001-8001-000000000001',
    '10000001-0001-4001-8001-000000000004',
    'f0000001-0001-4001-8001-000000000005',
    '2026-05-02 15:30:00+03',
    'post_op_follow_up',
    'control_planned',
    'Seed: TKA post-op week 2 (fake)',
    'Seed: Wound check + ROM goals (fake)',
    '{
      "bodyRegion": "knee",
      "side": "left",
      "examination": { "rangeOfMotion": "Flexion 85 deg post-op" },
      "plan": {
        "controlDate": "2026-05-16T10:00:00+03:00",
        "physiotherapyReferral": true,
        "exerciseRecommendation": "Heel slides, ankle pumps",
        "warningNotes": "Weight bearing as tolerated per protocol",
        "surgeryRecommendation": "TKA post-op week 2 — incision healing good (seed)"
      }
    }'::jsonb,
    null,
    'b0000001-0001-4001-8001-000000000001',
    '2026-05-02 16:00:00+03',
    '2026-05-23 16:00:00+03',
    null
  ),
  (
    'ce000001-0001-4001-8001-000000000005',
    'a0000001-0001-4001-8001-000000000001',
    '10000001-0001-4001-8001-000000000005',
    'f0000001-0001-4001-8001-000000000006',
    '2026-04-28 10:15:00+03',
    'general_orthopedic_eval',
    'physiotherapy_referred',
    'Seed: Lumbar radiculopathy screen — FTR candidate (fake)',
    'Seed: Core stability + PT (fake)',
    '{
      "bodyRegion": "spine",
      "side": "bilateral",
      "examination": { "rangeOfMotion": "Lumbar flexion limited, SLR negative bilat" },
      "plan": {
        "controlDate": "2026-06-15T14:00:00+03:00",
        "physiotherapyReferral": true,
        "exerciseRecommendation": "McKenzie extension, core activation",
        "warningNotes": "Red flags education provided (seed)"
      },
      "sports": { "returnToSportGoal": "Return to desk job ergonomics (seed)" }
    }'::jsonb,
    null,
    'b0000001-0001-4001-8001-000000000001',
    '2026-04-28 10:30:00+03',
    '2026-05-21 11:00:00+03',
    null
  ),
  (
    'ce000001-0001-4001-8001-000000000006',
    'a0000001-0001-4001-8001-000000000001',
    '10000001-0001-4001-8001-000000000006',
    'f0000001-0001-4001-8001-000000000002',
    '2026-05-24 11:45:00+03',
    'follow_up',
    'draft',
    'Seed: Routine ortho check (fake)',
    'Seed: Continue observation (fake)',
    '{
      "bodyRegion": "ankle",
      "side": "right",
      "examination": { "rangeOfMotion": "Full ROM, mild swelling" },
      "plan": {
        "controlDate": "2026-08-01T09:00:00+03:00",
        "physiotherapyReferral": false,
        "exerciseRecommendation": "Balance board 5 min",
        "warningNotes": "Ice after activity"
      }
    }'::jsonb,
    null,
    'b0000001-0001-4001-8001-000000000001',
    '2026-05-24 12:00:00+03',
    '2026-05-24 12:00:00+03',
    null
  ),
  -- Tenant B — cross-tenant
  (
    'ce000002-0001-4001-8001-000000000001',
    'a0000001-0001-4001-8001-000000000002',
    '20000001-0001-4001-8001-000000000001',
    'f0000002-0001-4001-8001-000000000002',
    '2026-05-12 14:45:00+03',
    'follow_up',
    'completed',
    'Seed B: Generic knee pain (fake)',
    'Seed B: Home program (fake)',
    '{
      "bodyRegion": "knee",
      "side": "left",
      "examination": { "rangeOfMotion": "Full" },
      "plan": {
        "controlDate": "2026-06-12T10:00:00+03:00",
        "physiotherapyReferral": true,
        "exerciseRecommendation": "Hamstring stretch",
        "warningNotes": "Seed tenant B only"
      }
    }'::jsonb,
    null,
    'b0000001-0001-4001-8001-000000000002',
    '2026-05-12 15:00:00+03',
    '2026-05-16 12:00:00+03',
    null
  ),
  (
    'ce000002-0001-4001-8001-000000000002',
    'a0000001-0001-4001-8001-000000000002',
    '20000001-0001-4001-8001-000000000002',
    null,
    '2026-05-06 11:00:00+03',
    'first_visit',
    'completed',
    'Seed B: Shoulder strain (fake)',
    'Seed B: Rest + PT (fake)',
    '{
      "bodyRegion": "shoulder",
      "side": "left",
      "plan": {
        "physiotherapyReferral": false,
        "exerciseRecommendation": "Pendulum exercises"
      }
    }'::jsonb,
    'SEED B ONLY (fake): Internal note tenant B — must not leak to tenant A users.',
    'b0000001-0001-4001-8001-000000000002',
    '2026-05-06 11:15:00+03',
    '2026-05-06 11:15:00+03',
    null
  )
on conflict (id) do update set
  visit_type = excluded.visit_type,
  status = excluded.status,
  diagnosis_summary = excluded.diagnosis_summary,
  treatment_plan_summary = excluded.treatment_plan_summary,
  clinical_data = excluded.clinical_data,
  internal_doctor_note = excluded.internal_doctor_note,
  updated_at = excluded.updated_at;

-- -----------------------------------------------------------------------------
-- 8) Patient files (metadata only — no binary, no signed/public URLs)
-- -----------------------------------------------------------------------------

insert into patient_files (
  id, tenant_id, patient_id, file_name, file_type, mime_type, storage_path, size_bytes,
  created_by, created_at, deleted_at,
  storage_bucket, file_kind, clinical_context, encounter_id, appointment_id,
  display_name, original_file_name, checksum, status, visibility_scope, metadata, updated_at
)
values
  (
    '0f000001-0001-4001-8001-000000000001',
    'a0000001-0001-4001-8001-000000000001',
    '10000001-0001-4001-8001-000000000001',
    'seed-mri-report.pdf',
    'pdf',
    'application/pdf',
    'a0000001-0001-4001-8001-000000000001/patients/10000001-0001-4001-8001-000000000001/files/0f000001-0001-4001-8001-000000000001/seed-mri-report.pdf',
    102400,
    'b0000001-0001-4001-8001-000000000001',
    '2026-05-11 12:00:00+03',
    null,
    'patient-files-private',
    'imaging_report',
    'encounter',
    'ce000001-0001-4001-8001-000000000001',
    'f0000001-0001-4001-8001-000000000004',
    'Seed MRI Report (fake)',
    'seed-mri-report.pdf',
    'seed-checksum-fake-001',
    'active',
    'doctor_admin',
    '{"seedTag": "patient_upload_metadata_only", "source": "staging_seed_v1"}'::jsonb,
    '2026-05-11 12:00:00+03'
  ),
  (
    '0f000001-0001-4001-8001-000000000002',
    'a0000001-0001-4001-8001-000000000001',
    '10000001-0001-4001-8001-000000000002',
    'seed-consent.pdf',
    'pdf',
    'application/pdf',
    'a0000001-0001-4001-8001-000000000001/patients/10000001-0001-4001-8001-000000000002/files/0f000001-0001-4001-8001-000000000002/seed-consent.pdf',
    51200,
    'b0000001-0001-4001-8001-000000000011',
    '2026-05-19 09:00:00+03',
    null,
    'patient-files-private',
    'consent_document',
    'consent',
    null,
    null,
    'Seed Consent (fake)',
    'seed-consent.pdf',
    'seed-checksum-fake-002',
    'active',
    'clinic_operations',
    '{"seedTag": "consent_metadata_only"}'::jsonb,
    '2026-05-19 09:00:00+03'
  ),
  (
    '0f000001-0001-4001-8001-000000000003',
    'a0000001-0001-4001-8001-000000000001',
    '10000001-0001-4001-8001-000000000005',
    'seed-pt-plan.pdf',
    'pdf',
    'application/pdf',
    'a0000001-0001-4001-8001-000000000001/patients/10000001-0001-4001-8001-000000000005/files/0f000001-0001-4001-8001-000000000003/seed-pt-plan.pdf',
    76800,
    'b0000001-0001-4001-8001-000000000021',
    '2026-05-20 14:00:00+03',
    null,
    'patient-files-private',
    'physiotherapy_document',
    'physiotherapy',
    'ce000001-0001-4001-8001-000000000005',
    null,
    'Seed PT Plan (fake)',
    'seed-pt-plan.pdf',
    'seed-checksum-fake-003',
    'active',
    'physiotherapy',
    '{"seedTag": "physio_visibility_test"}'::jsonb,
    '2026-05-20 14:00:00+03'
  ),
  (
    '0f000001-0001-4001-8001-000000000004',
    'a0000001-0001-4001-8001-000000000001',
    '10000001-0001-4001-8001-000000000006',
    'seed-patient-upload.jpg',
    'image',
    'image/jpeg',
    'a0000001-0001-4001-8001-000000000001/patients/10000001-0001-4001-8001-000000000006/files/0f000001-0001-4001-8001-000000000004/seed-patient-upload.jpg',
    204800,
    'b0000001-0001-4001-8001-000000000011',
    '2026-05-23 10:00:00+03',
    null,
    'patient-files-private',
    'patient_upload',
    'patient',
    null,
    null,
    'Seed Patient Upload (fake)',
    'seed-patient-upload.jpg',
    'seed-checksum-fake-004',
    'active',
    'clinic_operations',
    '{"seedTag": "assistant_file_list_test"}'::jsonb,
    '2026-05-23 10:00:00+03'
  ),
  (
    '0f000002-0001-4001-8001-000000000001',
    'a0000001-0001-4001-8001-000000000002',
    '20000001-0001-4001-8001-000000000001',
    'seed-b-file.pdf',
    'pdf',
    'application/pdf',
    'a0000001-0001-4001-8001-000000000002/patients/20000001-0001-4001-8001-000000000001/files/0f000002-0001-4001-8001-000000000001/seed-b-file.pdf',
    40960,
    'b0000001-0001-4001-8001-000000000002',
    '2026-05-14 11:00:00+03',
    null,
    'patient-files-private',
    'patient_upload',
    'patient',
    null,
    null,
    'Seed Tenant B File (fake)',
    'seed-b-file.pdf',
    'seed-checksum-fake-b01',
    'active',
    'clinic_operations',
    '{"seedTag": "tenant_b_cross_tenant_test"}'::jsonb,
    '2026-05-14 11:00:00+03'
  )
on conflict (id) do update set
  display_name = excluded.display_name,
  visibility_scope = excluded.visibility_scope,
  metadata = excluded.metadata,
  updated_at = excluded.updated_at;

-- -----------------------------------------------------------------------------
-- 9) PDF outputs (metadata only)
-- -----------------------------------------------------------------------------

insert into pdf_outputs (
  id, tenant_id, patient_id, document_type, source_module, source_record_id,
  storage_path, status, created_by, created_at,
  storage_bucket, file_kind, clinical_context, encounter_id, appointment_id,
  display_name, original_file_name, mime_type, file_size_bytes, checksum,
  visibility_scope, metadata, updated_at, deleted_at
)
values
  (
    '0d000001-0001-4001-8001-000000000001',
    'a0000001-0001-4001-8001-000000000001',
    '10000001-0001-4001-8001-000000000001',
    'encounter_summary',
    'clinical_encounter',
    'ce000001-0001-4001-8001-000000000001',
    'a0000001-0001-4001-8001-000000000001/patients/10000001-0001-4001-8001-000000000001/pdf/0d000001-0001-4001-8001-000000000001.pdf',
    'ready',
    'b0000001-0001-4001-8001-000000000001',
    '2026-05-12 16:00:00+03',
    'patient-files-private',
    'generated_pdf',
    'encounter',
    'ce000001-0001-4001-8001-000000000001',
    null,
    'Seed Encounter PDF (fake)',
    'encounter-summary.pdf',
    'application/pdf',
    88000,
    'seed-pdf-checksum-001',
    'doctor_admin',
    '{"seedTag": "generated_pdf_metadata"}'::jsonb,
    '2026-05-12 16:00:00+03',
    null
  ),
  (
    '0d000001-0001-4001-8001-000000000002',
    'a0000001-0001-4001-8001-000000000001',
    '10000001-0001-4001-8001-000000000005',
    'pt_referral',
    'physiotherapy_referral',
    null,
    'a0000001-0001-4001-8001-000000000001/patients/10000001-0001-4001-8001-000000000005/pdf/0d000001-0001-4001-8001-000000000002.pdf',
    'draft',
    'b0000001-0001-4001-8001-000000000001',
    '2026-05-21 10:00:00+03',
    'patient-files-private',
    'physiotherapy_document',
    'physiotherapy',
    'ce000001-0001-4001-8001-000000000005',
    null,
    'Seed PT Referral PDF (fake)',
    'pt-referral.pdf',
    'application/pdf',
    45000,
    'seed-pdf-checksum-002',
    'doctor_admin',
    '{"seedTag": "pt_pdf_metadata"}'::jsonb,
    '2026-05-21 10:00:00+03',
    null
  )
on conflict (id) do update set
  status = excluded.status,
  metadata = excluded.metadata,
  updated_at = excluded.updated_at;

-- -----------------------------------------------------------------------------
-- 10) Audit logs (append-only samples — optional timeline-adjacent context)
-- -----------------------------------------------------------------------------

insert into audit_logs (id, tenant_id, actor_profile_id, action, module, record_id, patient_id, metadata, created_at)
values
  ('aa000001-0001-4001-8001-000000000001', 'a0000001-0001-4001-8001-000000000001', 'b0000001-0001-4001-8001-000000000001', 'patient.view', 'patients', '10000001-0001-4001-8001-000000000001', '10000001-0001-4001-8001-000000000001', '{"seed": true}'::jsonb, '2026-05-20 08:00:00+03'),
  ('aa000001-0001-4001-8001-000000000002', 'a0000001-0001-4001-8001-000000000001', 'b0000001-0001-4001-8001-000000000011', 'appointment.create', 'appointments', 'f0000001-0001-4001-8001-000000000007', '10000001-0001-4001-8001-000000000007', '{"seed": true}'::jsonb, '2026-05-22 09:05:00+03'),
  ('aa000001-0001-4001-8001-000000000003', 'a0000001-0001-4001-8001-000000000001', 'b0000001-0001-4001-8001-000000000001', 'clinical_encounter.update', 'clinical_encounters', 'ce000001-0001-4001-8001-000000000001', '10000001-0001-4001-8001-000000000001', '{"seed": true}'::jsonb, '2026-05-22 14:05:00+03')
on conflict (id) do nothing;

-- -----------------------------------------------------------------------------
-- 11) Maintenance / Bootstrap Console (staging/dev only)
-- -----------------------------------------------------------------------------

insert into maintenance_config (id, enabled, updated_at)
values (1, true, now())
on conflict (id) do update set
  enabled = true,
  updated_at = excluded.updated_at;

update profiles
set maintenance_operator = true
where id = 'b0000001-0001-4001-8001-000000000001';

commit;
