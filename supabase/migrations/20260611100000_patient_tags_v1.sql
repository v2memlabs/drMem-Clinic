-- Patient tags v1 — tenant-scoped tanımlar + hasta atamaları.

create table if not exists public.patient_tags (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  name text not null,
  color text not null default 'blue',
  description text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint patient_tags_color_check check (
    color in ('blue', 'green', 'orange', 'red', 'purple', 'gray', 'teal')
  ),
  constraint patient_tags_name_len check (
    char_length(trim(name)) >= 1 and char_length(trim(name)) <= 32
  )
);

create unique index if not exists patient_tags_tenant_name_active_uidx
  on public.patient_tags (tenant_id, lower(trim(name)))
  where is_active = true;

create index if not exists idx_patient_tags_tenant_active
  on public.patient_tags (tenant_id, is_active);

comment on table public.patient_tags is
  'Klinik hasta etiket tanımları (Ayarlar > Hasta ayarları).';

create table if not exists public.patient_tag_assignments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  patient_id uuid not null references public.patients (id) on delete cascade,
  tag_id uuid not null references public.patient_tags (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (patient_id, tag_id)
);

create index if not exists idx_patient_tag_assignments_patient
  on public.patient_tag_assignments (patient_id);

create index if not exists idx_patient_tag_assignments_tag
  on public.patient_tag_assignments (tag_id);

comment on table public.patient_tag_assignments is
  'Hasta ↔ etiket atamaları (tenant scope).';

alter table public.patient_tags enable row level security;
alter table public.patient_tag_assignments enable row level security;

-- patient_tags SELECT — doktor, asistan, fizyoterapist
drop policy if exists patient_tags_select_clinical_v1 on public.patient_tags;
create policy patient_tags_select_clinical_v1
  on public.patient_tags
  for select
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary', 'physiotherapist']
    )
  );

drop policy if exists patient_tags_insert_doctor_assistant_v1 on public.patient_tags;
create policy patient_tags_insert_doctor_assistant_v1
  on public.patient_tags
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
  );

drop policy if exists patient_tags_update_doctor_assistant_v1 on public.patient_tags;
create policy patient_tags_update_doctor_assistant_v1
  on public.patient_tags
  for update
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
  );

-- patient_tag_assignments SELECT
drop policy if exists patient_tag_assignments_select_clinical_v1 on public.patient_tag_assignments;
create policy patient_tag_assignments_select_clinical_v1
  on public.patient_tag_assignments
  for select
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(
      tenant_id,
      array['doctor_admin', 'assistant_secretary', 'physiotherapist']
    )
  );

drop policy if exists patient_tag_assignments_insert_doctor_assistant_v1 on public.patient_tag_assignments;
create policy patient_tag_assignments_insert_doctor_assistant_v1
  on public.patient_tag_assignments
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
    and exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.tenant_id = tenant_id
        and p.deleted_at is null
    )
    and exists (
      select 1
      from public.patient_tags t
      where t.id = tag_id
        and t.tenant_id = tenant_id
        and t.is_active = true
    )
  );

drop policy if exists patient_tag_assignments_delete_doctor_assistant_v1 on public.patient_tag_assignments;
create policy patient_tag_assignments_delete_doctor_assistant_v1
  on public.patient_tag_assignments
  for delete
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'assistant_secretary'])
  );
