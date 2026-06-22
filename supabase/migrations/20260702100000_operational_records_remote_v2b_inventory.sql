-- =============================================================================
-- Operational Records Remote v2b — inventory_items + inventory_movements + RPC
--
-- Prerequisite: 20260521100000_draft_saas_schema_rls_v1.sql
--               20260522100000_draft_rls_policies_v1.sql (RLS helpers)
--               20260701100000_operational_records_remote_v2a.sql
--
-- Scope: inventory only; doctor_admin + nurse; movement via SECURITY DEFINER RPC
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) inventory_items
-- -----------------------------------------------------------------------------

create table if not exists inventory_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  name text not null,
  category text not null,
  unit text not null,
  current_quantity numeric(12, 3) not null default 0,
  minimum_quantity numeric(12, 3) not null default 0,
  expiration_date date,
  location text,
  supplier_name text,
  notes text,
  is_active boolean not null default true,
  created_by uuid references profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint inventory_items_current_quantity_nonneg check (current_quantity >= 0),
  constraint inventory_items_minimum_quantity_nonneg check (minimum_quantity >= 0)
);

comment on table inventory_items is
  'Klinik stok kartları — tenant scoped; soft delete via deleted_at.';

create index if not exists inventory_items_tenant_id_idx
  on inventory_items (tenant_id);

create index if not exists inventory_items_category_idx
  on inventory_items (tenant_id, category)
  where deleted_at is null;

create index if not exists inventory_items_expiration_date_idx
  on inventory_items (tenant_id, expiration_date)
  where deleted_at is null and expiration_date is not null;

create index if not exists inventory_items_deleted_at_idx
  on inventory_items (tenant_id, deleted_at)
  where deleted_at is null;

create index if not exists inventory_items_active_tenant_idx
  on inventory_items (tenant_id)
  where deleted_at is null and is_active = true;

-- -----------------------------------------------------------------------------
-- 2) inventory_movements (append-only)
-- -----------------------------------------------------------------------------

create table if not exists inventory_movements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  inventory_item_id uuid not null references inventory_items (id) on delete restrict,
  movement_type text not null,
  quantity numeric(12, 3) not null,
  movement_date timestamptz not null default now(),
  performed_by_display text,
  note text,
  patient_id uuid references patients (id),
  related_module text,
  related_record_id uuid,
  created_by uuid references profiles (id),
  created_at timestamptz not null default now(),
  constraint inventory_movements_quantity_positive check (quantity > 0),
  constraint inventory_movements_type_check check (
    movement_type in ('giris', 'cikis', 'duzeltme')
  )
);

comment on table inventory_movements is
  'Stok hareketleri — append-only; insert via record_inventory_movement RPC.';

create index if not exists inventory_movements_tenant_id_idx
  on inventory_movements (tenant_id);

create index if not exists inventory_movements_item_id_idx
  on inventory_movements (inventory_item_id);

create index if not exists inventory_movements_movement_date_idx
  on inventory_movements (tenant_id, movement_date desc);

create index if not exists inventory_movements_patient_id_idx
  on inventory_movements (patient_id)
  where patient_id is not null;

-- -----------------------------------------------------------------------------
-- 3) updated_at trigger (reuse set_updated_at)
-- -----------------------------------------------------------------------------

drop trigger if exists inventory_items_updated_at on inventory_items;
create trigger inventory_items_updated_at
  before update on inventory_items
  for each row execute function set_updated_at();

-- -----------------------------------------------------------------------------
-- 4) RLS — inventory_items
-- -----------------------------------------------------------------------------

alter table inventory_items enable row level security;

drop policy if exists inventory_items_select_staff_v2b on inventory_items;
create policy inventory_items_select_staff_v2b
  on inventory_items
  for select
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'nurse'])
  );

drop policy if exists inventory_items_insert_staff_v2b on inventory_items;
create policy inventory_items_insert_staff_v2b
  on inventory_items
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'nurse'])
  );

drop policy if exists inventory_items_update_staff_v2b on inventory_items;
create policy inventory_items_update_staff_v2b
  on inventory_items
  for update
  to authenticated
  using (
    deleted_at is null
    and tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'nurse'])
  )
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'nurse'])
  );

-- -----------------------------------------------------------------------------
-- 5) RLS — inventory_movements (SELECT only; INSERT via RPC)
-- -----------------------------------------------------------------------------

alter table inventory_movements enable row level security;

drop policy if exists inventory_movements_select_staff_v2b on inventory_movements;
create policy inventory_movements_select_staff_v2b
  on inventory_movements
  for select
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and has_tenant_role(tenant_id, array['doctor_admin', 'nurse'])
  );

