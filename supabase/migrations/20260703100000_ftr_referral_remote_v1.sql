-- =============================================================================
-- FTR Referral Remote v1 — physiotherapy_referrals
--
-- Prerequisite: 20260521100000_draft_saas_schema_rls_v1.sql
--               20260522100000_draft_rls_policies_v1.sql (RLS helpers)
--
-- Scope: physiotherapy_referrals table + RLS (doctor_admin, physiotherapist)
-- Not included: sessions, exercise_programs, timeline, audit
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) physiotherapy_referrals
-- -----------------------------------------------------------------------------

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

comment on table physiotherapy_referrals is
  'FTR yönlendirme kayıtları — tenant scoped; soft delete via deleted_at.';

create index if not exists physiotherapy_referrals_tenant_id_idx
  on physiotherapy_referrals (tenant_id);

create index if not exists physiotherapy_referrals_patient_id_idx
  on physiotherapy_referrals (patient_id);

create index if not exists physiotherapy_referrals_clinical_encounter_id_idx
  on physiotherapy_referrals (clinical_encounter_id)
  where clinical_encounter_id is not null;

create index if not exists physiotherapy_referrals_status_idx
  on physiotherapy_referrals (tenant_id, status)
  where deleted_at is null;

create index if not exists physiotherapy_referrals_assigned_physio_idx
  on physiotherapy_referrals (assigned_physiotherapist_profile_id)
  where assigned_physiotherapist_profile_id is not null;

create index if not exists physiotherapy_referrals_deleted_at_idx
  on physiotherapy_referrals (tenant_id, deleted_at)
  where deleted_at is null;

-- -----------------------------------------------------------------------------
-- 2) updated_at trigger (reuse set_updated_at)
-- -----------------------------------------------------------------------------

drop trigger if exists physiotherapy_referrals_updated_at on physiotherapy_referrals;
create trigger physiotherapy_referrals_updated_at
  before update on physiotherapy_referrals
  for each row execute function set_updated_at();

-- -----------------------------------------------------------------------------
-- 3) RLS — doctor_admin
-- -----------------------------------------------------------------------------

alter table physiotherapy_referrals enable row level security;

drop policy if exists physiotherapy_referrals_select_doctor_v1 on physiotherapy_referrals;
create policy physiotherapy_referrals_select_doctor_v1
  on physiotherapy_referrals
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  );

drop policy if exists physiotherapy_referrals_insert_doctor_v1 on physiotherapy_referrals;
create policy physiotherapy_referrals_insert_doctor_v1
  on physiotherapy_referrals
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and exists (
      select 1
      from patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
    and (
      clinical_encounter_id is null
      or exists (
        select 1
        from clinical_encounters ce
        where ce.id = clinical_encounter_id
          and ce.tenant_id = tenant_id
          and ce.deleted_at is null
      )
    )
    and (
      appointment_id is null
      or exists (
        select 1
        from appointments a
        where a.id = appointment_id
          and a.tenant_id = tenant_id
          and a.deleted_at is null
      )
    )
  );

drop policy if exists physiotherapy_referrals_update_doctor_v1 on physiotherapy_referrals;
create policy physiotherapy_referrals_update_doctor_v1
  on physiotherapy_referrals
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and exists (
      select 1
      from patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
    and (
      clinical_encounter_id is null
      or exists (
        select 1
        from clinical_encounters ce
        where ce.id = clinical_encounter_id
          and ce.tenant_id = tenant_id
          and ce.deleted_at is null
      )
    )
    and (
      appointment_id is null
      or exists (
        select 1
        from appointments a
        where a.id = appointment_id
          and a.tenant_id = tenant_id
          and a.deleted_at is null
      )
    )
  );

-- -----------------------------------------------------------------------------
-- 4) RLS — physiotherapist (select + limited update)
-- -----------------------------------------------------------------------------

drop policy if exists physiotherapy_referrals_select_physio_v1 on physiotherapy_referrals;
create policy physiotherapy_referrals_select_physio_v1
  on physiotherapy_referrals
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
  );

drop policy if exists physiotherapy_referrals_update_physio_v1 on physiotherapy_referrals;
create policy physiotherapy_referrals_update_physio_v1
  on physiotherapy_referrals
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and exists (
      select 1
      from patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );

-- assistant_secretary and nurse: no policies (deny by default)
-- hard delete: no DELETE policy
