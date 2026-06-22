-- =============================================================================
-- Maintenance / Bootstrap Console v1
-- Staging/dev operator console — SECURITY DEFINER RPC only (no service_role client)
-- Production: maintenance_config.enabled must remain false
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) maintenance_config (single row)
-- -----------------------------------------------------------------------------

create table if not exists public.maintenance_config (
  id int primary key check (id = 1),
  enabled boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles (id)
);

insert into public.maintenance_config (id, enabled)
values (1, false)
on conflict (id) do nothing;

alter table public.maintenance_config enable row level security;

drop policy if exists maintenance_config_no_client_draft_v1 on public.maintenance_config;
create policy maintenance_config_no_client_draft_v1
  on public.maintenance_config for all
  using (false);

-- -----------------------------------------------------------------------------
-- 2) profiles.maintenance_operator
-- -----------------------------------------------------------------------------

alter table public.profiles
  add column if not exists maintenance_operator boolean not null default false;

-- -----------------------------------------------------------------------------
-- 3) Helpers
-- -----------------------------------------------------------------------------

create or replace function public.maintenance_is_valid_role(p_role text)
returns boolean
language sql
immutable
as $$
  select p_role in (
    'doctor_admin',
    'assistant_secretary',
    'physiotherapist',
    'nurse'
  );
$$;

create or replace function public.maintenance_is_valid_membership_status(p_status text)
returns boolean
language sql
immutable
as $$
  select p_status in ('active', 'invited', 'disabled');
$$;

create or replace function public.maintenance_is_valid_tenant_status(p_status text)
returns boolean
language sql
immutable
as $$
  select p_status in ('active', 'suspended', 'trial');
$$;

create or replace function public.maintenance_assert_enabled()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.maintenance_config mc
    where mc.id = 1 and mc.enabled = true
  ) then
    raise exception 'maintenance_disabled' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.maintenance_assert_operator()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_operator boolean;
begin
  perform public.maintenance_assert_enabled();

  if auth.uid() is null then
    raise exception 'maintenance_forbidden' using errcode = 'P0001';
  end if;

  select p.id, coalesce(p.maintenance_operator, false)
  into v_profile_id, v_operator
  from public.profiles p
  where p.auth_user_id = auth.uid()
  limit 1;

  if v_profile_id is null or not v_operator then
    raise exception 'maintenance_forbidden' using errcode = 'P0001';
  end if;

  return v_profile_id;
end;
$$;

create or replace function public._maintenance_forbidden_metadata_key(p_key text)
returns boolean
language sql
immutable
as $$
  select lower(replace(p_key, '-', '_')) in (
    'email',
    'display_name',
    'phone',
    'password',
    'signed_url',
    'storage_path',
    'public_url',
    'jwt',
    'service_role',
    'stack_trace',
    'sql',
    'internal_doctor_note',
    'clinical_data'
  )
  or lower(p_key) like '%email%'
  or lower(p_key) like '%password%';
$$;

create or replace function public._sanitize_maintenance_metadata(p_metadata jsonb)
returns jsonb
language plpgsql
immutable
as $$
declare
  result jsonb := '{}'::jsonb;
  k text;
  v jsonb;
begin
  if p_metadata is null or p_metadata = 'null'::jsonb then
    return jsonb_build_object('source', 'maintenance_console_v1');
  end if;
  for k, v in select * from jsonb_each(p_metadata)
  loop
    if public._maintenance_forbidden_metadata_key(k) then
      continue;
    end if;
    if jsonb_typeof(v) in ('object', 'array') then
      continue;
    end if;
    result := result || jsonb_build_object(k, v);
  end loop;
  return result || jsonb_build_object(
    'source', coalesce(result ->> 'source', 'maintenance_console_v1')
  );
end;
$$;

create or replace function public.maintenance_resolve_audit_tenant(
  p_target_tenant_id uuid,
  p_target_profile_id uuid default null
)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    p_target_tenant_id,
    (
      select m.tenant_id
      from public.memberships m
      where m.profile_id = p_target_profile_id
        and m.status = 'active'
      order by m.created_at asc
      limit 1
    ),
    public.current_tenant_id(),
    (
      select t.id
      from public.tenants t
      where t.status = 'active'
      order by t.created_at asc
      limit 1
    )
  );
