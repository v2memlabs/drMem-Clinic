-- =============================================================================
-- Clinical chain remote v1 — prescriptions, lab orders/templates, radiology, reports
--
-- Prerequisite:
--   - patients, clinical_encounters, tenant helpers
--   - 20260824100000_faz2_role_access_financial_helpers_v1.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Prescriptions
-- ---------------------------------------------------------------------------

create table if not exists public.prescriptions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  patient_id uuid not null references public.patients (id) on delete restrict,
  clinical_encounter_id uuid references public.clinical_encounters (id) on delete set null,
  status text not null default 'taslak',
  diagnosis text not null default '',
  medications jsonb not null default '[]'::jsonb,
  additional_notes text,
  created_by uuid references public.profiles (id),
  created_by_display text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint prescriptions_status_check check (
    status in ('taslak', 'hazirlandi', 'hastayaVerildi', 'iptal')
  ),
  constraint prescriptions_medications_array_check check (
    jsonb_typeof(medications) = 'array'
  )
);

comment on table public.prescriptions is
  'Reçeteler — tenant scoped; medications jsonb array; soft delete via deleted_at.';

create index if not exists prescriptions_tenant_id_idx
  on public.prescriptions (tenant_id);

create index if not exists prescriptions_patient_id_idx
  on public.prescriptions (patient_id);

create index if not exists prescriptions_clinical_encounter_id_idx
  on public.prescriptions (clinical_encounter_id)
  where clinical_encounter_id is not null;

create index if not exists prescriptions_created_at_idx
  on public.prescriptions (tenant_id, created_at desc)
  where deleted_at is null;

create index if not exists prescriptions_status_idx
  on public.prescriptions (tenant_id, status)
  where deleted_at is null;

drop trigger if exists prescriptions_updated_at on public.prescriptions;
create trigger prescriptions_updated_at
  before update on public.prescriptions
  for each row execute function public.set_updated_at();

alter table public.prescriptions enable row level security;

drop policy if exists prescriptions_select_role_access_v1 on public.prescriptions;
create policy prescriptions_select_role_access_v1
  on public.prescriptions
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_prescriptions')
  );

drop policy if exists prescriptions_insert_role_access_v1 on public.prescriptions;
create policy prescriptions_insert_role_access_v1
  on public.prescriptions
  for insert
  to authenticated
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_prescriptions')
    and exists (
      select 1 from public.patients p
      where p.id = patient_id and p.tenant_id = tenant_id and p.deleted_at is null
    )
    and (
      clinical_encounter_id is null
      or exists (
        select 1 from public.clinical_encounters e
        where e.id = clinical_encounter_id
          and e.tenant_id = tenant_id
          and e.deleted_at is null
      )
    )
  );

drop policy if exists prescriptions_update_role_access_v1 on public.prescriptions;
create policy prescriptions_update_role_access_v1
  on public.prescriptions
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_prescriptions')
  )
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_prescriptions')
    and exists (
      select 1 from public.patients p
      where p.id = patient_id and p.tenant_id = tenant_id and p.deleted_at is null
    )
    and (
      clinical_encounter_id is null
      or exists (
        select 1 from public.clinical_encounters e
        where e.id = clinical_encounter_id
          and e.tenant_id = tenant_id
          and e.deleted_at is null
      )
    )
  );

-- ---------------------------------------------------------------------------
-- Lab order templates
-- ---------------------------------------------------------------------------

create table if not exists public.lab_order_templates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  name text not null,
  description text,
  selected_tests jsonb not null default '[]'::jsonb,
  selected_custom_test_ids jsonb not null default '[]'::jsonb,
  default_order_reason text not null default 'preoperatifHazirlik',
  default_diagnosis text,
  default_infection_context text not null default 'yok',
  preoperative_notes text,
  ekg_notes text,
  additional_notes text,
  created_by uuid references public.profiles (id),
  created_by_display text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint lab_order_templates_order_reason_check check (
    default_order_reason in (
      'preoperatifHazirlik', 'enfeksiyonSuphesi', 'postoperatif', 'takip'
    )
  ),
  constraint lab_order_templates_infection_context_check check (
    default_infection_context in (
      'yok', 'septikArtrit', 'sellulit', 'osteomiyelit', 'endokardit', 'diger'
    )
  ),
  constraint lab_order_templates_selected_tests_array_check check (
    jsonb_typeof(selected_tests) = 'array'
  ),
  constraint lab_order_templates_custom_tests_array_check check (
    jsonb_typeof(selected_custom_test_ids) = 'array'
  )
);

