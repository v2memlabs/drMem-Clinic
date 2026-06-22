-- =============================================================================
-- Staging Remote PDF & Storage Smoke Checks v1
-- Extends pdf_storage_smoke_checks.sql for remote gate verification pack.
--
-- WHERE: Supabase SQL Editor (staging), service_role OK for structural checks.
-- Per-role storage access: Flutter client or signed-URL API smoke (section 6).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Bucket configuration
-- -----------------------------------------------------------------------------

select
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types,
  case
    when public = true then 'FAIL — bucket must be private'
    when id <> 'patient-files-private' then 'WARN — unexpected bucket id'
    else 'OK'
  end as bucket_status
from storage.buckets
where id = 'patient-files-private';

-- Expected: exactly 1 row, public = false

-- -----------------------------------------------------------------------------
-- 2) Storage RLS policies on storage.objects
-- -----------------------------------------------------------------------------

select
  policyname,
  cmd,
  roles::text,
  case cmd
    when 'SELECT' then 'Signed URL / authenticated read path'
    when 'INSERT' then 'Upload path (doctor/staff)'
    else 'REVIEW — unexpected cmd'
  end as purpose
from pg_policies
where schemaname = 'storage'
  and tablename = 'objects'
  and policyname like 'patient_files_storage_%'
order by policyname;

-- Expected:
--   patient_files_storage_select_v1 (SELECT)
--   patient_files_storage_insert_v1 (INSERT)
-- No UPDATE/DELETE policies (immutability)

-- -----------------------------------------------------------------------------
-- 3) pdf_outputs / patient_files table RLS (metadata layer)
-- -----------------------------------------------------------------------------

select
  tablename,
  count(*) as policy_count,
  bool_or(cmd = 'SELECT') as has_select,
  bool_or(cmd = 'INSERT') as has_insert
from pg_policies
where schemaname = 'public'
  and tablename in ('pdf_outputs', 'patient_files')
group by tablename;

select tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename in ('pdf_outputs', 'patient_files')
order by tablename, policyname;

-- pdf_outputs: doctor_admin SELECT/INSERT (draft policies)
-- patient_files: role-scoped visibility_scope policies

-- -----------------------------------------------------------------------------
-- 4) Metadata hygiene — forbidden keys in JSONB
-- -----------------------------------------------------------------------------

select 'patient_files' as source, id, tenant_id, metadata
from patient_files
where deleted_at is null
  and (
    metadata ? 'signed_url'
    or metadata ? 'signedUrl'
    or metadata ? 'file_content'
    or metadata ? 'fileContent'
    or metadata ? 'clinical_data'
    or metadata ? 'internal_doctor_note'
  )
limit 20;

-- Expected: 0 rows

select 'pdf_outputs' as source, id, tenant_id, metadata
from pdf_outputs
where deleted_at is null
  and (
    metadata ? 'signed_url'
    or metadata ? 'signedUrl'
    or metadata ? 'file_content'
    or metadata ? 'clinical_data'
  )
limit 20;

-- Expected: 0 rows

-- -----------------------------------------------------------------------------
-- 5) storage_path / bucket column presence (remote save prerequisite)
-- -----------------------------------------------------------------------------

select
  'pdf_outputs' as table_name,
  count(*) filter (where storage_path is not null and storage_path <> '') as with_path,
  count(*) filter (where storage_bucket is not null) as with_bucket,
  count(*) as total_active
from pdf_outputs
where deleted_at is null;

select
  'patient_files' as table_name,
  count(*) filter (where storage_path is not null and storage_path <> '') as with_path,
  count(*) filter (where storage_bucket is not null) as with_bucket,
  count(*) as total_active
from patient_files
where deleted_at is null;

-- Recent pdf_outputs sample (path format check):
select
  id,
  tenant_id,
  patient_id,
  document_type,
  storage_bucket,
  left(storage_path, 80) as storage_path_prefix,
  visibility_scope,
  created_at
from pdf_outputs
where deleted_at is null
order by created_at desc
limit 10;

-- Expected path pattern: tenants/<tenant_id>/... (not http URL)

-- -----------------------------------------------------------------------------
-- 6) Public URL deny + signed URL smoke (MANUAL — Flutter / curl)
-- -----------------------------------------------------------------------------
-- A) Public object URL deny:
--    https://<project>.supabase.co/storage/v1/object/public/patient-files-private/...
--    → expect 400/404 (bucket not public)
--
-- B) Signed URL TTL smoke (doctor-a JWT):
--    1) Flutter: PDF detay → Aç → DevTools: signed URL request
--    2) URL works once; after TTL expires → 401/403
--    3) Copy URL to incognito → works until expiry
--
-- C) PDF "Aç" failure triage:
--    | Symptom                          | Likely layer              |
--    |----------------------------------|---------------------------|
--    | storage_path NULL in pdf_outputs | Save/upload failed        |
--    | object missing in bucket         | Upload rollback / orphan  |
--    | signed URL 403                   | storage RLS / role        |
--    | signed URL 200, Aç fails         | launchUrl / local handler |
--    | Liste OK, prefill fail           | sync mock source (app)    |

-- -----------------------------------------------------------------------------
-- 7) Orphan storage objects (manual dashboard spot)
-- -----------------------------------------------------------------------------
-- Dashboard → Storage → patient-files-private → tenants/
-- Compare object count vs patient_files/pdf_outputs rows with matching storage_path.
-- Note orphans in verification report.

-- -----------------------------------------------------------------------------
-- 8) Minimal metadata insert smoke (service_role — schema only)
-- Uncomment and set UUIDs from seed.
-- -----------------------------------------------------------------------------

/*
insert into pdf_outputs (
  tenant_id,
  patient_id,
  document_type,
  storage_bucket,
  storage_path,
  visibility_scope,
  metadata
) values (
  'a0000001-0001-4001-8001-000000000001',
  '<PATIENT_UUID>',
  'muayene_ozeti',
  'patient-files-private',
  'tenants/a0000001-0001-4001-8001-000000000001/smoke/test.pdf',
  'doctor_admin',
  '{"smoke": true}'::jsonb
) returning id, storage_path;

-- Cleanup:
-- update pdf_outputs set deleted_at = now() where id = '<ID>';
*/
