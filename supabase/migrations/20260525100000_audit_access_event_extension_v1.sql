-- =============================================================================
-- Audit / KVKK Access Event Extension v1
-- Append-only audit via SECURITY DEFINER RPC (no client direct INSERT on audit_logs)
--
-- Prerequisite: audit_logs table (20260521100000_draft_saas_schema_rls_v1.sql)
--               RLS helpers (20260522100000_draft_rls_policies_v1.sql)
--
-- Intentionally NOT changed:
--   - clinical_encounters RLS
--   - Safe summary RPC projections
--   - audit_logs SELECT policy (doctor_admin only)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Metadata sanitizer (strip forbidden keys — defense in depth)
-- -----------------------------------------------------------------------------

create or replace function _audit_metadata_forbidden_key(p_key text)
returns boolean
language sql
immutable
as $$
  select lower(replace(p_key, '-', '_')) in (
    'internal_doctor_note',
    'clinical_data',
    'rawclinicaldata',
    'anamnesis',
    'physical_exam',
    'doctor_private_note',
    'private_note',
    'pdf_content',
    'file_content',
    'access_token',
    'jwt',
    'service_role',
    'stack_trace',
    'sql',
    'postgrest'
  )
  or lower(p_key) like '%internal%note%'
  or lower(p_key) like '%clinical%data%';
$$;

revoke all on function _audit_metadata_forbidden_key(text) from public;
revoke all on function _audit_metadata_forbidden_key(text) from authenticated;

create or replace function _sanitize_audit_metadata(p_metadata jsonb)
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
    if _audit_metadata_forbidden_key(k) then
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

revoke all on function _sanitize_audit_metadata(jsonb) from public;
revoke all on function _sanitize_audit_metadata(jsonb) from authenticated;

-- -----------------------------------------------------------------------------
-- 2) record_audit_access_event — append-only insert
-- -----------------------------------------------------------------------------

create or replace function record_audit_access_event(
  p_action text,
  p_module text,
  p_record_id uuid default null,
  p_patient_id uuid default null,
  p_metadata jsonb default '{}'::jsonb,
  p_success boolean default true,
  p_failure_category text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_actor_profile_id uuid;
  v_meta jsonb;
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  v_tenant_id := current_tenant_id();
  if v_tenant_id is null then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if not is_tenant_member(v_tenant_id) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if not exists (
    select 1 from tenants t
    where t.id = v_tenant_id and t.status = 'active'
  ) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  select p.id into v_actor_profile_id
  from profiles p
  where p.user_id = auth.uid()
  limit 1;

  v_meta := _sanitize_audit_metadata(coalesce(p_metadata, '{}'::jsonb));
  v_meta := v_meta || jsonb_build_object(
    'success', coalesce(p_success, true),
    'source', coalesce(v_meta ->> 'source', 'rpc')
  );
  if p_failure_category is not null and length(trim(p_failure_category)) > 0 then
    v_meta := v_meta || jsonb_build_object(
      'failure_category', trim(p_failure_category)
    );
  end if;

  insert into audit_logs (
    tenant_id,
    actor_profile_id,
    action,
    module,
    record_id,
    patient_id,
    metadata
  )
  values (
    v_tenant_id,
    v_actor_profile_id,
    trim(p_action),
    trim(p_module),
    p_record_id,
    p_patient_id,
    v_meta
  )
  returning id into v_id;

  return v_id;
end;
$$;

comment on function record_audit_access_event(text, text, uuid, uuid, jsonb, boolean, text) is
  'Append-only KVKK access audit. No internal_doctor_note/clinical_data in metadata. '
  'Client must use authenticated JWT; service_role not required.';

revoke all on function record_audit_access_event(text, text, uuid, uuid, jsonb, boolean, text)
  from public;
grant execute on function record_audit_access_event(text, text, uuid, uuid, jsonb, boolean, text)
  to authenticated;

-- Defense: no direct INSERT on audit_logs for app roles (append via RPC only)
revoke insert on audit_logs from authenticated;
revoke insert on audit_logs from anon;

-- =============================================================================
-- Manual checklist (staging, JWT per role — NOT service_role SQL editor)
-- =============================================================================
-- [ ] doctor: record_audit_access_event('clinical.full.view', 'clinical', ...) → row
-- [ ] assistant: record after summary list → clinical.summary.assistant.list
-- [ ] metadata with internal_doctor_note key → stripped / not stored
-- [ ] nurse: RPC still allowed to insert own access attempt; SELECT audit doctor only
-- [ ] authenticated INSERT audit_logs direct → denied
-- =============================================================================
