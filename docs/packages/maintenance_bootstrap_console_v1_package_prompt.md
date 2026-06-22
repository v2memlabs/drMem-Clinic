# DrMem Clinic — Maintenance / Bootstrap Console v1

> **Belge türü:** Uygulanabilir paket prompt taslağı (planlama only)  
> **Kod / migration / test:** Bu belgede yok — uygulama için §14 Cursor promptu kullanılır  
> **Önkoşul:** [staging_trial_result_report_v1.md](../staging_trial_result_report_v1.md) — Conditional Go / Practical Pass  
> **Üretim:** 2026-05-28

---

## 1. Paket adı

**Maintenance / Bootstrap Console v1** (`MAINTENANCE-BOOTSTRAP-v1`)

---

## 2. Amaç

Staging ve dahili dev ortamda, **yetkili bakım operatörünün** SQL Editor veya Dashboard’a girmeden uygulama içinden:

- `profiles.auth_user_id` ↔ Supabase Auth user eşlemesi
- Tenant (`tenants.status`) görünürlüğü ve staging’de düzeltme
- `memberships` oluşturma / rol / `status` düzeltme
- **Bootstrap zinciri** tanısı: `auth.uid()` → profile → active membership → active tenant

işlemlerini **kontrollü, audit’lenebilir ve RLS-bypass’sız (service_role yok)** şekilde yapabilmesi.

**Ürün sınırı:** Production SaaS admin paneli değil; normal klinik kullanıcılarına (doktor/asistan/FTR/hemşire) **görünmez**. Hasta / muayene / tıbbi veri düzenlemez.

---

## 3. Problem / kök neden özeti

| Sorun | Etki | Trial kanıtı |
|-------|------|----------------|
| Manuel `profiles.auth_user_id` bağlama | Login: “aktif klinik üyeliği yok” | SETUP-001 benzeri |
| Membership eksik / yanlış rol-status | Bootstrap fail, route guard block | Auth hotfix sonrası kısmen çözüldü |
| Tenant `suspended` / membership `disabled` | Oturum hazır değil, listeler boş | Operatör SQL müdahalesi |
| Aktif tenant’ın mock ile ezilmesi | Supabase sorguları boş tenant filtresi | Düzeltildi; tekrarını önlemek için diagnostic gerekli |
| SQL Editor ile müdahale | Hata riski, audit yok, PII sızıntısı | Staging trial operasyon yükü |

**Kök ihtiyaç:** Teknik bootstrap işlemlerini **tek kapı**, **çift kilit (ortam + operatör)** ve **güvenli RPC** ile toplamak.

---

## 4. Ortam / erişim modeli önerisi

### 4.1 Önerilen model: üç katmanlı kapı

| Katman | Mekanizma | Production |
|--------|-----------|------------|
| **A — Derleme / paket** | `MAINTENANCE_MODE=true` (`--dart-define`) | **Kapalı** (define yok veya `false`) |
| **B — Ortam** | `APP_ENV=staging` \| `dev` (yeni dart-define; `production` hariç) | `APP_ENV=production` → maintenance UI **hiç register edilmez** |
| **C — Operatör** | DB: `profiles.maintenance_operator = true` (veya allowlist tablosu) + RPC gate | Aynı gate; production’da RPC `maintenance_disabled` |

**Karar (öneri):** Üçünün **hepsi** true olmadan route ve RPC çalışmaz. Tek başına `doctor_admin` rolü **yeterli olmamalı** (klinik doktor ≠ bakım operatörü).

### 4.2 Ortam matrisi

| Ortam | Maintenance UI | Maintenance RPC (DB) |
|-------|----------------|----------------------|
| `dev` + flag + operatör | Açık | `maintenance_config.enabled = true` |
| `staging` + flag + operatör | Açık | `enabled = true` |
| `production` | **Kapalı** | `enabled = false` veya migration uygulanmaz |
| `mock` (`DATA_BACKEND=mock`) | **Kapalı** (anlamsız) | N/A |

### 4.3 `APP_ENV` vs mevcut `DATA_BACKEND`

| Define | Rol |
|--------|-----|
| `DATA_BACKEND=supabase` | Zaten var — maintenance yalnız Supabase modda anlamlı |
| `APP_ENV=staging\|dev\|production` | **Yeni** — maintenance ve telemetry ayrımı |
| `MAINTENANCE_MODE=true` | Bakım route’larını Flutter’da register eder |