comment on table public.lab_order_templates is
  'Lab istem şablonları — tenant scoped; soft delete via deleted_at.';

create index if not exists lab_order_templates_tenant_id_idx
  on public.lab_order_templates (tenant_id);

create index if not exists lab_order_templates_created_at_idx
  on public.lab_order_templates (tenant_id, created_at desc)
  where deleted_at is null;

drop trigger if exists lab_order_templates_updated_at on public.lab_order_templates;
create trigger lab_order_templates_updated_at
  before update on public.lab_order_templates
  for each row execute function public.set_updated_at();

alter table public.lab_order_templates enable row level security;

drop policy if exists lab_order_templates_select_role_access_v1 on public.lab_order_templates;
create policy lab_order_templates_select_role_access_v1
  on public.lab_order_templates
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_lab_orders')
  );

drop policy if exists lab_order_templates_insert_role_access_v1 on public.lab_order_templates;
create policy lab_order_templates_insert_role_access_v1
  on public.lab_order_templates
  for insert
  to authenticated
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'manage_lab_order_templates')
  );

drop policy if exists lab_order_templates_update_role_access_v1 on public.lab_order_templates;
create policy lab_order_templates_update_role_access_v1
  on public.lab_order_templates
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'manage_lab_order_templates')
  )
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'manage_lab_order_templates')
  );

-- ---------------------------------------------------------------------------
-- Lab orders
-- ---------------------------------------------------------------------------

create table if not exists public.lab_orders (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  patient_id uuid not null references public.patients (id) on delete restrict,
  clinical_encounter_id uuid references public.clinical_encounters (id) on delete set null,
  clinical_encounter_protocol_number text,
  status text not null default 'taslak',
  diagnosis text not null default '',
  order_reason text not null default 'preoperatifHazirlik',
  selected_tests jsonb not null default '[]'::jsonb,
  selected_custom_test_ids jsonb not null default '[]'::jsonb,
  infection_context text not null default 'yok',
  infection_notes text,
  preoperative_notes text,
  ekg_notes text,
  additional_notes text,
  template_id uuid references public.lab_order_templates (id) on delete set null,
  template_name text,
  created_by uuid references public.profiles (id),
  created_by_display text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint lab_orders_status_check check (
    status in ('taslak', 'istendi', 'tamamlandi', 'iptal')
  ),
  constraint lab_orders_order_reason_check check (
    order_reason in (
      'preoperatifHazirlik', 'enfeksiyonSuphesi', 'postoperatif', 'takip'
    )
  ),
  constraint lab_orders_infection_context_check check (
    infection_context in (
      'yok', 'septikArtrit', 'sellulit', 'osteomiyelit', 'endokardit', 'diger'
    )
  ),
  constraint lab_orders_selected_tests_array_check check (
    jsonb_typeof(selected_tests) = 'array'
  ),
  constraint lab_orders_custom_tests_array_check check (
    jsonb_typeof(selected_custom_test_ids) = 'array'
  )
);

comment on table public.lab_orders is
  'Lab istemleri — tenant scoped; soft delete via deleted_at.';

create index if not exists lab_orders_tenant_id_idx on public.lab_orders (tenant_id);
create index if not exists lab_orders_patient_id_idx on public.lab_orders (patient_id);
create index if not exists lab_orders_clinical_encounter_id_idx
  on public.lab_orders (clinical_encounter_id) where clinical_encounter_id is not null;
create index if not exists lab_orders_created_at_idx
  on public.lab_orders (tenant_id, created_at desc) where deleted_at is null;
create index if not exists lab_orders_status_idx
  on public.lab_orders (tenant_id, status) where deleted_at is null;

drop trigger if exists lab_orders_updated_at on public.lab_orders;
create trigger lab_orders_updated_at
  before update on public.lab_orders
  for each row execute function public.set_updated_at();

alter table public.lab_orders enable row level security;

drop policy if exists lab_orders_select_role_access_v1 on public.lab_orders;
create policy lab_orders_select_role_access_v1
  on public.lab_orders
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_lab_orders')
  );

