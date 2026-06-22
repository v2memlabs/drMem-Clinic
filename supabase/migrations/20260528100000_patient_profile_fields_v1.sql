-- Patient basic profile fields v1 (nullable, additive; RLS unchanged)

alter table patients add column if not exists identity_type text;
alter table patients add column if not exists nationality text;
alter table patients add column if not exists blood_type text;
alter table patients add column if not exists occupation text;
alter table patients add column if not exists sports_branch text;
alter table patients add column if not exists secondary_phone text;
alter table patients add column if not exists email text;
alter table patients add column if not exists address text;
alter table patients add column if not exists city text;
alter table patients add column if not exists district text;
alter table patients add column if not exists emergency_contact_name text;
alter table patients add column if not exists emergency_contact_relation text;
alter table patients add column if not exists emergency_contact_phone text;
alter table patients add column if not exists emergency_contact_note text;

-- gender, national_id already exist on patients (rls schema v1)
