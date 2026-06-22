-- Auth Context Helper Hotfix v1
-- JWT profile_id/tenant_id claim olmadan profiles + memberships üzerinden context.

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $function$
  select p.id
  from public.profiles p
  where p.auth_user_id = auth.uid()
  limit 1;
$function$;

create or replace function public.current_tenant_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $function$
  select m.tenant_id
  from public.memberships m
  where m.profile_id = public.current_profile_id()
    and m.status = 'active'
  order by m.created_at asc
  limit 1;
$function$;

comment on function public.current_profile_id is
  'Auth Context Hotfix v1: profiles.auth_user_id = auth.uid()';

comment on function public.current_tenant_id is
  'Auth Context Hotfix v1: ilk active membership tenant_id';
