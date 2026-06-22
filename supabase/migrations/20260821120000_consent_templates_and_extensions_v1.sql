-- =============================================================================
-- Paket A — consent_templates + consents extension (onam workflow)
-- Prerequisite: operational_records_remote_v2a (consents table)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) consent_templates
-- -----------------------------------------------------------------------------

create table if not exists public.consent_templates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  owner_profile_id uuid references public.profiles (id) on delete set null,
  title text not null,
  category text not null,
  consent_type text not null,
  description text not null default '',
  version text not null default 'v1.0',
  content_source text not null default 'text'
    check (content_source in ('text', 'uploaded_pdf', 'text_with_pdf_base')),
  content_body text not null default '',
  source_storage_path text,
  editable_overlay jsonb not null default '{}'::jsonb,
  required_for text not null default 'optional',
  document_file_name text,
  is_active boolean not null default true,
  is_system_seed boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.consent_templates is
  'Onam/KVKK form şablonları — hekim veya klinik seed; tenant scoped.';

create index if not exists consent_templates_tenant_id_idx
  on public.consent_templates (tenant_id);

create index if not exists consent_templates_owner_idx
  on public.consent_templates (tenant_id, owner_profile_id)
  where deleted_at is null;

create index if not exists consent_templates_active_idx
  on public.consent_templates (tenant_id, is_active)
  where deleted_at is null;

drop trigger if exists consent_templates_updated_at on public.consent_templates;
create trigger consent_templates_updated_at
  before update on public.consent_templates
  for each row execute function set_updated_at();

-- -----------------------------------------------------------------------------
-- 2) consents extensions
-- -----------------------------------------------------------------------------

alter table public.consents
  add column if not exists template_id uuid
    references public.consent_templates (id) on delete set null;

alter table public.consents
  add column if not exists template_version text;

alter table public.consents
  add column if not exists pdf_output_id uuid
    references public.pdf_outputs (id) on delete set null;

alter table public.consents
  add column if not exists appointment_id uuid
    references public.appointments (id) on delete set null;

alter table public.consents
  add column if not exists encounter_id uuid
    references public.clinical_encounters (id) on delete set null;

alter table public.consents
  add column if not exists signature_mode text not null default 'pending'
    check (signature_mode in ('pending', 'pad', 'wet_upload'));

alter table public.consents
  add column if not exists metadata jsonb not null default '{}'::jsonb;

create index if not exists consents_patient_type_status_idx
  on public.consents (tenant_id, patient_id, consent_type, status)
  where deleted_at is null;

-- -----------------------------------------------------------------------------
-- 3) RLS — consent_templates
-- -----------------------------------------------------------------------------

alter table public.consent_templates enable row level security;

drop policy if exists consent_templates_select_staff_v1 on public.consent_templates;
create policy consent_templates_select_staff_v1
  on public.consent_templates
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
  );

drop policy if exists consent_templates_insert_doctor_v1 on public.consent_templates;
create policy consent_templates_insert_doctor_v1
  on public.consent_templates
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and (
      owner_profile_id is null
      or owner_profile_id = current_profile_id()
    )
  );

drop policy if exists consent_templates_update_doctor_v1 on public.consent_templates;
create policy consent_templates_update_doctor_v1
  on public.consent_templates
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
    and (
      owner_profile_id is null
      or owner_profile_id = current_profile_id()
    )
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  );
