# Supabase Tam Entegrasyon Yol Haritası

> **Kural:** Bu entegrasyon tamamlanana kadar yeni özellik / yan iş açılmaz.
> Son güncelleme: 2026-06-21

Hedef: `DATA_BACKEND=supabase` + giriş + aktif tenant iken tüm klinik akışların gerçek veriyle çalışması; mock yalnızca test/offline fallback.

---

## Faz 0 — Altyapı stabilizasyonu

| # | Görev | Durum |
|---|--------|--------|
| 0.1 | `set_active_tenant_context` RPC + login/tenant sync | ✅ |
| 0.2 | `current_profile_id()` / `created_by` tutarlılığı | ✅ |
| 0.3 | FTR randevu RLS (physio INSERT/UPDATE) | ✅ |
| 0.4 | Storage UPDATE policy (PDF imza) | ✅ |
| 0.5 | Onam şablonları remote + seed | ✅ |
| 0.6 | Debug `flutter run` → staging asset | ✅ |
| 0.7 | Production CI `--dart-define` pipeline | ✅ |

---

## Faz 1 — Hibrit temizliği (tablo + repo var)

**Durum:** Faz 1 tamamlandı (1A + 1B + 1C) — hibrit temizliği bitti; Faz 2 mock-only modüllere geçildi.

### 1A — Kritik klinik akış (öncelik 1)

| Modül | DB | Remote | Eksik |
|--------|-----|--------|-------|
| Hastalar | ✅ | ✅ | Async/lookup ✅ |
| Randevular | ✅ | ✅ | Async/lookup ✅ |
| Muayene | ✅ | ✅ | Async/lookup ✅ |
| FTR yönlendirme | ✅ | ✅ | Polish + E2E |
| FTR seans | ✅ | ✅ | Remote-only doğrulama |
| Onam + şablon | ✅ | ✅ | Async-only resolver |
| PDF + Storage | ✅ | ✅ | Lookup/print mock fallback temizliği |
| Hasta dosyası | ✅ | ✅ | Eski `files` modülü birleştir |

**Kabul:** Doktor → muayene → FTR → randevu → onam → PDF uçtan uca kalıcı veri.

### 1B — Operasyonel kayıtlar (öncelik 2)

**Durum:** Faz 1B tamamlandı — lookup + PDF/timeline async; staging operasyonel seed migration eklendi.

Ödemeler, stok, ameliyat notu/şablon, görüntüleme, egzersiz, post-op — remote polish + staging seed ✅

### 1C — Ayarlar & platform (öncelik 3)

**Durum:** Faz 1C tamamlandı — audit log remote + async UI; timeline fail-fast resolver; ayarlar/etiketler zaten provider tabanlı.

Tenant/profil ayarları, izin, etiketler, timeline, audit log listesi (mock → remote) ✅

---

## Faz 2 — Mock-only modüller (yeni tablo gerekir)

### 2A — Muayene zinciri

**Durum:** Faz 2A tamamlandı — migration + RLS + remote repo + async UI + architecture testleri.

| Modül | Migration | Remote | UI async |
|--------|-----------|--------|----------|
| Reçeteler | ✅ | ✅ | ✅ |
| Lab istemleri | ✅ | ✅ | ✅ |
| Lab şablonları | ✅ | ✅ | ✅ |
| Radyoloji istemleri | ✅ | ✅ | ✅ |
| Klinik raporlar | ✅ | ✅ | ✅ |

Migration: `20260826180000_clinical_chain_remote_v1.sql` — staging'e `supabase db push` gerekir.

Staging seed (opsiyonel): henüz eklenmedi.

Her modül: migration + RLS → supabase repo → provider → UI async → staging seed.

### 2B — İletişim ✅

- Mesaj gönderimi + şablonları
- Migration: `20260826190000_messaging_remote_v1.sql`
- Remote stack: `message_templates` + `sent_messages` tabloları, provider, UI async

---

## Faz 3 — Legacy karar ✅

**Durum:** Faz 3 tamamlandı.

| Modül | Karar |
|--------|--------|
| `anamnesis`, `examination`, `treatment` | Kaldırıldı → `/clinical-records` redirect |
| `diagnosis` | Kaldırıldı → `/clinical-records/diagnosis-summary` redirect |
| `files` (legacy mock list) | `patient_files` metadata stack'e birleştirildi; `FileRepository` kaldırıldı |

---

## Faz 4 — Production ✅

**Durum:** Faz 4 tamamlandı — CI, migration drift, RLS audit testleri, rol gate.

| Alan | Durum |
|------|--------|
| CI `flutter analyze` + test + release web build (`--dart-define`) | ✅ `.github/workflows/ci.yml` |
| Migration drift (linked remote) | ✅ `.github/workflows/migration-drift.yml` + `scripts/ci/check_migration_drift.sh` |
| RLS migration audit | ✅ `test/architecture/rls_enabled_in_migrations_test.dart` |
| Rol E2E gate (doktor/asistan/fizyo route matrix) | ✅ `test/e2e/role_access_production_gate_test.dart` |
| Production env (debug asset yok) | ✅ `test/core/config/production_release_env_test.dart` |
| Canlı staging E2E | Manuel — [staging_live_e2e_readiness_execution_v1.md](staging_live_e2e_readiness_execution_v1.md) |

**GitHub secrets (migration drift):** `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF` (`dgzmybbgrofapjptjspf` staging).

---

## Uygulama sırası

1. ~~Faz 2B — Mesajlaşma~~ ✅
1. ~~Faz 3 — Legacy~~ ✅
1. ~~Faz 4 — Production CI~~ ✅
2. Canlı staging E2E + production deploy ← **SONRA**

---

## Tam entegre tanımı (Done)

1. Mock modül kalmadı (reçete, lab, radyoloji, mesaj, klinik rapor dahil)
2. Production path'te `Repository.instance` / mock list ecreanları yok
3. Doktor / asistan / fizyoterapist E2E geçiyor
4. Release build dart-define ile ortam ayrımı net
5. Migration drift yok
