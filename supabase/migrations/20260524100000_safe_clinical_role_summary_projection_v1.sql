-- =============================================================================
-- Safe Clinical Role Summary Projection v1
-- Assistant/Secretary + Physiotherapist narrow allowlist views + SECURITY DEFINER RPC
--
-- Prerequisite: 20260521100000_draft_saas_schema_rls_v1.sql (tables)
--               20260522100000_draft_rls_policies_v1.sql (RLS helpers + doctor-only CE)
--
-- Intentionally NOT changed:
--   - clinical_encounters RLS (doctor_admin full path only)
--   - clinical_encounter_operational_summary (doctor path; unchanged)
--   - No broad SELECT policy on clinical_encounters for assistant/physio
--
-- Security intent:
--   - internal_doctor_note intentionally excluded from all projections/RPC output
--   - raw clinical_data intentionally not exposed (explicit key extract only)
--   - assistant/physio must use RPC, not full clinical_encounters
--   - tenant/role checked server-side via auth.uid() + memberships
--   - service_role not required for client access
--
-- Apply: dev/staging after manual review (same as prior draft migrations)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0) Drop dependents (idempotent re-run)
-- -----------------------------------------------------------------------------

drop function if exists get_assistant_clinical_summary(uuid);
drop function if exists list_assistant_clinical_summaries(uuid);
drop function if exists get_physiotherapist_clinical_summary(uuid);
drop function if exists list_physiotherapist_clinical_summaries(uuid);
drop function if exists _clinical_summary_access_allowed(uuid, text[]);

drop view if exists clinical_encounter_assistant_summary;
drop view if exists clinical_encounter_physiotherapist_summary;

-- -----------------------------------------------------------------------------
-- 1) Internal access gate (not callable by clients)
-- -----------------------------------------------------------------------------

create or replace function _clinical_summary_access_allowed(
  p_tenant_id uuid,
  p_allowed_roles text[]
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  -- Fail-closed: inactive membership, inactive tenant, cross-tenant → false → 0 rows
  select
    auth.uid() is not null
    and p_tenant_id is not null
    and current_tenant_id() is not null
    and p_tenant_id = current_tenant_id()
    and is_tenant_member(p_tenant_id)
    and has_tenant_role(p_tenant_id, p_allowed_roles)
    and exists (
      select 1
      from tenants t
      where t.id = p_tenant_id
        and t.status = 'active'
    );
$$;

comment on function _clinical_summary_access_allowed(uuid, text[]) is
  'Internal RPC gate. Nurse excluded by role list. Not for direct client use.';

revoke all on function _clinical_summary_access_allowed(uuid, text[]) from public;
revoke all on function _clinical_summary_access_allowed(uuid, text[]) from authenticated;

-- -----------------------------------------------------------------------------
-- 2) Assistant/Secretary narrow projection (allowlist only)
-- -----------------------------------------------------------------------------

create view clinical_encounter_assistant_summary
with (security_invoker = true)
as
select
  ce.id as encounter_id,
  ce.tenant_id,
  ce.patient_id,
  trim(concat_ws(' ', p.first_name, p.last_name)) as patient_display_name,
  ce.encounter_date,
  ce.visit_type,
  ce.status,
  ce.diagnosis_summary,
  -- operational_headline: no dedicated safe column in schema v1
  null::text as operational_headline,
  case
    when nullif(ce.clinical_data -> 'plan' ->> 'controlDate', '') is not null
    then (ce.clinical_data -> 'plan' ->> 'controlDate')::timestamptz
    else null
  end as next_control_date,
  ce.appointment_id,
  coalesce(
    (ce.clinical_data -> 'plan' ->> 'physiotherapyReferral')::boolean,
    false
  ) as has_physiotherapy_referral,
  ce.updated_at
from clinical_encounters ce
inner join patients p
  on p.id = ce.patient_id
 and p.tenant_id = ce.tenant_id
 and p.deleted_at is null
where ce.deleted_at is null;
-- internal_doctor_note intentionally excluded
-- raw clinical_data intentionally not exposed (explicit allowlist keys only)

comment on view clinical_encounter_assistant_summary is
  'Assistant/Secretary safe CE projection. No internal_doctor_note, no raw clinical_data. '
  'Direct SELECT revoked for authenticated; use list/get_assistant_clinical_summary RPC.';

-- -----------------------------------------------------------------------------
-- 3) Physiotherapist narrow projection (allowlist only)
-- -----------------------------------------------------------------------------

