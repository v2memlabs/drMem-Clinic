# Staging Remote Gate / Migration / RLS Verification v1

**DrMem Clinic — Operatör runbook**  
**Tarih:** 2026-05-28  
**Kaynak bulgular:** Staging Full Smoke v2, Full Product QA v2  
**Kapsam:** FTR, ödeme, onam, stok, PDF remote akışlarının staging’de neden yüklenemediğini/kaydedilemediğini izole etmek.

> **Bu pakette kod değişikliği yok.** Yalnızca SQL smoke scriptleri ve bu runbook.

---

## 1. Amaç

Staging’de aşağıdaki modüllerin toplu “yüklenemedi / kaydedilemedi” hatasının kök nedenini **migration → schema → auth zinciri → RLS → provider gate → PostgREST embed → storage** sırasıyla ayırmak.

Ana hipotezler:

| # | Hipotez | Doğrulama |
|---|---------|-----------|
| H1 | `202607*` migration’lar staging’de uygulanmamış | `schema_migrations` + tablo/kolon varlığı |
| H2 | `current_tenant_id` / membership zinciri bozuk | Profil `auth_user_id`, active membership |
| H3 | Capability `true` → Supabase repo seçiliyor ama tablo/RLS eksik | Gate + schema script birlikte |
| H4 | PostgREST embed/select kolon uyumsuzluğu | FK + PGRST200/201 network log |
| H5 | PDF ayrıca sync/mock source parity | Liste OK + prefill fail pattern |

---

## 2. Ön koşullar

### 2.1 Ortam

| Değişken | Beklenen |
|----------|----------|
| `DATA_BACKEND` | `supabase` |
| `APP_ENV` | `staging` |
| `secrets/staging.json` | URL + anon key mevcut |

Flutter başlatma:

```powershell
flutter run -d windows --dart-define-from-file=secrets/staging.json
```

### 2.2 Migration push durumu

Staging Supabase projesinde aşağıdaki migration’ların **hepsi** `supabase_migrations.schema_migrations` içinde olmalı:

| Version | Dosya | Tablolar / fonksiyonlar |
|---------|-------|-------------------------|
| `20260601100000` | `auth_context_helper_hotfix_v1.sql` | `current_profile_id()`, `current_tenant_id()`, `is_tenant_member()`, `has_tenant_role()` |
| `20260701100000` | `operational_records_remote_v2a.sql` | `payments`, `consents` |
| `20260702100000` | `operational_records_remote_v2b_inventory.sql` | `inventory_items`, `inventory_movements`, `record_inventory_movement()` |
| `20260703100000` | `ftr_referral_remote_v1.sql` | `physiotherapy_referrals` |
| `20260704100000` | `ftr_sessions_remote_v2.sql` | `physiotherapy_sessions` |

PDF/storage için ayrıca (genelde daha önce uygulanmış olmalı):

- `20260522100000_draft_rls_policies_v1.sql` veya güncel PDF policy migration’ları
- `20260525200000_patient_file_pdf_storage_metadata_v1.sql`

### 2.3 Staging kullanıcıları

| E-posta | Rol | Tenant |
|---------|-----|--------|
| `doctor-a@example.test` | `doctor_admin` | A |
| `assistant-a@example.test` | `assistant_secretary` | A |
| `physio-a@example.test` | `physiotherapist` | A |
| `nurse-a@example.test` | `nurse` | A |
| `doctor-b@example.test` | `doctor_admin` | B (cross-tenant) |

Seed referans: `docs/staging_seed_data_v1.md`, `supabase/seeds/staging_seed_data_v1.sql`  
Tenant A UUID: `a0000001-0001-4001-8001-000000000001`

### 2.4 Auth user bağlantısı

Her test kullanıcısı için:

1. Supabase Auth’ta kullanıcı var mı?
2. `profiles.auth_user_id` = Auth UID mi?

Bootstrap konsolu: `docs/ops/staging_bootstrap_runbook_v1.md` (`/maintenance`, `MAINTENANCE_MODE=true`).

