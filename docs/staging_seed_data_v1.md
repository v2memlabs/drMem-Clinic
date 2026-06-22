# Staging Seed Data v1

> **Paket kapsamı:** Yalnızca local / staging / dev ortamı için güvenli, tekrar çalıştırılabilir demo seed verisi.  
> **Production’da çalıştırmayın.** Gerçek hasta verisi, gerçek şifre veya `service_role` anahtarı bu repoda yoktur.

## Amaç

Supabase staging/dev ortamında uygulamayı rol bazlı ve gerçekçi şekilde test etmek:

- Tenant, membership, hasta, randevu, muayene
- `internal_doctor_note` güvenlik testi (yalnız doctor/admin kolonu)
- Assistant / Physiotherapist safe summary RPC projection testleri
- Patient file / PDF **metadata** (içerik yok, signed URL yok)
- Timeline RPC kaynak tabloları
- Cross-tenant / RLS negatif testleri (en az iki aktif tenant)

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `supabase/seed.sql` | Supabase CLI seed giriş noktası (`db reset` sonrası) |
| `supabase/seeds/staging_seed_data_v1.sql` | Ana seed SQL (deterministic UUID + `ON CONFLICT`) |
| `docs/staging_seed_data_v1.md` | Bu doküman |

## Production uyarısı

| Kural | Açıklama |
|-------|----------|
| **Asla production** | Bu SQL production veritabanına uygulanmamalıdır. |
| **Fake veri** | Tüm isimler, telefonlar ve klinik metinler açıkça demo/seed içindir. |
| **Auth şifreleri** | Repoda yazılmaz; staging secret store veya Auth Admin API kullanın. |
| **service_role** | Repoya veya Flutter client’a yazılmaz; yalnızca sunucu tarafı admin script için. |

SQL içinde ortam guard (ör. `current_database() = 'prod'`) zorunlu değildir; güvenlik operasyonel süreç + bu dokümandır.

## Çalıştırma

### Local (önerilen)

```bash
# Migrations + seed (seed.sql otomatik)
supabase db reset
```

Yalnızca seed’i tekrar uygulamak (mevcut veriyi silmez, idempotent upsert):

```bash
psql "$DATABASE_URL" -f supabase/seeds/staging_seed_data_v1.sql
```

### Staging (manuel)

1. Migration’ların staging’de uygulandığını doğrulayın.
2. SQL Editor veya CI job ile **yalnızca** `staging_seed_data_v1.sql` çalıştırın.
3. Production branch / prod DB’ye bağlanmadığınızı iki kez kontrol edin.

### RLS testleri için önemli

| Yöntem | RLS sonucu |
|--------|------------|
| SQL Editor + **service_role** | RLS bypass — **yanıltıcı** |
| Flutter / PostgREST + **authenticated** + JWT `tenant_id` / `profile_id` | Gerçek RLS davranışı |

RLS ve cross-tenant testlerini **mutlaka** authenticated oturumlarla yapın.

## Auth kullanıcı oluşturma (checklist)

Seed SQL **auth.users** eklemez. Her demo profile için Auth kullanıcısı oluşturup `profiles.auth_user_id` bağlayın.

### Önerilen akış (staging)

1. Supabase Dashboard → Authentication → Add user **veya** Auth Admin API (sunucu tarafı, `service_role` yalnızca bu script’te).
2. E-posta: aşağıdaki `@example.test` adresleri (gerçek kişi e-postası kullanmayın).
3. Şifre: staging secret store’da tutun; repoya yazmayın.
4. Oluşan `auth.users.id` değerini ilgili `profiles.auth_user_id` satırına güncelleyin:

```sql
-- Örnek (staging SQL editor — auth user id'yi kendi ortamınızdan alın)
update profiles
set auth_user_id = '<AUTH_USER_UUID_FROM_DASHBOARD>'
where id = 'b0000001-0001-4001-8001-000000000001';
```

5. JWT custom claims (Faz 1 Auth): `profile_id`, `tenant_id` — uygulama oturum köprüsü ile set edilir.

### Demo kullanıcı / rol matrisi

| Profile ID (seed) | E-posta (placeholder) | Tenant | DB rolü | Flutter rol |
|-------------------|----------------------|--------|---------|-------------|
| `b0000001-...000001` | `doctor-a@example.test` | A | `doctor_admin` | doctor |
| `b0000001-...000011` | `assistant-a@example.test` | A | `assistant_secretary` | assistant |
| `b0000001-...000021` | `physio-a@example.test` | A | `physiotherapist` | physiotherapist |
| `b0000001-...000031` | `nurse-a@example.test` | A | `nurse` | nurse |
| `b0000001-...000002` | `doctor-b@example.test` | B | `doctor_admin` | doctor |
| `b0000001-...000012` | `assistant-b@example.test` | B | `assistant_secretary` | assistant |
| `b0000001-...000022` | `physio-b@example.test` | B | `physiotherapist` | physiotherapist |
| `b0000001-...000091` | `inactive-a@example.test` | A | `assistant_secretary` | — (`status=disabled`) |
| `b0000001-...000099` | `no-membership@example.test` | — | *(membership yok)* | — |

## Demo tenant matrisi

| Tenant ID | Ad | status | Amaç |
|-----------|-----|--------|------|
| `a0000001-...000001` | DrMem Demo Clinic A | `active` | Ana test verisi |
| `a0000001-...000002` | DrMem Demo Clinic B | `active` | Cross-tenant RLS |
| `a0000001-...000003` | DrMem Suspended Clinic | `suspended` | Suspended tenant → veri dönmemeli |

## Seed stratejisi

