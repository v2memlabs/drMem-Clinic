-- =============================================================================
-- Payment performance RPC v1 label fix
--
-- Corrects the Turkish search label for havale_eft in list_payments_filtered_v1.
-- =============================================================================

create or replace function public.list_payments_filtered_v1(
  p_patient_id uuid default null,
  p_query text default null,
  p_service_type text default null,
  p_payment_status text default null,
  p_payment_method text default null,
  p_operational_scope boolean default true
)
returns table (
  id uuid,
  tenant_id uuid,
  patient_id uuid,
  clinical_encounter_id uuid,
  service_type text,
  rehab_billing_mode text,
  package_session_count integer,
  source_kind text,
  total_amount numeric,
  paid_amount numeric,
  payment_method text,
  payment_status text,
  invoice_status text,
  transaction_date timestamptz,
  notes text,
  recorded_by_display text,
  created_by uuid,
  created_at timestamptz,
  patient_first_name text,
  patient_last_name text,
  patient_file_number text
)
language sql
stable
set search_path = public
as $$
  with input as (
    select
      p_patient_id as patient_id,
      nullif(lower(trim(p_query)), '') as q,
      nullif(trim(p_service_type), '') as service_type,
      nullif(trim(p_payment_status), '') as payment_status,
      nullif(trim(p_payment_method), '') as payment_method,
      coalesce(p_operational_scope, true) as operational_scope,
      date_trunc('month', timezone('Europe/Istanbul', now())) as current_month
  )
  select
    pay.id,
    pay.tenant_id,
    pay.patient_id,
    pay.clinical_encounter_id,
    pay.service_type,
    pay.rehab_billing_mode,
    pay.package_session_count,
    pay.source_kind,
    pay.total_amount,
    pay.paid_amount,
    pay.payment_method,
    pay.payment_status,
    pay.invoice_status,
    pay.transaction_date,
    pay.notes,
    pay.recorded_by_display,
    pay.created_by,
    pay.created_at,
    pat.first_name as patient_first_name,
    pat.last_name as patient_last_name,
    pat.file_number as patient_file_number
  from public.payments pay
  join public.patients pat
    on pat.id = pay.patient_id
   and pat.tenant_id = pay.tenant_id
  cross join input i
  where pay.tenant_id = public.current_tenant_id()
    and pay.deleted_at is null
    and (i.patient_id is null or pay.patient_id = i.patient_id)
    and (i.service_type is null or pay.service_type = i.service_type)
    and (i.payment_status is null or pay.payment_status = i.payment_status)
    and (i.payment_method is null or pay.payment_method = i.payment_method)
    and (
      not i.operational_scope
      or date_trunc('month', timezone('Europe/Istanbul', pay.transaction_date)) =
        i.current_month
      or (
        pay.payment_status not in ('iptal', 'iade')
        and (pay.total_amount - pay.paid_amount) > 0.009
      )
    )
    and (
      i.q is null
      or lower(coalesce(pat.first_name, '')) like '%' || i.q || '%'
      or lower(coalesce(pat.last_name, '')) like '%' || i.q || '%'
      or lower(coalesce(pat.file_number, '')) like '%' || i.q || '%'
      or lower(coalesce(pay.notes, '')) like '%' || i.q || '%'
      or lower(coalesce(pay.service_type, '')) like '%' || i.q || '%'
      or lower(coalesce(pay.payment_status, '')) like '%' || i.q || '%'
      or lower(coalesce(pay.payment_method, '')) like '%' || i.q || '%'
      or lower(
        case pay.service_type
          when 'muayene' then 'muayene'
          when 'kontrol' then 'kontrol'
          when 'enjeksiyon_girisim' then 'enjeksiyon girişim'
          when 'ameliyat_girisim_notu' then 'ameliyat girişim notu'
          when 'fizyoterapi_seansi' then 'fizyoterapi seansı'
          when 'rehabilitasyon' then 'rehabilitasyon'
          when 'rapor_belge' then 'rapor belge'
          else 'diğer'
        end
      ) like '%' || i.q || '%'
      or lower(
        case pay.payment_status
          when 'odendi' then 'ödendi'
          when 'kismi_odendi' then 'kısmi ödendi'
          when 'bekliyor' then 'bekliyor'
          when 'iptal' then 'iptal'
          else 'iade'
        end
      ) like '%' || i.q || '%'
      or lower(
        case pay.payment_method
          when 'nakit' then 'nakit'
          when 'kredi_karti' then 'kredi kartı'
          when 'havale_eft' then 'havale eft'
          when 'karma' then 'karma'
          else 'belirtilmedi'
        end
      ) like '%' || i.q || '%'
    )
  order by pay.transaction_date desc, pay.id desc;
$$;