---

## 3. Migration checklist

SQL Editor’da `scripts/staging/staging_remote_schema_checks.sql` **bölüm 0** çalıştır.

- [ ] 5 satır (`20260601100000` … `20260704100000`) — eksik satır = deploy gerekli
- [ ] `payments`, `consents`, `inventory_*`, `physiotherapy_*` tabloları `exists = true`
- [ ] Her tabloda `rls_enabled = true`, `policy_count > 0`
- [ ] Kritik kolonlar `missing_columns` boş
- [ ] `record_inventory_movement` fonksiyonu var
- [ ] `set_updated_at` trigger’ları bağlı

**Fail →** `supabase db push` veya CI migration pipeline’ı staging’e uygula; tekrar schema script.

---

## 4. Auth / profile / membership checklist

`scripts/staging/staging_remote_rls_smoke_checks.sql` çalıştır.

- [ ] Tüm demo kullanıcılarda `auth_user_id` dolu (`auth_link_status = OK`)
- [ ] `membership_status = active`, `tenant_status = active`
- [ ] Rol eşleşmesi doğru (doctor-a → `doctor_admin`, vb.)
- [ ] Tenant A’da en az 1 aktif hasta (FK hedefleri)

### SQL Editor uyarısı

`current_auth_user_id()`, `current_profile_id()`, `current_tenant_id()` SQL Editor’da (service_role) **NULL döner — bu normal**.

JWT bağlamı doğrulama:

1. Flutter’da `doctor-a` ile giriş
2. DevTools → Network → herhangi bir `rest/v1/*` isteği → `Authorization: Bearer …` var mı?
3. İsteğe bağlı: `/maintenance` → Bootstrap tanı → zincir yeşil

---

## 5. Capability flags checklist

Kodda sabit `true` (staging’de repo **Supabase’e geçer**, tablo yoksa fail):

| Flag | Sınıf | Etki |
|------|-------|------|
| `paymentsTableReady` | `OperationalRecordsRemoteCapabilities` | Ödeme remote |
| `consentsTableReady` | aynı | Onam remote |
| `inventoryTablesReady` | aynı | Stok remote |
| `referralsTableReady` | `FtrRemoteCapabilities` | FTR yönlendirme |
| `sessionsTableReady` | aynı | FTR seans |

**Not:** Capability `true` + migration eksik = kullanıcıya “yüklenemedi”, log’da `relation does not exist` veya PostgREST 404/400.

---

## 6. Provider gate checklist

Remote repo seçimi için **hepsi** gerekli (`*RepositoryBackendGate` pattern):

| Koşul | Nasıl doğrulanır |
|-------|------------------|
| `AppBackendConfig.isMock == false` | `DATA_BACKEND=supabase` |
| `SupabaseEnvConfig.isSupabaseConfigured` | staging.json URL/key |
| `SupabaseClientInitializer.isInitialized` | Uygulama açılış log / ilk API çağrısı |
| `AuthSession.isLoggedIn` | Giriş sonrası |
| `SessionReadiness.isReady` | Bootstrap tamamlandıktan sonra |
| `ActiveTenantContextStore.current != null` | Tenant A UUID set |
| Rol uygunluğu | `AuthSession.canView*` / `canEdit*` |

**Gate geçti ama DB fail** → migration/RLS sorunu (H1/H2).  
**Gate geçmedi** → auth/bootstrap/tenant (H2) veya rol (UI “yetki yok”).

---

## 7. SQL smoke execution order

Supabase Dashboard → SQL Editor → staging projesi.

| Sıra | Script | Rol | Amaç |
|------|--------|-----|------|
| 1 | `staging_remote_schema_checks.sql` | service_role | Migration + tablo + RLS + kolon + index + trigger |
| 2 | `staging_remote_rls_smoke_checks.sql` | service_role | Profil/membership/seed hasta |
| 3 | `staging_remote_role_matrix_checks.sql` §1, §5, §6 | service_role | Policy haritası + FK embed |
| 4 | `staging_remote_role_matrix_checks.sql` §3 | service_role | Yapısal insert smoke (yorum aç, UUID doldur) |
| 5 | `staging_remote_pdf_storage_smoke_checks.sql` | service_role | Bucket + metadata + path |

