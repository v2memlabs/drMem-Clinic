-- =============================================================================
-- Timeline DB Projection / RPC v1
-- Read-only patient timeline via SECURITY DEFINER RPC (no audit events)
--
-- Prerequisite: 20260521100000_draft_saas_schema_rls_v1.sql
--               20260522100000_draft_rls_policies_v1.sql
--               20260524100000_safe_clinical_role_summary_projection_v1.sql
--               20260525200000_patient_file_pdf_storage_metadata_v1.sql
--
-- Intentionally NOT included:
--   - audit_logs / access audit events in timeline
--   - internal_doctor_note, clinical_data, storage_path, storage_bucket
--   - signed_url, public_url, file/pdf binary content
--   - consents / physiotherapy_referrals tables (not in schema v1)
--   - Broadening clinical_encounters RLS for assistant/physio
--   - Dart / UI / provider changes
--
-- Apply: dev/staging after manual review
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0) Drop prior timeline objects (idempotent re-run)
-- -----------------------------------------------------------------------------

drop function if exists list_patient_timeline_events(uuid, int, int);
drop function if exists _timeline_role_allows_event(text, text);
drop function if exists _timeline_sanitize_metadata(jsonb);
drop function if exists _timeline_forbidden_metadata_key(text);
drop function if exists _timeline_actor_display_name(uuid);
drop function if exists _timeline_patient_scope(uuid);

-- -----------------------------------------------------------------------------
-- 1) Patient scope + tenant gate (internal)
-- -----------------------------------------------------------------------------

create or replace function _timeline_patient_scope(p_patient_id uuid)
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
begin
  if auth.uid() is null or p_patient_id is null then
    return null;
  end if;

  v_tenant_id := current_tenant_id();
  if v_tenant_id is null then
    return null;
  end if;

  if not is_tenant_member(v_tenant_id) then
    return null;
  end if;

  if not exists (
    select 1
    from tenants t
    where t.id = v_tenant_id
      and t.status = 'active'
  ) then
    return null;
  end if;

  if not exists (
    select 1
    from patients p
    where p.id = p_patient_id
      and p.tenant_id = v_tenant_id
      and p.deleted_at is null
  ) then
    return null;
  end if;

  return v_tenant_id;
end;
$$;

comment on function _timeline_patient_scope(uuid) is
  'Internal timeline gate: auth, active tenant/membership, patient in tenant. Nurse-only returns null scope.';

revoke all on function _timeline_patient_scope(uuid) from public;
revoke all on function _timeline_patient_scope(uuid) from authenticated;

-- -----------------------------------------------------------------------------
-- 2) Metadata allowlist sanitizer (internal)
-- -----------------------------------------------------------------------------

create or replace function _timeline_forbidden_metadata_key(p_key text)
returns boolean
language sql
immutable
as $$
  select lower(replace(p_key, '-', '_')) in (
    'internal_doctor_note',
    'clinical_data',
    'rawclinicaldata',
    'file_content',
    'pdf_content',
    'storage_path',
    'storage_bucket',
    'signed_url',
    'signedurl',
    'public_url',
    'publicurl',
    'service_role',
    'secret',
    'token',
    'jwt',
    'access_token',
    'stack_trace',
    'sql',
    'postgrest',
    'anamnesis',
    'physical_exam',
    'doctor_private_note',
    'private_note',
    'notes',
    'description'
  )
  or lower(p_key) like '%internal%note%'
  or lower(p_key) like '%clinical%data%'
  or lower(p_key) like '%storage%path%'
  or lower(p_key) like '%signed%url%';
$$;

revoke all on function _timeline_forbidden_metadata_key(text) from public;
revoke all on function _timeline_forbidden_metadata_key(text) from authenticated;

create or replace function _timeline_sanitize_metadata(p_metadata jsonb)
returns jsonb
language plpgsql
immutable
as $$
declare
  result jsonb := '{}'::jsonb;
  k text;
  v jsonb;
