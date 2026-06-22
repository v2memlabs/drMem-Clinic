-- =============================================================================
-- FTR Forward Compat Stub v1
--
-- Fresh migration chain fix: physiotherapy_referrals and physiotherapy_sessions
-- must exist before 20260602130000_ftr_sessions_insert_policy_hardening_v1.sql.
-- Canonical table definitions remain in 20260703100000 / 20260704100000 (no-op
-- via create table if not exists). Policies are applied by later migrations.
-- =============================================================================

create table if not exists physiotherapy_referrals (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  patient_id uuid not null references patients (id) on delete restrict,
  clinical_encounter_id uuid references clinical_encounters (id) on delete set null,
  appointment_id uuid references appointments (id) on delete set null,
  referred_by_profile_id uuid not null references profiles (id) on delete restrict,
  assigned_physiotherapist_profile_id uuid references profiles (id) on delete set null,
  reason text not null,
  body_region text,
  side text,
  priority text default 'normal',
  status text not null,
  planned_start_date date,
  treatment_goal text,
  precautions text,
  allowed_activities text,
  restricted_activities text,
  target_return_date date,
  notes_safe text,
  doctor_summary text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint physiotherapy_referrals_status_check check (
    status in (
      'yeni',
      'devam',
      'tamamlandi',
      'doktor_degerlendirmesi_bekliyor',
      'iptal'
    )
  )
);

create table if not exists physiotherapy_sessions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  referral_id uuid not null references physiotherapy_referrals (id) on delete restrict,
  patient_id uuid not null references patients (id) on delete restrict,
  physiotherapist_profile_id uuid not null references profiles (id) on delete restrict,
  session_date timestamptz not null,
  status text not null default 'kayitli',
  pain_score numeric(4, 1),
  range_of_motion text,
  strength text,
  functional_status text,
  exercises_performed text,
  adherence text,
  warning_signs text,
  return_to_sport_stage text,
  doctor_notification_needed boolean not null default false,
  notes text,
  next_plan text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint physiotherapy_sessions_pain_score_check check (
    pain_score is null
    or (pain_score >= 0 and pain_score <= 10)
  ),
  constraint physiotherapy_sessions_return_to_sport_stage_check check (
    return_to_sport_stage is null
    or return_to_sport_stage in (
      'uygun_degil',
      'agri_kontrolu',
      'hareket_acikligi',
      'kuvvetlendirme',
      'kosuya_donus',
      'saha_brans_calisma',
      'temasli_antrenman',
      'maca_donus'
    )
  )
);

alter table physiotherapy_referrals enable row level security;
alter table physiotherapy_sessions enable row level security;