`secrets/staging.json` örneği (repoda yok, operatör local):

```json
{
  "DATA_BACKEND": "supabase",
  "APP_ENV": "staging",
  "MAINTENANCE_MODE": "true",
  "SUPABASE_URL": "...",
  "SUPABASE_ANON_KEY": "..."
}
```

### 4.4 Production’da kapalı kalma garantisi

- Flutter: `AppMaintenanceConfig.isAvailable` → `APP_ENV != production && MAINTENANCE_MODE && isSupabase`
- Router: maintenance `GoRoute` listesi yalnız `isAvailable` iken eklenir
- DB: `maintenance_assert_enabled()` — `maintenance_config.enabled` false ise tüm maintenance RPC’ler `RAISE EXCEPTION 'maintenance_disabled'`
- CI: production build pipeline’da `MAINTENANCE_MODE` define’ı **yasak** (lint/script — opsiyonel v1.1)

---

## 5. Ekran / IA önerisi

### 5.1 Konum

| Seçenek | Öneri |
|---------|--------|
| Ayarlar altında herkese görünür | **Hayır** |
| Gizli route `/maintenance` | **Evet (v1)** |
| Login ekranında link | **Hayır** (staging’de bile keşfedilebilirlik riski) |

**Erişim yolu (v1):** Doğrudan URL `/maintenance` (yalnız flag+env+RPC ping geçince). İsteğe bağlı v1.1: Ayarlar’da **yalnız maintenance operatörüne** “Bakım konsolu” satırı (RPC `maintenance_ping` success sonrası).

### 5.2 Bilgi mimarisi

```
/maintenance                          → Maintenance Dashboard
/maintenance/diagnostics              → Bootstrap Diagnostics (chain)
/maintenance/auth-profile             → Auth ↔ Profile eşleştirme
/maintenance/tenants                  → Tenant listesi + status
/maintenance/memberships              → Membership listesi (filtreli)
/maintenance/memberships/new          → Kullanıcıyı kliniğe bağla
/maintenance/memberships/:id          → Rol / status düzenle
```

### 5.3 Ekran özetleri

| Ekran | İçerik |
|-------|--------|
| **Maintenance Dashboard** | Ortam rozeti (STAGING), operatör profil özeti, hızlı diagnostic özeti, son 10 maintenance audit (action only) |
| **Bootstrap Diagnostics** | Form: e-posta veya `profile_id` / `auth_user_id` → zincir kartları: Auth ✓/✗, Profile ✓/✗, Membership(s), Tenant status, önerilen düzeltme linki |
| **Auth / Profile** | Liste/arama: profiles; `auth_user_id` boş olanlar; aksiyon: Auth UUID yapıştır + onay; profil oluştur (email, display_name) |
| **Tenant listesi** | Tablo: name, specialty, status, id (copy); staging’de status dropdown → RPC update |
| **Membership listesi** | Filtre: tenant, email, status; kolonlar: tenant, profile email, **UI rol etiketi**, DB role key (küçük monospace), status |
| **Membership form** | tenant seç, profile seç/oluştur, role picker (UI label), status; kaydet → RPC |
| **Membership detail** | Rol değiştir, active/disabled/suspended |

### 5.4 UI ilkeleri

- Sade tablo + diagnostic kartlar (ClinicalListPanel değil; bakım amaçlı DataTable / ListTile yeterli)
- Onay diyaloğu: role/status/auth link değişikliklerinde
- Teknik ID: **yalnız maintenance ekranlarında**, monospace + copy-to-clipboard; **asla** hasta listesi / detay / normal ayarlar
- Hata metinleri: Türkçe, teknik Postgres kodu kullanıcıya gösterilmez
- `service_role`, `signed_url`, `storage_path` alanları **yok**

---

## 6. V1 kapsam içi işlemler

