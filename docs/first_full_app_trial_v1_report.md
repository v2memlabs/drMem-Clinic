# First Full App Trial v1 — Report

> **Paket türü:** Test, deneme ve raporlama (kod değişikliği yok).  
> **Üretim tarihi:** 2026-05-24  
> **Güncelleme:** 2026-05-24 — Agent oturumu: canlı testler **Blocked** (credential yok). Kullanıcı canlı staging denemesi sonrası özet: **[staging_trial_report_v1.md](staging_trial_report_v1.md)** (**Conditional Go**, majör blokaj bildirilmedi).  
> **Önceki:** Staging Live E2E Readiness v1 — canlı sonuç işleme formatı (kod değişikliği yok).  
> **Canlı trial özeti (resmi):** [staging_trial_report_v1.md](staging_trial_report_v1.md)  
> **Referans checklist’ler:** [remote_manual_smoke_test_checklist_v1.md](remote_manual_smoke_test_checklist_v1.md), [supabase_rls_manual_smoke_v1.md](supabase_rls_manual_smoke_v1.md), [staging_seed_data_v1.md](staging_seed_data_v1.md), [negative_rls_test_checklist_v1.md](negative_rls_test_checklist_v1.md)  
> **Canlı yürütme runbook:** [staging_live_e2e_readiness_execution_v1.md](staging_live_e2e_readiness_execution_v1.md)

---

## Yürütme durumu (okunması zorunlu)

| Katman | Durum | Kanıt |
|--------|--------|--------|
| **Canlı Supabase staging E2E** | **Partial** (2026-05-24) | Kullanıcı canlı deneme yaptı — özet [staging_trial_report_v1.md](staging_trial_report_v1.md). Agent oturumu: credential yoktu → workbook **Blocked**. Tam SMK/RLS kanıtı hâlâ eksik. |
| **Supabase RLS API (authenticated JWT)** | **Blocked** (2026-05-24) | User JWT / staging PostgREST erişimi yok. |
| **Mock mod** | **Pass (auto)** | `flutter test` auth route + cache + timeline → 66 passed; tam manuel mock UI: Blocked (aynı oturum). |
| **Statik kod / mimari inceleme** | **Tamamlandı** | Route guard, DTO sanitizer, repository gate, unit testler. |

**Sonuç etiketleri bu raporda:**

| Etiket | Anlam |
|--------|--------|
| **Pass (design)** | Mimari + unit test ile uyumlu; canlı staging teyidi bekleniyor. |
| **Pass (auto)** | Otomatik test geçti. |
| **Not Tested (live)** | Canlı staging’de insan QA çalıştırmalı. |
| **Partial** | Kısmen uyumlu veya bilinçli ürün sınırı. |
| **Fail** | Bilinen uyumsuzluk veya blokaj. |

### Canlı sonuç işleme (QA)

Her **LIVE-*** maddesi için doldurun (detaylı adımlar: [staging_live_e2e_readiness_execution_v1.md](staging_live_e2e_readiness_execution_v1.md)):

| Alan | Açıklama |
|------|----------|
| **Live Status** | `Pass` \| `Fail` \| `Partial` \| `Not Tested` |
| **Evidence** | Screenshot path, HAR, `evidence/rls/*.json`, tarih/saat |
| **Bug ID** | Issue tracker ID (Fail/Partial) |
| **Severity** | Critical \| High \| Medium \| Low |
| **Next Action** | Hotfix paketi veya backlog |

---

## Live Results Workbook

> QA: Canlı staging oturumu sonrası **Live Status** sütununu güncelleyin. Evidence klasörünü repoya commit etmeyin (secret riski).

