-- Draft migration — NOT APPLIED YET (superseded)
-- Superseded by: 20260521100000_draft_saas_schema_rls_v1.sql
-- drMem Clinic SaaS schema taslagi (Supabase PostgreSQL + RLS hedefi)
-- Bu dosya referans amaclidir; otomatik deploy edilmez.

-- extensions
-- create extension if not exists "pgcrypto";

-- =============================================================================
-- TENANT / AUTH
-- =============================================================================

create table if not exists tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  specialty text,
  settings_json jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists memberships (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  role text not null check (role in ('doctor', 'assistant', 'physiotherapist', 'nurse')),
  status text not null default 'active' check (status in ('active', 'invited', 'disabled')),
  created_at timestamptz not null default now(),
  unique (tenant_id, user_id)
);

-- =============================================================================
-- RBAC (minimal seed — genisletilebilir)
-- =============================================================================

create table if not exists permissions (
  key text primary key,
  description text
);

create table if not exists role_permissions (
  role text not null,
  permission_key text not null references permissions (key),
  primary key (role, permission_key)
);

-- =============================================================================
-- CORE CLINICAL (tenant_id zorunlu)
-- =============================================================================

create table if not exists patients (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  file_number text not null,
  first_name text not null,
  last_name text not null,
  phone text,
  birth_date date,
  identity_type text,
  identity_number text,
  insurance_json jsonb,
  clinical_meta jsonb,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, file_number)
);

create table if not exists appointments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  patient_id uuid not null references patients (id) on delete cascade,
  appointment_at timestamptz not null,
  status text not null,
  type text,
  reason text,
  duration_minutes int,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =============================================================================
-- AUDIT (append-only hedef)
-- =============================================================================

create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  actor_user_id uuid references profiles (id),
  action_type text not null,
  module text not null,
  patient_id uuid references patients (id),
  description text,
  payload jsonb,
  created_at timestamptz not null default now()
);

-- =============================================================================
-- RLS (DRAFT — policies disabled until Faz 1)
-- =============================================================================
-- alter table patients enable row level security;
-- create policy patients_tenant_select on patients for select using (
--   tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
--   and exists (
--     select 1 from memberships m
--     where m.tenant_id = patients.tenant_id
--       and m.user_id = auth.uid()
--       and m.status = 'active'
--   )
-- );
-- Hassas alanlar (clinical_encounters.internal_doctor_note) ayri view/policy ile Faz 3.
