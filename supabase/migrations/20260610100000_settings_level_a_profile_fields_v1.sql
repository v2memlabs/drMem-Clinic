-- Settings Level A — profil iletişim alanları (first_name, last_name, title, phone).
-- Mevcut profiles_update_own RLS ile uyumlu; kullanıcı yalnızca kendi satırını günceller.

alter table public.profiles
  add column if not exists first_name text,
  add column if not exists last_name text,
  add column if not exists title text,
  add column if not exists phone text;

comment on column public.profiles.first_name is 'Profil ayarları — ad';
comment on column public.profiles.last_name is 'Profil ayarları — soyad';
comment on column public.profiles.title is 'Profil ayarları — ünvan (örn. Op. Dr.)';
comment on column public.profiles.phone is 'Profil ayarları — telefon';