$$;

create or replace function public.maintenance_write_audit(
  p_action text,
  p_record_id uuid default null,
  p_target_tenant_id uuid default null,
  p_target_profile_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid;
  v_tenant uuid;
  v_meta jsonb;
  v_id uuid;
begin
  v_actor := public.maintenance_assert_operator();
  v_tenant := public.maintenance_resolve_audit_tenant(p_target_tenant_id, p_target_profile_id);
  if v_tenant is null then
    raise exception 'maintenance_audit_tenant_required' using errcode = 'P0001';
  end if;

  v_meta := public._sanitize_maintenance_metadata(coalesce(p_metadata, '{}'::jsonb));

  insert into public.audit_logs (
    tenant_id,
    actor_profile_id,
    action,
    module,
    record_id,
    patient_id,
    metadata
  )
  values (
    v_tenant,
    v_actor,
    trim(p_action),
    'maintenance',
    p_record_id,
    null,
    v_meta
  )
  returning id into v_id;

  return v_id;
end;
$$;

-- -----------------------------------------------------------------------------
-- 4) Read RPCs
-- -----------------------------------------------------------------------------

create or replace function public.maintenance_ping()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
begin
  v_profile_id := public.maintenance_assert_operator();
  return jsonb_build_object(
    'ok', true,
    'operator_profile_id', v_profile_id,
    'auth_user_id', auth.uid()
  );
exception
  when others then
    return jsonb_build_object(
      'ok', false,
      'error', sqlerrm
    );
end;
$$;

create or replace function public.maintenance_get_bootstrap_chain(
  p_email text default null,
  p_profile_id uuid default null,
  p_auth_user_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_uid uuid;
  v_profile_id uuid;
  v_profile_auth uuid;
  v_profile_operator boolean;
  v_memberships jsonb;
  v_resolved_tenant uuid;
begin
  perform public.maintenance_assert_operator();

  v_auth_uid := p_auth_user_id;
  if v_auth_uid is null and p_profile_id is not null then
    select p.auth_user_id into v_auth_uid
    from public.profiles p
    where p.id = p_profile_id;
  end if;
  if v_auth_uid is null and p_email is not null and length(trim(p_email)) > 0 then
    select p.auth_user_id into v_auth_uid
    from public.profiles p
    where lower(trim(p.email)) = lower(trim(p_email))
    limit 1;
  end if;
  if v_auth_uid is null and p_email is not null and length(trim(p_email)) > 0 then
    select u.id into v_auth_uid
    from auth.users u
    where lower(u.email) = lower(trim(p_email))
    limit 1;
  end if;

  if p_profile_id is not null then
    select p.id, p.auth_user_id, coalesce(p.maintenance_operator, false)
    into v_profile_id, v_profile_auth, v_profile_operator
    from public.profiles p
    where p.id = p_profile_id;
  elsif v_auth_uid is not null then
    select p.id, p.auth_user_id, coalesce(p.maintenance_operator, false)
    into v_profile_id, v_profile_auth, v_profile_operator
    from public.profiles p
    where p.auth_user_id = v_auth_uid
    limit 1;
  elsif p_email is not null and length(trim(p_email)) > 0 then
    select p.id, p.auth_user_id, coalesce(p.maintenance_operator, false)
    into v_profile_id, v_profile_auth, v_profile_operator
    from public.profiles p
    where lower(trim(p.email)) = lower(trim(p_email))
    limit 1;
  end if;

  if v_profile_id is not null then
    select coalesce(jsonb_agg(
      jsonb_build_object(
        'membership_id', m.id,
        'tenant_id', m.tenant_id,
        'tenant_name', t.name,
        'tenant_status', t.status,
        'role', m.role,
        'membership_status', m.status,
        'created_at', m.created_at
      )
      order by m.created_at asc
    ), '[]'::jsonb)
    into v_memberships
    from public.memberships m
    join public.tenants t on t.id = m.tenant_id
    where m.profile_id = v_profile_id;
  else
    v_memberships := '[]'::jsonb;
  end if;

  v_resolved_tenant := public.current_tenant_id();

  return jsonb_build_object(
    'auth_user_id', v_auth_uid,
    'auth_user_exists', (
      v_auth_uid is not null
      and exists (select 1 from auth.users u where u.id = v_auth_uid)
    ),
    'profile', case
      when v_profile_id is null then null
      else jsonb_build_object(
        'id', v_profile_id,
        'auth_user_id', v_profile_auth,
        'has_auth_link', v_profile_auth is not null,
        'maintenance_operator', v_profile_operator
      )
    end,
    'memberships', v_memberships,
    'resolved_active_tenant_id', v_resolved_tenant,
    'chain_ok', (
      v_auth_uid is not null
      and v_profile_id is not null
      and v_profile_auth = v_auth_uid
      and exists (
        select 1
        from public.memberships m
        join public.tenants t on t.id = m.tenant_id
        where m.profile_id = v_profile_id
          and m.status = 'active'
          and t.status = 'active'
      )
    )
  );
end;
$$;

create or replace function public.maintenance_list_tenants()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.maintenance_assert_operator();
  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'id', t.id,
        'name', t.name,
        'specialty', t.specialty,
        'timezone', t.timezone,
        'status', t.status,
        'created_at', t.created_at,
        'updated_at', t.updated_at
      )
      order by t.name asc
    )
    from public.tenants t
  ), '[]'::jsonb);