create view clinical_encounter_physiotherapist_summary
with (security_invoker = true)
as
select
  ce.id as encounter_id,
  ce.tenant_id,
  ce.patient_id,
  trim(concat_ws(' ', p.first_name, p.last_name)) as patient_display_name,
  ce.encounter_date,
  ce.clinical_data ->> 'bodyRegion' as body_region,
  ce.clinical_data ->> 'side' as side,
  ce.visit_type,
  ce.status,
  coalesce(
    (ce.clinical_data -> 'plan' ->> 'physiotherapyReferral')::boolean,
    false
  ) as physiotherapy_referral,
  left(
    nullif(trim(ce.clinical_data -> 'plan' ->> 'exerciseRecommendation'), ''),
    120
  ) as exercise_recommendation_short,
  left(
    nullif(trim(ce.clinical_data -> 'plan' ->> 'warningNotes'), ''),
    120
  ) as rehab_precautions_short,
  -- weight_bearing_status: no safe dedicated key in clinical_data schema v1
  null::text as weight_bearing_status,
  left(
    nullif(trim(ce.clinical_data -> 'examination' ->> 'rangeOfMotion'), ''),
    120
  ) as rom_limitation_short,
  case
    when nullif(ce.clinical_data -> 'plan' ->> 'controlDate', '') is not null
    then (ce.clinical_data -> 'plan' ->> 'controlDate')::timestamptz
    else null
  end as control_date,
  left(
    nullif(trim(ce.clinical_data -> 'plan' ->> 'surgeryRecommendation'), ''),
    120
  ) as post_op_context_short,
  left(
    nullif(trim(ce.clinical_data -> 'sports' ->> 'returnToSportGoal'), ''),
    120
  ) as ftr_goal_short,
  ce.diagnosis_summary,
  ce.treatment_plan_summary,
  ce.updated_at
from clinical_encounters ce
inner join patients p
  on p.id = ce.patient_id
 and p.tenant_id = ce.tenant_id
 and p.deleted_at is null
where ce.deleted_at is null;
-- internal_doctor_note intentionally excluded
-- raw clinical_data intentionally not exposed (explicit allowlist keys only)
-- Never extract: clinicalImpression, preliminaryDiagnosis, finalDiagnosis, private notes

comment on view clinical_encounter_physiotherapist_summary is
  'Physiotherapist safe CE projection. No internal_doctor_note, no raw clinical_data. '
  'Direct SELECT revoked for authenticated; use list/get_physiotherapist_clinical_summary RPC.';

-- Defense in depth: no direct view access for client roles
revoke all on clinical_encounter_assistant_summary from public;
revoke all on clinical_encounter_assistant_summary from authenticated;
revoke all on clinical_encounter_physiotherapist_summary from public;
revoke all on clinical_encounter_physiotherapist_summary from authenticated;

-- -----------------------------------------------------------------------------
-- 4) Assistant RPC (SECURITY DEFINER — reads allowlist view, role/tenant gated)
-- -----------------------------------------------------------------------------

