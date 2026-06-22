-- =============================================================================
-- Profile login_username — global unique giriş kimliği (e-posta auth arkada kalır)
-- =============================================================================

alter table public.profiles
  add column if not exists login_username text;

create unique index if not exists profiles_login_username_unique_idx
  on public.profiles (lower(trim(login_username)))
  where login_username is not null and length(trim(login_username)) > 0;

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

create or replace function public.normalize_login_username(p_username text)
returns text
language sql
immutable
as $$
  select lower(regexp_replace(trim(coalesce(p_username, '')), '[^a-z0-9._]', '', 'g'));
$$;

create or replace function public.is_valid_login_username(p_username text)
returns boolean
language sql
immutable
as $$
  select length(public.normalize_login_username(p_username)) between 3 and 32;
$$;

create or replace function public.resolve_login_email(p_login_username text)
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_normalized text;
  v_email text;
begin
  v_normalized := public.normalize_login_username(p_login_username);
  if length(v_normalized) < 3 then
    return null;
  end if;

  select p.email
  into v_email
  from public.profiles p
  where lower(trim(p.login_username)) = v_normalized
    and p.auth_user_id is not null
    and exists (
      select 1
      from public.memberships m
      where m.profile_id = p.id
        and m.status in ('active', 'invited')
    )
  limit 1;

  return nullif(trim(coalesce(v_email, '')), '');
end;
$$;

revoke all on function public.resolve_login_email(text) from public;
grant execute on function public.resolve_login_email(text) to anon, authenticated;

-- -----------------------------------------------------------------------------
-- set_profile_login_username_v1 — doctor_admin veya maintenance operator
-- -----------------------------------------------------------------------------

create or replace function public.set_profile_login_username_v1(
  p_profile_id uuid,
  p_login_username text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_normalized text;
  v_tenant_id uuid;
  v_is_maintenance boolean := false;
begin
  v_normalized := public.normalize_login_username(p_login_username);
  if not public.is_valid_login_username(v_normalized) then
    raise exception 'invalid_login_username' using errcode = 'P0001';
  end if;

  begin
    v_tenant_id := public._user_mgmt_assert_doctor_admin();
  exception
    when others then
      perform public.maintenance_assert_operator();
      v_is_maintenance := true;
  end;

  if not v_is_maintenance then
    if not exists (
      select 1
      from public.memberships m
      where m.profile_id = p_profile_id
        and m.tenant_id = v_tenant_id
    ) then
      raise exception 'not_found' using errcode = 'P0001';
    end if;
  end if;

  if exists (
    select 1
    from public.profiles p
    where lower(trim(p.login_username)) = v_normalized
      and p.id is distinct from p_profile_id
  ) then
    raise exception 'login_username_taken' using errcode = 'P0001';
  end if;

  update public.profiles
  set login_username = v_normalized,
      updated_at = now()
  where id = p_profile_id;

  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'ok', true,
    'profile_id', p_profile_id,
    'login_username', v_normalized
  );
end;
$$;

revoke all on function public.set_profile_login_username_v1(uuid, text) from public;
grant execute on function public.set_profile_login_username_v1(uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- list_tenant_memberships_v1 — login_username dahil
-- -----------------------------------------------------------------------------

create or replace function public.list_tenant_memberships_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
begin
  v_tenant_id := public._user_mgmt_assert_doctor_admin();

  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'membership_id', m.id,
        'profile_id', p.id,
        'display_name', coalesce(nullif(trim(p.display_name), ''), 'Kullanıcı'),
        'email', p.email,
        'login_username', p.login_username,
        'role', m.role,
        'status', m.status,
        'created_at', m.created_at,
        'updated_at', m.updated_at
      )
      order by coalesce(nullif(trim(p.display_name), ''), p.email, '') asc
    )
    from public.memberships m
    join public.profiles p on p.id = m.profile_id
    where m.tenant_id = v_tenant_id
      and coalesce(p.maintenance_operator, false) = false
  ), '[]'::jsonb);
end;
$$;
