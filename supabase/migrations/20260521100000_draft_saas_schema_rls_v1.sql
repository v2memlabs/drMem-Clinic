-- =============================================================================
-- Draft migration — review before applying
-- Not executed automatically. Do not treat as applied to production.
--
-- drMem Clinic — SaaS schema + RLS draft v1
-- Target: Supabase PostgreSQL
-- Flutter backend: remains mock until Faz 2+ (no deploy from this file)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Extensions (enable when applying)
-- -----------------------------------------------------------------------------
-- create extension if not exists "pgcrypto";

-- -----------------------------------------------------------------------------
-- Role model: TEXT + CHECK (not ENUM) — easier to extend without ALTER TYPE.
-- DB role keys (this migration):
--   doctor_admin | assistant_secretary | physiotherapist | nurse
-- Flutter AppRoles mapping (lib/core/constants/app_roles.dart):
--   doctor          -> doctor_admin
--   assistant       -> assistant_secretary
--   physiotherapist -> physiotherapist
--   nurse           -> nurse
-- -----------------------------------------------------------------------------

-- =============================================================================
-- A) tenants
-- =============================================================================

create table if not exists tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  specialty text,
  timezone text not null default 'Europe/Istanbul',
  status text not null default 'active'
    check (status in ('active', 'suspended', 'trial')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =============================================================================
-- B) profiles
-- =============================================================================

create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique, -- references auth.users(id) when Supabase Auth enabled
  display_name text,
  email text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Future: alter table profiles add constraint profiles_auth_user_fk
--   foreign key (auth_user_id) references auth.users(id) on delete cascade;

-- =============================================================================
-- C) memberships
-- =============================================================================

create table if not exists memberships (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  profile_id uuid not null references profiles (id) on delete cascade,
  role text not null check (role in (
    'doctor_admin',
    'assistant_secretary',
    'physiotherapist',
    'nurse'
  )),
  status text not null default 'active'
    check (status in ('active', 'invited', 'disabled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, profile_id)
);

create index if not exists idx_memberships_profile on memberships (profile_id);
create index if not exists idx_memberships_tenant on memberships (tenant_id);

-- =============================================================================
-- D) permissions + role_permissions (minimal seed structure)
-- =============================================================================

create table if not exists permissions (
  key text primary key,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists role_permissions (
  role text not null,
  permission_key text not null references permissions (key) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (role, permission_key)
);

-- Draft seed (uncomment on review):
-- insert into permissions (key, description) values
--   ('patients.read', 'Hasta listeleme'),
--   ('patients.write', 'Hasta oluşturma/güncelleme'),
--   ('appointments.read', 'Randevu okuma'),
--   ('appointments.write', 'Randevu yazma'),
--   ('clinical_encounter.read_full', 'Tam muayene kaydı'),
--   ('clinical_encounter.read_summary', 'Operasyonel özet'),
--   ('pdf_outputs.read', 'PDF metadata'),
--   ('audit_logs.read', 'Audit okuma'),
--   ('settings.clinic_write', 'Klinik ayarları')
-- on conflict (key) do nothing;

-- =============================================================================
-- E) patients
-- =============================================================================

create table if not exists patients (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  file_number text not null,
  first_name text not null,
  last_name text not null,
  phone text,
  birth_date date,
  gender text,
  national_id text, -- hassas: KVKK; maskelenmiş görünüm API'de değerlendirilmeli
  insurance_type text,
  status text not null default 'active'
    check (status in ('active', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (tenant_id, file_number)
);

create index if not exists idx_patients_tenant on patients (tenant_id);
create index if not exists idx_patients_tenant_deleted on patients (tenant_id) where deleted_at is null;

-- =============================================================================
-- F) appointments
-- =============================================================================

create table if not exists appointments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  patient_id uuid not null references patients (id) on delete restrict,
  appointment_at timestamptz not null,
  status text not null,
  appointment_type text,
  notes text,
  created_by uuid references profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists idx_appointments_tenant on appointments (tenant_id);
create index if not exists idx_appointments_patient on appointments (patient_id);
create index if not exists idx_appointments_at on appointments (tenant_id, appointment_at);

-- =============================================================================
-- G) clinical_encounters
-- =============================================================================

create table if not exists clinical_encounters (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  patient_id uuid not null references patients (id) on delete restrict,
  appointment_id uuid references appointments (id) on delete set null,
  encounter_date timestamptz not null default now(),
  visit_type text,
  status text,
  diagnosis_summary text,
  treatment_plan_summary text,
  clinical_data jsonb not null default '{}'::jsonb,
  internal_doctor_note text, -- RESTRICTED: doctor_admin only via RLS/view
  created_by uuid references profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists idx_clinical_encounters_tenant on clinical_encounters (tenant_id);
create index if not exists idx_clinical_encounters_patient on clinical_encounters (patient_id);
create index if not exists idx_clinical_encounters_date on clinical_encounters (tenant_id, encounter_date);

-- Safe projection for assistant / physio / nurse (no internal_doctor_note)
-- DROP required: CREATE OR REPLACE cannot change column names/order (PostgreSQL 42P16).
drop view if exists clinical_encounter_operational_summary;

create view clinical_encounter_operational_summary as
select
  id,
  tenant_id,
  patient_id,
  appointment_id,
  encounter_date,
  visit_type,
  status,
  diagnosis_summary,
  treatment_plan_summary,
  clinical_data,
  created_by,
  created_at,
  updated_at,
  deleted_at
from clinical_encounters;

-- =============================================================================
-- H) patient_files
-- =============================================================================

create table if not exists patient_files (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  patient_id uuid not null references patients (id) on delete cascade,
  file_name text not null,
  file_type text,
  mime_type text,
  storage_path text not null, -- {tenant_id}/patients/{patient_id}/files/{file_id}/{filename}
  size_bytes bigint,
  created_by uuid references profiles (id),
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists idx_patient_files_tenant on patient_files (tenant_id);
create index if not exists idx_patient_files_patient on patient_files (patient_id);

-- =============================================================================
-- I) pdf_outputs
-- =============================================================================

create table if not exists pdf_outputs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  patient_id uuid not null references patients (id) on delete cascade,
  document_type text not null,
  source_module text,
  source_record_id uuid,
  storage_path text, -- {tenant_id}/patients/{patient_id}/pdf/{pdf_output_id}.pdf
  status text not null default 'draft',
  created_by uuid references profiles (id),
  created_at timestamptz not null default now()
);

