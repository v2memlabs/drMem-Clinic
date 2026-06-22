-- =============================================================================
-- Patient File / PDF Storage Metadata v1
-- Extends existing patient_files + pdf_outputs for private storage readiness
--
-- Prerequisite: 20260521100000_draft_saas_schema_rls_v1.sql
--               20260522100000_draft_rls_policies_v1.sql
--
-- Intentionally NOT included:
--   - Storage bucket creation
--   - Signed URL generation
--   - File binary in DB
--   - service_role client usage
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) patient_files — metadata columns
-- -----------------------------------------------------------------------------

alter table patient_files
  add column if not exists storage_bucket text,
  add column if not exists file_kind text,
  add column if not exists clinical_context text,
  add column if not exists encounter_id uuid references clinical_encounters (id),
  add column if not exists appointment_id uuid references appointments (id),
  add column if not exists display_name text,
  add column if not exists original_file_name text,
  add column if not exists checksum text,
  add column if not exists status text,
  add column if not exists visibility_scope text,
  add column if not exists metadata jsonb,
  add column if not exists updated_at timestamptz;

update patient_files
set
  storage_bucket = coalesce(storage_bucket, 'patient-files-private'),
  file_kind = coalesce(file_kind, 'patient_upload'),
  clinical_context = coalesce(clinical_context, 'patient'),
  display_name = coalesce(display_name, file_name),
  original_file_name = coalesce(original_file_name, file_name),
  status = coalesce(status, case when deleted_at is not null then 'deleted' else 'active' end),
  visibility_scope = coalesce(visibility_scope, 'clinic_operations'),
  metadata = coalesce(metadata, '{}'::jsonb),
  updated_at = coalesce(updated_at, created_at)
where storage_bucket is null
   or file_kind is null
   or clinical_context is null
   or display_name is null
   or status is null
   or visibility_scope is null
   or metadata is null
   or updated_at is null;

alter table patient_files
  alter column storage_bucket set default 'patient-files-private',
  alter column storage_bucket set not null,
  alter column file_kind set default 'patient_upload',
  alter column file_kind set not null,
  alter column clinical_context set default 'patient',
  alter column clinical_context set not null,
  alter column display_name set not null,
  alter column status set default 'active',
  alter column status set not null,
  alter column visibility_scope set default 'clinic_operations',
  alter column visibility_scope set not null,
  alter column metadata set default '{}'::jsonb,
  alter column metadata set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

alter table patient_files
  drop constraint if exists patient_files_file_kind_check;
alter table patient_files
  add constraint patient_files_file_kind_check check (
    file_kind in (
      'patient_upload',
      'generated_pdf',
      'consent_document',
      'imaging_report',
      'lab_report',
      'physiotherapy_document',
      'other'
    )
  );

alter table patient_files
  drop constraint if exists patient_files_clinical_context_check;
alter table patient_files
  add constraint patient_files_clinical_context_check check (
    clinical_context in (
      'patient',
      'appointment',
      'encounter',
      'physiotherapy',
      'consent',
      'billing'
    )
  );

alter table patient_files
  drop constraint if exists patient_files_status_check;
alter table patient_files
  add constraint patient_files_status_check check (
    status in ('active', 'archived', 'deleted')
  );

alter table patient_files
  drop constraint if exists patient_files_visibility_scope_check;
alter table patient_files
  add constraint patient_files_visibility_scope_check check (
    visibility_scope in (
      'doctor_admin',
      'clinic_operations',
      'physiotherapy',
      'patient_share_later'
    )
  );

alter table patient_files
  drop constraint if exists patient_files_size_bytes_nonneg;
alter table patient_files
  add constraint patient_files_size_bytes_nonneg check (
    size_bytes is null or size_bytes >= 0
  );

create unique index if not exists idx_patient_files_tenant_storage_path_active
  on patient_files (tenant_id, storage_path)
  where deleted_at is null;

create index if not exists idx_patient_files_visibility
  on patient_files (tenant_id, patient_id, visibility_scope)
  where deleted_at is null;

-- -----------------------------------------------------------------------------
-- 2) pdf_outputs — metadata columns
-- -----------------------------------------------------------------------------

alter table pdf_outputs
  add column if not exists storage_bucket text,
  add column if not exists file_kind text,
  add column if not exists clinical_context text,
  add column if not exists encounter_id uuid references clinical_encounters (id),
  add column if not exists appointment_id uuid references appointments (id),
  add column if not exists display_name text,
  add column if not exists original_file_name text,
  add column if not exists mime_type text,
  add column if not exists file_size_bytes bigint,
  add column if not exists checksum text,
  add column if not exists visibility_scope text,
  add column if not exists metadata jsonb,
  add column if not exists updated_at timestamptz,
  add column if not exists deleted_at timestamptz;

