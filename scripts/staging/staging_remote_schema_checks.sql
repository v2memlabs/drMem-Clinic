-- =============================================================================
-- Staging Remote Schema Checks v1
-- DrMem Clinic — FTR + Operational + PDF/storage structural verification
--
-- WHERE TO RUN: Supabase SQL Editor (staging project)
-- ROLE: service_role / postgres OK (structural only; RLS not exercised here)
--
-- DO NOT RUN ON PRODUCTION without explicit approval.
-- Output: copy result sets into staging verification report.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0) Migration tracking (Supabase CLI)
-- -----------------------------------------------------------------------------

select
  version,
  name
from supabase_migrations.schema_migrations
where version in (
  '20260601100000',
  '20260701100000',
  '20260702100000',
  '20260703100000',
  '20260704100000'
)
order by version;

-- Expected: 5 rows (auth hotfix + v2a + v2b + ftr referral + ftr session)
-- Missing row → run `supabase db push` / pipeline deploy on staging

-- -----------------------------------------------------------------------------
-- 1) Auth / RLS helper functions
-- -----------------------------------------------------------------------------

select
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as args,
  p.prosecdef as security_definer
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'current_auth_user_id',
    'current_profile_id',
    'current_tenant_id',
    'is_tenant_member',
    'has_tenant_role',
    'record_inventory_movement',
    'set_updated_at'
  )
order by p.proname;

-- Expected: all listed functions exist; record_inventory_movement security_definer = true

-- -----------------------------------------------------------------------------
-- 2) Table / RLS / policy summary
-- Output: table_name | exists | rls_enabled | policy_count | notes
-- -----------------------------------------------------------------------------

with expected_tables as (
  select unnest(array[
    'tenants',
    'profiles',
    'memberships',
    'patients',
    'appointments',
    'clinical_encounters',
    'payments',
    'consents',
    'inventory_items',
    'inventory_movements',
    'physiotherapy_referrals',
    'physiotherapy_sessions',
    'patient_files',
    'pdf_outputs'
  ]) as table_name
),
table_exists as (
  select
    t.table_name,
    (t.table_name is not null) as exists
  from expected_tables e
  left join information_schema.tables t
    on t.table_schema = 'public'
   and t.table_name = e.table_name
   and t.table_type = 'BASE TABLE'
),
rls_flags as (
  select
    c.relname as table_name,
    c.relrowsecurity as rls_enabled
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
),
policy_counts as (
  select
    tablename as table_name,
    count(*)::int as policy_count
  from pg_policies
  where schemaname = 'public'
  group by tablename
)
select
  e.table_name,
  coalesce(te.exists, false) as exists,
  coalesce(r.rls_enabled, false) as rls_enabled,
  coalesce(p.policy_count, 0) as policy_count,
  case
    when not coalesce(te.exists, false) then 'TABLE MISSING — migration not applied'
    when not coalesce(r.rls_enabled, false) then 'RLS DISABLED — policy gap'
    when coalesce(p.policy_count, 0) = 0 then 'NO POLICIES — deny-by-default for authenticated'
    else 'OK (verify policy names in section 3)'
  end as notes
from expected_tables e
left join table_exists te on te.table_name = e.table_name
left join rls_flags r on r.table_name = e.table_name
left join policy_counts p on p.table_name = e.table_name
order by e.table_name;

-- -----------------------------------------------------------------------------
-- 3) Expected RLS policy names (spot check)
-- -----------------------------------------------------------------------------

select tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'public'
  and tablename in (
    'payments',
    'consents',
    'inventory_items',
    'inventory_movements',
    'physiotherapy_referrals',
    'physiotherapy_sessions',
    'pdf_outputs',
    'patient_files'
  )
order by tablename, policyname;

