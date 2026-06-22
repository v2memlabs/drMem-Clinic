-- İzin talebi oluşturma RPC — JWT profile/tenant ile sunucu tarafı doğrulama.

create or replace function public.create_staff_leave_request_v1(
  p_leave_type text,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_note text default null,
  p_staff_display_name text default null,
  p_role_label text default null
)
returns staff_leave_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_profile_id uuid;
  v_display_name text;
  v_note text;
  v_row staff_leave_requests%rowtype;
begin
  v_tenant_id := current_tenant_id();
  v_profile_id := current_profile_id();

  if v_tenant_id is null or v_profile_id is null then
    raise exception 'auth_context_required';
  end if;

  if not is_tenant_member(v_tenant_id) then
    raise exception 'forbidden';
  end if;

  if p_ends_at <= p_starts_at then
    raise exception 'invalid_range';
  end if;

  if p_leave_type not in (
    'annual', 'sick', 'administrative', 'meeting_training', 'other'
  ) then
    raise exception 'invalid_leave_type';
  end if;

  v_note := nullif(trim(coalesce(p_note, '')), '');
  if v_note is not null and char_length(v_note) > 500 then
    raise exception 'note_too_long';
  end if;

  v_display_name := nullif(trim(coalesce(p_staff_display_name, '')), '');
  if v_display_name is null then
    select display_name into v_display_name
    from profiles
    where id = v_profile_id;
    v_display_name := nullif(trim(coalesce(v_display_name, '')), '');
  end if;

  if v_display_name is null then
    raise exception 'display_name_required';
  end if;

  insert into staff_leave_requests (
    tenant_id,
    requester_profile_id,
    staff_display_name,
    role_label,
    leave_type,
    starts_at,
    ends_at,
    note,
    status
  )
  values (
    v_tenant_id,
    v_profile_id,
    v_display_name,
    nullif(trim(coalesce(p_role_label, '')), ''),
    p_leave_type,
    p_starts_at,
    p_ends_at,
    v_note,
    'pending'
  )
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.create_staff_leave_request_v1(
  text, timestamptz, timestamptz, text, text, text
) from public;
grant execute on function public.create_staff_leave_request_v1(
  text, timestamptz, timestamptz, text, text, text
) to authenticated;