| Execution ID | Live Status | Evidence | Bug ID | Severity | Next Action |
|--------------|-------------|----------|--------|----------|-------------|
| LIVE-DOC-01 | Blocked | Agent: no staging URL/key; readiness R-01…R-05 Fail | — | High | QA: `secrets/staging.json` + `flutter run` |
| LIVE-DOC-02 | Blocked | Depends LIVE-DOC-01 | — | High | Same |
| LIVE-DOC-03 | Blocked | Depends LIVE-DOC-01 | — | High | Same |
| LIVE-DOC-04 | Blocked | Depends LIVE-DOC-01 | — | High | Same |
| LIVE-DOC-05 | Blocked | Depends LIVE-DOC-01 | — | High | Same |
| LIVE-DOC-06 | Blocked | Depends LIVE-DOC-01 | — | Medium | Same |
| LIVE-DOC-07 | Blocked | Depends LIVE-DOC-01 | — | Medium | Same |
| LIVE-DOC-08 | Blocked | Depends LIVE-DOC-01 | — | Low | Same |
| LIVE-AST-01 | Blocked | Depends LIVE-DOC-01 | — | High | Same |
| LIVE-AST-02 | Blocked | Depends LIVE-DOC-01 | — | High | Same |
| LIVE-AST-03 | Blocked | Depends LIVE-DOC-01 | — | High | Same |
| LIVE-AST-04 | Blocked | Depends LIVE-DOC-01 | — | Critical | Same |
| LIVE-PHY-01 | Blocked | Depends LIVE-DOC-01 | — | High | Same |
| LIVE-PHY-02 | Blocked | Depends LIVE-DOC-01 | — | High | Same |
| LIVE-PHY-03 | Blocked | Depends LIVE-DOC-01 | — | High | Same |
| LIVE-PHY-04 | Blocked | Depends LIVE-DOC-01 | — | Medium | Same |
| LIVE-PHY-05 | Blocked | Depends LIVE-DOC-01 | — | Medium | Same |
| LIVE-NUR-01 | Blocked | Depends LIVE-DOC-01 | — | High | Same |
| LIVE-NUR-02 | Blocked | Depends LIVE-DOC-01 | — | Critical | Same |
| LIVE-RLS-01 | Blocked | No user JWT; API-01…13 not run | — | Critical | QA: authenticated curl |
| LIVE-CCH-01 | Blocked | No multi-role live session | — | High | QA manual |
| LIVE-CCH-02 | Blocked | No live app | — | Medium | QA manual |
| LIVE-UX-01 | Blocked | No live app / network sim | — | Medium | QA manual |
| LIVE-MCK-01 | Pass (auto) | `flutter test` 66 passed (auth route, cache, timeline); manual UI not run | — | Low | Optional mock UI walkthrough |

---

## 1. Test ortamı

| Alan | Değer |
|------|--------|
| **Test tarihi** | 2026-05-24 |
| **Ortam** | staging/dev (hedef); rapor üretimi: local repo analizi |
| **Backend mode (hedef)** | `DATA_BACKEND=supabase` + `SupabaseEnvConfig` dolu |
| **Backend mode (rapor oturumu)** | Varsayılan mock (`AppBackendConfig`); canlı supabase denemesi yok |
| **Seed data** | `supabase/seeds/staging_seed_data_v1.sql` repoda mevcut — **canlı uygulama teyidi: Not Tested (live)** |
| **Demo tenantlar** | Tenant A/B/C seed’de tanımlı — **canlı teyit: Not Tested (live)** |
| **Demo kullanıcılar** | `doctor-a@`, `assistant-a@`, `physio-a@`, `nurse-a@`, `doctor-b@` … `@example.test` — Auth `profiles.auth_user_id` bağlantısı [staging_seed_data_v1.md](staging_seed_data_v1.md) checklist’ine bağlı |
| **Mock mod ayrı test** | **Evet (kısmi)** — unit/widget testler; tam manuel mock walkthrough: Not Tested (live) |

### Hedef roller

| Rol | Kullanıcı (seed) | Tenant |
|-----|------------------|--------|
| Doctor/Admin A | `doctor-a@example.test` | Clinic A |
| Assistant/Secretary A | `assistant-a@example.test` | Clinic A |
| Physiotherapist A | `physio-a@example.test` | Clinic A |
| Nurse A | `nurse-a@example.test` | Clinic A |
| Doctor/Admin B | `doctor-b@example.test` | Clinic B |

**Güvenlik:** Production test yok. `service_role` UI/RLS doğrulaması yok. Gerçek hasta verisi yok.

---

## 2. Doctor/Admin test özeti (Supabase hedef)