- **Deterministic UUID:** Testlerde sabit ID referansı.
- **`ON CONFLICT`:** Tekrar çalıştırılabilir; mevcut local veriyi toplu silmez.
- **Auth ayrı:** `profiles.auth_user_id` null kalabilir; Auth sonradan bağlanır.
- **internal_doctor_note:** Yalnız `clinical_encounters.internal_doctor_note` kolonu; `clinical_data` içinde `internalDoctorNote` / `privateNote` **yok**.
- **Dosyalar:** `storage_path` fake private path; `signedUrl` / `publicUrl` / binary içerik **yok**.

## Hangi ekranı ne besler?

| Test alanı | Seed kaynağı |
|------------|--------------|
| Dashboard / randevu listesi | Tenant A: bugün/geçmiş/gelecek/iptal/ertelenmiş randevular |
| Hasta listesi / detay | Tenant A: 8 hasta; Tenant B: 3 hasta |
| Doctor muayene formu | `ce000001-...001` — `internal_doctor_note` dolu |
| Assistant safe summary | RPC + `diagnosis_summary`, `visit_type`, `status`, `appointment_id`, `plan.controlDate`, `plan.physiotherapyReferral` |
| Physio safe summary | `bodyRegion`, `side`, `plan.*`, `examination.rangeOfMotion`, `sports.returnToSportGoal` |
| Patient files metadata | `visibility_scope`: doctor_admin, clinic_operations, physiotherapy |
| PDF metadata | `pdf_outputs` — doctor_admin visibility |
| Timeline | patients / appointments / clinical_encounters / patient_files / pdf_outputs `created_at` / `updated_at` (son 30 gün dağılımı) |

## Test akışları

### Doctor / Admin (Tenant A)

1. `doctor-a@example.test` ile giriş, tenant JWT = Clinic A.
2. Hasta `SEED-A-001` (Demo Sporcu Diz) → muayene `ce000001-...001`.
3. **internal_doctor_note** görünür olmalı (tam CE path).
4. Assistant/physio oturumlarında aynı encounter’da internal not **görünmemeli**.

### Assistant (Tenant A)

1. `assistant-a@example.test`, tenant A.
2. `list_assistant_clinical_summaries` → `ce000001-...001` için `has_physiotherapy_referral = true`, `next_control_date` dolu.
3. `patient_files` → `clinic_operations` scope dosyaları görünür; `doctor_admin` only dosyalar görünmez.
4. Tenant B hasta/randevu → **0 satır** (cross-tenant).

### Physiotherapist (Tenant A)

1. `physio-a@example.test`, tenant A.
2. `list_physiotherapist_clinical_summaries` → diz/omuz/spine örnekleri, `physiotherapy_referral`, ROM, rehab alanları.
3. `patient_files` → `physiotherapy` scope (`seed-pt-plan.pdf` metadata).
4. Tenant B verisi → **0 satır**.

### Nurse (Tenant A)

1. `nurse-a@example.test`, tenant A.
2. Hasta listesi (read) mümkün; clinical safe summary / timeline clinical events → **kısıtlı veya boş** (RLS/RPC tasarımına göre).
3. `patient_files` → **0 satır** (metadata RLS).

### Cross-tenant / RLS

| Senaryo | Beklenen |
|---------|----------|
| Assistant A → Tenant B hasta | Erişim yok |
| Physio A → Tenant B encounter summary | Erişim yok |
| Doctor A → Tenant B (JWT tenant A) | Erişim yok |
| Suspended tenant C | Active membership olsa bile tenant `status=suspended` → gate false |

### internalDoctorNote güvenlik

- Seed encounter `ce000001-...001` ve Tenant B `ce000002-...002` kolonda fake internal not taşır.
- `clinical_data` JSON’da internal/private anahtar yoktur.
- Assistant/physio RPC çıktısında internal not alanı yoktur.

### Safe summary

| Rol | Örnek encounter | Kontrol |
|-----|-----------------|---------|
| Assistant | `ce000001-...001` | diagnosis, visit_type, status, appointment_id, next_control_date, physio referral |
| Physio | `ce000001-...001`, `...004`, `...005` | body_region, side, exercise/rehab/ROM/post-op/FTR alanları |

### Timeline

Hasta `p0000001-...001` için `list_patient_timeline_events`:

- patient.created/updated (zaman damgaları seed’de dağıtılmış)
- appointment.* (planlı, iptal, güncelleme)
- clinical.encounter.* (doctor path; nurse kısıtlı)
- file.metadata.* / pdf.metadata.* (rol allowlist’e göre)

### Patient file metadata

- İçerik yok; yalnızca `storage_path`, `display_name`, `file_kind`, `visibility_scope`.
- `metadata` JSON: `seedTag` gibi güvenli anahtarlar; `clinical_data` / `internalDoctorNote` / `fileContent` yok.

## Sabit kimlik referansı (özet)

```
Tenant A:  a0000001-0001-4001-8001-000000000001
Tenant B:  a0000001-0001-4001-8001-000000000002
Tenant C:  a0000001-0001-4001-8001-000000000003 (suspended)

Patient A-001 (timeline rich): `10000001-0001-4001-8001-000000000001` (eski hatalı `p…` prefix düzeltildi — yalnız hex UUID)
Encounter + internal note:     `ce000001-0001-4001-8001-000000000001`
```

Tam liste: `supabase/seeds/staging_seed_data_v1.sql`.

## İlgili dokümanlar

- `docs/backend/seed-plan.md` — taslak plan (referans)
- `supabase/migrations/20260524100000_safe_clinical_role_summary_projection_v1.sql`
- `supabase/migrations/20260526100000_timeline_db_projection_rpc_v1.sql`

## Sonraki paket

**Remote Manual Smoke Test Checklist v1** — bu seed verisi üzerinde uzaktan manuel smoke adımları.
