-- =============================================================================
-- Mevcut profiller için login_username backfill (giriş kilidi önleme)
-- =============================================================================

create or replace function public._backfill_suggest_login_username(
  p_display_name text,
  p_email text
)
returns text
language plpgsql
immutable
as $$
declare
  v_parts text[];
  v_first text;
  v_last text;
  v_candidate text;
  v_local text;
begin
  v_parts := regexp_split_to_array(trim(coalesce(p_display_name, '')), '\s+');
  if coalesce(array_length(v_parts, 1), 0) >= 2 then
    v_first := public.normalize_login_username(v_parts[1]);
    v_last := public.normalize_login_username(v_parts[array_length(v_parts, 1)]);
    if length(v_first) > 0 and length(v_last) >= 2 then
      v_candidate := left(v_first, 1) || v_last;
      v_candidate := public.normalize_login_username(v_candidate);
      if public.is_valid_login_username(v_candidate) then
        return v_candidate;
      end if;
    end if;
  elsif coalesce(array_length(v_parts, 1), 0) = 1 then
    v_candidate := public.normalize_login_username(v_parts[1]);
    if public.is_valid_login_username(v_candidate) then
      return v_candidate;
    end if;
  end if;

  v_local := split_part(lower(trim(coalesce(p_email, ''))), '@', 1);
  v_local := public.normalize_login_username(v_local);
  if public.is_valid_login_username(v_local) then
    return v_local;
  end if;

  return null;
end;
$$;

do $$
declare
  r record;
  v_base text;
  v_candidate text;
  v_suffix int;
begin
  for r in
    select p.id, p.display_name, p.email
    from public.profiles p
    where p.login_username is null
       or length(trim(p.login_username)) = 0
    order by p.created_at nulls last, p.id
  loop
    v_base := public._backfill_suggest_login_username(r.display_name, r.email);
    if v_base is null then
      v_base := 'user' || left(replace(r.id::text, '-', ''), 8);
    end if;

    v_candidate := v_base;
    v_suffix := 1;
    while exists (
      select 1
      from public.profiles p2
      where lower(trim(p2.login_username)) = lower(trim(v_candidate))
        and p2.id is distinct from r.id
    ) loop
      v_suffix := v_suffix + 1;
      v_candidate := left(v_base, 28) || v_suffix::text;
    end loop;

    update public.profiles
    set login_username = v_candidate,
        updated_at = now()
    where id = r.id;
  end loop;
end $$;

-- Geçiş: e-posta ile de çözümleme (kullanıcı adı henüz bilinmiyorsa)
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
  v_input text;
begin
  v_input := trim(coalesce(p_login_username, ''));
  v_normalized := public.normalize_login_username(v_input);

  if length(v_normalized) >= 3 then
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

    if nullif(trim(coalesce(v_email, '')), '') is not null then
      return trim(v_email);
    end if;
  end if;

  -- Geçiş dönemi: kayıtlı e-posta ile giriş
  if v_input like '%@%' then
    select p.email
    into v_email
    from public.profiles p
    where lower(trim(p.email)) = lower(v_input)
      and p.auth_user_id is not null
      and exists (
        select 1
        from public.memberships m
        where m.profile_id = p.id
          and m.status in ('active', 'invited')
      )
    limit 1;

    return nullif(trim(coalesce(v_email, '')), '');
  end if;

  return null;
end;
$$;

revoke all on function public.resolve_login_email(text) from public;
grant execute on function public.resolve_login_email(text) to anon, authenticated;
