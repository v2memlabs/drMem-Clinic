-- =============================================================================
-- FTR Sessions Remote v2 — physiotherapy_sessions
--
-- Prerequisite: 20260703100000_ftr_referral_remote_v1.sql
--               20260522100000_draft_rls_policies_v1.sql (RLS helpers)
--
-- Scope: physiotherapy_sessions table + RLS (doctor_admin, physiotherapist)
-- Not included: session update, status bridge, timeline, audit
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) physiotherapy_sessions
-- -----------------------------------------------------------------------------

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

comment on table physiotherapy_sessions is
  'FTR seans notları — tenant scoped; soft delete via deleted_at.';

create index if not exists physiotherapy_sessions_tenant_id_idx
  on physiotherapy_sessions (tenant_id);

create index if not exists physiotherapy_sessions_referral_id_idx
  on physiotherapy_sessions (referral_id);

create index if not exists physiotherapy_sessions_patient_id_idx
  on physiotherapy_sessions (patient_id);

create index if not exists physiotherapy_sessions_session_date_idx
  on physiotherapy_sessions (tenant_id, session_date desc)
  where deleted_at is null;

create index if not exists physiotherapy_sessions_deleted_at_idx
  on physiotherapy_sessions (tenant_id, deleted_at)
  where deleted_at is null;

create index if not exists physiotherapy_sessions_physiotherapist_profile_id_idx
  on physiotherapy_sessions (physiotherapist_profile_id)
  where deleted_at is null;

-- -----------------------------------------------------------------------------
-- 2) updated_at trigger (reuse set_updated_at)
-- -----------------------------------------------------------------------------

drop trigger if exists physiotherapy_sessions_updated_at on physiotherapy_sessions;
create trigger physiotherapy_sessions_updated_at
  before update on physiotherapy_sessions
  for each row execute function set_updated_at();

-- -----------------------------------------------------------------------------
-- 3) RLS — doctor_admin
-- -----------------------------------------------------------------------------

alter table physiotherapy_sessions enable row level security;

drop policy if exists physiotherapy_sessions_select_doctor_v1 on physiotherapy_sessions;
create policy physiotherapy_sessions_select_doctor_v1
  on physiotherapy_sessions
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  );

drop policy if exists physiotherapy_sessions_insert_doctor_v1 on physiotherapy_sessions;
create policy physiotherapy_sessions_insert_doctor_v1
  on physiotherapy_sessions
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and physiotherapist_profile_id = current_profile_id()
    and exists (
      select 1
      from patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
    and exists (
      select 1
      from physiotherapy_referrals r
      where r.id = referral_id
        and r.tenant_id = tenant_id
        and r.deleted_at is null
        and r.patient_id = patient_id
    )
  );

-- -----------------------------------------------------------------------------
-- 4) RLS — physiotherapist
-- -----------------------------------------------------------------------------

drop policy if exists physiotherapy_sessions_select_physio_v1 on physiotherapy_sessions;
create policy physiotherapy_sessions_select_physio_v1
  on physiotherapy_sessions
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
  );

drop policy if exists physiotherapy_sessions_insert_physio_v1 on physiotherapy_sessions;
create policy physiotherapy_sessions_insert_physio_v1
  on physiotherapy_sessions
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and physiotherapist_profile_id = current_profile_id()
    and exists (
      select 1
      from patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
    and exists (
      select 1
      from physiotherapy_referrals r
      where r.id = referral_id
        and r.tenant_id = tenant_id
        and r.deleted_at is null
        and r.patient_id = patient_id
    )
  );

-- assistant_secretary and nurse: no policies (deny by default)
-- hard delete: no DELETE policy
-- session update: no UPDATE policy (v2)
