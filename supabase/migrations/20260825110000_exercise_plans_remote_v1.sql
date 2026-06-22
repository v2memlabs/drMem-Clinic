-- =============================================================================
-- Exercise plans remote v1
--
-- Prerequisite:
--   - tenant helpers / patients table
--   - 20260824100000_faz2_role_access_financial_helpers_v1.sql
-- =============================================================================

create table if not exists public.exercise_plans (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  patient_id uuid not null references public.patients (id) on delete restrict,
  referral_id uuid references public.physiotherapy_referrals (id) on delete set null,
  title text not null default '',
  diagnosis_summary text not null default '',
  phase text not null,
  goal text not null default '',
  exercises jsonb not null default '[]'::jsonb,
  home_instructions text not null default '',
  warnings text not null default '',
  doctor_approved boolean not null default false,
  control_date date,
  status text not null default 'taslak',
  notes text not null default '',
  created_by uuid references public.profiles (id),
  created_by_display text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint exercise_plans_phase_check check (
    phase in (
      'erkenRehabilitasyon',
      'ortaRehabilitasyon',
      'ileriRehabilitasyon',
      'sporaDonus',
      'koruyucu'
    )
  ),
  constraint exercise_plans_status_check check (
    status in (
      'taslak',
      'aktif',
      'hastayaVerildi',
      'doktorOnayBekliyor',
      'tamamlandi',
      'arsiv'
    )
  ),
  constraint exercise_plans_exercises_array_check check (
    jsonb_typeof(exercises) = 'array'
  )
);

comment on table public.exercise_plans is
  'Egzersiz programları — tenant scoped; exercises jsonb array; soft delete via deleted_at.';

create index if not exists exercise_plans_tenant_id_idx
  on public.exercise_plans (tenant_id);

create index if not exists exercise_plans_patient_id_idx
  on public.exercise_plans (patient_id);

create index if not exists exercise_plans_referral_id_idx
  on public.exercise_plans (referral_id)
  where referral_id is not null;

create index if not exists exercise_plans_created_at_idx
  on public.exercise_plans (tenant_id, created_at desc)
  where deleted_at is null;

create index if not exists exercise_plans_status_idx
  on public.exercise_plans (tenant_id, status)
  where deleted_at is null;

create index if not exists exercise_plans_phase_idx
  on public.exercise_plans (tenant_id, phase)
  where deleted_at is null;

drop trigger if exists exercise_plans_updated_at on public.exercise_plans;
create trigger exercise_plans_updated_at
  before update on public.exercise_plans
  for each row execute function public.set_updated_at();

alter table public.exercise_plans enable row level security;

drop policy if exists exercise_plans_select_role_access_v1 on public.exercise_plans;
create policy exercise_plans_select_role_access_v1
  on public.exercise_plans
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_exercise_plans')
  );

drop policy if exists exercise_plans_insert_role_access_v1 on public.exercise_plans;
create policy exercise_plans_insert_role_access_v1
  on public.exercise_plans
  for insert
  to authenticated
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_exercise_plans')
    and exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
    and (
      referral_id is null
      or exists (
        select 1
        from public.physiotherapy_referrals r
        where r.id = referral_id
          and r.tenant_id = tenant_id
          and r.deleted_at is null
      )
    )
  );

drop policy if exists exercise_plans_update_role_access_v1 on public.exercise_plans;
create policy exercise_plans_update_role_access_v1
  on public.exercise_plans
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_exercise_plans')
  )
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_exercise_plans')
    and exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
    and (
      referral_id is null
      or exists (
        select 1
        from public.physiotherapy_referrals r
        where r.id = referral_id
          and r.tenant_id = tenant_id
          and r.deleted_at is null
      )
    )
  );