| ID | İşlem | Yöntem (öneri) |
|----|--------|----------------|
| M-01 | `profile.auth_user_id` bağla / güncelle | RPC `maintenance_link_profile_auth` |
| M-02 | Profile oluştur (email, display_name) | RPC `maintenance_create_profile` |
| M-03 | Profile düzelt (display_name; email dikkatli) | RPC `maintenance_update_profile` |
| M-04 | Tenant listele + status görüntüle | RPC `maintenance_list_tenants` |
| M-05 | Tenant status düzelt (staging) | RPC `maintenance_update_tenant_status` |
| M-06 | Membership oluştur | RPC `maintenance_create_membership` |
| M-07 | Membership role güncelle | RPC `maintenance_update_membership_role` |
| M-08 | Membership status güncelle | RPC `maintenance_update_membership_status` |
| M-09 | Bootstrap chain diagnostic (okuma) | RPC `maintenance_get_bootstrap_chain` |
| M-10 | Maintenance ping (erişim teyidi) | RPC `maintenance_ping` |
| M-11 | “Unlinked profiles” / “orphan auth” listesi (read-only) | RPC `maintenance_list_profile_auth_gaps` |

**DB role değerleri (değişmez):** `doctor_admin`, `assistant_secretary`, `physiotherapist`, `nurse` — UI’da [TenantRoleMapper](../lib/core/auth/tenant_role_mapper.dart) + yeni maintenance-specific label map.

**Status değerleri:** Mevcut CHECK constraint’lere uy (seed/migration’daki enum’lar — implementasyonda tablodan okunacak).

---

## 7. V1 kapsam dışı işlemler

| Madde | Neden |
|-------|--------|
| Supabase Auth user oluşturma | Dashboard/Admin API; güvenli server endpoint yok |
| Şifre sıfırlama / magic link | Auth admin API; ayrı paket |
| `service_role` istemci | Kesinlikle yasak |
| Hasta / randevu / muayene / dosya içeriği | Klinik veri; bu konsol değil |
| Tenant hard delete | Geri alınamaz risk |
| Production tenant silme / merge | SaaS admin kapsamı |
| Billing / subscription | Kapsam dışı |
| Multi-tenant owner self-service paneli | v2+ ürün |
| JWT custom claim (`profile_id`, `tenant_id`) yazma | Hotfix ile gerek kalmadı; v1’de dokunma |
| RLS policy edit UI | Tehlikeli; migration ile kalır |
| Toplu seed import | Ayrı seed paketi |

---

## 8. RLS / RPC / security yaklaşımı

### 8.1 İlkeler

1. Flutter **yalnızca** `anon` + kullanıcı JWT.
2. Bakım yazma işlemleri **doğrudan tablo UPDATE/INSERT değil** → `SECURITY DEFINER` RPC.
3. Her RPC başında: `maintenance_assert_enabled()` + `maintenance_assert_operator()`.
4. Operatör kontrolü: `profiles.maintenance_operator = true` (veya `maintenance_operators` allowlist).
5. RPC içinde `SET search_path = public`; tablo RLS’i definer ile aşılır ama **mantıksal gate** kodda kalır.
6. `GRANT EXECUTE ON FUNCTION ... TO authenticated`; `REVOKE` from `anon` where needed.
7. Production: `maintenance_config.enabled = false` → tüm RPC fail.

### 8.2 Neden RPC?

| Tablo | RLS gerçeği | Bakım ihtiyacı |
|-------|-------------|----------------|
| `profiles` | Kullanıcı kendi profilini görür | Başka profile `auth_user_id` yazma — normal rol ile imkânsız |
| `memberships` | Tenant member SELECT | Başka tenant’a membership INSERT — policy yok |
| `tenants` | Member SELECT | Status update — doctor_admin bile kısıtlı olabilir |

### 8.3 Örnek RPC imzaları (aday)

```sql
-- Okuma
maintenance_ping() → jsonb { ok, app_env_hint, operator_profile_id }
maintenance_get_bootstrap_chain(p_email text default null, p_profile_id uuid default null, p_auth_user_id uuid default null)
maintenance_list_tenants()
maintenance_list_memberships(p_tenant_id uuid default null, p_profile_id uuid default null)
maintenance_list_profile_auth_gaps()

-- Yazma (audit içerir)
maintenance_link_profile_auth(p_profile_id uuid, p_auth_user_id uuid)
maintenance_create_profile(p_email text, p_display_name text)
maintenance_update_profile(p_profile_id uuid, p_display_name text)
maintenance_update_tenant_status(p_tenant_id uuid, p_status text)
maintenance_create_membership(p_tenant_id uuid, p_profile_id uuid, p_role text, p_status text default 'active')
maintenance_update_membership_role(p_membership_id uuid, p_role text)
maintenance_update_membership_status(p_membership_id uuid, p_status text)
```