revoke insert on inventory_movements from authenticated;
revoke update on inventory_movements from authenticated;
revoke delete on inventory_movements from authenticated;

-- -----------------------------------------------------------------------------
-- 6) record_inventory_movement — atomic qty update
-- -----------------------------------------------------------------------------

create or replace function record_inventory_movement(
  p_inventory_item_id uuid,
  p_movement_type text,
  p_quantity numeric,
  p_movement_date timestamptz default now(),
  p_performed_by_display text default null,
  p_note text default null,
  p_patient_id uuid default null,
  p_related_module text default null,
  p_related_record_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_profile_id uuid;
  v_item inventory_items%rowtype;
  v_new_qty numeric(12, 3);
  v_movement_id uuid;
begin
  if auth.uid() is null then
    raise exception 'INV_MOV_FORBIDDEN' using errcode = '42501';
  end if;

  v_tenant_id := current_tenant_id();
  if v_tenant_id is null then
    raise exception 'INV_MOV_FORBIDDEN' using errcode = '42501';
  end if;

  if not is_tenant_member(v_tenant_id) then
    raise exception 'INV_MOV_FORBIDDEN' using errcode = '42501';
  end if;

  if not has_tenant_role(v_tenant_id, array['doctor_admin', 'nurse']) then
    raise exception 'INV_MOV_FORBIDDEN' using errcode = '42501';
  end if;

  v_profile_id := current_profile_id();

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'INV_MOV_INVALID_QTY';
  end if;

  if p_movement_type is null
     or p_movement_type not in ('giris', 'cikis', 'duzeltme') then
    raise exception 'INV_MOV_INVALID_TYPE';
  end if;

  if p_patient_id is not null then
    if not exists (
      select 1
      from patients p
      where p.id = p_patient_id
        and p.tenant_id = v_tenant_id
        and p.deleted_at is null
    ) then
      raise exception 'INV_MOV_PATIENT_TENANT';
    end if;
  end if;

  select *
  into v_item
  from inventory_items i
  where i.id = p_inventory_item_id
    and i.tenant_id = v_tenant_id
    and i.deleted_at is null
  for update;

  if not found then
    raise exception 'INV_MOV_ITEM_NOT_FOUND';
  end if;

  if not v_item.is_active then
    raise exception 'INV_MOV_ITEM_INACTIVE';
  end if;

  case p_movement_type
    when 'giris' then
      v_new_qty := v_item.current_quantity + p_quantity;
    when 'cikis' then
      if p_quantity > v_item.current_quantity then
        raise exception 'INV_MOV_INSUFFICIENT_STOCK';
      end if;
      v_new_qty := v_item.current_quantity - p_quantity;
    when 'duzeltme' then
      v_new_qty := p_quantity;
      if v_new_qty < 0 then
        raise exception 'INV_MOV_NEGATIVE_RESULT';
      end if;
  end case;

  insert into inventory_movements (
    tenant_id,
    inventory_item_id,
    movement_type,
    quantity,
    movement_date,
    performed_by_display,
    note,
    patient_id,
    related_module,
    related_record_id,
    created_by
  )
  values (
    v_tenant_id,
    p_inventory_item_id,
    p_movement_type,
    p_quantity,
    coalesce(p_movement_date, now()),
    nullif(trim(p_performed_by_display), ''),
    nullif(trim(p_note), ''),
    p_patient_id,
    nullif(trim(p_related_module), ''),
    p_related_record_id,
    v_profile_id
  )
  returning id into v_movement_id;

  update inventory_items
  set current_quantity = v_new_qty,
      updated_at = now()
  where id = p_inventory_item_id
    and tenant_id = v_tenant_id;

  return jsonb_build_object(
    'id', v_movement_id,
    'tenant_id', v_tenant_id,
    'inventory_item_id', p_inventory_item_id,
    'movement_type', p_movement_type,
    'quantity', p_quantity,
    'movement_date', coalesce(p_movement_date, now()),
    'performed_by_display', nullif(trim(p_performed_by_display), ''),
    'note', nullif(trim(p_note), ''),
    'patient_id', p_patient_id,
    'related_module', nullif(trim(p_related_module), ''),
    'related_record_id', p_related_record_id,
    'created_at', now()
  );
end;
$$;

revoke all on function record_inventory_movement(
  uuid, text, numeric, timestamptz, text, text, uuid, text, uuid
) from public;

grant execute on function record_inventory_movement(
  uuid, text, numeric, timestamptz, text, text, uuid, text, uuid
) to authenticated;
