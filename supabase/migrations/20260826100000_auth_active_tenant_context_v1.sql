-- =============================================================================
-- Auth active tenant context — RLS current_tenant_id() ↔ app ActiveTenantContext
-- =============================================================================

alter table public.profiles
  add column if not exists active_tenant_id uuid
    references public.tenants (id) on delete set null;

comment on column public.profiles.active_tenant_id is
  'Son seçilen aktif klinik — current_tenant_id() önceliği.';

create or replace function public.current_tenant_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select p.active_tenant_id
      from public.profiles p
      where p.auth_user_id = auth.uid()
        and p.active_tenant_id is not null
      limit 1
    ),
    (
      select m.tenant_id
      from public.memberships m
      where m.profile_id = public.current_profile_id()
        and m.status = 'active'
      order by m.created_at asc
      limit 1
    )
  );
$$;

comment on function public.current_tenant_id() is
  'profiles.active_tenant_id varsa onu, yoksa ilk active membership tenant.';

create or replace function public.set_active_tenant_context(p_tenant_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_tenant_id is null then
    return;
  end if;

  if not public.is_tenant_member(p_tenant_id) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  update public.profiles p
  set active_tenant_id = p_tenant_id
  where p.auth_user_id = auth.uid();
end;
$$;

revoke all on function public.set_active_tenant_context(uuid) from public;
grant execute on function public.set_active_tenant_context(uuid) to authenticated;
