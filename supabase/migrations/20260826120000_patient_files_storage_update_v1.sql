-- İmzalı PDF güncelleme — mevcut storage nesnesinin üzerine yazma (upsert).
-- Önceki v1: INSERT/SELECT only; imza sonrası replaceStoredPdfBytes UPDATE gerektirir.

drop policy if exists patient_files_storage_update_v1 on storage.objects;
create policy patient_files_storage_update_v1
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'patient-files-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and is_tenant_member(current_tenant_id())
    and public._storage_object_metadata_visible(name)
    and public.has_role_access(current_tenant_id(), 'edit_files')
    and (
      has_tenant_role(current_tenant_id(), array['doctor_admin'])
      or has_tenant_role(current_tenant_id(), array['assistant_secretary'])
      or has_tenant_role(current_tenant_id(), array['physiotherapist'])
    )
  )
  with check (
    bucket_id = 'patient-files-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and is_tenant_member(current_tenant_id())
    and public.has_role_access(current_tenant_id(), 'edit_files')
    and (
      has_tenant_role(current_tenant_id(), array['doctor_admin'])
      or has_tenant_role(current_tenant_id(), array['assistant_secretary'])
      or has_tenant_role(current_tenant_id(), array['physiotherapist'])
    )
  );
