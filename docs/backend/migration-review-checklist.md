# Migration Review Checklist

Supabase şema uygulanmadan önce (`20260521100000_draft_saas_schema_rls_v1.sql`).

## Tenant izolasyonu

- [ ] Tüm iş tablolarında `tenant_id NOT NULL` var mı?
- [ ] `memberships` üzerinden tenant üyeliği tanımlı mı?
- [ ] `unique (tenant_id, file_number)` hasta dosya no için uygun mu?
- [ ] Cross-tenant SELECT test planı hazır mı? ([rls-test-plan.md](rls-test-plan.md) G1)

## RLS

- [ ] İş tablolarında `ENABLE ROW LEVEL SECURITY` açıldı mı?
- [ ] **Policy yokken** Data API boş döner — bilinen durum ([rls-test-plan.md](rls-test-plan.md))
- [ ] Draft policy SQL review: [20260522100000_draft_rls_policies_v1.sql](../../supabase/migrations/20260522100000_draft_rls_policies_v1.sql)
- [ ] Policy’ler staging’de uygulandı mı? (production’a apply öncesi)
- [ ] Draft policy’ler tenant + rol ile uyumlu mu? ([permission-rls-matrix.md](permission-rls-matrix.md), [rls-policies-v1.md](rls-policies-v1.md))
- [ ] View üzerinde **doğrudan** `ENABLE ROW LEVEL SECURITY` / `CREATE POLICY` **yok** (PG view kısıtı)
- [ ] Operational summary view `DROP VIEW` + `CREATE` ile yenilendi (kolon azaltımı; **CASCADE yok**)
- [ ] View’da hassas kolonlar yok (`internal_doctor_note`, `clinical_data`, `appointment_id`)
- [ ] `clinical_encounter_operational_summary` `security_invoker` + güvenli özet kolonları
- [ ] `internal_doctor_note` tam tabloda yalnız doctor_admin; asistan/FTR özet erişimi ayrı fazda doğrulandı mı?
- [ ] `service_role` yalnızca sunucu/edge/seed script’te mi? (**istemci yok**)
- [ ] Cross-tenant SELECT engellendi mi? (staging test)
- [ ] Unauthorized INSERT/UPDATE engellendi mi?

## Hassas veri

- [ ] `clinical_encounters.internal_doctor_note` ayrı kolon
- [ ] Asistan / fizyoterapist / hemşire iç notu **göremiyor** (view veya policy)
- [ ] `clinical_encounter_operational_summary` view tanımlı mı?
- [ ] Assistant `internal_doctor_note` RLS testi (A1) geçti mi?

## Audit & silme

- [ ] `audit_logs` append-only (UPDATE/DELETE policy yok)
- [ ] `patients`, `appointments`, `clinical_encounters` için `deleted_at` soft delete
- [ ] `deleted_at` kayıtları normal SELECT’te gizleniyor mu?

## Storage

- [ ] `patient_files.storage_path` tenant-aware path standardı ([storage-and-pdf-paths.md](storage-and-pdf-paths.md))
- [ ] `pdf_outputs.storage_path` tenant-aware
- [ ] Private bucket + signed URL planı dokümante mi?
- [ ] Başka tenant dosya path erişimi engelli mi? (plan S4)

## Demo / freemium

- [ ] `subscriptions.plan_key = demo` taslağı
- [ ] `usage_limits.metric_key = patient_records`, `limit_value = 3` seed planı ([seed-plan.md](seed-plan.md))
- [ ] Limit **enforcement** sonraki fazda mı? (bu paket: metadata only)
- [ ] Demo/freemium test senaryoları (F1–F4) tanımlı mı?

## Roller & seed

- [ ] DB rolleri: `doctor_admin`, `assistant_secretary`, `physiotherapist`, `nurse`
- [ ] Flutter `AppRoles` mapping dokümante mi?
- [ ] `role_permissions` seed hazır mı?
- [ ] Test tenant + 4 kullanıcı seed planı ([seed-plan.md](seed-plan.md))

## Secrets & client

- [ ] `.env` gerçek değerleri commit edilmedi ([config.example.md](config.example.md))
- [ ] Flutter yalnızca `SUPABASE_ANON_KEY` kullanıyor
- [ ] `service_role` client tarafına **girmedi**

## Index & trigger

- [ ] Temel index’ler: tenant_id, patient_id, appointment_at, encounter_date
- [ ] `updated_at` trigger’ları gereken tablolarda aktif mi?

## Uygulama

- [ ] Migration staging’de test edildi
- [ ] RLS test planı çalıştırıldı ([rls-test-plan.md](rls-test-plan.md))
- [ ] Flutter varsayılan mock backend (gerçek bağlantı öncesi)
- [ ] JWT claim’leri (`tenant_id`, `profile_id`) Faz 6’da doğrulanacak
- [ ] Go/No-Go tamamlandı ([supabase-connection-prerequisites.md](supabase-connection-prerequisites.md))