| Alan | Sonuç | Severity | Notlar |
|------|--------|----------|--------|
| Auth login / tenant / logout | **Not Tested (live)** | High | `SupabaseAuthRepository` + `SupabaseMembershipLoader` kodda mevcut; seed Auth bağlantısı gerekir. |
| Dashboard remote özet | **Not Tested (live)** | Medium | Seed bugün randevuları `2026-05-24` referanslı. |
| Patients CRUD | **Not Tested (live)** | High | RLS: `doctor_admin` + `assistant` insert/update; doctor read. |
| Appointments CRUD + iptal | **Not Tested (live)** | High | |
| Clinical list/detail/create/update | **Not Tested (live)** | High | |
| internalDoctorNote görünür | **Pass (design)** | Critical | `clinical_encounter_form_screen` + `clinical_encounter_detail_display`; yalnız `canViewFullClinicalEncounter`. |
| internalDoctorNote ∉ clinical_data UI | **Pass (design)** | Critical | Ayrı kolon mapper; form structured fields + `ClinicalEncounterClinicalData.toMap`. |
| Patient file metadata list | **Not Tested (live)** | Medium | UI: `PatientFileMetadataDisplay` storage path göstermez. |
| Download/preview kapalı | **Pass (design)** | — | Storage fazı yok; beklenen. |
| Timeline | **Not Tested (live)** | Medium | **Pass (auto):** timeline UI testleri (66 test). Doctor-only route. |
| Audit/KVKK route | **Pass (design)** | Low | `canViewAuditLogs` → doctor only. |

---

## 3. Assistant/Secretary test özeti (Supabase hedef)

| Alan | Sonuç | Severity | Notlar |
|------|--------|----------|--------|
| Login + operasyonel dashboard | **Not Tested (live)** | High | Dashboard kartları `AuthRoutePermissions` ile filtrelenir. |
| Patients list/detail | **Not Tested (live)** | High | RLS patients: assistant allowed. |
| Appointments operasyonel | **Not Tested (live)** | High | |
| diagnosis-summary + RPC alanları | **Not Tested (live)** | High | **Pass (design):** `AssistantClinicalSummaryDto` internal note / clinical_data okumaz. |
| Full clinical gizli | **Pass (design)** | Critical | `canViewClinicalEncounters` false; URL guard. |
| Forbidden routes | **Pass (auto)** | Critical | `test/core/auth_route_permissions_test.dart` (16 test). |
| internalDoctorNote yok | **Pass (design)** | Critical | Model + DTO + mapper. |
| raw clinical_data yok | **Pass (design)** | Critical | |

---

## 4. Physiotherapist test özeti (Supabase hedef)

| Alan | Sonuç | Severity | Notlar |
|------|--------|----------|--------|
| Login + FTR dashboard | **Not Tested (live)** | High | |
| clinical-summaries RPC alanları | **Not Tested (live)** | High | **Pass (design):** `PhysiotherapistClinicalSummaryDto` allowlist. |
| Full clinical kapalı | **Pass (design)** | Critical | Route + session. |
| Timeline subset (RPC) | **Not Tested (live)** | Medium | DB: physio subset var; **UI route kapalı** (`canViewPatientTimeline` doctor only) → **Partial** ürün tutarlılığı. |
| Patients list (remote) | **Pass (design)** | Medium | RLS: physio **patients SELECT yok** → liste boş beklenir. |
| Patient files (physiotherapy scope) | **Partial** | Medium | RLS seed: physio scope dosya var; Flutter `canViewFiles` **false** → `/files` UI yok. |
| Forbidden: audit, payment, assistant summary | **Pass (design)** | High | |

---

## 5. Nurse test özeti (Supabase hedef)

| Alan | Sonuç | Severity | Notlar |
|------|--------|----------|--------|
| Login + nurse dashboard | **Not Tested (live)** | High | |
| Patients read | **Not Tested (live)** | Medium | RLS: nurse patients OK. |
| Inventory | **Not Tested (live)** | Low | `canViewInventory` true. |
| Full clinical / summaries / timeline / audit / payment / PDF | **Pass (design)** | Critical | Session + route matrix. |
| Timeline RPC | **Pass (auto)** | High | `timeline_repository_backend_gate_test`: nurse remote flag false. |
| Patient files | **Pass (design)** | High | RLS metadata: nurse no rows; UI `canViewFiles` false. |

