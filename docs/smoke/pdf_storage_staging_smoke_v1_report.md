# PDF Storage Hardening / Staging Smoke v1 — Rapor

**Tarih:** 2026-05-25  
**Paket:** PDF Storage Hardening / Staging Smoke v1  
**Önceki paket:** PDF Storage & Signed URL v1 (kod + 63 unit/widget test)

---

## 1. Ortam ve migration durumu

| Öğe | Durum | Not |
|-----|--------|-----|
| Supabase staging projesi (canlı JWT smoke) | **MANUEL BEKLİYOR** | Workspace’te yalnızca `.env.example`; staging `.env` ve 2 tenant × 4 rol JWT bu oturumda doğrulanmadı |
| Migration `20260530100000_patient_files_private_storage_bucket_v1.sql` | **KOD HAZIR** | Repo’da mevcut; staging’de `supabase db push` / pipeline ile operatör onayı gerekir |
| Flutter `DATA_BACKEND=supabase` | **MANUEL BEKLİYOR** | `flutter run --dart-define-from-file=.env` ile operatör smoke |
| Bucket `patient-files-private` public=false | **MANUEL BEKLİYOR** | SQL: `scripts/staging/pdf_storage_smoke_checks.sql` |
| service_role client tarafında | **PASS (statik)** | `lib/` içinde service_role kullanımı yok |

**Backend mod (yerel otomasyon):** Mock — `flutter test` ile regresyon doğrulandı.

---

## 2. Checklist pass/fail tablosu

| Alan | Otomasyon / statik | Staging manuel | Sonuç |
|------|-------------------|----------------|--------|
| Bucket mevcut + public=false | SQL script | Dashboard doğrulama | **BEKLİYOR** |
| Public URL negatif | — | Public path denemesi | **BEKLİYOR** |
| SELECT/INSERT policy + prefix | Migration inceleme | SQL + JWT | **PASS (kod)** / **BEKLİYOR (canlı)** |
| UPDATE/DELETE kapalı | Migration inceleme | Policy listesi | **PASS (kod)** |
| Role matrix (doctor/assistant/FTR/nurse) | Access gate + AuthSession testleri | UI smoke | **PASS (kısmi)** / **BEKLİYOR** |
| Cross-tenant negatif | RLS/policy tasarım inceleme | 2 tenant JWT | **BEKLİYOR** |
| Signed URL TTL 120 | Unit test | 121 sn bekleme | **PASS** / **BEKLİYOR** |
| signed_url kalıcı değil | Sanitizer + servis inceleme | DB spot SQL | **PASS (kod)** / **BEKLİYOR** |
| UI upload/view/PDF | Widget/unit testler | Supabase UI | **PASS (kısmi)** / **BEKLİYOR** |
| storage_path UI’da yok | Display/list testleri | Ekran kontrolü | **PASS (kod)** |
| url_launcher | — | Windows + web/mobil | **BEKLİYOR** |
| KVKK/security spot | Invariants test + timeline sanitizer | SQL metadata spot | **PASS (kısmi)** |
| Mock regression | `flutter test` 68/68 | — | **PASS** |
| flutter analyze (storage paths) | analyze | — | **0 error** |

---

## 3. P0 / P1 / P2 bulgular

### P0 (staging kanıtı olmadan kapatılmaz)

- Canlı **public bucket / public URL** erişimi — henüz test edilmedi.
- Canlı **cross-tenant** metadata/storage leak — henüz test edilmedi.
- **signed_url** veya dosya içeriğinin DB’ye yazılması — SQL spot staging’de doğrulanmalı.

*Bu oturumda P0 kanıtı bulunmadı (staging erişimi yok).*

### P1

- Yok (kod incelemesinde scope bypass veya TTL sapması tespit edilmedi).

### P2 / backlog

- **Mock PDF aç:** `PdfOutputViewLauncher` mock dalında `storagePath` model üzerinden doğrudan signed URL; route doctor-only ile korunuyor — staging’de asistan deep link ile doğrulanmalı.
- **Web `url_launcher`:** `drmem-mock://` bilinçli engel; gerçek Supabase URL web’de ayrı smoke.
- **Storage policy geniş SELECT:** Tenant prefix altında tüm roller SELECT alabilir; **asıl scope sınırı** `PatientFileMetadataAccessGate` + `getPatientFileMetadata` (RLS). Staging’de asistanın yanlış scope dosyasını açamadığı manuel doğrulanmalı.

---

## 4. Hotfix diff summary

**Kod değişikliği yapılmadı** — smoke FAIL kanıtı yok.

Eklenenler (smoke paketi kapsamında, davranış değiştirmeyen):

- `scripts/staging/pdf_storage_smoke_checks.sql` — operatör SQL checklist
- `test/patient_files/patient_file_storage_security_invariants_test.dart` — güvenlik regresyon testleri
- `docs/smoke/pdf_storage_staging_smoke_v1_report.md` — bu rapor

---

## 5. Remaining backlog

1. **Staging manuel smoke tamamlama** — 2 tenant, 4 rol, public URL negatif, TTL 121 sn, url_launcher platformları.
2. **Personel İzin v1**
3. **PDF audit / access event extension** (signed URL loglanmadan)
4. **Storage quota / subscription**
5. **Geniş cihaz QA** (iOS/Android tablette PDF açma)
6. **PDF template redesign** (ayrı paket)

---

## Statik doğrulama özeti (PASS)

- `PatientFileSignedUrlService`: `getPatientFileMetadata` → `PatientFileMetadataAccessGate.canView` → `createSignedUrl(120)`.
- `PdfOutputSignedUrlService`: `canViewPdfOutputs` → `getStoredRecord` (RLS) → signed URL.
- Migration: bucket `public=false`; SELECT/INSERT `tenants/{current_tenant_id()}/...` + membership + role; UPDATE/DELETE yok.
- `PatientFileMetadataSanitizer` + timeline sanitizer: `signed_url`, `storage_path` strip.
- UI: `PatientFileMetadataDisplay` storage_path göstermez; liste snackbar Türkçe.

---

## Operatör — staging smoke sırası (özet)

1. Migration push + `pdf_storage_smoke_checks.sql` çalıştır.
2. Doctor: upload PDF → listede aç → Dashboard’da object path.
3. Assistant: yalnız `clinic_operations` dosyası açılır; diğer scope reddedilir.
4. Nurse: dosya/PDF erişimi yok.
5. Tenant B id/path ile Tenant A JWT dene → red.
6. Signed URL kopyala → 2 dk bekle → aynı URL ölü → UI’dan yeniden aç.
7. Public URL şablonu dene → başarısız.

Smoke tamamlandığında bu rapordaki **BEKLİYOR** satırları PASS/FAIL ile güncelleyin.
