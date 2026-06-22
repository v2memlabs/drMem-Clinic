-- =============================================================================
-- Payment performance RPC v1
--
-- Adds server-side payment list filtering and aggregate payment statistics.
-- Functions are SECURITY INVOKER by default, so payments/patients RLS still apply.
-- =============================================================================

create schema if not exists extensions;
create extension if not exists pg_trgm with schema extensions;

create index if not exists payments_tenant_service_type_idx
  on public.payments (tenant_id, service_type)
  where deleted_at is null;

create index if not exists payments_tenant_payment_status_idx
  on public.payments (tenant_id, payment_status)
  where deleted_at is null;

create index if not exists payments_tenant_payment_method_idx
  on public.payments (tenant_id, payment_method)
  where deleted_at is null;

create index if not exists payments_open_balance_idx
  on public.payments (tenant_id, patient_id, transaction_date)
  where deleted_at is null
    and payment_status not in ('iptal', 'iade')
    and total_amount > paid_amount;

create index if not exists payments_notes_trgm_idx
  on public.payments
  using gin (lower(coalesce(notes, '')) extensions.gin_trgm_ops)
  where deleted_at is null;

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

create or replace function public.get_payment_statistics_v1(
  p_scope text default 'month',
  p_year integer default extract(year from timezone('Europe/Istanbul', now()))::integer,
  p_month integer default extract(month from timezone('Europe/Istanbul', now()))::integer
)
returns table (
  period_label text,
  total_accrual numeric,
  total_collected numeric,
  open_balance_all_time numeric,
  payment_count integer,
  patient_count integer,
  outstanding_patient_count integer,
  collected_by_service jsonb
)
language sql
stable
set search_path = public
as $$
  with input as (
    select
      case when p_scope = 'year' then 'year' else 'month' end as scope,
      coalesce(
        p_year,
        extract(year from timezone('Europe/Istanbul', now()))::integer
      ) as year_value,
      least(
        greatest(
          coalesce(
            p_month,
            extract(month from timezone('Europe/Istanbul', now()))::integer
          ),
          1
        ),
        12
      ) as month_value
  ),
  active_payments as (
    select pay.*
    from public.payments pay
    where pay.tenant_id = public.current_tenant_id()
      and pay.deleted_at is null
  ),
  period_payments as (
    select pay.*
    from active_payments pay
    cross join input i
    where extract(year from timezone('Europe/Istanbul', pay.transaction_date))::integer =
        i.year_value
      and (
        i.scope = 'year'
        or extract(month from timezone('Europe/Istanbul', pay.transaction_date))::integer =
          i.month_value
      )
  ),
  valid_period_payments as (
    select *
    from period_payments
    where payment_status not in ('iptal', 'iade')
  ),
  open_payments as (
    select *
    from active_payments
    where payment_status not in ('iptal', 'iade')
      and (total_amount - paid_amount) > 0.009
  ),
  service_totals as (
    select coalesce(jsonb_object_agg(service_type, collected), '{}'::jsonb) as totals
    from (
      select service_type, sum(paid_amount) as collected
      from valid_period_payments
      group by service_type
    ) grouped
  )
  select
    case
      when i.scope = 'year' then i.year_value::text
      else (
        (array[
          'Ocak',
          'Şubat',
          'Mart',
          'Nisan',
          'Mayıs',
          'Haziran',
          'Temmuz',
          'Ağustos',
          'Eylül',
          'Ekim',
          'Kasım',
          'Aralık'
        ])[i.month_value] || ' ' || i.year_value::text
      )
    end as period_label,
    coalesce((select sum(total_amount) from valid_period_payments), 0) as total_accrual,
    coalesce((select sum(paid_amount) from valid_period_payments), 0) as total_collected,
    coalesce((select sum(total_amount - paid_amount) from open_payments), 0)
      as open_balance_all_time,
    (select count(*) from period_payments)::integer as payment_count,
    (select count(distinct patient_id) from period_payments)::integer as patient_count,
    (select count(distinct patient_id) from open_payments)::integer
      as outstanding_patient_count,
    service_totals.totals as collected_by_service
  from input i
  cross join service_totals;
$$;

create or replace function public.list_payment_outstanding_alerts_v1()
returns table (
  patient_id uuid,
  patient_name text,
  total_remaining numeric,
  open_record_count integer,
  oldest_unpaid_date timestamptz
)
language sql
stable
set search_path = public
as $$
  select
    pay.patient_id,
    nullif(trim(concat_ws(' ', pat.first_name, pat.last_name)), '') as patient_name,
    sum(pay.total_amount - pay.paid_amount) as total_remaining,
    count(*)::integer as open_record_count,
    min(pay.transaction_date) as oldest_unpaid_date
  from public.payments pay
  join public.patients pat
    on pat.id = pay.patient_id
   and pat.tenant_id = pay.tenant_id
  where pay.tenant_id = public.current_tenant_id()
    and pay.deleted_at is null
    and pay.payment_status not in ('iptal', 'iade')
    and (pay.total_amount - pay.paid_amount) > 0.009
  group by pay.patient_id, pat.first_name, pat.last_name
  order by total_remaining desc, oldest_unpaid_date asc;
$$;

revoke all on function public.list_payments_filtered_v1(
  uuid,
  text,
  text,
  text,
  text,
  boolean
) from public;
revoke all on function public.get_payment_statistics_v1(text, integer, integer)
  from public;
revoke all on function public.list_payment_outstanding_alerts_v1() from public;

grant execute on function public.list_payments_filtered_v1(
  uuid,
  text,
  text,
  text,
  text,
  boolean
) to authenticated;
grant execute on function public.get_payment_statistics_v1(text, integer, integer)
  to authenticated;
grant execute on function public.list_payment_outstanding_alerts_v1()
  to authenticated;