---

## 6. Cross-tenant / RLS test özeti

| Alan | Sonuç | Severity | Notlar |
|------|--------|----------|--------|
| Tenant B verisi Tenant A JWT ile görünmez | **Not Tested (live)** | Critical | Migration + seed B kayıtları hazır; [supabase_rls_manual_smoke_v1.md](supabase_rls_manual_smoke_v1.md) `RLS-RLS-*` çalıştırılmalı. |
| Direct patient/encounter/file ID URL | **Pass (design)** | Critical | Repository tenant scope + RLS; UI guard. |
| Assistant/physio cross-RPC | **Pass (design)** | Critical | `_clinical_summary_access_allowed` + `current_tenant_id()`. |
| SQL Editor / service_role | **N/A** | — | Kasıtlı kullanılmadı. |

**Statik güvenlik değerlendirmesi:** Critical sızıntı **tespit edilmedi** (kod incelemesi); **canlı RLS smoke zorunlu** sign-off öncesi.

---

## 7. Cache / session switch test özeti

| Alan | Sonuç | Severity | Notlar |
|------|--------|----------|--------|
| Doctor → logout → Assistant (clinical cache) | **Pass (auto)** | High | `RepositoryCacheCoordinator` + `test/core/repository_cache_coordinator_test.dart` (49 test). |
| Assistant → Physio summary cache | **Pass (auto)** | High | `resetAllCaches()` on auth/tenant hooks. |
| Tenant switch stale data | **Not Tested (live)** | High | Mock tenant bridge var; remote multi-tenant UI: Not Tested. |
| Browser refresh bootstrap | **Not Tested (live)** | Medium | |
| No active tenant güvenli state | **Pass (design)** | Medium | Timeline/files `notConfigured` / `noActiveTenant` kullanıcı mesajları. |

---

## 8. Mock mode regression özeti

| Alan | Sonuç | Severity | Notlar |
|------|--------|----------|--------|
| Rol dropdown login | **Pass (design)** | High | `MockAuthRepositoryAdapter.signInMock`. |
| Dashboard / patients / appointments | **Not Tested (live)** | Medium | Mock data stores mevcut. |
| Doctor clinical mock | **Pass (design)** | Medium | Mock clinical encounters. |
| Assistant/physio summary ekranları | **Pass (design)** | Medium | Mock mappers. |
| Patient file metadata UI | **Pass (auto)** | Low | Presentation layer testleri (ilgili feature testler). |
| Timeline UI | **Pass (auto)** | Medium | 42+ timeline widget/state testleri. |
| Role visibility ↔ Supabase matrix | **Pass (auto)** | High | `auth_route_permissions_test`. |
| Supabase notConfigured ana akışı bozmaz | **Pass (design)** | Medium | `AppBackendConfig` mock fallback. |

**Mock genel:** **Conditional Pass** — otomatik testler yeşil; tam manuel mock walkthrough QA’da önerilir.

---

## 9. Loading / error / empty state gözlemi

| Gözlem | Sonuç | Severity | Notlar |
|--------|--------|----------|--------|
| Timeline loading / error / empty | **Pass (auto)** | Low | `timeline_list_user_messages`, stale-load generation testleri. |
| Teknik exception / PostgREST / enum UI’da | **Pass (design)** | High | Mapper’lar kullanıcı mesajına çevirir; **canlı ağ hatası: Not Tested**. |
| Empty list metinleri | **Pass (design)** | Low | |
| Stale veri flash | **Pass (auto)** | Medium | Timeline `_loadGeneration` pattern. |
| Dashboard count tutarlılığı | **Not Tested (live)** | Medium | |

---

## 10. Bulgular (severity)

### Critical

| ID | Bulgu | Durum | Önerilen aksiyon |
|----|--------|--------|------------------|
| C-01 | Canlı staging’de cross-tenant / internalDoctorNote sızıntısı | **Not Tested (live)** | [supabase_rls_manual_smoke_v1.md](supabase_rls_manual_smoke_v1.md) critical set çalıştır; Fail ise Security Hotfix. |
| — | Statik incelemede Critical kod defect | **Yok (şu an)** | — |