begin
  if p_metadata is null or p_metadata = 'null'::jsonb then
    return '{}'::jsonb;
  end if;
  for k, v in select * from jsonb_each(p_metadata)
  loop
    if _timeline_forbidden_metadata_key(k) then
      continue;
    end if;
    if jsonb_typeof(v) in ('object', 'array') then
      continue;
    end if;
    result := result || jsonb_build_object(k, v);
  end loop;
  return result;
end;
$$;

revoke all on function _timeline_sanitize_metadata(jsonb) from public;
revoke all on function _timeline_sanitize_metadata(jsonb) from authenticated;

-- -----------------------------------------------------------------------------
-- 3) Actor display name (internal)
-- -----------------------------------------------------------------------------

create or replace function _timeline_actor_display_name(p_profile_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select nullif(trim(pr.display_name), '')
  from profiles pr
  where pr.id = p_profile_id
  limit 1;
$$;

revoke all on function _timeline_actor_display_name(uuid) from public;
revoke all on function _timeline_actor_display_name(uuid) from authenticated;

-- -----------------------------------------------------------------------------
-- 4) Role × event_type allowlist (internal)
-- -----------------------------------------------------------------------------

create or replace function _timeline_role_allows_event(
  p_event_type text,
  p_visibility_scope text
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_is_doctor boolean;
  v_is_assistant boolean;
  v_is_physio boolean;
  v_is_nurse_only boolean;
begin
  v_tenant_id := current_tenant_id();
  if v_tenant_id is null or auth.uid() is null then
    return false;
  end if;

  v_is_doctor := has_tenant_role(v_tenant_id, array['doctor_admin']);
  v_is_assistant := has_tenant_role(v_tenant_id, array['assistant_secretary']);
  v_is_physio := has_tenant_role(v_tenant_id, array['physiotherapist']);

  -- Nurse without clinical timeline roles → no rows
  if not v_is_doctor and not v_is_assistant and not v_is_physio then
    return false;
  end if;

  if v_is_doctor then
    return true;
  end if;

  if v_is_assistant then
    -- Operational subset only; no doctor_admin clinical/file rows (definer bypass guard).
    if p_event_type like 'clinical.encounter.%' then
      return coalesce(p_visibility_scope, '') = 'clinic_operations';
    end if;
    if p_event_type like 'file.metadata.%' or p_event_type like 'pdf.metadata.%' then
      return coalesce(p_visibility_scope, '') = 'clinic_operations';
    end if;
    return p_event_type in (
      'patient.created',
      'patient.updated',
      'appointment.created',
      'appointment.updated',
      'appointment.cancelled',
      'appointment.completed'
    );
  end if;

  if v_is_physio then
    if p_event_type like 'clinical.encounter.%' then
      return coalesce(p_visibility_scope, '') = 'physiotherapy';
    end if;
    if p_event_type like 'file.metadata.%' or p_event_type like 'pdf.metadata.%' then
      return coalesce(p_visibility_scope, '') = 'physiotherapy';
    end if;
    return false;
  end if;

  return false;
end;
$$;

comment on function _timeline_role_allows_event(text, text) is
  'Per-row role filter. Doctor sees all; assistant operational; physio FTR/rehab scope only.';

revoke all on function _timeline_role_allows_event(text, text) from public;
revoke all on function _timeline_role_allows_event(text, text) from authenticated;

-- -----------------------------------------------------------------------------
-- 5) list_patient_timeline_events — MVP UNION projection (SECURITY DEFINER)
-- -----------------------------------------------------------------------------