update pdf_outputs
set
  storage_bucket = coalesce(storage_bucket, 'patient-files-private'),
  file_kind = coalesce(file_kind, 'generated_pdf'),
  clinical_context = coalesce(
    clinical_context,
    case
      when source_module = 'clinical_encounter' then 'encounter'
      when source_module = 'consent_template' then 'consent'
      when source_module = 'physiotherapy_referral' then 'physiotherapy'
      else 'patient'
    end
  ),
  encounter_id = coalesce(
    encounter_id,
    case when source_module = 'clinical_encounter' then source_record_id else null end
  ),
  display_name = coalesce(display_name, document_type),
  mime_type = coalesce(mime_type, 'application/pdf'),
  visibility_scope = coalesce(visibility_scope, 'doctor_admin'),
  metadata = coalesce(metadata, '{}'::jsonb),
  updated_at = coalesce(updated_at, created_at),
  status = coalesce(status, 'draft')
where storage_bucket is null
   or file_kind is null
   or clinical_context is null
   or visibility_scope is null
   or metadata is null
   or updated_at is null;

alter table pdf_outputs
  alter column storage_bucket set default 'patient-files-private',
  alter column storage_bucket set not null,
  alter column file_kind set default 'generated_pdf',
  alter column file_kind set not null,
  alter column clinical_context set not null,
  alter column visibility_scope set default 'doctor_admin',
  alter column visibility_scope set not null,
  alter column metadata set default '{}'::jsonb,
  alter column metadata set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

alter table pdf_outputs
  drop constraint if exists pdf_outputs_file_kind_check;
alter table pdf_outputs
  add constraint pdf_outputs_file_kind_check check (
    file_kind in (
      'patient_upload',
      'generated_pdf',
      'consent_document',
      'imaging_report',
      'lab_report',
      'physiotherapy_document',
      'other'
    )
  );

alter table pdf_outputs
  drop constraint if exists pdf_outputs_clinical_context_check;
alter table pdf_outputs
  add constraint pdf_outputs_clinical_context_check check (
    clinical_context in (
      'patient',
      'appointment',
      'encounter',
      'physiotherapy',
      'consent',
      'billing'
    )
  );

alter table pdf_outputs
  drop constraint if exists pdf_outputs_visibility_scope_check;
alter table pdf_outputs
  add constraint pdf_outputs_visibility_scope_check check (
    visibility_scope in (
      'doctor_admin',
      'clinic_operations',
      'physiotherapy',
      'patient_share_later'
    )
  );

alter table pdf_outputs
  drop constraint if exists pdf_outputs_file_size_bytes_nonneg;
alter table pdf_outputs
  add constraint pdf_outputs_file_size_bytes_nonneg check (
    file_size_bytes is null or file_size_bytes >= 0
  );

create unique index if not exists idx_pdf_outputs_tenant_storage_path_active
  on pdf_outputs (tenant_id, storage_path)
  where deleted_at is null and storage_path is not null;

-- -----------------------------------------------------------------------------
-- 3) RLS — patient_files visibility_scope (replaces staff-wide select)
-- -----------------------------------------------------------------------------

drop policy if exists patient_files_select_staff_draft_v1 on patient_files;

drop policy if exists patient_files_select_metadata_v1 on patient_files;
create policy patient_files_select_metadata_v1
  on patient_files for select
  to authenticated
  using (
    deleted_at is null
    and status <> 'deleted'
    and is_tenant_member(tenant_id)
    and tenant_id = current_tenant_id()
    and (
      has_tenant_role(tenant_id, array['doctor_admin'])
      or (
        visibility_scope = 'clinic_operations'
        and has_tenant_role(tenant_id, array['assistant_secretary'])
      )
      or (
        visibility_scope = 'physiotherapy'
        and has_tenant_role(tenant_id, array['physiotherapist'])
      )
    )
  );

-- Insert/update: unchanged staff/doctor draft policies (upload fazı sonra)

-- -----------------------------------------------------------------------------
-- 4) RLS — pdf_outputs remains doctor_admin; visibility_scope ready
-- -----------------------------------------------------------------------------

drop policy if exists pdf_outputs_select_doctor_draft_v1 on pdf_outputs;
create policy pdf_outputs_select_doctor_draft_v1
  on pdf_outputs for select
  to authenticated
  using (
    deleted_at is null
    and is_tenant_member(tenant_id)
    and tenant_id = current_tenant_id()
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and (
      visibility_scope = 'doctor_admin'
      or visibility_scope is null
    )
  );

-- =============================================================================
-- Manual checklist (staging JWT — not service_role SQL editor)
-- =============================================================================
-- [ ] doctor_admin: patient_files all visibility_scope in tenant
-- [ ] assistant: patient_files clinic_operations only
-- [ ] physiotherapist: patient_files physiotherapy only
-- [ ] nurse: patient_files 0 rows
-- [ ] cross-tenant: 0 rows
-- [ ] deleted_at / status=deleted hidden
-- [ ] storage_path not a public URL; no signed_url column
-- [ ] metadata JSONB has no file content / internal_doctor_note / clinical_data
-- =============================================================================