**Validasyon (RPC içi):**

- `p_role` ∈ known DB roles
- `p_status` ∈ allowed membership/tenant statuses
- `auth_user_id` uniqueness (bir auth user tek profile)
- Link öncesi: auth.users’ta uid var mı (opsiyonel `auth.users` read — definer)

### 8.4 Flutter route guard

```
canAccessMaintenance =
  AppMaintenanceConfig.isAvailable
  && AuthSession.isLoggedIn
  && SessionReadiness.isReady
  && maintenancePingSuccess (cache 5 dk veya her girişte)
```

Normal `AuthSession.canViewSettings` ile **bağlama**.

### 8.5 Mock tenant ezilmesi (regresyon)

- Maintenance ekranları `MockTenantContextBridge` çağırmaz.
- Diagnostic kartında: `ActiveTenantContextStore.current?.tenantId` vs DB `maintenance_get_bootstrap_chain` karşılaştırması (uyumsuzluk uyarısı).

---

## 9. Audit yaklaşımı

### 9.1 Evet — maintenance işlemleri audit edilmeli

Mevcut `audit_logs` + `record_audit_access_event` pattern’i genişletilir (**yeni tablo yok**).

| Alan | Değer |
|------|--------|
| `module` | `maintenance` |
| `action` | `maintenance.profile.link_auth`, `maintenance.membership.create`, … |
| `tenant_id` | Hedef membership tenant (yoksa null) |
| `actor_profile_id` | Operatör |
| `record_id` | `membership_id` veya `profile_id` |
| `patient_id` | **null** |

### 9.2 İzinli metadata (jsonb)

```json
{
  "target_profile_id": "uuid",
  "target_membership_id": "uuid",
  "target_tenant_id": "uuid",
  "field": "role",
  "before": "assistant_secretary",
  "after": "nurse",
  "before_status": "active",
  "after_status": "disabled",
  "source": "maintenance_console_v1"
}
```

### 9.3 Yasak metadata

- E-posta, telefon, display_name, hasta adı, tıbbi alanlar
- `service_role` key, JWT, şifre, signed_url, storage_path
- Ham SQL, exception stack

### 9.4 Okuma

- Maintenance dashboard: son N kayıt — doctor audit ekranından **ayrı** repository (`MaintenanceAuditReader`) — yalnız `module = maintenance` ve operatör RPC ile.

---

## 10. UI dili ve role label kararları

| DB `memberships.role` | UI etiketi (maintenance + uygulama geneli) |
|------------------------|---------------------------------------------|
| `doctor_admin` | Doktor |
| `assistant_secretary` | Asistan |
| `physiotherapist` | Fizyoterapist |
| `nurse` | Hemşire |

- Form picker: kullanıcıya **Türkçe label**; kayıtta **DB key**.
- Tabloda: birincil sütun label; ikincil (opsiyonel) küçük `doctor_admin` — yalnız maintenance.
- `TenantRoleMapper` tek kaynak; maintenance ayrı map **yazılmamalı**.

---

## 11. Dosya / migration / RPC adayları

### 11.1 Dokümantasyon (bu paket sonrası)

| Dosya | Açıklama |
|-------|----------|
| `docs/packages/maintenance_bootstrap_console_v1_spec.md` | Uygulama sonrası spec + RPC sözleşmesi |
| `docs/ops/staging_bootstrap_runbook_v1.md` | SQL yerine konsol adımları |

### 11.2 Migration (uygulama paketinde)

| Dosya | İçerik |
|-------|--------|
| `supabase/migrations/20260602100000_maintenance_bootstrap_console_v1.sql` | `maintenance_config`, `profiles.maintenance_operator`, RPC’ler, audit helper, grants |

### 11.3 Flutter (uygulama paketinde)

| Yol | Açıklama |
|-----|----------|
| `lib/core/config/app_env_config.dart` | `APP_ENV` parse |
| `lib/core/config/maintenance_config.dart` | `MAINTENANCE_MODE`, `isAvailable` |
| `lib/features/maintenance/` | screens, data sources, repositories |
| `lib/features/maintenance/data/maintenance_repository.dart` | RPC wrapper |
| `lib/core/router/app_router.dart` | Koşullu maintenance routes |
| `lib/core/router/maintenance_route_guard.dart` | ping + env gate |
| `test/maintenance/` | guard + label + ping mock tests |