**RLS allow/deny** SQL Editor ile test edilemez (service_role bypass). Bölüm 8 Flutter smoke zorunlu.

---

## 8. Flutter UI smoke execution order

Her adımda DevTools Network’te HTTP status + PostgREST `code` not al.

### 8.1 doctor-a (Tenant A)

1. Giriş → dashboard yüklenir
2. **Ödemeler** → liste yüklenir (200) → yeni ödeme kaydet
3. **Onamlar** → liste → bekleyen sayısı
4. **Stok** → liste → ürün ekle → giriş/çıkış hareketi
5. **FTR Yönlendirmeler** → liste → yeni yönlendirme
6. **FTR Seans** (physio veya doctor görünümü) → seans ekle
7. **PDF** → liste OK → yeni PDF (kaynak seçimi notu: mock parity ayrı paket)

### 8.2 assistant-a

1. Ödeme/onam **sidebar’da olmayabilir** (nav tasarımı) — doğrudan route veya deep link ile test
2. Ödeme/onam liste + oluştur
3. FTR / muayene / stok → erişim reddi veya boş

### 8.3 physio-a

1. Yönlendirme listesi + durum güncelleme
2. Seans listesi + yeni seans
3. Hasta listesi → uygulama gate (“hasta listesi yok”) — RLS’ten ayrı not et
4. Ödeme/stok/PDF → reddedilmeli

### 8.4 nurse-a

1. Stok liste + hareket RPC
2. FTR/ödeme/onam/PDF → reddedilmeli

### 8.5 Cross-tenant

1. `doctor-a` → Tenant B hasta/yönlendirme/ödeme görünmemeli
2. Tenant A `patient_id` ile Tenant B `tenant_id` insert → fail

---

## 9. Expected pass/fail matrix

| Rol | payments | consents | inventory | FTR ref | FTR sess | PDF | clinical | patients |
|-----|----------|----------|-----------|---------|----------|-----|----------|----------|
| doctor_admin | S/I/U | S/I/U | S/I/U | S/I/U | S/I | S/I | S/I/U | S |
| assistant | S/I/U | S/I/U | DENY | DENY | DENY | DENY | DENY | S |
| physiotherapist | DENY | DENY | DENY | S/U* | S/I | DENY | DENY | app DENY** |
| nurse | DENY | DENY | S/I/U+RPC | DENY | DENY | DENY | DENY | S*** |

\* Physio UPDATE: yalnızca güvenli alanlar (`status`, `notes_safe`)  
\*\* `canViewPatients=false` — UI route kapalı; DB policy ayrı raporlanır  
\*\*\* Nurse patient SELECT mevcut patients RLS’e bağlı

---

## 10. Common failure interpretation

| Belirti / log | Olası kök neden | Sonraki adım |
|---------------|-----------------|--------------|
| `relation "payments" does not exist` | Migration v2a uygulanmamış | §3 migration push |
| `relation "physiotherapy_referrals" does not exist` | Migration v1 uygulanmamış | §3 |
| `column "X" does not exist` | Eski/partial migration | Schema script §4, migration diff |
| `42501 permission denied` | RLS deny veya rol uyumsuz | §4 membership, §8 rol smoke |
| `current_tenant_id()` NULL (JWT test) | `auth_user_id` boş / membership yok | Bootstrap §2.4 |
| PostgREST `PGRST205` | Tablo yok | Migration |
| PostgREST `PGRST200` / `PGRST201` | Embed FK / relationship | role_matrix §6 FK |
| UI “yüklenemedi” + 403/42501 | RLS (H2) | RLS smoke + rol matrix |
| UI “yüklenemedi” + 404 relation | Migration (H1) | Schema script |
| Gate stub / mock davranışı | `DATA_BACKEND` mock veya gate false | §6 checklist |
| PDF liste OK, prefill “kaynak bulunamadı” | Sync mock source (app) | PDF Source Parity paketi |
| PDF kayıt fail + DB insert yok | Upload/storage/RLS | pdf_storage script §5–6 |
| PDF insert var, Aç fail | signed URL veya `launchUrl` | §6C triage tablosu |

