-- =============================================================================
-- Safe Summary View Column Order Hotfix v1
-- Fixes PostgreSQL 42P16: cannot change name of view column "encounter_date" to "appointment_id"
--
-- Cause: CREATE OR REPLACE VIEW cannot change column order/names on existing views.
--        clinical_encounter_operational_summary (wide, with appointment_id early)
--        vs narrow definition (encounter_date at same ordinal) conflicts on re-apply.
--
-- Prerequisite: 20260521100000, 20260522100000, 20260524100000 (partial OK)
--
-- Security unchanged:
--   - No internal_doctor_note / raw clinical_data in assistant/physio views or RPC output
--   - No clinical_encounters RLS broadening for assistant/physio
--   - View direct SELECT revoked; RPC execute for authenticated only
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0) Drop dependents (functions before views — no CASCADE)
-- -----------------------------------------------------------------------------

drop function if exists get_assistant_clinical_summary(uuid);
drop function if exists list_assistant_clinical_summaries(uuid);
drop function if exists get_physiotherapist_clinical_summary(uuid);
drop function if exists list_physiotherapist_clinical_summaries(uuid);

drop view if exists clinical_encounter_assistant_summary;
drop view if exists clinical_encounter_physiotherapist_summary;
drop view if exists clinical_encounter_operational_summary;

-- -----------------------------------------------------------------------------
-- 1) clinical_encounter_operational_summary — narrow doctor path (221 semantics)
-- -----------------------------------------------------------------------------
-- Must match 20260522100000 column order; do not re-introduce appointment_id/clinical_data here.

create view clinical_encounter_operational_summary
with (security_invoker = true)
as
select
  id,
  tenant_id,
  patient_id,
  encounter_date,
  visit_type,
  status,
  diagnosis_summary,
  treatment_plan_summary,
  created_at,
  updated_at
from clinical_encounters
where deleted_at is null;

comment on view clinical_encounter_operational_summary is
  'Safe CE projection. No internal_doctor_note, clinical_data, appointment_id. '
  'Hotfix v1: DROP+CREATE to avoid 42P16 on column reorder.';

-- -----------------------------------------------------------------------------
-- 2) Internal access gate (unchanged semantics)
-- -----------------------------------------------------------------------------

drop function if exists _clinical_summary_access_allowed(uuid, text[]);

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
-- 3) Assistant/Secretary narrow projection — fixed column order
-- -----------------------------------------------------------------------------
-- encounter_id, tenant_id, patient_id, patient_display_name, encounter_date,
-- visit_type, status, diagnosis_summary, operational_headline, next_control_date,
-- appointment_id, has_physiotherapy_referral, updated_at

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

comment on view clinical_encounter_assistant_summary is
  'Assistant/Secretary safe CE projection. Hotfix v1 DROP+CREATE. No internal_doctor_note, no raw clinical_data.';

-- -----------------------------------------------------------------------------
-- 4) Physiotherapist narrow projection — fixed column order
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

comment on view clinical_encounter_physiotherapist_summary is
  'Physiotherapist safe CE projection. Hotfix v1 DROP+CREATE. No internal_doctor_note, no raw clinical_data.';

revoke all on clinical_encounter_assistant_summary from public;
revoke all on clinical_encounter_assistant_summary from authenticated;
revoke all on clinical_encounter_physiotherapist_summary from public;
revoke all on clinical_encounter_physiotherapist_summary from authenticated;

-- -----------------------------------------------------------------------------
-- 5) Assistant RPC (SECURITY DEFINER)
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

-- -----------------------------------------------------------------------------
-- 6) Physiotherapist RPC (SECURITY DEFINER)
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

-- -----------------------------------------------------------------------------
-- 7) Grants
-- -----------------------------------------------------------------------------

grant execute on function list_assistant_clinical_summaries(uuid) to authenticated;
grant execute on function get_assistant_clinical_summary(uuid) to authenticated;
grant execute on function list_physiotherapist_clinical_summaries(uuid) to authenticated;
grant execute on function get_physiotherapist_clinical_summary(uuid) to authenticated;

-- =============================================================================
-- Post-apply smoke (staging JWT — not service_role SQL editor for RLS)
-- =============================================================================
-- [ ] CREATE VIEW clinical_encounter_operational_summary — no 42P16
-- [ ] list_assistant_clinical_summaries / get_assistant_clinical_summary
-- [ ] list_physiotherapist_clinical_summaries / get_physiotherapist_clinical_summary
-- [ ] RPC columns: no internal_doctor_note, no clinical_data
-- [ ] SELECT on summary views as authenticated → denied
-- =============================================================================
