-- Malzeme şarjı — hemşire/FTR için hasta muayene seçenekleri (klinik detay yok).

create or replace function list_patient_encounters_for_material_charge(
  p_patient_id uuid
)
returns table (
  encounter_id uuid,
  patient_id uuid,
  patient_display_name text,
  encounter_date timestamptz,
  protocol_number text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ce.id as encounter_id,
    ce.patient_id,
    trim(concat_ws(' ', p.first_name, p.last_name)) as patient_display_name,
    ce.encounter_date,
    ce.protocol_number
  from clinical_encounters ce
  join patients p on p.id = ce.patient_id
  where ce.deleted_at is null
    and p.deleted_at is null
    and ce.tenant_id = current_tenant_id()
    and ce.patient_id = p_patient_id
    and _clinical_summary_access_allowed(
      ce.tenant_id,
      array['doctor_admin', 'assistant_secretary', 'nurse', 'physiotherapist']
    )
  order by ce.encounter_date desc, ce.updated_at desc;
$$;

comment on function list_patient_encounters_for_material_charge(uuid) is
  'Malzeme şarjı muayene seçimi — yalnızca id, tarih, protokol; klinik içerik yok.';

grant execute on function list_patient_encounters_for_material_charge(uuid) to authenticated;
