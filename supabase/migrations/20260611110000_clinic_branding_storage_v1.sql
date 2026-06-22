-- Clinic branding + profile avatar storage (private bucket, signed URL preview).
-- Paths:
--   tenants/{tenantId}/profiles/{profileId}/avatar.{ext}
--   tenants/{tenantId}/branding/logo.{ext}
--   tenants/{tenantId}/branding/banner.{ext}
-- DB: profiles.avatar_url stores object path; tenants.settings_json.branding stores logo_path/banner_path.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'clinic-branding-private',
  'clinic-branding-private',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- SELECT — tenant members can preview branding/avatars in their clinic
drop policy if exists clinic_branding_storage_select_v1 on storage.objects;
create policy clinic_branding_storage_select_v1
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'clinic-branding-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and is_tenant_member(current_tenant_id())
  );

-- INSERT — own profile avatar
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

-- UPDATE — own profile avatar (upsert replace)
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

-- INSERT — clinic logo/banner (doctor_admin)
drop policy if exists clinic_branding_storage_insert_branding_v1 on storage.objects;
create policy clinic_branding_storage_insert_branding_v1
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'clinic-branding-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and (storage.foldername(name))[3] = 'branding'
    and is_tenant_member(current_tenant_id())
    and has_tenant_role(current_tenant_id(), array['doctor_admin'])
  );

-- UPDATE — clinic logo/banner (upsert replace)
drop policy if exists clinic_branding_storage_update_branding_v1 on storage.objects;
create policy clinic_branding_storage_update_branding_v1
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'clinic-branding-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and (storage.foldername(name))[3] = 'branding'
    and is_tenant_member(current_tenant_id())
    and has_tenant_role(current_tenant_id(), array['doctor_admin'])
  )
  with check (
    bucket_id = 'clinic-branding-private'
    and (storage.foldername(name))[1] = 'tenants'
    and (storage.foldername(name))[2] = current_tenant_id()::text
    and (storage.foldername(name))[3] = 'branding'
    and is_tenant_member(current_tenant_id())
    and has_tenant_role(current_tenant_id(), array['doctor_admin'])
  );
