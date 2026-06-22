# Test Seed Planı (Draft v1)

> **Bu doküman plandır.** Migration deploy, seed script çalıştırma veya gerçek Auth kullanıcı oluşturma **yapılmaz**.

Referans şema: `supabase/migrations/20260521100000_draft_saas_schema_rls_v1.sql`

## Test ortamı özeti

| Varlık | Sayı | Not |
|--------|------|-----|
| Tenant | 1 | `DrMem Test Klinik` |
| Profile | 4 | Rol başına 1 |
| Membership | 4 | Hepsi `active` |
| Subscription | 1 | `plan_key = demo` |
| Usage limit | 1 | `patient_records` = 3 |
| Patients | 3 | Demo isimler (limit sınırında) |
| Appointments | 2 | |
| Clinical encounters | 2 | Biri `internal_doctor_note` dolu |
| Patient files (metadata) | 2 | `storage_path` tenant-aware |
| PDF outputs (metadata) | 1 | |
| Audit logs | 3 | Append-only örnek |

## Sabit kimlikler (placeholder UUID — uygulamada üretilir)

Staging’de sabit UUID kullanmak RLS testlerini kolaylaştırır. Örnek prefix:

| Kayıt | Örnek id (taslak) |
|-------|-------------------|
| `tenants.id` | `11111111-1111-1111-1111-111111111101` |
| `profiles` (doctor) | `22222222-2222-2222-2222-222222222201` |
| … | Staging seed SQL’de `gen_random_uuid()` veya sabit set |

## 1. Test tenant

| Alan | Değer |
|------|--------|
| `name` | DrMem Test Klinik |
| `specialty` | Ortopedi ve Travmatoloji (Test) |
| `timezone` | Europe/Istanbul |
| `status` | `active` |

İkinci tenant (`tenant-b`) yalnızca **cross-tenant RLS** testleri için opsiyonel; MVP seed’de zorunlu değil.

## 2. Test kullanıcıları (Auth + profile)

**Gerçek şifre yazılmaz.** Staging’de test şifresi secret store’da tutulur.

| Rol (DB) | Flutter | E-posta (placeholder) | `display_name` |
|----------|---------|----------------------|----------------|
| `doctor_admin` | `doctor` | `doctor@example.test` | Test Doktor |
| `assistant_secretary` | `assistant` | `assistant@example.test` | Test Asistan |
| `physiotherapist` | `physiotherapist` | `physio@example.test` | Test Fizyoterapist |
| `nurse` | `nurse` | `nurse@example.test` | Test Hemşire |

### auth.users nasıl oluşturulur?

| Yöntem | Kullanım | Not |
|--------|---------|-----|
| **Supabase Auth Admin API** | Önerilen (staging) | `service_role` yalnızca **sunucu/admin script**; Flutter’da **asla** |
| Dashboard “Add user” | Manuel QA | Az sayıda test kullanıcı |
| Doğrudan SQL `auth.users` | **Önerilmez** | Hash/trigger uyumu riskli |

Akış:

1. Admin API veya Dashboard ile `auth.users` oluştur
2. `profiles` satırı: `auth_user_id` = auth user id
3. `memberships` satırı: `profile_id` + `tenant_id` + `role`

## 3. Memberships

Her profile için tek membership, aynı test tenant:

| profile | `role` | `status` |
|---------|--------|----------|
| doctor | `doctor_admin` | `active` |
| assistant | `assistant_secretary` | `active` |
| physio | `physiotherapist` | `active` |
| nurse | `nurse` | `active` |

`TenantRoleMapper` (Flutter): `doctor` ↔ `doctor_admin`, vb. — [permission-rls-matrix.md](permission-rls-matrix.md)

## 4. role_permissions (minimal seed)

`permissions` + `role_permissions` migration yorumlarındaki taslak anahtarlar uygulanmalı. Özet:

- `doctor_admin`: tüm iş izinleri (audit, full clinical, pdf, timeline)
- `assistant_secretary`: patients/appointments/files/consents/payments + summary view
- `physiotherapist`: physiotherapy + summary view
- `nurse`: patients (read) + inventory

## 5. Demo subscription & usage

| Tablo | Değer |
|-------|--------|
| `subscriptions.plan_key` | `demo` |
| `subscriptions.status` | `active` |
| `usage_limits.metric_key` | `patient_records` |
| `usage_limits.limit_value` | `3` |
| `usage_limits.period` | `lifetime` |

Enforcement: **yok** (bilgilendirme); bkz. [demo-freemium-schema.md](demo-freemium-schema.md)

## 6. Test patients (fake veri)

Gerçek hasta verisi **yok**. Açıkça demo isimler:

| file_number | first_name | last_name |
|-------------|------------|-----------|
| DEMO-001 | Demo | Hasta Bir |
| DEMO-002 | Demo | Hasta İki |
| DEMO-003 | Demo | Hasta Üç |

Tümü aynı `tenant_id`. `deleted_at` null.

4. hasta: yalnızca **freemium test senaryosu** için INSERT denemesi (RLS/enforcement sonraki faz).

## 7. Test appointments

- 2 randevu, farklı `patient_id`, `tenant_id` test tenant
- `status`: `scheduled` / `completed`

## 8. Test clinical_encounters

| Kayıt | `internal_doctor_note` | Amaç |
|-------|------------------------|------|
| ENC-1 | Dolu metin | Asistan/FTR/hemşire SELECT testi |
| ENC-2 | Null veya boş | Özet view testi |

Asistan yalnızca `clinical_encounter_operational_summary` view görmeli.

## 9. patient_files & pdf_outputs (metadata)

Path standardı: [storage-and-pdf-paths.md](storage-and-pdf-paths.md)

```
{tenant_id}/patients/{patient_id}/files/{file_id}/demo.pdf
{tenant_id}/patients/{patient_id}/pdf/{pdf_output_id}.pdf
```

Bucket oluşturma bu pakette **yok**.

## 10. audit_logs

- 3 örnek: `patient.view`, `appointment.create`, `clinical_encounter.update`
- `actor_profile_id` = test doctor profile
- UPDATE/DELETE policy olmamalı (append-only)

---

## Seed sırası ve FK bağımlılıkları

```
1. tenants
2. auth.users (Admin API / Dashboard) → profiles (auth_user_id)
3. memberships
4. permissions + role_permissions
5. subscriptions + usage_limits
6. patients
7. appointments
8. clinical_encounters
9. patient_files, pdf_outputs (metadata)
10. audit_logs
11. usage_events (opsiyonel, freemium test)
```

| Adım | Bağımlılık |
|------|------------|
| profiles | `auth.users` (opsiyonel FK sonradan) |
| memberships | tenants, profiles |
| patients | tenants |
| appointments | tenants, patients, profiles (created_by) |
| clinical_encounters | tenants, patients |
| patient_files / pdf_outputs | tenants, patients |
| audit_logs | tenants, profiles |

## Güvenlik notları

- **service_role**: yalnızca seed script / CI admin job (sunucu tarafı)
- **Flutter client**: yalnızca `SUPABASE_ANON_KEY`
- Seed SQL dosyası gerçek key içermez
- Prod’da bu fake hasta verisi kullanılmaz

## İlgili dokümanlar

- [rls-test-plan.md](rls-test-plan.md)
- [migration-review-checklist.md](migration-review-checklist.md)
- [supabase-connection-prerequisites.md](supabase-connection-prerequisites.md)
