-- =============================================================================
-- Faz 2 — role_access + financial SQL helpers (mirror Flutter defaults)
-- =============================================================================

create or replace function public.membership_role_to_access_role(p_db_role text)
returns text
language sql
immutable
as $$
  select case p_db_role
    when 'doctor_admin' then 'doctor'
    when 'assistant_secretary' then 'assistant'
    when 'physiotherapist' then 'physiotherapist'
    when 'nurse' then 'nurse'
    else null
  end;
$$;

create or replace function public.current_membership_access_role(p_tenant_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select public.membership_role_to_access_role(m.role)
  from public.memberships m
  where m.tenant_id = p_tenant_id
    and m.profile_id = public.current_profile_id()
    and m.status = 'active'
  limit 1;
$$;

create or replace function public.role_access_default_allowed(
  p_flutter_role text,
  p_access_key text
)
returns boolean
language sql
immutable
as $$
  select case p_access_key
    when 'view_patients' then p_flutter_role in ('doctor', 'assistant', 'physiotherapist', 'nurse')
    when 'edit_patients' then p_flutter_role in ('doctor', 'assistant')
    when 'view_all_appointments' then p_flutter_role in ('assistant', 'nurse')
    when 'view_own_scoped_appointments' then p_flutter_role in ('doctor', 'physiotherapist')
    when 'edit_appointments' then p_flutter_role in ('doctor', 'assistant', 'nurse')
    when 'select_appointment_doctor' then p_flutter_role in ('assistant', 'nurse')
    when 'start_anamnesis' then p_flutter_role in ('doctor', 'assistant')
    when 'edit_anamnesis' then p_flutter_role = 'doctor'
    when 'view_clinical_encounters' then p_flutter_role = 'doctor'
    when 'edit_clinical_encounters' then p_flutter_role = 'doctor'
    when 'view_clinical_diagnosis_summary' then p_flutter_role in ('doctor', 'assistant')
    when 'view_anamnesis_details' then p_flutter_role = 'doctor'
    when 'view_examination_details' then p_flutter_role = 'doctor'
    when 'view_treatment_plan_details' then p_flutter_role = 'doctor'
    when 'view_clinical_summary' then p_flutter_role in ('doctor', 'physiotherapist')
    when 'view_clinical_diagnosis' then p_flutter_role in ('doctor', 'physiotherapist')
    when 'view_clinical_treatment_plan' then p_flutter_role in ('doctor', 'physiotherapist')
    when 'edit_examination_notes' then p_flutter_role = 'doctor'
    when 'edit_diagnosis' then p_flutter_role = 'doctor'
    when 'edit_treatment_plans' then p_flutter_role = 'doctor'
    when 'view_imaging' then p_flutter_role = 'doctor'
    when 'edit_imaging' then p_flutter_role = 'doctor'
    when 'view_pdf_outputs' then p_flutter_role in ('doctor', 'assistant')
    when 'edit_pdf_outputs' then p_flutter_role in ('doctor', 'assistant')
    when 'view_prescriptions' then p_flutter_role in ('doctor', 'assistant')
    when 'edit_prescriptions' then p_flutter_role = 'doctor'
    when 'view_clinical_reports' then p_flutter_role in ('doctor', 'assistant')
    when 'edit_clinical_reports' then p_flutter_role = 'doctor'
    when 'view_radiology_orders' then p_flutter_role in ('doctor', 'assistant')
    when 'edit_radiology_orders' then p_flutter_role = 'doctor'
    when 'view_lab_orders' then p_flutter_role in ('doctor', 'assistant', 'nurse')
    when 'edit_lab_orders' then p_flutter_role in ('doctor', 'assistant', 'nurse')
    when 'manage_lab_order_templates' then p_flutter_role in ('doctor', 'assistant', 'nurse')
    when 'view_audit_logs' then p_flutter_role = 'doctor'
    when 'view_surgery_notes' then p_flutter_role = 'doctor'
    when 'edit_surgery_notes' then p_flutter_role = 'doctor'
    when 'view_patient_timeline' then p_flutter_role = 'doctor'
    when 'view_files' then p_flutter_role in ('doctor', 'assistant')
    when 'edit_files' then p_flutter_role in ('doctor', 'assistant')
    when 'view_consents' then p_flutter_role in ('doctor', 'assistant')
    when 'edit_consents' then p_flutter_role in ('doctor', 'assistant')
    when 'view_consent_templates' then p_flutter_role in ('doctor', 'assistant')
    when 'view_payments' then p_flutter_role in ('doctor', 'assistant', 'physiotherapist')
    when 'create_payments' then p_flutter_role in ('doctor', 'assistant', 'physiotherapist')
    when 'edit_payments' then p_flutter_role in ('doctor', 'assistant', 'physiotherapist')
    when 'charge_patient_materials' then p_flutter_role in ('doctor', 'assistant', 'physiotherapist', 'nurse')
    when 'view_messages' then p_flutter_role in ('doctor', 'assistant')
    when 'view_message_templates' then p_flutter_role = 'doctor'
    when 'view_physiotherapy' then p_flutter_role in ('doctor', 'physiotherapist')
    when 'edit_physiotherapy' then p_flutter_role in ('doctor', 'physiotherapist')
    when 'view_exercise_plans' then p_flutter_role in ('doctor', 'physiotherapist')
    when 'edit_exercise_plans' then p_flutter_role in ('doctor', 'physiotherapist')
    when 'view_post_op_protocols' then p_flutter_role in ('doctor', 'physiotherapist')
    when 'edit_post_op_protocols' then p_flutter_role = 'doctor'
    when 'view_inventory' then p_flutter_role in ('doctor', 'nurse')
    when 'edit_inventory' then p_flutter_role in ('doctor', 'nurse')
    when 'record_inventory_movement' then p_flutter_role in ('doctor', 'nurse')
    when 'view_patient_alerts' then p_flutter_role in ('doctor', 'assistant')
    when 'view_patient_tags' then p_flutter_role in ('doctor', 'assistant', 'physiotherapist')
    when 'create_patient_tags' then p_flutter_role in ('doctor', 'assistant')
    when 'assign_patient_tags' then p_flutter_role in ('doctor', 'assistant')
    when 'remove_patient_tags' then p_flutter_role in ('doctor', 'assistant')
    when 'approve_staff_leave' then p_flutter_role = 'doctor'
    when 'view_doctor_only_settings' then p_flutter_role = 'doctor'
    when 'edit_clinic_profile' then p_flutter_role = 'doctor'
    else false
  end;
$$;

create or replace function public.has_role_access(
  p_tenant_id uuid,
  p_access_key text
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_flutter_role text;
  v_raw jsonb;
begin
  if p_tenant_id is null or p_access_key is null or length(trim(p_access_key)) = 0 then
    return false;
  end if;

  if not public.is_tenant_member(p_tenant_id) then
    return false;
  end if;

  v_flutter_role := public.current_membership_access_role(p_tenant_id);
  if v_flutter_role is null then
    return false;
  end if;

  select t.settings_json -> 'role_access' -> v_flutter_role -> p_access_key
    into v_raw
  from public.tenants t
  where t.id = p_tenant_id;

  if v_raw is not null and jsonb_typeof(v_raw) = 'boolean' then
    return v_raw::boolean;
  end if;

  return public.role_access_default_allowed(v_flutter_role, p_access_key);
end;
$$;

create or replace function public.is_financial_feature_enabled(
  p_tenant_id uuid,
  p_feature_key text
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_raw jsonb;
begin
  if p_tenant_id is null or p_feature_key is null or length(trim(p_feature_key)) = 0 then
    return false;
  end if;

  select t.settings_json -> 'financial' -> p_feature_key
    into v_raw
  from public.tenants t
  where t.id = p_tenant_id;

  if v_raw is null then
    return true;
  end if;

  if jsonb_typeof(v_raw) = 'boolean' then
    return v_raw::boolean;
  end if;

  return true;
end;
$$;

create or replace function public.payments_access_allowed(
  p_tenant_id uuid,
  p_access_key text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_financial_feature_enabled(p_tenant_id, 'payment_records')
    and public.has_role_access(p_tenant_id, p_access_key);
$$;

revoke all on function public.membership_role_to_access_role(text) from public;
revoke all on function public.current_membership_access_role(uuid) from public;
revoke all on function public.role_access_default_allowed(text, text) from public;
revoke all on function public.has_role_access(uuid, text) from public;
revoke all on function public.is_financial_feature_enabled(uuid, text) from public;
revoke all on function public.payments_access_allowed(uuid, text) from public;

grant execute on function public.has_role_access(uuid, text) to authenticated;
grant execute on function public.is_financial_feature_enabled(uuid, text) to authenticated;
grant execute on function public.payments_access_allowed(uuid, text) to authenticated;

-- Prevent clinic users from mutating maintenance-only settings keys.
create or replace function public.tenants_guard_privileged_settings_json()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  if coalesce(current_setting('request.jwt.claim.role', true), '') = 'service_role' then
    return new;
  end if;

  begin
    perform public.maintenance_assert_operator();
    return new;
  exception
    when others then
      null;
  end;

  if new.settings_json is distinct from old.settings_json then
    new.settings_json := coalesce(new.settings_json, '{}'::jsonb);

    if (new.settings_json -> 'role_access') is distinct from (old.settings_json -> 'role_access') then
      new.settings_json := jsonb_set(
        new.settings_json,
        '{role_access}',
        coalesce(old.settings_json -> 'role_access', '{}'::jsonb),
        true
      );
    end if;

    if (new.settings_json -> 'financial') is distinct from (old.settings_json -> 'financial') then
      new.settings_json := jsonb_set(
        new.settings_json,
        '{financial}',
        coalesce(old.settings_json -> 'financial', '{}'::jsonb),
        true
      );
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists tenants_guard_privileged_settings_json_v1 on public.tenants;
create trigger tenants_guard_privileged_settings_json_v1
  before update on public.tenants
  for each row
  execute function public.tenants_guard_privileged_settings_json();