drop policy if exists lab_orders_insert_role_access_v1 on public.lab_orders;
create policy lab_orders_insert_role_access_v1
  on public.lab_orders
  for insert
  to authenticated
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_lab_orders')
    and exists (
      select 1 from public.patients p
      where p.id = patient_id and p.tenant_id = tenant_id and p.deleted_at is null
    )
    and (
      clinical_encounter_id is null
      or exists (
        select 1 from public.clinical_encounters e
        where e.id = clinical_encounter_id
          and e.tenant_id = tenant_id
          and e.deleted_at is null
      )
    )
    and (
      template_id is null
      or exists (
        select 1 from public.lab_order_templates t
        where t.id = template_id
          and t.tenant_id = tenant_id
          and t.deleted_at is null
      )
    )
  );

drop policy if exists lab_orders_update_role_access_v1 on public.lab_orders;
create policy lab_orders_update_role_access_v1
  on public.lab_orders
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_lab_orders')
  )
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_lab_orders')
    and exists (
      select 1 from public.patients p
      where p.id = patient_id and p.tenant_id = tenant_id and p.deleted_at is null
    )
    and (
      clinical_encounter_id is null
      or exists (
        select 1 from public.clinical_encounters e
        where e.id = clinical_encounter_id
          and e.tenant_id = tenant_id
          and e.deleted_at is null
      )
    )
    and (
      template_id is null
      or exists (
        select 1 from public.lab_order_templates t
        where t.id = template_id
          and t.tenant_id = tenant_id
          and t.deleted_at is null
      )
    )
  );

-- ---------------------------------------------------------------------------
-- Radiology orders
-- ---------------------------------------------------------------------------

create table if not exists public.radiology_orders (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  patient_id uuid not null references public.patients (id) on delete restrict,
  clinical_encounter_id uuid references public.clinical_encounters (id) on delete set null,
  clinical_encounter_protocol_number text,
  status text not null default 'taslak',
  priority text not null default 'rutin',
  diagnosis text not null default '',
  lines jsonb not null default '[]'::jsonb,
  additional_notes text,
  created_by uuid references public.profiles (id),
  created_by_display text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint radiology_orders_status_check check (
    status in ('taslak', 'istendi', 'tamamlandi', 'iptal')
  ),
  constraint radiology_orders_priority_check check (
    priority in ('rutin', 'acil')
  ),
  constraint radiology_orders_lines_array_check check (
    jsonb_typeof(lines) = 'array'
  )
);

comment on table public.radiology_orders is
  'Radyoloji istemleri — tenant scoped; lines jsonb array; soft delete via deleted_at.';

create index if not exists radiology_orders_tenant_id_idx
  on public.radiology_orders (tenant_id);
create index if not exists radiology_orders_patient_id_idx
  on public.radiology_orders (patient_id);
create index if not exists radiology_orders_clinical_encounter_id_idx
  on public.radiology_orders (clinical_encounter_id) where clinical_encounter_id is not null;
create index if not exists radiology_orders_created_at_idx
  on public.radiology_orders (tenant_id, created_at desc) where deleted_at is null;
create index if not exists radiology_orders_status_idx
  on public.radiology_orders (tenant_id, status) where deleted_at is null;

drop trigger if exists radiology_orders_updated_at on public.radiology_orders;
create trigger radiology_orders_updated_at
  before update on public.radiology_orders
  for each row execute function public.set_updated_at();

alter table public.radiology_orders enable row level security;

drop policy if exists radiology_orders_select_role_access_v1 on public.radiology_orders;
create policy radiology_orders_select_role_access_v1
  on public.radiology_orders
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_radiology_orders')
  );

drop policy if exists radiology_orders_insert_role_access_v1 on public.radiology_orders;
create policy radiology_orders_insert_role_access_v1
  on public.radiology_orders
  for insert
  to authenticated
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_radiology_orders')
    and exists (
      select 1 from public.patients p
      where p.id = patient_id and p.tenant_id = tenant_id and p.deleted_at is null
    )
    and (
      clinical_encounter_id is null
      or exists (
        select 1 from public.clinical_encounters e
        where e.id = clinical_encounter_id
          and e.tenant_id = tenant_id
          and e.deleted_at is null
      )
    )
  );

drop policy if exists radiology_orders_update_role_access_v1 on public.radiology_orders;
create policy radiology_orders_update_role_access_v1
  on public.radiology_orders
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_radiology_orders')
  )
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_radiology_orders')
    and exists (
      select 1 from public.patients p
      where p.id = patient_id and p.tenant_id = tenant_id and p.deleted_at is null
    )
    and (
      clinical_encounter_id is null
      or exists (
        select 1 from public.clinical_encounters e
        where e.id = clinical_encounter_id
          and e.tenant_id = tenant_id
          and e.deleted_at is null
      )
    )
  );

-- ---------------------------------------------------------------------------
-- Clinical reports
-- ---------------------------------------------------------------------------

create table if not exists public.clinical_reports (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  patient_id uuid not null references public.patients (id) on delete restrict,
  clinical_encounter_id uuid references public.clinical_encounters (id) on delete set null,
  clinical_encounter_protocol_number text,
  report_number text,
  document_date_source text not null default 'belgeTarihi',
  status text not null default 'taslak',
  report_type text not null,
  diagnosis text not null default '',
  body_text text not null default '',
  type_payload jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles (id),
  created_by_display text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint clinical_reports_status_check check (
    status in ('taslak', 'hazirlandi', 'hastayaVerildi', 'iptal')
  ),
  constraint clinical_reports_type_check check (
    report_type in ('istirahat', 'durumBildirir', 'ucabilir', 'cihazKullanim', 'diger')
  ),
  constraint clinical_reports_document_date_source_check check (
    document_date_source in ('belgeTarihi', 'muayeneTarihi')
  ),
  constraint clinical_reports_type_payload_object_check check (
    jsonb_typeof(type_payload) = 'object'
  )
);

comment on table public.clinical_reports is
  'Klinik raporlar — tenant scoped; type-specific fields in type_payload jsonb.';

create index if not exists clinical_reports_tenant_id_idx
  on public.clinical_reports (tenant_id);
create index if not exists clinical_reports_patient_id_idx
  on public.clinical_reports (patient_id);
create index if not exists clinical_reports_clinical_encounter_id_idx
  on public.clinical_reports (clinical_encounter_id) where clinical_encounter_id is not null;
create index if not exists clinical_reports_created_at_idx
  on public.clinical_reports (tenant_id, created_at desc) where deleted_at is null;
create index if not exists clinical_reports_status_idx
  on public.clinical_reports (tenant_id, status) where deleted_at is null;
create index if not exists clinical_reports_report_type_idx
  on public.clinical_reports (tenant_id, report_type) where deleted_at is null;

drop trigger if exists clinical_reports_updated_at on public.clinical_reports;
create trigger clinical_reports_updated_at
  before update on public.clinical_reports
  for each row execute function public.set_updated_at();

alter table public.clinical_reports enable row level security;

drop policy if exists clinical_reports_select_role_access_v1 on public.clinical_reports;
create policy clinical_reports_select_role_access_v1
  on public.clinical_reports
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_clinical_reports')
  );

drop policy if exists clinical_reports_insert_role_access_v1 on public.clinical_reports;
create policy clinical_reports_insert_role_access_v1
  on public.clinical_reports
  for insert
  to authenticated
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_clinical_reports')
    and exists (
      select 1 from public.patients p
      where p.id = patient_id and p.tenant_id = tenant_id and p.deleted_at is null
    )
    and (
      clinical_encounter_id is null
      or exists (
        select 1 from public.clinical_encounters e
        where e.id = clinical_encounter_id
          and e.tenant_id = tenant_id
          and e.deleted_at is null
      )
    )
  );

drop policy if exists clinical_reports_update_role_access_v1 on public.clinical_reports;
create policy clinical_reports_update_role_access_v1
  on public.clinical_reports
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_clinical_reports')
  )
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'edit_clinical_reports')
    and exists (
      select 1 from public.patients p
      where p.id = patient_id and p.tenant_id = tenant_id and p.deleted_at is null
    )
    and (
      clinical_encounter_id is null
      or exists (
        select 1 from public.clinical_encounters e
        where e.id = clinical_encounter_id
          and e.tenant_id = tenant_id
          and e.deleted_at is null
      )
    )
  );