### 11.4 Seed / staging

| Dosya | İçerik |
|-------|--------|
| `supabase/seed.sql` veya staging seed | `maintenance_config.enabled=true`; trial doctor-a `maintenance_operator=true` (opsiyonel, yalnız staging) |

---

## 12. Test planı taslağı

| ID | Senaryo | Beklenen |
|----|---------|----------|
| T-01 | `APP_ENV=production`, `MAINTENANCE_MODE=true` | Route yok / 404 redirect dashboard |
| T-02 | Staging, `MAINTENANCE_MODE` false | `/maintenance` erişilemez |
| T-03 | Staging, flag true, normal `doctor_admin` (operatör flag false) | RPC `maintenance_ping` forbidden |
| T-04 | Staging, operatör flag true | Dashboard açılır |
| T-05 | `maintenance_link_profile_auth` | Sonrası login bootstrap ready |
| T-06 | Membership create + role update | DB doğru; audit satırı `before`/`after` |
| T-07 | Role picker | UI “Asistan” → DB `assistant_secretary` |
| T-08 | `rg service_role` / `lib` grep | İstemcide service_role yok |
| T-09 | Audit metadata spot | Email/hasta adı yok |
| T-10 | Bootstrap chain RPC | auth→profile→membership→tenant active sırası doğru |
| T-11 | `AuthSession.setUser` sonrası | Active tenant mock ile ezilmez (mevcut regresyon testi + diagnostic) |
| T-12 | Production DB `maintenance_config.enabled=false` | Yazma RPC hepsi fail |

**Otomasyon:** Unit/widget guard testleri; RPC integration staging JWT ile manuel veya `supabase test` (v1.1).

---

## 13. Riskler / açık kararlar

| # | Konu | Seçenekler | Öneri (v1) |
|---|------|------------|------------|
| D-01 | Operatör kimliği | DB flag vs e-posta allowlist vs env secret | **DB flag** `profiles.maintenance_operator` + staging seed |
| D-02 | Auth user oluşturma | Dashboard vs Edge Function | **Dashboard** (dokümante runbook); konsolda “Auth UUID yapıştır” |
| D-03 | Tenant status değerleri | `active` / `suspended` / … | Migration CHECK ile sabitle; UI dropdown |
| D-04 | Membership `disabled` vs `inactive` | Seed ile uyum | Mevcut şemayı oku, RPC validate |
| D-05 | Maintenance audit SELECT | doctor audit ekranında mı? | **Hayır** — ayrı maintenance dashboard widget |
| D-06 | Çoklu membership | Diagnostic’te listele; v1 tek active öner | Listele; düzeltme operatör kararı |
| D-07 | `APP_ENV` introduce | Yeni define | Evet — production gate için |
| D-08 | Production migration | RPC var ama disabled | Evet — tek migration, `enabled` false prod’da |

| Risk | Azaltma |
|------|---------|
| Operatör flag yanlışlıkla prod’da true | Seed + review checklist; prod `enabled=false` |
| RPC definer açığı | Code review + `assert_operator` tek fonksiyon + minimal grant |
| Route keşfi | Gizli route + ping; robots N/A desktop |
| Audit’te PII | Metadata allowlist test |

---

## 14. Cursor’a verilecek nihai uygulama promptu taslağı

Aşağıdaki blok, uygulama oturumunda **olduğu gibi** yapıştırılabilir.

---

