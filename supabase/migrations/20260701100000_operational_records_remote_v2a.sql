-- =============================================================================
-- Operational Records Remote v2a — payments + consents
--
-- Prerequisite: 20260521100000_draft_saas_schema_rls_v1.sql
--               20260522100000_draft_rls_policies_v1.sql (RLS helpers)
--
-- Scope: payments, consents tables + RLS (doctor_admin, assistant_secretary)
-- Not included: inventory, audit triggers, timeline projection
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) payments
-- -----------------------------------------------------------------------------

create table if not exists payments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  patient_id uuid not null references patients (id) on delete restrict,
  service_type text not null,
  total_amount numeric(12, 2) not null,
  paid_amount numeric(12, 2) not null default 0,
  payment_method text not null,
  payment_status text not null,
  invoice_status text not null,
  transaction_date timestamptz not null,
  notes text,
  created_by uuid references profiles (id),
  recorded_by_display text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint payments_total_amount_nonneg check (total_amount >= 0),
  constraint payments_paid_amount_nonneg check (paid_amount >= 0),
  constraint payments_paid_lte_total check (paid_amount <= total_amount)
);

comment on table payments is
  'Klinik ödeme kayıtları — tenant scoped; soft delete via deleted_at.';

create index if not exists payments_tenant_id_idx
  on payments (tenant_id);

create index if not exists payments_patient_id_idx
  on payments (patient_id);

create index if not exists payments_transaction_date_idx
  on payments (tenant_id, transaction_date desc);

create index if not exists payments_deleted_at_idx
  on payments (tenant_id, deleted_at)
  where deleted_at is null;

-- -----------------------------------------------------------------------------
-- 2) consents
-- -----------------------------------------------------------------------------

create table if not exists consents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  patient_id uuid not null references patients (id) on delete restrict,
  consent_type text not null,
  status text not null,
  given_at timestamptz,
  expires_at timestamptz,
  document_file_name text,
  notes text,
  patient_file_id uuid references patient_files (id) on delete set null,
  created_by uuid references profiles (id),
  recorded_by_display text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table consents is
  'Hasta onam kayıtları — tenant scoped; soft delete via deleted_at.';

create index if not exists consents_tenant_id_idx
  on consents (tenant_id);

create index if not exists consents_patient_id_idx
  on consents (patient_id);

create index if not exists consents_status_idx
  on consents (tenant_id, status)
  where deleted_at is null;

create index if not exists consents_deleted_at_idx
  on consents (tenant_id, deleted_at)
  where deleted_at is null;

-- -----------------------------------------------------------------------------
-- 3) updated_at triggers (reuse set_updated_at from draft schema)
-- -----------------------------------------------------------------------------

drop trigger if exists payments_updated_at on payments;
create trigger payments_updated_at
  before update on payments
  for each row execute function set_updated_at();

drop trigger if exists consents_updated_at on consents;
create trigger consents_updated_at
  before update on consents
  for each row execute function set_updated_at();

-- -----------------------------------------------------------------------------
-- 4) RLS — payments
-- -----------------------------------------------------------------------------

alter table payments enable row level security;

drop policy if exists payments_select_staff_v2a on payments;
create policy payments_select_staff_v2a
  on payments
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

drop policy if exists payments_insert_staff_v2a on payments;
create policy payments_insert_staff_v2a
  on payments
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and exists (
      select 1
      from patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );

drop policy if exists payments_update_staff_v2a on payments;
create policy payments_update_staff_v2a
  on payments
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and exists (
      select 1
      from patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );

-- -----------------------------------------------------------------------------
-- 5) RLS — consents
-- -----------------------------------------------------------------------------

alter table consents enable row level security;

drop policy if exists consents_select_staff_v2a on consents;
create policy consents_select_staff_v2a
  on consents
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

drop policy if exists consents_insert_staff_v2a on consents;
create policy consents_insert_staff_v2a
  on consents
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and exists (
      select 1
      from patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );

drop policy if exists consents_update_staff_v2a on consents;
create policy consents_update_staff_v2a
  on consents
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
    and exists (
      select 1
      from patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
  );