-- Key expectations:
-- payments: payments_select_staff_v2a, payments_insert_staff_v2a, payments_update_staff_v2a
-- consents: consents_select_staff_v2a, consents_insert_staff_v2a, consents_update_staff_v2a
-- inventory_items: inventory_items_select_v2b, inventory_items_insert_v2b, inventory_items_update_v2b
-- inventory_movements: direct INSERT denied; use record_inventory_movement RPC
-- physiotherapy_referrals: *_doctor_v1, *_physio_v1 (select + update physio)
-- physiotherapy_sessions: *_doctor_v1, *_physio_v1 (select + insert)
-- pdf_outputs: pdf_outputs_select_doctor_draft_v1 or pdf_outputs_select_doctor_draft_v1 (metadata migration)

-- -----------------------------------------------------------------------------
-- 4) Critical column presence (202607* migrations)
-- missing_columns = comma-separated absent columns
-- -----------------------------------------------------------------------------

with checks as (
  select 'payments' as table_name, array[
    'id','tenant_id','patient_id','service_type','total_amount','paid_amount',
    'payment_method','payment_status','invoice_status','transaction_date',
    'deleted_at','created_at','updated_at'
  ] as required_cols
  union all select 'consents', array[
    'id','tenant_id','patient_id','consent_type','status','given_at',
    'deleted_at','created_at','updated_at'
  ]
  union all select 'inventory_items', array[
    'id','tenant_id','name','category','unit','current_quantity',
    'minimum_quantity','deleted_at','created_at','updated_at'
  ]
  union all select 'inventory_movements', array[
    'id','tenant_id','inventory_item_id','movement_type','quantity','movement_date'
  ]
  union all select 'physiotherapy_referrals', array[
    'id','tenant_id','patient_id','referred_by_profile_id','reason','status',
    'notes_safe','doctor_summary','deleted_at','created_at','updated_at'
  ]
  union all select 'physiotherapy_sessions', array[
    'id','tenant_id','referral_id','patient_id','physiotherapist_profile_id',
    'session_date','pain_score','doctor_notification_needed','deleted_at'
  ]
  union all select 'pdf_outputs', array[
    'id','tenant_id','patient_id','document_type','storage_path','storage_bucket',
    'visibility_scope','deleted_at','metadata'
  ]
  union all select 'patient_files', array[
    'id','tenant_id','patient_id','storage_path','storage_bucket',
    'visibility_scope','deleted_at','metadata'
  ]
),
expanded as (
  select c.table_name, col as column_name
  from checks c
  cross join unnest(c.required_cols) as col
),
actual as (
  select table_name, column_name
  from information_schema.columns
  where table_schema = 'public'
)
select
  e.table_name,
  string_agg(e.column_name, ', ' order by e.column_name)
    filter (where a.column_name is null) as missing_columns,
  case
    when count(*) filter (where a.column_name is null) = 0 then 'OK'
    else 'COLUMN GAP — migration partial or wrong version'
  end as notes
from expanded e
left join actual a
  on a.table_name = e.table_name
 and a.column_name = e.column_name
group by e.table_name
order by e.table_name;

-- -----------------------------------------------------------------------------
-- 5) Index spot checks
-- -----------------------------------------------------------------------------

select
  tablename,
  indexname
from pg_indexes
where schemaname = 'public'
  and tablename in (
    'payments',
    'consents',
    'inventory_items',
    'inventory_movements',
    'physiotherapy_referrals',
    'physiotherapy_sessions'
  )
order by tablename, indexname;

-- -----------------------------------------------------------------------------
-- 6) updated_at triggers (reuse set_updated_at)
-- -----------------------------------------------------------------------------

select
  tgname as trigger_name,
  relname as table_name
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and not t.tgisinternal
  and relname in (
    'payments',
    'consents',
    'inventory_items',
    'physiotherapy_referrals',
    'physiotherapy_sessions'
  )
  and tgname like '%updated_at%'
order by relname;

-- -----------------------------------------------------------------------------
-- 7) Storage bucket (PDF / patient files)
-- -----------------------------------------------------------------------------

select id, name, public, file_size_limit, allowed_mime_types
from storage.buckets
where id = 'patient-files-private';

-- Expected: 1 row, public = false

select policyname, cmd
from pg_policies
where schemaname = 'storage'
  and tablename = 'objects'
  and policyname like 'patient_files_storage_%'
order by policyname;

-- Expected: SELECT + INSERT policies; no broad public read
