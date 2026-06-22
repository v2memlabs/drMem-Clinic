-- Ödeme kaydı sonrası asistan bildirimi: doktor ve fizyoterapist insert edebilsin.
-- SELECT/UPDATE yalnızca asistan (mevcut davranış).

drop policy if exists payment_staff_notifications_assistant_v1
  on payment_staff_notifications;

drop policy if exists payment_staff_notifications_select_assistant_v1
  on payment_staff_notifications;
create policy payment_staff_notifications_select_assistant_v1
  on payment_staff_notifications
  for select
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary'])
  );

drop policy if exists payment_staff_notifications_update_assistant_v1
  on payment_staff_notifications;
create policy payment_staff_notifications_update_assistant_v1
  on payment_staff_notifications
  for update
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary'])
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary'])
  );

drop policy if exists payment_staff_notifications_insert_staff_v1
  on payment_staff_notifications;
create policy payment_staff_notifications_insert_staff_v1
  on payment_staff_notifications
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'physiotherapist']
    )
    and exists (
      select 1
      from patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );
