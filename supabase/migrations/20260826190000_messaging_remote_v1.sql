-- =============================================================================
-- Messaging remote v1 — message templates + sent message records
--
-- Prerequisite:
--   - patients, tenant helpers
--   - 20260824100000_faz2_role_access_financial_helpers_v1.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Message templates
-- ---------------------------------------------------------------------------

create table if not exists public.message_templates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  title text not null,
  channel text not null,
  category text not null,
  content text not null default '',
  is_active boolean not null default true,
  created_by uuid references public.profiles (id),
  created_by_display text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint message_templates_channel_check check (
    channel in ('whatsapp', 'sms', 'email')
  ),
  constraint message_templates_category_check check (
    category in (
      'randevu_hatirlatma',
      'kontrol_hatirlatma',
      'randevu_degisim',
      'konum_bilgisi',
      'ameliyat_oncesi_hazirlik',
      'ameliyat_sonrasi_oneri',
      'egzersiz_programi',
      'fizyoterapi_yonlendirme',
      'pdf_bilgilendirme',
      'genel_bilgilendirme'
    )
  )
);

comment on table public.message_templates is
  'Mesaj şablonları — tenant scoped; soft delete via deleted_at.';

create index if not exists message_templates_tenant_id_idx
  on public.message_templates (tenant_id);

create index if not exists message_templates_created_at_idx
  on public.message_templates (tenant_id, created_at desc)
  where deleted_at is null;

create index if not exists message_templates_channel_idx
  on public.message_templates (tenant_id, channel)
  where deleted_at is null;

create index if not exists message_templates_category_idx
  on public.message_templates (tenant_id, category)
  where deleted_at is null;

drop trigger if exists message_templates_updated_at on public.message_templates;
create trigger message_templates_updated_at
  before update on public.message_templates
  for each row execute function public.set_updated_at();

alter table public.message_templates enable row level security;

drop policy if exists message_templates_select_role_access_v1 on public.message_templates;
create policy message_templates_select_role_access_v1
  on public.message_templates
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and (
      public.has_role_access(tenant_id, 'view_messages')
      or public.has_role_access(tenant_id, 'view_message_templates')
    )
  );

drop policy if exists message_templates_insert_role_access_v1 on public.message_templates;
create policy message_templates_insert_role_access_v1
  on public.message_templates
  for insert
  to authenticated
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_message_templates')
  );

drop policy if exists message_templates_update_role_access_v1 on public.message_templates;
create policy message_templates_update_role_access_v1
  on public.message_templates
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_message_templates')
  )
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_message_templates')
  );

-- ---------------------------------------------------------------------------
-- Sent messages (delivery log / prepared messages)
-- ---------------------------------------------------------------------------

create table if not exists public.sent_messages (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  patient_id uuid not null references public.patients (id) on delete restrict,
  patient_phone text not null default '',
  patient_email text,
  channel text not null,
  category text not null default '',
  template_id uuid references public.message_templates (id) on delete set null,
  template_title text not null default '',
  status text not null default 'gonderildi',
  content text not null default '',
  content_preview text not null default '',
  related_module text not null default '',
  notes text not null default '',
  sent_by uuid references public.profiles (id),
  sent_by_display text,
  sent_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint sent_messages_channel_check check (
    channel in ('whatsapp', 'sms', 'email')
  ),
  constraint sent_messages_status_check check (
    status in ('hazirlandi', 'gonderildi', 'basarisiz', 'iptal')
  )
);

comment on table public.sent_messages is
  'Mesaj gönderim kayıtları — tenant scoped; soft delete via deleted_at.';

create index if not exists sent_messages_tenant_id_idx
  on public.sent_messages (tenant_id);

create index if not exists sent_messages_patient_id_idx
  on public.sent_messages (patient_id);

create index if not exists sent_messages_sent_at_idx
  on public.sent_messages (tenant_id, sent_at desc)
  where deleted_at is null;

create index if not exists sent_messages_status_idx
  on public.sent_messages (tenant_id, status)
  where deleted_at is null;

create index if not exists sent_messages_template_id_idx
  on public.sent_messages (template_id)
  where template_id is not null;

drop trigger if exists sent_messages_updated_at on public.sent_messages;
create trigger sent_messages_updated_at
  before update on public.sent_messages
  for each row execute function public.set_updated_at();

alter table public.sent_messages enable row level security;

drop policy if exists sent_messages_select_role_access_v1 on public.sent_messages;
create policy sent_messages_select_role_access_v1
  on public.sent_messages
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_messages')
  );

drop policy if exists sent_messages_insert_role_access_v1 on public.sent_messages;
create policy sent_messages_insert_role_access_v1
  on public.sent_messages
  for insert
  to authenticated
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_messages')
    and exists (
      select 1 from public.patients p
      where p.id = patient_id and p.tenant_id = tenant_id and p.deleted_at is null
    )
    and (
      template_id is null
      or exists (
        select 1 from public.message_templates t
        where t.id = template_id
          and t.tenant_id = tenant_id
          and t.deleted_at is null
      )
    )
  );

drop policy if exists sent_messages_update_role_access_v1 on public.sent_messages;
create policy sent_messages_update_role_access_v1
  on public.sent_messages
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_messages')
  )
  with check (
    tenant_id = public.current_tenant_id()
    and public.is_tenant_member(tenant_id)
    and public.has_role_access(tenant_id, 'view_messages')
    and exists (
      select 1 from public.patients p
      where p.id = patient_id and p.tenant_id = tenant_id and p.deleted_at is null
    )
  );

-- ---------------------------------------------------------------------------
-- Default templates seed (tenant başına, tablo boşsa)
-- ---------------------------------------------------------------------------

insert into public.message_templates (
  tenant_id,
  title,
  channel,
  category,
  content,
  is_active,
  created_by_display
)
select
  base.tenant_id,
  seed.title,
  seed.channel,
  seed.category,
  seed.content,
  true,
  'Sistem'
from (
  select distinct on (t.id)
    t.id as tenant_id
  from public.tenants t
  order by t.id
) base
cross join (
  values
    (
      'Randevu Hatırlatma',
      'whatsapp',
      'randevu_hatirlatma',
      'Merhaba {{hastaAdi}}, randevunuz {{tarih}} tarihinde, saat {{saat}}''te planlanmıştır. Lütfen zamanında geliniz.'
    ),
    (
      'Kontrol Hatırlatma',
      'sms',
      'kontrol_hatirlatma',
      '{{hastaAdi}} - Kontrol randevunuz {{tarih}} tarihinde. Gerekli belgeleri yanınızda getiriniz.'
    ),
    (
      'Klinik Konum Bilgisi',
      'email',
      'konum_bilgisi',
      'Klinik adresimiz: Örnek Cad. No:1. Harita ve ulaşım bilgisi için lütfen arayın.'
    )
) as seed(title, channel, category, content)
where not exists (
  select 1
  from public.message_templates mt
  where mt.tenant_id = base.tenant_id
    and mt.deleted_at is null
);
