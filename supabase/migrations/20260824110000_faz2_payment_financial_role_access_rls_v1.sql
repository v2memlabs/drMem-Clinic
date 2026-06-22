-- =============================================================================
-- Faz 2 — Enforce financial + role_access on payments and related RPC/policies
-- =============================================================================

-- -----------------------------------------------------------------------------
-- payments — doctor / assistant
-- -----------------------------------------------------------------------------

drop policy if exists payments_select_staff_v2a on public.payments;
create policy payments_select_staff_v2a
  on public.payments
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and public.payments_access_allowed(tenant_id, 'view_payments')
  );

drop policy if exists payments_insert_staff_v2a on public.payments;
create policy payments_insert_staff_v2a
  on public.payments
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and public.payments_access_allowed(tenant_id, 'create_payments')
    and exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );

drop policy if exists payments_update_staff_v2a on public.payments;
create policy payments_update_staff_v2a
  on public.payments
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and public.payments_access_allowed(tenant_id, 'edit_payments')
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and public.payments_access_allowed(tenant_id, 'edit_payments')
    and exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );

-- -----------------------------------------------------------------------------
-- payments — physiotherapist / nurse
-- -----------------------------------------------------------------------------

drop policy if exists payments_select_physio_nurse_v1 on public.payments;
create policy payments_select_physio_nurse_v1
  on public.payments
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['physiotherapist', 'nurse']
    )
    and public.payments_access_allowed(tenant_id, 'view_payments')
  );

drop policy if exists payments_insert_physio_v1 on public.payments;
create policy payments_insert_physio_v1
  on public.payments
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and public.payments_access_allowed(tenant_id, 'create_payments')
    and exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );

drop policy if exists payments_update_physio_own_v1 on public.payments;
create policy payments_update_physio_own_v1
  on public.payments
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and created_by = current_profile_id()
    and public.payments_access_allowed(tenant_id, 'edit_payments')
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and created_by = current_profile_id()
    and public.payments_access_allowed(tenant_id, 'edit_payments')
  );

-- -----------------------------------------------------------------------------
-- payment_staff_notifications
-- -----------------------------------------------------------------------------

drop policy if exists payment_staff_notifications_select_assistant_v1
  on public.payment_staff_notifications;
create policy payment_staff_notifications_select_assistant_v1
  on public.payment_staff_notifications
  for select
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary'])
    and public.is_financial_feature_enabled(tenant_id, 'payment_records')
    and public.is_financial_feature_enabled(tenant_id, 'assistant_finance_notifications')
  );

drop policy if exists payment_staff_notifications_update_assistant_v1
  on public.payment_staff_notifications;
create policy payment_staff_notifications_update_assistant_v1
  on public.payment_staff_notifications
  for update
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary'])
    and public.is_financial_feature_enabled(tenant_id, 'payment_records')
    and public.is_financial_feature_enabled(tenant_id, 'assistant_finance_notifications')
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary'])
    and public.is_financial_feature_enabled(tenant_id, 'payment_records')
    and public.is_financial_feature_enabled(tenant_id, 'assistant_finance_notifications')
  );

drop policy if exists payment_staff_notifications_insert_staff_v1
  on public.payment_staff_notifications;
create policy payment_staff_notifications_insert_staff_v1
  on public.payment_staff_notifications
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'physiotherapist']
    )
    and public.is_financial_feature_enabled(tenant_id, 'payment_records')
    and public.is_financial_feature_enabled(tenant_id, 'assistant_finance_notifications')
    and exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );

-- -----------------------------------------------------------------------------
-- Material charge encounter picker RPC
-- -----------------------------------------------------------------------------

create or replace function public.list_patient_encounters_for_material_charge(
  p_patient_id uuid
)
returns table (
  encounter_id uuid,
  patient_id uuid,
  patient_display_name text,
  encounter_date timestamptz,
  protocol_number text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ce.id as encounter_id,
    ce.patient_id,
    trim(concat_ws(' ', p.first_name, p.last_name)) as patient_display_name,
    ce.encounter_date,
    ce.protocol_number
  from public.clinical_encounters ce
  join public.patients p on p.id = ce.patient_id
  where ce.deleted_at is null
    and p.deleted_at is null
    and ce.tenant_id = current_tenant_id()
    and ce.patient_id = p_patient_id
    and public.is_financial_feature_enabled(ce.tenant_id, 'material_charges')
    and public.has_role_access(ce.tenant_id, 'charge_patient_materials')
  order by ce.encounter_date desc, ce.updated_at desc;
$$;

comment on function public.list_patient_encounters_for_material_charge(uuid) is
  'Malzeme şarjı muayene seçimi — tenant financial + role_access enforced.';

grant execute on function public.list_patient_encounters_for_material_charge(uuid)
  to authenticated;
