-- Randevu slotları için klinik mesai ayarlarını hemşire ve FTR de okuyabilsin.

drop policy if exists clinic_workflow_settings_select_member_v1 on clinic_workflow_settings;
create policy clinic_workflow_settings_select_member_v1
  on clinic_workflow_settings
  for select
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary', 'nurse', 'physiotherapist']
    )
  );
