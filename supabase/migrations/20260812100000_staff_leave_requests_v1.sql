-- Personel izin talepleri — tüm personel oluşturur; doktor onaylar/reddeder.

create table if not exists staff_leave_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  requester_profile_id uuid not null references profiles (id) on delete cascade,
  staff_display_name text not null,
  role_label text null,
  leave_type text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  note text null,
  status text not null default 'pending',
  reviewed_by uuid null references profiles (id),
  reviewed_at timestamptz null,
  rejection_reason text null,
  leave_record_id uuid null references staff_leave_records (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint staff_leave_requests_ends_after_start check (ends_at > starts_at),
  constraint staff_leave_requests_note_len check (
    note is null or char_length(note) <= 500
  ),
  constraint staff_leave_requests_rejection_reason_len check (
    rejection_reason is null or char_length(rejection_reason) <= 500
  ),
  constraint staff_leave_requests_leave_type_check check (
    leave_type in (
      'annual',
      'sick',
      'administrative',
      'meeting_training',
      'other'
    )
  ),
  constraint staff_leave_requests_status_check check (
    status in ('pending', 'approved', 'rejected')
  )
);

comment on table staff_leave_requests is
  'Personel izin talepleri — onay sonrası staff_leave_records kaydına bağlanır.';

create index if not exists idx_staff_leave_requests_tenant_status
  on staff_leave_requests (tenant_id, status, created_at desc);

create index if not exists idx_staff_leave_requests_requester
  on staff_leave_requests (tenant_id, requester_profile_id, created_at desc);

alter table staff_leave_requests enable row level security;

drop policy if exists staff_leave_requests_select_v1 on staff_leave_requests;
create policy staff_leave_requests_select_v1
  on staff_leave_requests
  for select
  to authenticated
  using (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and (
      requester_profile_id = current_profile_id()
      or has_tenant_role(tenant_id, array['doctor_admin'])
    )
  );

drop policy if exists staff_leave_requests_insert_v1 on staff_leave_requests;
create policy staff_leave_requests_insert_v1
  on staff_leave_requests
  for insert
  to authenticated
  with check (
    tenant_id = current_tenant_id()
    and is_tenant_member(tenant_id)
    and requester_profile_id = current_profile_id()
    and status = 'pending'
  );

create or replace function public.approve_staff_leave_request_v1(p_request_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_req staff_leave_requests%rowtype;
  v_leave_id uuid;
  v_reviewer uuid;
begin
  v_reviewer := current_profile_id();
  if v_reviewer is null then
    raise exception 'profile_required';
  end if;

  select *
  into v_req
  from staff_leave_requests
  where id = p_request_id
  for update;

  if not found then
    raise exception 'not_found';
  end if;

  if v_req.tenant_id <> current_tenant_id() then
    raise exception 'forbidden';
  end if;

  if not has_tenant_role(v_req.tenant_id, array['doctor_admin']) then
    raise exception 'forbidden';
  end if;

  if v_req.status <> 'pending' then
    raise exception 'not_pending';
  end if;

  insert into staff_leave_records (
    tenant_id,
    profile_id,
    staff_display_name,
    role_label,
    leave_type,
    starts_at,
    ends_at,
    note,
    status,
    created_by
  )
  values (
    v_req.tenant_id,
    v_req.requester_profile_id,
    v_req.staff_display_name,
    v_req.role_label,
    v_req.leave_type,
    v_req.starts_at,
    v_req.ends_at,
    v_req.note,
    'active',
    v_reviewer
  )
  returning id into v_leave_id;

  update staff_leave_requests
  set
    status = 'approved',
    reviewed_by = v_reviewer,
    reviewed_at = now(),
    leave_record_id = v_leave_id,
    updated_at = now()
  where id = p_request_id;

  return v_leave_id;
end;
$$;

create or replace function public.reject_staff_leave_request_v1(
  p_request_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_req staff_leave_requests%rowtype;
  v_reviewer uuid;
  v_reason text;
begin
  v_reviewer := current_profile_id();
  if v_reviewer is null then
    raise exception 'profile_required';
  end if;

  v_reason := nullif(trim(coalesce(p_reason, '')), '');
  if v_reason is not null and char_length(v_reason) > 500 then
    raise exception 'reason_too_long';
  end if;

  select *
  into v_req
  from staff_leave_requests
  where id = p_request_id
  for update;

  if not found then
    raise exception 'not_found';
  end if;

  if v_req.tenant_id <> current_tenant_id() then
    raise exception 'forbidden';
  end if;

  if not has_tenant_role(v_req.tenant_id, array['doctor_admin']) then
    raise exception 'forbidden';
  end if;

  if v_req.status <> 'pending' then
    raise exception 'not_pending';
  end if;

  update staff_leave_requests
  set
    status = 'rejected',
    reviewed_by = v_reviewer,
    reviewed_at = now(),
    rejection_reason = v_reason,
    updated_at = now()
  where id = p_request_id;
end;
$$;

revoke all on function public.approve_staff_leave_request_v1(uuid) from public;
grant execute on function public.approve_staff_leave_request_v1(uuid) to authenticated;

revoke all on function public.reject_staff_leave_request_v1(uuid, text) from public;
grant execute on function public.reject_staff_leave_request_v1(uuid, text) to authenticated;
