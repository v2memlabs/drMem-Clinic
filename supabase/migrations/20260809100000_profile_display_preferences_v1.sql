-- Kullanıcıya özel görünüm tercihleri — profiles.preferences_json.display

alter table public.profiles
  add column if not exists preferences_json jsonb not null default '{}'::jsonb;

comment on column public.profiles.preferences_json is
  'Kullanıcı tercihleri — display: tema, dil, tarih formatı';