create or replace function list_patient_timeline_events(
  p_patient_id uuid,
  p_limit int default 50,
  p_offset int default 0
)
returns table (
  event_id text,
  tenant_id uuid,
  patient_id uuid,
  event_type text,
  event_group text,
  title text,
  subtitle text,
  occurred_at timestamptz,
  source_entity_type text,
  source_entity_id uuid,
  actor_display_name text,
  visibility_scope text,
  icon_key text,
  status text,
  metadata jsonb
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_limit int;
  v_offset int;
begin
  v_tenant_id := _timeline_patient_scope(p_patient_id);
  if v_tenant_id is null then
    return;
  end if;

  v_limit := greatest(least(coalesce(p_limit, 50), 200), 1);
  v_offset := greatest(coalesce(p_offset, 0), 0);

  return query
  with
  scoped as (
    select v_tenant_id as tenant_id, p_patient_id as patient_id
  ),
  -- -------------------------------------------------------------------------
  -- Patient events
  -- -------------------------------------------------------------------------
  patient_created as (
    select
      ('patient:created:' || p.id::text) as event_id,
      p.tenant_id,
      p.id as patient_id,
      'patient.created'::text as event_type,
      'patient'::text as event_group,
      'Hasta kaydı oluşturuldu'::text as title,
      null::text as subtitle,
      p.created_at as occurred_at,
      'patient'::text as source_entity_type,
      p.id as source_entity_id,
      null::text as actor_display_name,
      'clinic_operations'::text as visibility_scope,
      'patient'::text as icon_key,
      p.status as status,
      _timeline_sanitize_metadata(jsonb_build_object('patient_status', p.status)) as metadata
    from patients p
    inner join scoped s on s.tenant_id = p.tenant_id and s.patient_id = p.id
    where p.deleted_at is null
  ),
  patient_updated as (
    select
      ('patient:updated:' || p.id::text || ':' || floor(extract(epoch from p.updated_at))::text) as event_id,
      p.tenant_id,
      p.id as patient_id,
      'patient.updated'::text,
      'patient'::text,
      'Hasta kaydı güncellendi'::text,
      null::text,
      p.updated_at,
      'patient'::text,
      p.id,
      null::text,
      'clinic_operations'::text,
      'patient'::text,
      p.status,
      _timeline_sanitize_metadata(jsonb_build_object('patient_status', p.status))
    from patients p
    inner join scoped s on s.tenant_id = p.tenant_id and s.patient_id = p.id
    where p.deleted_at is null
      and p.updated_at > p.created_at + interval '1 second'
  ),
  -- -------------------------------------------------------------------------
  -- Appointments
  -- -------------------------------------------------------------------------
  appointment_events as (
    select
      ('appointment:' || a.id::text || ':' || ev.kind) as event_id,
      a.tenant_id,
      a.patient_id,
      ev.event_type,
      'appointment'::text as event_group,
      ev.title,
      ev.subtitle,
      ev.occurred_at,
      'appointment'::text as source_entity_type,
      a.id as source_entity_id,
      _timeline_actor_display_name(a.created_by) as actor_display_name,
      'clinic_operations'::text as visibility_scope,
      'calendar'::text as icon_key,
      a.status,
      _timeline_sanitize_metadata(
        jsonb_build_object(
          'appointment_status', a.status,
          'appointment_type', a.appointment_type
        )
      ) as metadata
    from appointments a
    inner join scoped s on s.tenant_id = a.tenant_id and s.patient_id = a.patient_id
    cross join lateral (
      select
        'appointment.created'::text as event_type,
        'created'::text as kind,
        'Randevu oluşturuldu'::text as title,
        nullif(
          trim(concat_ws(' · ', nullif(a.appointment_type, ''), nullif(a.status, ''))),
          ''
        ) as subtitle,
        a.created_at as occurred_at
      union all
      select
        'appointment.updated',
        'updated',
        'Randevu güncellendi',
        nullif(trim(concat_ws(' · ', nullif(a.appointment_type, ''), nullif(a.status, ''))), ''),
        a.updated_at
      where a.updated_at > a.created_at + interval '1 second'
      union all
      select
        'appointment.cancelled',
        'cancelled',
        'Randevu iptal edildi',
        nullif(a.status, ''),
        coalesce(a.updated_at, a.created_at)
      where lower(coalesce(a.status, '')) in (
        'cancelled', 'canceled', 'iptal', 'cancel'
      )
      union all
      select
        'appointment.completed',
        'completed',
        'Randevu tamamlandı',
        nullif(a.status, ''),
        coalesce(a.updated_at, a.appointment_at)
      where lower(coalesce(a.status, '')) in (
        'completed', 'done', 'tamamlandı', 'tamamlandi', 'complete'
      )
    ) ev
    where a.deleted_at is null
  ),
  -- -------------------------------------------------------------------------
  -- Clinical encounters — doctor path (safe columns only)
  -- -------------------------------------------------------------------------
  clinical_doctor_events as (
    select
      ('clinical:' || ce.id::text || ':' || ev.kind) as event_id,
      ce.tenant_id,
      ce.patient_id,
      ev.event_type,
      'clinical'::text as event_group,
      ev.title,
      ev.subtitle,
      ev.occurred_at,
      'clinical_encounter'::text as source_entity_type,
      ce.id as source_entity_id,
      _timeline_actor_display_name(ce.created_by) as actor_display_name,
      'doctor_admin'::text as visibility_scope,
      'clinical'::text as icon_key,
      ce.status,
      _timeline_sanitize_metadata(
        jsonb_build_object(
          'visit_type', ce.visit_type,
          'encounter_status', ce.status
        )
      ) as metadata
    from clinical_encounters ce
    inner join scoped s on s.tenant_id = ce.tenant_id and s.patient_id = ce.patient_id
    cross join lateral (
      select
        'clinical.encounter.created'::text as event_type,
        'created'::text as kind,
        'Muayene kaydı oluşturuldu'::text as title,
        nullif(trim(concat_ws(' · ', nullif(ce.visit_type, ''), nullif(ce.status, ''))), '') as subtitle,
        ce.created_at as occurred_at
      union all
      select
        'clinical.encounter.updated',
        'updated',
        'Muayene kaydı güncellendi',
        nullif(trim(concat_ws(' · ', nullif(ce.visit_type, ''), nullif(ce.status, ''))), ''),
        ce.updated_at
      where ce.updated_at > ce.created_at + interval '1 second'
      union all
      select
        'clinical.encounter.completed',
        'completed',
        'Muayene kaydı tamamlandı',
        nullif(ce.status, ''),
        coalesce(ce.updated_at, ce.encounter_date)
      where lower(coalesce(ce.status, '')) in (
        'completed', 'done', 'tamamlandı', 'tamamlandi', 'closed', 'kapalı', 'kapali'
      )
    ) ev
    where ce.deleted_at is null
  ),
  -- -------------------------------------------------------------------------
  -- Clinical — assistant safe projection (no diagnosis_summary in v1)
  -- -------------------------------------------------------------------------
  clinical_assistant_events as (
    select
      ('clinical:asst:' || v.encounter_id::text || ':' || ev.kind) as event_id,
      v.tenant_id,
      v.patient_id,
      ev.event_type,
      'clinical'::text as event_group,
      ev.title,
      ev.subtitle,
      ev.occurred_at,
      'clinical_encounter'::text as source_entity_type,
      v.encounter_id as source_entity_id,
      null::text as actor_display_name,
      'clinic_operations'::text as visibility_scope,
      'clinical'::text as icon_key,
      v.status,
      _timeline_sanitize_metadata(
        jsonb_build_object(
          'visit_type', v.visit_type,
          'encounter_status', v.status,
          'has_physiotherapy_referral', v.has_physiotherapy_referral
        )
      ) as metadata
    from clinical_encounter_assistant_summary v
    inner join scoped s on s.tenant_id = v.tenant_id and s.patient_id = v.patient_id
    cross join lateral (
      select
        'clinical.encounter.created'::text as event_type,
        'created'::text as kind,
        'Muayene kaydı oluşturuldu'::text as title,
        nullif(trim(concat_ws(' · ', nullif(v.visit_type, ''), nullif(v.status, ''))), '') as subtitle,
        v.encounter_date as occurred_at
      union all
      select
        'clinical.encounter.updated',
        'updated',
        'Muayene kaydı güncellendi',
        nullif(trim(concat_ws(' · ', nullif(v.visit_type, ''), nullif(v.status, ''))), ''),
        v.updated_at
      where v.updated_at > v.encounter_date + interval '1 second'
    ) ev
  ),
  -- -------------------------------------------------------------------------
  -- Clinical — physiotherapist (FTR referral only)
  -- -------------------------------------------------------------------------
  clinical_physio_events as (
    select
      ('clinical:ftr:' || v.encounter_id::text || ':' || ev.kind) as event_id,
      v.tenant_id,
      v.patient_id,
      ev.event_type,
      'clinical'::text as event_group,
      ev.title,
      ev.subtitle,
      ev.occurred_at,
      'clinical_encounter'::text as source_entity_type,
      v.encounter_id as source_entity_id,
      null::text as actor_display_name,
      'physiotherapy'::text as visibility_scope,
      'clinical'::text as icon_key,
      v.status,
      _timeline_sanitize_metadata(
        jsonb_build_object(
          'visit_type', v.visit_type,
          'encounter_status', v.status,
          'physiotherapy_referral', v.physiotherapy_referral
        )
      ) as metadata
    from clinical_encounter_physiotherapist_summary v
    inner join scoped s on s.tenant_id = v.tenant_id and s.patient_id = v.patient_id
    cross join lateral (
      select
        'clinical.encounter.created'::text as event_type,
        'created'::text as kind,
        'FTR bağlantılı muayene kaydı'::text as title,
        nullif(trim(concat_ws(' · ', nullif(v.visit_type, ''), nullif(v.status, ''))), '') as subtitle,
        v.encounter_date as occurred_at
      union all
      select
        'clinical.encounter.updated',
        'updated',
        'FTR bağlantılı muayene güncellendi',
        nullif(trim(concat_ws(' · ', nullif(v.visit_type, ''), nullif(v.status, ''))), ''),
        v.updated_at
      where v.updated_at > v.encounter_date + interval '1 second'
    ) ev
    where v.physiotherapy_referral is true
  ),
  -- -------------------------------------------------------------------------
  -- Patient file metadata (no storage_path)
  -- -------------------------------------------------------------------------
  file_metadata_events as (
    select
      ('file:' || pf.id::text || ':' || ev.kind) as event_id,
      pf.tenant_id,
      pf.patient_id,
      ev.event_type,
      case when pf.file_kind = 'generated_pdf' then 'pdf' else 'file' end as event_group,
      ev.title,
      ev.subtitle,
      ev.occurred_at,
      'patient_file'::text as source_entity_type,
      pf.id as source_entity_id,
      _timeline_actor_display_name(pf.created_by) as actor_display_name,
      pf.visibility_scope,
      case when pf.file_kind = 'generated_pdf' then 'pdf' else 'file' end as icon_key,
      pf.status,
      _timeline_sanitize_metadata(
        jsonb_build_object(
          'file_kind', pf.file_kind,
          'clinical_context', pf.clinical_context,
          'visibility_scope', pf.visibility_scope
        )
      ) as metadata
    from patient_files pf
    inner join scoped s on s.tenant_id = pf.tenant_id and s.patient_id = pf.patient_id
    cross join lateral (
      select
        case
          when pf.file_kind = 'generated_pdf' then 'pdf.metadata.created'::text
          else 'file.metadata.created'::text
        end as event_type,
        'created'::text as kind,
        case
          when pf.file_kind = 'generated_pdf' then 'PDF çıktısı kaydı oluşturuldu'
          else 'Dosya metadata kaydı eklendi'
        end as title,
        nullif(trim(concat_ws(' · ', nullif(pf.display_name, ''), nullif(pf.file_kind, ''))), '') as subtitle,
        pf.created_at as occurred_at
      where pf.deleted_at is null
        and pf.status = 'active'
      union all
      select
        case
          when pf.file_kind = 'generated_pdf' then 'pdf.metadata.archived'::text
          else 'file.metadata.archived'::text
        end,
        'archived',
        case
          when pf.file_kind = 'generated_pdf' then 'PDF çıktısı arşivlendi'
          else 'Dosya metadata arşivlendi'
        end,
        nullif(pf.display_name, ''),
        coalesce(pf.updated_at, pf.created_at)
      where pf.deleted_at is null
        and pf.status = 'archived'
    ) ev
  ),
  -- -------------------------------------------------------------------------
  -- PDF outputs table (doctor_admin metadata; distinct from patient_files PDF kind)
  -- -------------------------------------------------------------------------
  pdf_output_events as (
    select
      ('pdf_output:' || po.id::text || ':created') as event_id,
      po.tenant_id,
      po.patient_id,
      'pdf.metadata.created'::text as event_type,
      'pdf'::text as event_group,
      'PDF çıktısı kaydı oluşturuldu'::text as title,
      nullif(trim(concat_ws(' · ', nullif(po.display_name, ''), nullif(po.document_type, ''))), '') as subtitle,
      po.created_at as occurred_at,
      'pdf_output'::text as source_entity_type,
      po.id as source_entity_id,
      _timeline_actor_display_name(po.created_by) as actor_display_name,
      po.visibility_scope,
      'pdf'::text as icon_key,
      po.status,
      _timeline_sanitize_metadata(
        jsonb_build_object(
          'file_kind', po.file_kind,
          'clinical_context', po.clinical_context,
          'visibility_scope', po.visibility_scope,
          'document_type', po.document_type
        )
      ) as metadata
    from pdf_outputs po
    inner join scoped s on s.tenant_id = po.tenant_id and s.patient_id = po.patient_id
    where po.deleted_at is null
      and coalesce(po.status, '') not in ('deleted')
  ),
  all_events as (
    select * from patient_created
    union all select * from patient_updated
    union all select * from appointment_events
    union all select * from clinical_doctor_events
    union all select * from clinical_assistant_events
    union all select * from clinical_physio_events
    union all select * from file_metadata_events
    union all select * from pdf_output_events
  ),
  role_filtered as (
    select e.*
    from all_events e
    where _timeline_role_allows_event(e.event_type, e.visibility_scope)
  )
  select
    rf.event_id,
    rf.tenant_id,
    rf.patient_id,
    rf.event_type,
    rf.event_group,
    rf.title,
    rf.subtitle,
    rf.occurred_at,
    rf.source_entity_type,
    rf.source_entity_id,
    rf.actor_display_name,
    rf.visibility_scope,
    rf.icon_key,
    rf.status,
    rf.metadata
  from role_filtered rf
  order by rf.occurred_at desc, rf.event_id asc
  limit v_limit
  offset v_offset;
end;
$$;

comment on function list_patient_timeline_events(uuid, int, int) is
  'Role-aware patient timeline (read-only). No audit access events, no internal_doctor_note, '
  'no clinical_data, no storage_path. Nurse: 0 rows. SECURITY DEFINER + membership gate.';

revoke all on function list_patient_timeline_events(uuid, int, int) from public;
grant execute on function list_patient_timeline_events(uuid, int, int) to authenticated;

-- =============================================================================
-- Manual SQL test checklist (staging JWT — not service_role SQL editor)
-- =============================================================================
-- [ ] doctor_admin: list_patient_timeline_events(own_patient) → patient, appointment, clinical, file, pdf rows
-- [ ] assistant_secretary: operational subset; no pdf_output-only doctor rows unless file_kind path
-- [ ] assistant: clinical rows without internal_doctor_note (verify subtitle has no note text)
-- [ ] physiotherapist: only visibility_scope=physiotherapy files + FTR referral clinical rows
-- [ ] nurse: 0 rows
-- [ ] cross-tenant patient_id: 0 rows
-- [ ] inactive membership: 0 rows
-- [ ] suspended/inactive tenant: 0 rows
-- [ ] Response columns: no internal_doctor_note, clinical_data, storage_path, storage_bucket
-- [ ] metadata JSONB: no nested objects; no signed_url/public_url keys
-- [ ] audit_logs actions (clinical.summary.*.view, permission.denied) never appear
-- [ ] Direct SELECT on clinical_encounters as assistant still blocked (unchanged RLS)
-- [ ] pagination: p_limit max 200 respected
-- =============================================================================