> **Not:** Critical liste boş sayılmamalı — canlı RLS/UI smoke tamamlanmadan production’a yakın ortamda **Go verilmemeli**.

### High

| ID | Bulgu | Önerilen aksiyon |
|----|--------|------------------|
| H-01 | Supabase E2E trial (tüm roller) canlı çalıştırılmadı | QA: [remote_manual_smoke_test_checklist_v1.md](remote_manual_smoke_test_checklist_v1.md) + bu rapor tablosunu doldur. |
| H-02 | Auth seed (`profiles.auth_user_id`) staging’de manuel | [staging_seed_data_v1.md](staging_seed_data_v1.md) Auth checklist. |
| H-03 | Remote CRUD (patient/appointment/CE) doğrulanmadı | First Trial Bugfix Batch v1 — yalnız Fail maddeler. |
| H-04 | RLS API smoke (authenticated) doğrulanmadı | Supabase RLS Manual Smoke v1 oturumu. |

### Medium

| ID | Bulgu | Önerilen aksiyon |
|----|--------|------------------|
| M-01 | Physio: DB `patient_files` physiotherapy scope var; UI `/files` route kapalı (`canViewFiles` assistant+doctor) | Ürün kararı: FTR dosya ekranı ekle veya dokümante “v2”. Remote Trial Polish veya nav genişletme **ayrı paket**. |
| M-02 | Physio: `patients` RLS yok → remote hasta listesi boş; özet RPC üzerinden çalışıyor | Beklenen v1; UX metni “hasta seçimi” netleştir. |
| M-03 | Timeline RPC assistant/physio subset (DB) vs UI yalnız doctor | Bilinçli v1 ise dokümante; değilse Timeline nav genişletme planı. |
| M-04 | `DATA_BACKEND=supabase` + boş URL → sessiz mock fallback | Trial build komutunu dokümante et; yanlış yapılandırma riski. |
| M-05 | Seed “bugün” tarih sabiti vs QA takvimi | Seed yenileme veya dinamik tarih (ayrı paket). |
| M-06 | Dashboard remote sayı tutarlılığı | Not Tested (live). |

### Low

| ID | Bulgu | Önerilen aksiyon |
|----|--------|------------------|
| L-01 | 228 analyzer info/warning | Bilinçli ertelendi; ayrı hygiene paketi. |
| L-02 | CE / patient client-side arama MVP | İyileştirme backlog. |
| L-03 | Görsel/responsive polish | Remote Trial Polish Batch v1. |

---

## 11. Test sonuç tablosu (ana akışlar)

| Area | Role | Test | Result | Severity | Notes | Suggested next action |
|------|------|------|--------|----------|-------|------------------------|
| Auth | doctor | Login/logout/tenant | Not Tested (live) | High | Auth seed gerekli | Staging Auth setup |
| Dashboard | doctor | Remote özet | Not Tested (live) | Medium | Tarih seed | Live smoke |
| Patients | doctor | CRUD + arama | Not Tested (live) | High | | Bugfix if Fail |
| Appointments | doctor | CRUD + iptal | Not Tested (live) | High | | Bugfix if Fail |
| Clinical | doctor | CRUD + internal note | Pass (design) / Not Tested (live) | Critical | Kod hazır | RLS + UI smoke |
| Files | doctor | Metadata list | Pass (design) / Not Tested (live) | Medium | No path in UI | Live smoke |
| Timeline | doctor | Patient timeline | Pass (auto) / Not Tested (live) | Medium | 66 tests | Live smoke |
| Audit | doctor | Route | Pass (design) | Low | | Live smoke |
| Dashboard | assistant | Operasyonel | Not Tested (live) | High | | Live smoke |
| Safe summary | assistant | diagnosis-summary | Pass (design) / Not Tested (live) | High | DTO allowlist | RLS S1–S7 |
| Forbidden | assistant | Full clinical URL | Pass (auto) | Critical | Route tests | — |
| Safe summary | physio | clinical-summaries | Pass (design) / Not Tested (live) | High | | RLS S8–S14 |
| Files | physio | Metadata UI | Partial | Medium | RLS var, UI yok | Product decision |
| Patients | physio | List | Pass (design) | Medium | RLS no rows | Expected |
| Forbidden | physio | clinical/audit/payment | Pass (design) | High | | — |
| Patients | nurse | Read | Not Tested (live) | Medium | | Live smoke |
| Inventory | nurse | Stok | Not Tested (live) | Low | | Live smoke |
| Forbidden | nurse | Clinical/timeline/files | Pass (design/auto) | Critical | Gate tests | — |
| RLS | all | Cross-tenant | Not Tested (live) | Critical | | RLS smoke |
| Cache | multi | Logout/rol switch | Pass (auto) | High | 49 tests | Live confirm |
| Mock | multi | Regression | Pass (auto/design) | Medium | Partial manual | Mock walkthrough |
| UX | multi | Error messages | Pass (design/auto) | Medium | | Live network test |

