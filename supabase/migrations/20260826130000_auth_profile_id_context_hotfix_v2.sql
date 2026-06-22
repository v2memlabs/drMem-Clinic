-- Auth Context Hotfix v2 — JWT profile_id claim güvenilmez; RLS created_by eşleşmesi.
-- Staging'de draft_rls JWT coalesce sürümü hotfix v1'i gölgelemiş olabilir.

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.id
  from public.profiles p
  where p.auth_user_id = auth.uid()
  limit 1;
$$;

comment on function public.current_profile_id() is
  'profiles.auth_user_id = auth.uid(); JWT profile_id kullanılmaz (Hotfix v2).';
