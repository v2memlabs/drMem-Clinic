-- =============================================================================
-- Audit logs SELECT policy — has_role_access(view_audit_logs)
-- Prerequisite: audit_logs table + has_role_access helper
-- =============================================================================

drop policy if exists audit_logs_select_doctor_draft_v1 on public.audit_logs;

create policy audit_logs_select_role_access_v1
  on public.audit_logs
  for select
  to authenticated
  using (
    public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_audit_logs')
  );