---

## 12. Genel karar: First Full App Trial sonucu

| Boyut | Karar |
|-------|--------|
| **Mock mod** | **Conditional Go** — route guard, cache isolation, timeline/files UX testleri geçti; tam manuel mock walkthrough önerilir. |
| **Supabase remote** | **No-Go (live sign-off pending)** — canlı staging E2E ve authenticated RLS smoke bu raporda tamamlanmadı. |
| **Güvenlik (statik)** | **No Critical defect found** — DTO/sanitizer/route katmanları checklist ile uyumlu; **canlı sızıntı testi şart**. |
| **Genel** | **Proceed to live QA execution**, ardından **First Trial Bugfix Batch v1** (yalnız Critical/High Fail). |

---

## 13. Önerilen sonraki paketler

### Canlı smoke sonrası Critical yoksa (muhtemel sıra)

1. ~~**Staging Trial Report v1**~~ — **[staging_trial_report_v1.md](staging_trial_report_v1.md)** (tamamlandı).  
2. **First Trial Bugfix Batch v1** — Onaylı BUG-* (kullanıcı detayı sonrası); Critical/High Fail varsa önce Security Hotfix.  
3. **Remote Trial Polish Batch v1** — Medium UX (loading, dashboard counts, physio file UX).  
4. **Realtime Role-Filtered Refresh Plan v1**  
5. **Demo/Freemium/Subscription Plan v1**

### Canlı smoke Critical Fail çıkarsa (öncelik sırası)

1. **Security Hotfix Batch v1** — internalDoctorNote / cross-tenant / raw clinical_data leak.  
2. **RLS/Projection Hotfix v1** — RPC allowlist / migration policy.  
3. **Role Permission Hotfix v1** — `AuthRoutePermissions` / UI guard.  
4. **Cache Isolation Hotfix v1** — Oturumlar arası stale data.  
5. Ardından **First Trial Bugfix Batch v1**.

---

## 14. QA tamamlama checklist (canlı trial)

Önce: [staging_live_e2e_readiness_execution_v1.md](staging_live_e2e_readiness_execution_v1.md) §2 readiness (R-01…R-27).

- [ ] Readiness checklist Pass  
- [ ] `DATA_BACKEND=supabase` + dart-define-from-file (secret repoda değil)  
- [ ] Seed + Auth kullanıcılar bağlandı  
- [ ] UI walkthrough §5 (doctor → assistant → physio → nurse)  
- [ ] API RLS smoke §6 (authenticated JWT)  
- [ ] [remote_manual_smoke_test_checklist_v1.md](remote_manual_smoke_test_checklist_v1.md) — SMK-* Pass/Fail  
- [ ] [supabase_rls_manual_smoke_v1.md](supabase_rls_manual_smoke_v1.md) — RLS-* + evidence JSON  
- [ ] Bu rapor **Live Results Workbook** güncellendi  
- [ ] §11 ana akış tablosu Live Status senkronize edildi  
- [x] **Staging Trial Report v1** — [staging_trial_report_v1.md](staging_trial_report_v1.md)  

---

## Ek: Otomatik test kanıtı (rapor oturumu)

```
flutter test test/core/auth_route_permissions_test.dart
flutter test test/core/repository_cache_coordinator_test.dart
flutter test test/timeline/
→ 66+ tests passed (timeline suite end state)
```

---

*Bu rapor kod değiştirmez. Canlı trial sonuçları QA tarafından doldurulduğunda Staging Trial Report v1 ile birleştirilmelidir.*