create index if not exists idx_pdf_outputs_tenant on pdf_outputs (tenant_id);
create index if not exists idx_pdf_outputs_patient on pdf_outputs (patient_id);

-- =============================================================================
-- J) audit_logs (append-only — no UPDATE/DELETE for app roles)
-- =============================================================================

create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  actor_profile_id uuid references profiles (id),
  action text not null,
  module text not null,
  record_id uuid,
  patient_id uuid references patients (id),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_audit_logs_tenant on audit_logs (tenant_id, created_at desc);

-- =============================================================================
-- K) subscriptions
-- =============================================================================

create table if not exists subscriptions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  plan_key text not null default 'demo', -- demo | starter | pro
  status text not null default 'active'
    check (status in ('active', 'trialing', 'past_due', 'canceled')),
  current_period_start timestamptz,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id)
);

-- =============================================================================
-- L) usage_limits
-- =============================================================================

create table if not exists usage_limits (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  metric_key text not null, -- e.g. patient_records
  limit_value int not null,
  period text not null default 'lifetime', -- lifetime | monthly
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, metric_key, period)
);

-- Demo draft seed (uncomment on review):
-- insert into usage_limits (tenant_id, metric_key, limit_value, period)
-- select id, 'patient_records', 3, 'lifetime' from tenants limit 1;

-- =============================================================================
-- M) usage_events
-- =============================================================================

create table if not exists usage_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  metric_key text not null,
  quantity int not null default 1,
  reference_module text,
  reference_record_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_usage_events_tenant on usage_events (tenant_id, metric_key);

-- =============================================================================
-- updated_at trigger (draft)
-- =============================================================================

create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Draft triggers (uncomment per table on apply):
-- create trigger tenants_updated_at before update on tenants
--   for each row execute function set_updated_at();

-- =============================================================================
-- RLS helper functions (DRAFT — require JWT custom claims / membership wiring)
-- WARNING: Do not use service_role on client. Server-side only for admin tasks.
-- =============================================================================

-- Assumes JWT claims: tenant_id, profile_id (set in Faz 1 Auth)
create or replace function current_profile_id()
returns uuid
language sql
stable
as $$
  select nullif(auth.jwt() ->> 'profile_id', '')::uuid;
$$;

create or replace function current_tenant_id()
returns uuid
language sql
stable
as $$
  select nullif(auth.jwt() ->> 'tenant_id', '')::uuid;
$$;

create or replace function is_tenant_member(target_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from memberships m
    where m.tenant_id = target_tenant_id
      and m.profile_id = current_profile_id()
      and m.status = 'active'
  );
$$;

create or replace function has_tenant_role(target_tenant_id uuid, allowed_roles text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from memberships m
    where m.tenant_id = target_tenant_id
      and m.profile_id = current_profile_id()
      and m.status = 'active'
      and m.role = any (allowed_roles)
  );
$$;

create or replace function has_permission(target_tenant_id uuid, permission_key text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from memberships m
    join role_permissions rp on rp.role = m.role
    where m.tenant_id = target_tenant_id
      and m.profile_id = current_profile_id()
      and m.status = 'active'
      and rp.permission_key = permission_key
  );
$$;

-- =============================================================================
-- RLS ENABLE (draft)
-- =============================================================================

alter table tenants enable row level security;
alter table profiles enable row level security;
alter table memberships enable row level security;
alter table patients enable row level security;
alter table appointments enable row level security;
alter table clinical_encounters enable row level security;
alter table patient_files enable row level security;
alter table pdf_outputs enable row level security;
alter table audit_logs enable row level security;
alter table subscriptions enable row level security;
alter table usage_limits enable row level security;
alter table usage_events enable row level security;

-- =============================================================================
-- DRAFT POLICIES — not production-final; review with permission matrix doc
-- =============================================================================

-- patients: tenant members read; write roles
-- create policy patients_select_draft on patients for select using (
--   is_tenant_member(tenant_id) and deleted_at is null
-- );
-- create policy patients_insert_draft on patients for insert with check (
--   has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
-- );
-- create policy patients_update_draft on patients for update using (
--   has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
-- );

-- clinical_encounters: full table doctor only
-- create policy ce_select_doctor_draft on clinical_encounters for select using (
--   has_tenant_role(tenant_id, array['doctor_admin']) and deleted_at is null
-- );
-- Operational summary view: grant select to roles via separate policy on view (Faz 3)

-- audit_logs: insert via trigger/edge only; select doctor_admin
-- create policy audit_select_doctor_draft on audit_logs for select using (
--   has_tenant_role(tenant_id, array['doctor_admin'])
-- );

-- Realtime: channels must filter by tenant_id + role; see docs/backend/realtime-notes.md