end;
$$;

create or replace function public.maintenance_list_memberships(
  p_tenant_id uuid default null,
  p_profile_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.maintenance_assert_operator();
  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'id', m.id,
        'tenant_id', m.tenant_id,
        'tenant_name', t.name,
        'profile_id', m.profile_id,
        'profile_email', p.email,
        'profile_display_name', p.display_name,
        'role', m.role,
        'status', m.status,
        'created_at', m.created_at,
        'updated_at', m.updated_at
      )
      order by t.name asc, p.email asc nulls last
    )
    from public.memberships m
    join public.tenants t on t.id = m.tenant_id
    join public.profiles p on p.id = m.profile_id
    where (p_tenant_id is null or m.tenant_id = p_tenant_id)
      and (p_profile_id is null or m.profile_id = p_profile_id)
  ), '[]'::jsonb);
end;
$$;

create or replace function public.maintenance_list_profile_auth_gaps()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.maintenance_assert_operator();
  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'id', p.id,
        'email', p.email,
        'display_name', p.display_name,
        'auth_user_id', p.auth_user_id
      )
      order by p.email asc nulls last
    )
    from public.profiles p
    where p.auth_user_id is null
  ), '[]'::jsonb);
end;
$$;

create or replace function public.maintenance_list_audit_events(p_limit int default 20)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_limit int := greatest(1, least(coalesce(p_limit, 20), 100));
begin
  perform public.maintenance_assert_operator();
  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'id', a.id,
        'action', a.action,
        'tenant_id', a.tenant_id,
        'record_id', a.record_id,
        'metadata', a.metadata,
        'created_at', a.created_at
      )
      order by a.created_at desc
    )
    from (
      select *
      from public.audit_logs al
      where al.module = 'maintenance'
      order by al.created_at desc
      limit v_limit
    ) a
  ), '[]'::jsonb);
end;
$$;

-- -----------------------------------------------------------------------------
-- 5) Write RPCs
-- -----------------------------------------------------------------------------

