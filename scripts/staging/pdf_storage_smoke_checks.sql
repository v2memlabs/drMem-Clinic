-- PDF Storage Hardening / Staging Smoke v1 — operatör SQL kontrolleri
-- Supabase SQL Editor'da staging projede çalıştırın (service_role OK burada; Flutter client'ta YASAK).

-- 1) Bucket private
select id, name, public, file_size_limit, allowed_mime_types
from storage.buckets
where id = 'patient-files-private';

-- Beklenti: public = false

-- 2) Storage policies
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'storage'
  and tablename = 'objects'
  and policyname like 'patient_files_storage_%'
order by policyname;

-- Beklenti: patient_files_storage_select_v1 (SELECT), patient_files_storage_insert_v1 (INSERT)
-- UPDATE/DELETE policy olmamalı

-- 3) patient_files RLS (visibility_scope) — örnek sayım
-- Doctor JWT ile çalıştırılamaz; membership ile manuel UI smoke kullanın.

-- 4) Yasak metadata anahtarları spot (son 20 kayıt)
select id, tenant_id, metadata
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

-- Beklenti: 0 satır

select id, tenant_id, metadata
from pdf_outputs
where deleted_at is null
  and (
    metadata ? 'signed_url'
    or metadata ? 'file_content'
    or metadata ? 'clinical_data'
  )
limit 20;

-- Beklenti: 0 satır

-- 5) Orphan storage spot (manuel)
-- Dashboard > Storage > patient-files-private > tenants/
-- Metadata'sız object var mı operatör notu ile işaretleyin.