---

## 11. Operational module smoke (runbook özeti)

Detay SQL: `staging_remote_role_matrix_checks.sql` §3.

### Payments

- SELECT count
- INSERT minimal
- SELECT inserted row
- Soft delete → RLS altında görünmez
- assistant: allow; nurse/physio: deny

### Consents

- SELECT count
- INSERT `status=bekliyor`
- Pending count (assistant dashboard KPI)

### Inventory

- INSERT item → UPDATE → `record_inventory_movement('giris')` → `record_inventory_movement('cikis')`
- Oversell → exception
- nurse/doctor: allow; assistant/physio: deny

### FTR referrals

- Doctor INSERT → physio SELECT + safe UPDATE
- assistant/nurse: deny

### FTR sessions

- INSERT valid `referral_id` + `patient_id` same tenant
- physio/doctor SELECT; assistant/nurse deny
- cross-tenant patient_id → deny

### PDF / storage

- `pdf_outputs` metadata INSERT (doctor)
- `patient_files` metadata SELECT
- Bucket private; public URL deny
- Signed URL TTL manuel smoke
- Aç sorunu: storage_path vs signed URL vs launchUrl ayrımı (`staging_remote_pdf_storage_smoke_checks.sql` §6C)

---

## 12. Debug log önerisi (kod yazılmadı)

**Remote Failure Debug Logging v1** (ayrı mini paket önerisi):

- Repository error mapper `unknown` durumunda `kDebugMode`’da PostgREST `code` + `message` + `details` loglansın
- UI’a ham hata taşınmasın (mevcut kullanıcı mesajları korunur)
- Staging smoke sırasında operatör logcat/console’dan PGRST/42501 ayırt edebilir

---

## 13. Sonuçların raporlanması

Şablon: `docs/smoke/staging_full_smoke_v2_report.md` formatına uygun kısa ekleme.

Her modül için:

```
Modül: FTR Referrals
Schema: PASS/FAIL (not)
Auth chain: PASS/FAIL
RLS doctor-a: PASS/FAIL (HTTP code)
Flutter UI: PASS/FAIL
Kök neden: H1/H2/H3/H4/H5
Kanıt: SQL screenshot / network log snippet
Önerilen fix paketi: ...
```

Rapor dosyası önerisi: `docs/smoke/staging_remote_verification_result_v1.md`

---

## 14. Önerilen sonraki paketler (kod — bu runbook dışı)

| Sıra | Paket | Ne zaman |
|------|-------|----------|
| 0 | **Bu verification pack** | İlk — kök neden izolasyonu |
| 1 | Remote Failure Debug Logging v1 | Smoke tekrarında log yetersizse |
| 2 | Operational Records Staging Fix Pack | H1/H2 operational modüllerde confirm |
| 3 | FTR Referral/Session Staging Fix Pack | FTR-specific migration/RLS/embed |
| 4 | PDF Remote Source & Save Stabilization Pack | Schema OK ama prefill/save/Aç fail |

---

## Ek: Script dosyaları

| Dosya | Açıklama |
|-------|----------|
| `scripts/staging/staging_remote_schema_checks.sql` | Migration + tablo + kolon + RLS + index + trigger |
| `scripts/staging/staging_remote_rls_smoke_checks.sql` | Profil, membership, seed, auth helper |
| `scripts/staging/staging_remote_role_matrix_checks.sql` | Policy matrix + operational smoke + FK |
| `scripts/staging/staging_remote_pdf_storage_smoke_checks.sql` | Bucket, metadata, path, PDF triage |
| `scripts/staging/pdf_storage_smoke_checks.sql` | Önceki kısa versiyon (referans) |