create or replace function public.maintenance_link_profile_auth(
  p_profile_id uuid,
  p_auth_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_before uuid;
begin
  perform public.maintenance_assert_operator();

  if p_profile_id is null or p_auth_user_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0001';
  end if;

  if not exists (select 1 from auth.users u where u.id = p_auth_user_id) then
    raise exception 'auth_user_not_found' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.profiles p
    where p.auth_user_id = p_auth_user_id
      and p.id <> p_profile_id
  ) then
    raise exception 'auth_user_already_linked' using errcode = 'P0001';
  end if;

  select p.auth_user_id into v_before
  from public.profiles p
  where p.id = p_profile_id
  for update;

  if not found then
    raise exception 'profile_not_found' using errcode = 'P0001';
  end if;

  update public.profiles
  set auth_user_id = p_auth_user_id,
      updated_at = now()
  where id = p_profile_id;

  perform public.maintenance_write_audit(
    'maintenance.profile.link_auth',
    p_profile_id,
    null,
    p_profile_id,
    jsonb_build_object(
      'target_profile_id', p_profile_id,
      'field', 'auth_user_id',
      'before', v_before::text,
      'after', p_auth_user_id::text
    )
  );

  return jsonb_build_object('ok', true, 'profile_id', p_profile_id);
end;
$$;

