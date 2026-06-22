-- Payment workflow extensions v1
-- clinical encounter link, rehab billing, staff notifications, expanded RLS

alter table payments
  add column if not exists clinical_encounter_id uuid
    references clinical_encounters (id) on delete set null;

alter table payments
  add column if not exists rehab_billing_mode text;

alter table payments
  add column if not exists package_session_count integer;

alter table payments
  add column if not exists source_kind text not null default 'manual';

create index if not exists payments_clinical_encounter_id_idx
  on payments (clinical_encounter_id)
  where deleted_at is null and clinical_encounter_id is not null;

create table if not exists payment_staff_notifications (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  payment_id uuid not null references payments (id) on delete cascade,
  patient_id uuid not null references patients (id) on delete cascade,
  title text not null,
  body text not null,
  created_by_role text not null,
  created_by_display text,
  read_at timestamptz,
  read_by_display text,
  created_at timestamptz not null default now()
);

create index if not exists payment_staff_notifications_tenant_unread_idx
  on payment_staff_notifications (tenant_id, read_at)
  where read_at is null;

alter table payment_staff_notifications enable row level security;

drop policy if exists payment_staff_notifications_assistant_v1
  on payment_staff_notifications;
create policy payment_staff_notifications_assistant_v1
  on payment_staff_notifications
  for all
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary'])
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['assistant_secretary'])
  );

-- Physiotherapist + nurse: payment insert/select (no update unless extended later)
drop policy if exists payments_select_physio_nurse_v1 on payments;
create policy payments_select_physio_nurse_v1
  on payments
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['physiotherapist', 'nurse']
    )
  );

drop policy if exists payments_insert_physio_v1 on payments;
create policy payments_insert_physio_v1
  on payments
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and exists (
      select 1 from patients p
      where p.id = patient_id and p.tenant_id = tenant_id and p.deleted_at is null
    )
  );

drop policy if exists payments_update_physio_own_v1 on payments;
create policy payments_update_physio_own_v1
  on payments
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and created_by = current_profile_id()
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['physiotherapist'])
    and created_by = current_profile_id()
  );
