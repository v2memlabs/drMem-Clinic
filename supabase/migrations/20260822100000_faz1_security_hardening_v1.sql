-- =============================================================================
-- Faz 1 — Security hardening v1
-- 1) Block profiles.maintenance_operator self-escalation
-- 2) Sanitize maintenance_ping errors
-- 3) Restrict resolve_login_email to service_role (client uses edge function)
-- 4) Deny maintenance operators on clinical / PHI tables (restrictive RLS)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Privileged column guard on profiles
-- -----------------------------------------------------------------------------

create or replace function public.profiles_guard_privileged_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text := coalesce(current_setting('request.jwt.claim.role', true), '');
begin
  if tg_op = 'INSERT' then
    if coalesce(new.maintenance_operator, false) = true and v_role <> 'service_role' then
      raise exception 'privilege_escalation_denied' using errcode = '42501';
    end if;
  elsif tg_op = 'UPDATE' then
    if new.maintenance_operator is distinct from old.maintenance_operator
       and v_role <> 'service_role' then
      raise exception 'privilege_escalation_denied' using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_guard_privileged_columns_v1 on public.profiles;
create trigger profiles_guard_privileged_columns_v1
  before insert or update on public.profiles
  for each row
  execute function public.profiles_guard_privileged_columns();

-- -----------------------------------------------------------------------------
-- 2) maintenance_ping — do not leak sqlerrm to clients
-- -----------------------------------------------------------------------------

create or replace function public.maintenance_ping()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
begin
  v_profile_id := public.maintenance_assert_operator();
  return jsonb_build_object(
    'ok', true,
    'operator_profile_id', v_profile_id,
    'auth_user_id', auth.uid()
  );
exception
  when others then
    return jsonb_build_object(
      'ok', false,
      'error', 'maintenance_forbidden'
    );
end;
$$;

-- -----------------------------------------------------------------------------
-- 3) resolve_login_email — service_role only (sign-in-with-username edge fn)
-- -----------------------------------------------------------------------------

revoke all on function public.resolve_login_email(text) from public;
revoke all on function public.resolve_login_email(text) from anon;
revoke all on function public.resolve_login_email(text) from authenticated;
grant execute on function public.resolve_login_email(text) to service_role;

-- -----------------------------------------------------------------------------
-- 4) Maintenance operator clinical isolation (restrictive policies)
-- -----------------------------------------------------------------------------

create or replace function public.current_is_maintenance_operator()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select p.maintenance_operator
      from public.profiles p
      where p.auth_user_id = auth.uid()
      limit 1
    ),
    false
  );
$$;

revoke all on function public.current_is_maintenance_operator() from public;
grant execute on function public.current_is_maintenance_operator() to authenticated;

do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'patients',
    'appointments',
    'clinical_encounters',
    'patient_files',
    'pdf_outputs',
    'audit_logs',
    'payments',
    'consents',
    'inventory_items',
    'inventory_movements',
    'physiotherapy_referrals',
    'physiotherapy_sessions',
    'surgery_procedure_notes',
    'surgery_note_templates',
    'patient_tags',
    'patient_tag_assignments',
    'payment_staff_notifications',
    'staff_leave_records',
    'staff_leave_requests',
    'clinic_workflow_settings'
  ]
  loop
    if to_regclass(format('public.%I', v_table)) is null then
      continue;
    end if;

    execute format(
      'drop policy if exists %I on public.%I',
      v_table || '_deny_maintenance_operator_v1',
      v_table
    );
    execute format(
      $fmt$
        create policy %I
          on public.%I
          as restrictive
          for all
          to authenticated
          using (not public.current_is_maintenance_operator())
      $fmt$,
      v_table || '_deny_maintenance_operator_v1',
      v_table
    );
  end loop;
end $$;

-- Private patient file storage — maintenance operators excluded
drop policy if exists patient_files_storage_deny_maintenance_operator_v1 on storage.objects;
create policy patient_files_storage_deny_maintenance_operator_v1
  on storage.objects
  as restrictive
  for all
  to authenticated
  using (
    bucket_id <> 'patient-files-private'
    or not public.current_is_maintenance_operator()
  );