create or replace function public.maintenance_create_profile(
  p_email text,
  p_display_name text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  perform public.maintenance_assert_operator();

  if p_email is null or length(trim(p_email)) = 0 then
    raise exception 'invalid_email' using errcode = 'P0001';
  end if;

  insert into public.profiles (email, display_name)
  values (trim(p_email), nullif(trim(p_display_name), ''))
  returning id into v_id;

  perform public.maintenance_write_audit(
    'maintenance.profile.create',
    v_id,
    null,
    v_id,
    jsonb_build_object('target_profile_id', v_id)
  );

  return jsonb_build_object('ok', true, 'profile_id', v_id);
end;
$$;

create or replace function public.maintenance_update_profile(
  p_profile_id uuid,
  p_display_name text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.maintenance_assert_operator();

  if p_profile_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0001';
  end if;

  update public.profiles
  set display_name = nullif(trim(p_display_name), ''),
      updated_at = now()
  where id = p_profile_id;

  if not found then
    raise exception 'profile_not_found' using errcode = 'P0001';
  end if;

  perform public.maintenance_write_audit(
    'maintenance.profile.update',
    p_profile_id,
    null,
    p_profile_id,
    jsonb_build_object(
      'target_profile_id', p_profile_id,
      'field', 'display_name'
    )
  );

  return jsonb_build_object('ok', true, 'profile_id', p_profile_id);
end;
$$;

create or replace function public.maintenance_update_tenant_status(
  p_tenant_id uuid,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_before text;
begin
  perform public.maintenance_assert_operator();

  if not public.maintenance_is_valid_tenant_status(p_status) then
    raise exception 'invalid_tenant_status' using errcode = 'P0001';
  end if;

  select t.status into v_before
  from public.tenants t
  where t.id = p_tenant_id
  for update;

  if not found then
    raise exception 'tenant_not_found' using errcode = 'P0001';
  end if;

  update public.tenants
  set status = p_status,
      updated_at = now()
  where id = p_tenant_id;

  perform public.maintenance_write_audit(
    'maintenance.tenant.status_update',
    p_tenant_id,
    p_tenant_id,
    null,
    jsonb_build_object(
      'target_tenant_id', p_tenant_id,
      'field', 'status',
      'before_status', v_before,
      'after_status', p_status
    )
  );

  return jsonb_build_object('ok', true, 'tenant_id', p_tenant_id);
end;
$$;

create or replace function public.maintenance_create_membership(
  p_tenant_id uuid,
  p_profile_id uuid,
  p_role text,
  p_status text default 'active'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  perform public.maintenance_assert_operator();

  if not public.maintenance_is_valid_role(p_role) then
    raise exception 'invalid_role' using errcode = 'P0001';
  end if;
  if not public.maintenance_is_valid_membership_status(p_status) then
    raise exception 'invalid_membership_status' using errcode = 'P0001';
  end if;

  insert into public.memberships (tenant_id, profile_id, role, status)
  values (p_tenant_id, p_profile_id, p_role, p_status)
  returning id into v_id;

  perform public.maintenance_write_audit(
    'maintenance.membership.create',
    v_id,
    p_tenant_id,
    p_profile_id,
    jsonb_build_object(
      'target_membership_id', v_id,
      'target_tenant_id', p_tenant_id,
      'target_profile_id', p_profile_id,
      'after', p_role,
      'after_status', p_status
    )
  );

  return jsonb_build_object('ok', true, 'membership_id', v_id);
end;
$$;

create or replace function public.maintenance_update_membership_role(
  p_membership_id uuid,
  p_role text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_before text;
  v_tenant uuid;
  v_profile uuid;
begin
  perform public.maintenance_assert_operator();

  if not public.maintenance_is_valid_role(p_role) then
    raise exception 'invalid_role' using errcode = 'P0001';
  end if;

  select m.role, m.tenant_id, m.profile_id
  into v_before, v_tenant, v_profile
  from public.memberships m
  where m.id = p_membership_id
  for update;

  if not found then
    raise exception 'membership_not_found' using errcode = 'P0001';
  end if;

  update public.memberships
  set role = p_role,
      updated_at = now()
  where id = p_membership_id;

  perform public.maintenance_write_audit(
    'maintenance.membership.role_update',
    p_membership_id,
    v_tenant,
    v_profile,
    jsonb_build_object(
      'target_membership_id', p_membership_id,
      'field', 'role',
      'before', v_before,
      'after', p_role
    )
  );

  return jsonb_build_object('ok', true, 'membership_id', p_membership_id);
end;
$$;

create or replace function public.maintenance_update_membership_status(
  p_membership_id uuid,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_before text;
  v_tenant uuid;
  v_profile uuid;
begin
  perform public.maintenance_assert_operator();

  if not public.maintenance_is_valid_membership_status(p_status) then
    raise exception 'invalid_membership_status' using errcode = 'P0001';
  end if;

  select m.status, m.tenant_id, m.profile_id
  into v_before, v_tenant, v_profile
  from public.memberships m
  where m.id = p_membership_id
  for update;

  if not found then
    raise exception 'membership_not_found' using errcode = 'P0001';
  end if;

  update public.memberships
  set status = p_status,
      updated_at = now()
  where id = p_membership_id;

  perform public.maintenance_write_audit(
    'maintenance.membership.status_update',
    p_membership_id,
    v_tenant,
    v_profile,
    jsonb_build_object(
      'target_membership_id', p_membership_id,
      'field', 'status',
      'before_status', v_before,
      'after_status', p_status
    )
  );

  return jsonb_build_object('ok', true, 'membership_id', p_membership_id);
end;
$$;

-- -----------------------------------------------------------------------------
-- 6) Grants (authenticated only)
-- -----------------------------------------------------------------------------

revoke all on function public.maintenance_assert_enabled() from public;
revoke all on function public.maintenance_assert_operator() from public;
revoke all on function public.maintenance_write_audit(text, uuid, uuid, uuid, jsonb) from public;

grant execute on function public.maintenance_ping() to authenticated;
grant execute on function public.maintenance_get_bootstrap_chain(text, uuid, uuid) to authenticated;
grant execute on function public.maintenance_list_tenants() to authenticated;
grant execute on function public.maintenance_list_memberships(uuid, uuid) to authenticated;
grant execute on function public.maintenance_list_profile_auth_gaps() to authenticated;
grant execute on function public.maintenance_list_audit_events(int) to authenticated;
grant execute on function public.maintenance_link_profile_auth(uuid, uuid) to authenticated;
grant execute on function public.maintenance_create_profile(text, text) to authenticated;
grant execute on function public.maintenance_update_profile(uuid, text) to authenticated;
grant execute on function public.maintenance_update_tenant_status(uuid, text) to authenticated;
grant execute on function public.maintenance_create_membership(uuid, uuid, text, text) to authenticated;
grant execute on function public.maintenance_update_membership_role(uuid, text) to authenticated;
grant execute on function public.maintenance_update_membership_status(uuid, text) to authenticated;

-- Staging seed hint (run manually on staging after seed):
-- update maintenance_config set enabled = true, updated_at = now() where id = 1;
-- update profiles set maintenance_operator = true where id = 'b0000001-0001-4001-8001-000000000001';