```markdown
# Uygulama paketi: DrMem Clinic — Maintenance / Bootstrap Console v1

## Bağlam
- Staging trial: Conditional Go ([docs/staging_trial_result_report_v1.md](docs/staging_trial_result_report_v1.md)).
- Auth Context Helper Hotfix uygulandı; login çalışıyor.
- Mock tenant ezilmesi düzeltildi ([lib/core/session/mock_tenant_context_bridge.dart](lib/core/session/mock_tenant_context_bridge.dart)) — maintenance diagnostic bunu doğrulamalı.
- Bu paket **production SaaS admin değil**; staging/dev bakım operatörü içindir.

## Görev
Maintenance / Bootstrap Console v1’i uçtan uca uygula: Supabase RPC + Flutter UI + route guard + audit + testler.

## Zorunlu ürün kuralları
1. Normal doktor/asistan/FTR/hemşire UI’ında maintenance görünmez.
2. Hasta/klinik tıbbi veri düzenlenmez.
3. Flutter’da **service_role yok**; yalnız anon + user JWT.
4. Yazma işlemleri yalnız SECURITY DEFINER RPC ile; her RPC’de `maintenance_assert_enabled()` + `maintenance_assert_operator()`.
5. Production: `APP_ENV=production` veya `maintenance_config.enabled=false` → UI kapalı, RPC fail.
6. DB role keys değişmez: doctor_admin, assistant_secretary, physiotherapist, nurse.
7. UI labels: Doktor, Asistan, Fizyoterapist, Hemşire ([TenantRoleMapper](lib/core/auth/tenant_role_mapper.dart)).
8. Teknik ID yalnız maintenance ekranlarında, copy ile; normal UI’da yok.
9. Audit: audit_logs module=maintenance; metadata’da PII/tıbbi veri/secret yok; before/after role/status OK.

## Ortam / define
- `APP_ENV`: staging | dev | production (yeni parse)
- `MAINTENANCE_MODE`: true/false (dart-define)
- `AppMaintenanceConfig.isAvailable` = supabase && APP_ENV!=production && MAINTENANCE_MODE==true

## Migration: `supabase/migrations/20260602100000_maintenance_bootstrap_console_v1.sql`
- Tablo `maintenance_config` (single row: enabled boolean)
- Kolon `profiles.maintenance_operator boolean default false`
- RPC’ler (§8.3 bu spec’teki liste)
- Her yazma RPC sonunda maintenance audit insert (record_audit_access_event veya dedicated helper)
- Staging seed notu: enabled=true; opsiyonel trial operatör flag

## Flutter
- `lib/core/config/app_env_config.dart`, `maintenance_config.dart`
- `lib/features/maintenance/` — dashboard, diagnostics, auth-profile link, tenants, memberships list/form
- `lib/core/router/maintenance_route_guard.dart` — env + maintenance_ping
- Koşullu routes `/maintenance/...` in app_router
- `MaintenanceRepository` — Supabase RPC çağrıları, Türkçe hata map

## v1 işlemler (yap)
- Link profile.auth_user_id
- Create/update profile (minimal)
- List tenants, update tenant status (staging only gate)
- Create/update membership role & status
- Bootstrap chain diagnostic
- List auth-profile gaps

## v1 (yapma)
- Auth user create/password reset
- service_role client
- Patient/clinical/file edit
- Hard delete tenant
- Billing

## Testler
- maintenance_route_guard_test: production/staging/flag/operator
- maintenance_role_label_test
- auth_session_supabase_tenant_test regresyonu koru
- maintenance_audit_metadata_test (no email in json)

## Dokümantasyon
- `docs/packages/maintenance_bootstrap_console_v1_spec.md` (RPC sözleşmesi)
- `docs/ops/staging_bootstrap_runbook_v1.md` (SQL yerine konsol adımları)

## Kabul kriterleri
- [ ] Staging: operatör doctor-a benzeri hesap flag ile konsola girer, auth link yapar, membership düzeltir
- [ ] Normal doctor (flag false) konsola giremez
- [ ] Production build’de maintenance route yok
- [ ] flutter test ilgili paketler geçer; analyze 0 error (değişen dosyalar)
- [ ] grep: service_role yok lib’de

Spec detay: [docs/packages/maintenance_bootstrap_console_v1_package_prompt.md](docs/packages/maintenance_bootstrap_console_v1_package_prompt.md)
```

---

## Referanslar

| Belge | İlişki |
|-------|--------|
| [staging_trial_result_report_v1.md](../staging_trial_result_report_v1.md) | Trial kararı + bootstrap risk |
| [staging_trial_workbook_v1.md](../staging_trial_workbook_v1.md) | SETUP-001 auth bağlama |
| [audit_kvkk_access_event_extension_v1.md](../audit_kvkk_access_event_extension_v1.md) | Audit metadata standardı |
| [backend/auth-transition.md](../backend/auth-transition.md) | Rol eşlemesi |
| `20260601100000_auth_context_helper_hotfix_v1.sql` | current_profile_id / current_tenant_id |

---

*Bu belge uygulama öncesi paket promptudur; implementasyon sonrası spec dosyası ile güncellenmelidir.*
