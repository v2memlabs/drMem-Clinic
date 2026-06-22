-- =============================================================================
-- Post-op protocols remote v1
--
-- Prerequisite:
--   - tenant helpers / patients table
--   - surgery_procedure_notes
--   - 20260824100000_faz2_role_access_financial_helpers_v1.sql
-- =============================================================================

create table if not exists public.post_op_protocols (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  patient_id uuid not null references public.patients (id) on delete restrict,
  surgery_note_id uuid references public.surgery_procedure_notes (id) on delete set null,
  protocol_title text not null default '',
  diagnosis_or_procedure_summary text not null default '',
  phase text not null default 'genelProtokol',
  weight_bearing_status text not null default '',
  range_of_motion_limits text not null default '',
  brace_or_immobilization text not null default '',
  wound_care_notes text not null default '',
  medication_or_pain_control_notes text not null default '',
  physiotherapy_instructions text not null default '',
  exercise_restrictions text not null default '',
  red_flags text not null default '',
  control_date date,
  return_to_sport_estimate text not null default '',
  created_by uuid references public.profiles (id),
  created_by_display text,
  status text not null default 'taslak',
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint post_op_protocols_phase_check check (
    phase in (
      'erkenPostOp',
      'hafta0_2',
      'hafta2_6',
      'hafta6_12',
      'ay3VeSonrasi',
      'sporaDonus',
      'genelProtokol'
    )
  ),
  constraint post_op_protocols_status_check check (
    status in (
      'taslak',
      'aktif',
      'hastayaVerildi',
      'fizyoterapistlePaylasildi',
      'guncellenecek',
      'tamamlandi'
    )
  )
);

comment on table public.post_op_protocols is
  'Post-op takip protokolleri — tenant scoped; soft delete via deleted_at.';

create index if not exists post_op_protocols_tenant_id_idx
  on public.post_op_protocols (tenant_id);

create index if not exists post_op_protocols_patient_id_idx
  on public.post_op_protocols (patient_id);

create index if not exists post_op_protocols_surgery_note_id_idx
  on public.post_op_protocols (surgery_note_id)
  where surgery_note_id is not null;

create index if not exists post_op_protocols_created_at_idx
  on public.post_op_protocols (tenant_id, created_at desc)
  where deleted_at is null;

create index if not exists post_op_protocols_status_idx
  on public.post_op_protocols (tenant_id, status)
  where deleted_at is null;

create index if not exists post_op_protocols_phase_idx
  on public.post_op_protocols (tenant_id, phase)
  where deleted_at is null;

drop trigger if exists post_op_protocols_updated_at on public.post_op_protocols;
create trigger post_op_protocols_updated_at
  before update on public.post_op_protocols
  for each row execute function public.set_updated_at();

alter table public.post_op_protocols enable row level security;

drop policy if exists post_op_protocols_select_role_access_v1 on public.post_op_protocols;
create policy post_op_protocols_select_role_access_v1
  on public.post_op_protocols
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_post_op_protocols')
  );

drop policy if exists post_op_protocols_insert_role_access_v1 on public.post_op_protocols;
create policy post_op_protocols_insert_role_access_v1
  on public.post_op_protocols
  for insert
  to authenticated
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_post_op_protocols')
    and exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
    and (
      surgery_note_id is null
      or exists (
        select 1
        from public.surgery_procedure_notes s
        where s.id = surgery_note_id
          and s.tenant_id = tenant_id
          and s.deleted_at is null
      )
    )
  );

drop policy if exists post_op_protocols_update_role_access_v1 on public.post_op_protocols;
create policy post_op_protocols_update_role_access_v1
  on public.post_op_protocols
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_post_op_protocols')
  )
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_post_op_protocols')
    and exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
    and (
      surgery_note_id is null
      or exists (
        select 1
        from public.surgery_procedure_notes s
        where s.id = surgery_note_id
          and s.tenant_id = tenant_id
          and s.deleted_at is null
      )
    )
  );
