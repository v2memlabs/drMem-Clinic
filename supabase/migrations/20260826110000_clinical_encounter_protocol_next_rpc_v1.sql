-- Tenant geneli protokol numarası — doctor-scoped SELECT RLS'i bypass etmez;
-- security definer ile tenant içi max sıra okunur.

create or replace function public.next_clinical_encounter_protocol_number(
  p_tenant_id uuid,
  p_year int default extract(year from timezone('Europe/Istanbul', now()))::int
)
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_max int := 0;
  v_seq int;
  v_row record;
  v_prefix text;
begin
  if p_tenant_id is null then
    raise exception 'invalid_tenant' using errcode = '22023';
  end if;

  if not public.is_tenant_member(p_tenant_id) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  v_prefix := 'M-' || p_year::text || '-';

  for v_row in
    select ce.protocol_number as protocol_number
    from public.clinical_encounters ce
    where ce.tenant_id = p_tenant_id
      and ce.deleted_at is null
      and ce.protocol_number is not null
      and ce.protocol_number like v_prefix || '%'
  loop
    v_seq := nullif(
      regexp_replace(v_row.protocol_number, '^M-[0-9]{4}-', ''),
      ''
    )::int;
    if v_seq is not null and v_seq > v_max then
      v_max := v_seq;
    end if;
  end loop;

  return v_prefix || lpad((v_max + 1)::text, 5, '0');
end;
$$;

comment on function public.next_clinical_encounter_protocol_number(uuid, int) is
  'Tenant içi yıllık muayene protokol numarası — RLS doctor scope dışında benzersizlik.';

revoke all on function public.next_clinical_encounter_protocol_number(uuid, int) from public;
grant execute on function public.next_clinical_encounter_protocol_number(uuid, int) to authenticated;
