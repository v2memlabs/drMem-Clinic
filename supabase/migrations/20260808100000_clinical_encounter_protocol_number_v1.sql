-- Muayene protokol numarası — tenant içi benzersiz referans (reçete/rapor/istem).

alter table clinical_encounters
  add column if not exists protocol_number text;

create unique index if not exists idx_clinical_encounters_tenant_protocol
  on clinical_encounters (tenant_id, protocol_number)
  where deleted_at is null and protocol_number is not null;

comment on column clinical_encounters.protocol_number is
  'Klinik belgelerde referans — örn. M-2026-00001';