create or replace function list_assistant_clinical_summaries(
  p_patient_id uuid default null
)
returns table (
  encounter_id uuid,
  tenant_id uuid,
  patient_id uuid,
  patient_display_name text,
  encounter_date timestamptz,
  visit_type text,
  status text,
  diagnosis_summary text,
  operational_headline text,
  next_control_date timestamptz,
  appointment_id uuid,
  has_physiotherapy_referral boolean,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    v.encounter_id,
    v.tenant_id,
    v.patient_id,
    v.patient_display_name,
    v.encounter_date,
    v.visit_type,
    v.status,
    v.diagnosis_summary,
    v.operational_headline,
    v.next_control_date,
    v.appointment_id,
    v.has_physiotherapy_referral,
    v.updated_at
  from clinical_encounter_assistant_summary v
  where _clinical_summary_access_allowed(
    v.tenant_id,
    array['doctor_admin', 'assistant_secretary']
  )
    and v.tenant_id = current_tenant_id()
    and (p_patient_id is null or v.patient_id = p_patient_id)
  order by v.encounter_date desc, v.updated_at desc;
$$;

comment on function list_assistant_clinical_summaries(uuid) is
  'Assistant/Secretary (+ doctor_admin compat) safe CE list. No internal_doctor_note/clinical_data.';

create or replace function get_assistant_clinical_summary(
  p_encounter_id uuid
)
returns table (
  encounter_id uuid,
  tenant_id uuid,
  patient_id uuid,
  patient_display_name text,
  encounter_date timestamptz,
  visit_type text,
  status text,
  diagnosis_summary text,
  operational_headline text,
  next_control_date timestamptz,
  appointment_id uuid,
  has_physiotherapy_referral boolean,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    v.encounter_id,
    v.tenant_id,
    v.patient_id,
    v.patient_display_name,
    v.encounter_date,
    v.visit_type,
    v.status,
    v.diagnosis_summary,
    v.operational_headline,
    v.next_control_date,
    v.appointment_id,
    v.has_physiotherapy_referral,
    v.updated_at
  from clinical_encounter_assistant_summary v
  where v.encounter_id = p_encounter_id
    and _clinical_summary_access_allowed(
      v.tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and v.tenant_id = current_tenant_id()
  limit 1;
$$;

comment on function get_assistant_clinical_summary(uuid) is
  'Assistant/Secretary (+ doctor_admin compat) safe CE detail. Fail-closed on cross-tenant.';

-- -----------------------------------------------------------------------------
-- 5) Physiotherapist RPC (SECURITY DEFINER — separate allowlist)
-- -----------------------------------------------------------------------------

create or replace function list_physiotherapist_clinical_summaries(
  p_patient_id uuid default null
)
returns table (
  encounter_id uuid,
  tenant_id uuid,
  patient_id uuid,
  patient_display_name text,
  encounter_date timestamptz,
  body_region text,
  side text,
  visit_type text,
  status text,
  physiotherapy_referral boolean,
  exercise_recommendation_short text,
  rehab_precautions_short text,
  weight_bearing_status text,
  rom_limitation_short text,
  control_date timestamptz,
  post_op_context_short text,
  ftr_goal_short text,
  diagnosis_summary text,
  treatment_plan_summary text,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    v.encounter_id,
    v.tenant_id,
    v.patient_id,
    v.patient_display_name,
    v.encounter_date,
    v.body_region,
    v.side,
    v.visit_type,
    v.status,
    v.physiotherapy_referral,
    v.exercise_recommendation_short,
    v.rehab_precautions_short,
    v.weight_bearing_status,
    v.rom_limitation_short,
    v.control_date,
    v.post_op_context_short,
    v.ftr_goal_short,
    v.diagnosis_summary,
    v.treatment_plan_summary,
    v.updated_at
  from clinical_encounter_physiotherapist_summary v
  where _clinical_summary_access_allowed(
    v.tenant_id,
    array['doctor_admin', 'physiotherapist']
  )
    and v.tenant_id = current_tenant_id()
    and (p_patient_id is null or v.patient_id = p_patient_id)
  order by v.encounter_date desc, v.updated_at desc;
$$;

comment on function list_physiotherapist_clinical_summaries(uuid) is
  'Physiotherapist (+ doctor_admin compat) safe CE list. Nurse/assistant excluded by role gate.';

create or replace function get_physiotherapist_clinical_summary(
  p_encounter_id uuid
)
returns table (
  encounter_id uuid,
  tenant_id uuid,
  patient_id uuid,
  patient_display_name text,
  encounter_date timestamptz,
  body_region text,
  side text,
  visit_type text,
  status text,
  physiotherapy_referral boolean,
  exercise_recommendation_short text,
  rehab_precautions_short text,
  weight_bearing_status text,
  rom_limitation_short text,
  control_date timestamptz,
  post_op_context_short text,
  ftr_goal_short text,
  diagnosis_summary text,
  treatment_plan_summary text,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    v.encounter_id,
    v.tenant_id,
    v.patient_id,
    v.patient_display_name,
    v.encounter_date,
    v.body_region,
    v.side,
    v.visit_type,
    v.status,
    v.physiotherapy_referral,
    v.exercise_recommendation_short,
    v.rehab_precautions_short,
    v.weight_bearing_status,
    v.rom_limitation_short,
    v.control_date,
    v.post_op_context_short,
    v.ftr_goal_short,
    v.diagnosis_summary,
    v.treatment_plan_summary,
    v.updated_at
  from clinical_encounter_physiotherapist_summary v
  where v.encounter_id = p_encounter_id
    and _clinical_summary_access_allowed(
      v.tenant_id,
      array['doctor_admin', 'physiotherapist']
    )
    and v.tenant_id = current_tenant_id()
  limit 1;
$$;

comment on function get_physiotherapist_clinical_summary(uuid) is
  'Physiotherapist (+ doctor_admin compat) safe CE detail. Fail-closed on cross-tenant.';

-- -----------------------------------------------------------------------------
-- 6) Grants — RPC execute only for authenticated; no CE table policy expansion
-- -----------------------------------------------------------------------------

grant execute on function list_assistant_clinical_summaries(uuid) to authenticated;
grant execute on function get_assistant_clinical_summary(uuid) to authenticated;
grant execute on function list_physiotherapist_clinical_summaries(uuid) to authenticated;
grant execute on function get_physiotherapist_clinical_summary(uuid) to authenticated;

-- =============================================================================
-- Manual SQL test checklist (staging; run as role-specific JWT users)
-- =============================================================================
-- [ ] doctor_admin: list_assistant_clinical_summaries() → own tenant rows
-- [ ] doctor_admin: list_physiotherapist_clinical_summaries() → own tenant rows
-- [ ] assistant_secretary: list_assistant_clinical_summaries() → own tenant rows
-- [ ] assistant_secretary: SELECT * FROM clinical_encounters → 0 rows / denied
-- [ ] assistant_secretary: list_physiotherapist_clinical_summaries() → 0 rows
-- [ ] physiotherapist: list_physiotherapist_clinical_summaries() → own tenant rows
-- [ ] physiotherapist: list_assistant_clinical_summaries() → 0 rows
-- [ ] physiotherapist: SELECT * FROM clinical_encounters → 0 rows / denied
-- [ ] nurse: all four RPCs → 0 rows
-- [ ] inactive membership (status != active): all RPCs → 0 rows
-- [ ] inactive tenant (status != active): all RPCs → 0 rows
-- [ ] cross-tenant encounter_id in get_* → 0 rows
-- [ ] RPC response columns: no internal_doctor_note key
-- [ ] RPC response columns: no clinical_data key
-- [ ] REVOKE verified: SELECT on assistant/physio views as authenticated → denied
-- [ ] clinical_encounter_operational_summary unchanged (doctor path smoke)
-- =============================================================================
