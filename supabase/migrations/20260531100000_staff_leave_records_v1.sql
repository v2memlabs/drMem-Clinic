-- Personel izin kayıtları v1 — tenant-scoped, availability entegrasyonu yok.

create table if not exists staff_leave_records (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  profile_id uuid null,
  staff_display_name text not null,
  role_label text null,
  leave_type text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  note text null,
  status text not null default 'active',
  created_by uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  cancelled_at timestamptz null,
  constraint staff_leave_records_ends_after_start check (ends_at > starts_at),
  constraint staff_leave_records_note_len check (
    note is null or char_length(note) <= 500
  ),
  constraint staff_leave_records_leave_type_check check (
    leave_type in (
      'annual',
      'sick',
      'administrative',
      'meeting_training',
      'other'
    )
  ),
  constraint staff_leave_records_status_check check (
    status in ('active', 'cancelled')
  )
);

comment on table staff_leave_records is
  'Klinik personel izin/yokluk kayıtları (v1: randevu availability etkisi yok).';

create index if not exists idx_staff_leave_records_tenant_starts
  on staff_leave_records (tenant_id, starts_at desc);

create index if not exists idx_staff_leave_records_tenant_status
  on staff_leave_records (tenant_id, status)
  where status = 'active';

alter table staff_leave_records enable row level security;

drop policy if exists staff_leave_records_select_staff_v1 on staff_leave_records;
create policy staff_leave_records_select_staff_v1
  on staff_leave_records
  for select
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary']
    )
  );

drop policy if exists staff_leave_records_insert_doctor_v1 on staff_leave_records;
create policy staff_leave_records_insert_doctor_v1
  on staff_leave_records
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  );

drop policy if exists staff_leave_records_update_doctor_v1 on staff_leave_records;
create policy staff_leave_records_update_doctor_v1
  on staff_leave_records
  for update
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin'])
  );
