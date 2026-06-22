-- Private Storage bucket + tenant-scoped object policies (PDF Storage v1)
-- Prerequisite: current_tenant_id(), is_tenant_member(), has_tenant_role()

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'patient-files-private',
  'patient-files-private',
  false,
  26214400,
  array['application/pdf', 'image/jpeg', 'image/png']
)
on conflict (id) do update
set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- SELECT — download / signed URL (authenticated tenant members)
drop policy if exists patient_files_storage_select_v1 on storage.objects;
create policy patient_files_storage_select_v1
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'patient-files-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and is_tenant_member(current_tenant_id())
    and (
      has_tenant_role(current_tenant_id(), array['doctor_admin'])
      or has_tenant_role(current_tenant_id(), array['assistant_secretary'])
      or has_tenant_role(current_tenant_id(), array['physiotherapist'])
    )
  );

-- INSERT — upload (nurse excluded)
drop policy if exists patient_files_storage_insert_v1 on storage.objects;
create policy patient_files_storage_insert_v1
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'patient-files-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and is_tenant_member(current_tenant_id())
    and (
      has_tenant_role(current_tenant_id(), array['doctor_admin'])
      or has_tenant_role(current_tenant_id(), array['assistant_secretary'])
      or has_tenant_role(current_tenant_id(), array['physiotherapist'])
    )
  );

-- UPDATE / DELETE: v1 kapalı (versiyonlama ve client delete yok)
