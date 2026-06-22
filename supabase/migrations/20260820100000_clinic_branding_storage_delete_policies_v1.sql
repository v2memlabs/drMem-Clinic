-- Profil avatar storage path: profile id klasörü (avatar dosya adı policy dışında).

drop policy if exists clinic_branding_storage_insert_avatar_v1 on storage.objects;
create policy clinic_branding_storage_insert_avatar_v1
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'clinic-branding-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and (storage.foldername(name))[3] = 'profiles'
    and (storage.foldername(name))[4] = current_profile_id()::text
    and is_tenant_member(current_tenant_id())
  );

drop policy if exists clinic_branding_storage_update_avatar_v1 on storage.objects;
create policy clinic_branding_storage_update_avatar_v1
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'clinic-branding-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and (storage.foldername(name))[3] = 'profiles'
    and (storage.foldername(name))[4] = current_profile_id()::text
    and is_tenant_member(current_tenant_id())
  )
  with check (
    bucket_id = 'clinic-branding-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and (storage.foldername(name))[3] = 'profiles'
    and (storage.foldername(name))[4] = current_profile_id()::text
    and is_tenant_member(current_tenant_id())
  );

-- DELETE — avatar/branding upsert replace
drop policy if exists clinic_branding_storage_delete_avatar_v1 on storage.objects;
create policy clinic_branding_storage_delete_avatar_v1
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'clinic-branding-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and (storage.foldername(name))[3] = 'profiles'
    and (storage.foldername(name))[4] = current_profile_id()::text
    and is_tenant_member(current_tenant_id())
  );

drop policy if exists clinic_branding_storage_delete_branding_v1 on storage.objects;
create policy clinic_branding_storage_delete_branding_v1
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'clinic-branding-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and (storage.foldername(name))[3] = 'branding'
    and is_tenant_member(current_tenant_id())
    and has_tenant_role(current_tenant_id(), array['doctor_admin'])
  );
