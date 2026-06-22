-- =============================================================================
-- Operasyonel demo seed v1 — staging boş tablolar için örnek kayıt
-- Prerequisite: patients + operasyonel tablolar (imaging, surgery, exercise, post-op, payments, inventory)
-- Idempotent: tenant başına yalnızca ilgili tablo boşsa ekler
-- =============================================================================

-- Görüntüleme notu (tenant başına 1)
insert into public.imaging_notes (
  tenant_id,
  patient_id,
  imaging_type,
  imaging_date,
  imaging_center,
  body_region,
  side,
  report_summary,
  doctor_comment,
  related_diagnosis
)
select
  base.tenant_id,
  base.patient_id,
  'mr',
  current_date - 7,
  'Demo MR Merkezi',
  'diz',
  'sol',
  'Medial menisküs dejenerasyonu — demo seed kaydı',
  'Klinik ile uyumlu',
  'Medial menisküs dejenerasyonu'
from (
  select distinct on (p.tenant_id)
    p.tenant_id,
    p.id as patient_id
  from public.patients p
  where p.deleted_at is null
  order by p.tenant_id, p.created_at
) base
where not exists (
  select 1
  from public.imaging_notes i
  where i.tenant_id = base.tenant_id
    and i.deleted_at is null
);

-- Ameliyat / girişim notu (tenant başına 1)
insert into public.surgery_procedure_notes (
  tenant_id,
  patient_id,
  procedure_date,
  procedure_type,
  body_region,
  side,
  diagnosis,
  procedure_name,
  post_op_recommendations,
  surgeon_name
)
select
  base.tenant_id,
  base.patient_id,
  current_date - 14,
  'artroskopi',
  'diz',
  'sol',
  'Medial menisküs yırtığı',
  'Artroskopik parsiyel menisektomi — demo',
  'Erken mobilizasyon, ağrı kontrolü',
  'Dr. Demo'
from (
  select distinct on (p.tenant_id)
    p.tenant_id,
    p.id as patient_id
  from public.patients p
  where p.deleted_at is null
  order by p.tenant_id, p.created_at
) base
where not exists (
  select 1
  from public.surgery_procedure_notes s
  where s.tenant_id = base.tenant_id
    and s.deleted_at is null
);

-- Post-op protokol (tenant başına 1; surgery notu varsa bağla)
insert into public.post_op_protocols (
  tenant_id,
  patient_id,
  surgery_note_id,
  protocol_title,
  diagnosis_or_procedure_summary,
  phase,
  weight_bearing_status,
  physiotherapy_instructions,
  status
)
select
  base.tenant_id,
  base.patient_id,
  sn.id,
  'Diz artroskopi post-op — demo',
  'Artroskopik menisektomi sonrası erken rehabilitasyon',
  'hafta0_2',
  'Kısmi yük verme',
  'Erken ROM ve quadriceps aktivasyonu',
  'aktif'
from (
  select distinct on (p.tenant_id)
    p.tenant_id,
    p.id as patient_id
  from public.patients p
  where p.deleted_at is null
  order by p.tenant_id, p.created_at
) base
left join lateral (
  select s.id
  from public.surgery_procedure_notes s
  where s.tenant_id = base.tenant_id
    and s.patient_id = base.patient_id
    and s.deleted_at is null
  order by s.procedure_date desc
  limit 1
) sn on true
where not exists (
  select 1
  from public.post_op_protocols pop
  where pop.tenant_id = base.tenant_id
    and pop.deleted_at is null
);

-- Egzersiz programı (tenant başına 1)
insert into public.exercise_plans (
  tenant_id,
  patient_id,
  title,
  diagnosis_summary,
  phase,
  goal,
  exercises,
  home_instructions,
  status,
  doctor_approved
)
select
  base.tenant_id,
  base.patient_id,
  'Diz rehabilitasyon — demo program',
  'Post-op menisektomi',
  'erkenRehabilitasyon',
  'Ağrısız ROM ve quadriceps gücü',
  '[{"name":"Quadriceps izometrik","sets":3,"reps":10,"notes":"Demo seed"}]'::jsonb,
  'Günde 2 kez, ağrı eşiğinde',
  'aktif',
  true
from (
  select distinct on (p.tenant_id)
    p.tenant_id,
    p.id as patient_id
  from public.patients p
  where p.deleted_at is null
  order by p.tenant_id, p.created_at
) base
where not exists (
  select 1
  from public.exercise_plans ep
  where ep.tenant_id = base.tenant_id
    and ep.deleted_at is null
);

-- Ödeme kaydı (tenant başına 1)
insert into public.payments (
  tenant_id,
  patient_id,
  service_type,
  total_amount,
  paid_amount,
  payment_method,
  payment_status,
  invoice_status,
  transaction_date,
  notes,
  recorded_by_display
)
select
  base.tenant_id,
  base.patient_id,
  'muayene',
  500.00,
  500.00,
  'nakit',
  'odendi',
  'kesildi',
  now() - interval '3 days',
  'Demo ödeme kaydı — operasyonel seed',
  'Demo Kasa'
from (
  select distinct on (p.tenant_id)
    p.tenant_id,
    p.id as patient_id
  from public.patients p
  where p.deleted_at is null
  order by p.tenant_id, p.created_at
) base
where not exists (
  select 1
  from public.payments pay
  where pay.tenant_id = base.tenant_id
    and pay.deleted_at is null
);

-- Stok kartı (tenant başına 2 kalem)
insert into public.inventory_items (
  tenant_id,
  name,
  category,
  unit,
  current_quantity,
  minimum_quantity,
  location,
  supplier_name,
  notes
)
select
  base.tenant_id,
  v.name,
  v.category,
  v.unit,
  v.current_quantity,
  v.minimum_quantity,
  v.location,
  v.supplier_name,
  v.notes
from (
  select distinct on (p.tenant_id) p.tenant_id
  from public.patients p
  where p.deleted_at is null
  order by p.tenant_id, p.created_at
) base
cross join (
  values
    (
      'Steril eldiven (M)',
      'sarf',
      'kutu',
      12::numeric,
      5::numeric,
      'Depo A',
      'Demo Medikal',
      'Operasyonel seed'
    ),
    (
      'Betadin solüsyon',
      'sarf',
      'adet',
      8::numeric,
      3::numeric,
      'Depo A',
      'Demo Medikal',
      'Operasyonel seed'
    )
) as v(
  name,
  category,
  unit,
  current_quantity,
  minimum_quantity,
  location,
  supplier_name,
  notes
)
where not exists (
  select 1
  from public.inventory_items ii
  where ii.tenant_id = base.tenant_id
    and ii.deleted_at is null
);
