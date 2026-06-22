-- =============================================================================
-- resolve_login_email — allow maintenance operators (no clinic membership)
-- Maintenance-only profiles were excluded by membership EXISTS guard, breaking
-- sign-in-with-username for maintenance_operator accounts.
-- =============================================================================

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
    and (
      coalesce(p.maintenance_operator, false) = true
      or exists (
        select 1
        from public.memberships m
        where m.profile_id = p.id
          and m.status in ('active', 'invited')
      )
    )
  limit 1;

  return nullif(trim(coalesce(v_email, '')), '');
end;
$$;

revoke all on function public.resolve_login_email(text) from public;
revoke all on function public.resolve_login_email(text) from anon;
revoke all on function public.resolve_login_email(text) from authenticated;
grant execute on function public.resolve_login_email(text) to service_role;
