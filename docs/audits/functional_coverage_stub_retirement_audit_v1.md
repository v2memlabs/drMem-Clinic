# Functional Coverage & Stub Retirement Audit v1

**Proje:** v2Mem Clinic (`v2mem_clinic`)  
**Tarih:** 2026-05-29  
**Tür:** READ-ONLY audit / envanter / uygulama planı  
**Kapsam:** Kod değişikliği yok; sonraki Functional Completion Batch paketlerine temel.

---

## 1. Executive Summary

Staging Trial v1 sonrası uygulama **Conditional Go / Practical Pass** durumunda. Klinik çekirdek (auth, hasta, randevu, muayene, bakım konsolu) mock ve Supabase remote için kısmen çift yığınlı; birçok operasyonel modül **yalnızca in-memory mock**. En kritik fonksiyonel risk: **remote modda kaydedilen verinin bazı yüzeylerde görünmemesi** (patient detail clinical preview, dashboard KPI karışımı, timeline/file metadata stub).

**Öne çıkan bulgular:**

| # | Bulgu | Sınıf | Şiddet |
|---|--------|-------|--------|
| 1 | Patient detail clinical bölümleri hâlâ `ClinicalEncounterRepository.instance` (sync mock) kullanıyor; list/form async remote | B | **P0** |
| 2 | Patient file metadata + timeline: mock backend’de bile stub → `notConfigured` | D | **P0** |
| 3 | PDF list mock; remote persist orchestrator üzerinden; list/detail refresh tutarsız | B | **P1** |
| 4 | Payments, inventory, consents, surgery, FTR ops, exercise, imaging, messages → mock-only | C | **P1** |
| 5 | `PatientListRefresh.markStale()` hiç okunmuyor; `activate()` her seferinde reload | B | **P1** |
| 6 | Mock appointment tarihleri import-time sabitleniyor → gece yarısı test/flaky risk | B | **P2** |
| 7 | `pdf_output_detail_screen` SnackBar’da raw `$e` | Security | **P1** |

**Genel MVP functional readiness (ortalama):** **~1.6 / 3** — ana klinik akış mock’ta güçlü; Supabase remote parity ve operasyonel modüller zayıf.

---

## 2. Genel Fonksiyonellik Haritası

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA_BACKEND gate                         │
│  mock (default) │ supabase + env + session + tenant + role      │
└────────────┬───────────────────────────────┬────────────────────┘
             │                               │
    ┌────────▼────────┐              ┌───────▼────────┐
    │ Mock singletons │              │ Supabase repos │
    │ + async adapters│              │ + RPC/views    │
    └────────┬────────┘              └───────┬────────┘
             │                               │
    ┌────────▼───────────────────────────────▼────────┐
    │              UI (screens / forms)                  │
    │  Dual stack: sync mock vs async registry         │
    └──────────────────────────────────────────────────┘
```

**Katmanlar:**

| Katman | Durum |
|--------|--------|
| Auth / session / tenant bootstrap | Remote Supabase + mock login; membership/tenant loader remote |
| Maintenance console | Doğrudan Supabase RPC; env-gated |
| P0 klinik çekirdek | Kısmi remote (patients, appointments, encounters, settings) |
| Dosya metadata / timeline | Remote-only path; mock modda stub |
| PDF | Hybrid: mock list + remote storage insert |
| P1 operasyonel | Çoğunlukla mock-only UI |
| P2 placeholder | SaaS preview, demo settings, coming-soon aksiyonlar |

---

## 3. Route / Screen Coverage Tablosu (özet)

**Kaynak:** `lib/core/router/app_router.dart`, `lib/core/navigation/app_nav_config.dart`

| Alan | Route sayısı (yaklaşık) | List | Detail | Form | Remote repo | Mock | Placeholder |
|------|-------------------------|------|--------|------|-------------|------|-------------|
| Auth / session | 3 | — | — | login | ✓ | ✓ | — |
| Dashboards (4 rol) | 4 | — | — | — | kısmi | kısmi | — |
| Patients | 6 | ✓ | ✓ | ✓ | ✓ async | ✓ sync | — |
| Appointments | 4 | ✓ | ✓ | ✓ | ✓ async | ✓ sync | — |
| Clinical encounters | 5 | ✓ | ✓ | ✓ | ✓ async | ✓ sync | — |
| Diagnosis summary (assistant) | 2 | ✓ | ✓ | — | ✓ RPC | ✓ | — |
| Physio summaries | 2 | ✓ | ✓ | — | ✓ RPC | ✓ | — |
| Files (legacy + metadata) | 3 | ✓ | ✓ | upload | metadata remote | legacy mock | metadata stub |
| PDF outputs | 3 | ✓ | ✓ | ✓ | orchestrator | list mock | detail actions |
| Payments | 3 | ✓ | ✓ | ✓ | — | ✓ | — |
| Consents | 6 | ✓ | ✓ | ✓ | — | ✓ | template PDF |
| Inventory | 4 | ✓ | ✓ | ✓ | — | ✓ | — |
| Timeline | 1 | ✓ | — | — | ✓ | stub | “henüz etkin” |
| Settings | 11 | hub | — | kısmi | workflow/leave | prefs mock | SaaS/demo |
| FTR referrals/sessions | 6 | ✓ | ✓ | ✓ | — | ✓ | — |
| Exercise / surgery / post-op | 9 | ✓ | ✓ | ✓ | — | ✓ | — |
| Imaging / anamnesis / diagnosis / treatment / examination / messages | ~20 | ✓ | ✓ | ✓ | — | ✓ | — |
| Maintenance | 7 (conditional) | ✓ | ✓ | ✓ | ✓ | — | — |
| Audit logs | 2 | ✓ | ✓ | — | access remote | list mock | — |

**Sidebar vs deep-link:** ~13 doctor nav item; anamnesis, imaging, diagnoses, messages, consent-templates, patient-timeline **sidebar’da yok** — hasta detay / dashboard linkleriyle erişilir.

---

## 4. Repository Coverage Tablosu

| Repository / Provider | Mock | Supabase | Stub (active path) | CRUD | notConfigured | Test |
|----------------------|------|----------|-------------------|------|---------------|------|
| `PatientRepositoryProvider` | sync + async adapter | ✓ | unused async stub | full async | remote throws | ✓ güçlü |
| `AppointmentRepositoryProvider` | sync + async | ✓ | unused async stub | full async | remote throws | ✓ güçlü |
| `ClinicalEncounterRepositoryProvider` | sync + async | ✓ | unused async stub | full async | remote throws | ✓ güçlü |
| `ClinicalRoleSummaryRepositoryProvider` | mock summary | ✓ RPC | summary stub if gate fail | list/get | stub throws | ✓ |
| `PatientFileMetadataRepositoryProvider` | **yok** | ✓ | **stub always if not remote** | list/create/archive | **stub throws** | ✓ |
| `PatientFileStorageRepositoryProvider` | mock bytes | ✓ | — | upload/signed/remove | — | ✓ güçlü |
| `TimelineRepositoryProvider` | **yok** | ✓ | **stub if not remote** | list only | **stub throws** | ✓ |
| `ClinicWorkflowSettingsRepositoryProvider` | SharedPreferences mock | ✓ | — | load/save | — | ✓ |
| `StaffLeaveRecordRepositoryProvider` | mock | ✓ | — | list/create/update/cancel | — | ✓ |
| `PdfOutputRepository` | singleton list | insert via orchestrator | — | add (mock); remote insert | StateError | kısmi |
| `PaymentRepository` | ✓ | — | — | read/add | — | zayıf |
| `ConsentRepository` / templates | ✓ | — | — | read/add | — | zayıf |
| `InventoryRepository` | ✓ | — | — | full mock CRUD | — | zayıf |
| `PhysiotherapyRepository` | ✓ | — | — | referrals/sessions | — | yok |
| `ExercisePlanRepository` | ✓ | — | — | CRUD | — | yok |
| `SurgeryRepository` | ✓ | — | — | CRUD | — | yok |
| `PostOpProtocolRepository` | ✓ | — | — | CRUD | — | yok |
| `ImagingRepository` | ✓ | — | — | CRUD | — | yok |
| `MessageRepository` | ✓ | — | — | templates/sent | — | yok |
| `AuditLogRepository` | ✓ | — | — | read | — | yok |
| `AuditAccessEventProvider` | mock recorder | ✓ | no-op fallback | append | no throw | ✓ |
| Auth (`RepositoryRegistry`) | mock adapter | ✓ | unused stub | sign in/out | backendNotConfigured msg | ✓ |
| Maintenance | — | ✓ direct | — | RPC tools | notAvailable | ✓ |

**Orphan stub dosyaları (provider’da kullanılmıyor):**  
`supabase_*_repository_stub.dart` (patients, appointments, encounters, auth, session, membership) — dead code adayı.

---

## 5. Create → List → Detail → Related Surface Matrix

| Varlık | Create | List | Detail | Edit | Patient detail | Dashboard | Remote | Mock | Gap / risk |
|--------|--------|------|--------|------|----------------|-----------|--------|------|------------|
| **Hasta** | ✓ | ✓ | ✓ | ✓ | — | KPI kısmi | ✓ async | ✓ sync | Detail remote; list refresh token kullanılmıyor |
| **Randevu** | ✓ | ✓ | ✓ | ✓ | ✓ section | ✓ today async | ✓ | ✓ | Handoff + stale iyi; mock date import bug |
| **Muayene** | ✓ | ✓ | ✓ | ✓ | **mock preview** | ✓ filter client | ✓ | ✓ | **P0:** patient detail sync mock |
| **Dosya (metadata)** | upload ✓ | ✓ scoped | ✓ | archive | ✓ section | — | ✓ | **stub** | Mock modda “henüz etkin”; section parent reload yok |
| **PDF output** | ✓ | ✓ mock list | ✓ | — | contextual CTA | mock count | insert remote | list mock | List remote sync eksik; detail `$e` leak |
| **Ödeme** | ✓ | ✓ | ✓ | kısmi | — | — | — | ✓ | Tam mock-only |
| **Onam** | ✓ | ✓ | ✓ | kısmi | — | assistant KPI mock | — | ✓ | Template PDF/sign placeholder |
| **Stok** | ✓ | ✓ | ✓ | ✓ | — | nurse KPI mock | — | ✓ | Tam mock-only |
| **Staff leave** | ✓ | ✓ | ✓ | ✓ | — | — | ✓ | ✓ | Availability v1 etkisiz (bilinçli) |
| **FTR referral** | ✓ | ✓ | ✓ | — | — | — | — | ✓ | Mock-only |
| **FTR session** | ✓ | ✓ | ✓ | — | — | — | — | ✓ | Mock-only |
| **Exercise plan** | ✓ | ✓ | ✓ | — | — | — | — | ✓ | Mock-only |
| **Surgery note** | ✓ | ✓ | ✓ | — | — | — | — | ✓ | Mock-only |
| **Post-op protocol** | ✓ | ✓ | ✓ | — | — | — | — | ✓ | Mock-only |
| **Timeline event** | — | ✓ | — | — | route var | — | ✓ | stub | Mock modda notConfigured |

---

## 6. Stub / Mock / notConfigured Envanteri

### 6.1 Aktif stub path (kullanıcı akışını keser)

| Stub | Tetiklenme | UI mesajı |
|------|------------|-----------|
| `PatientFileMetadataRepositoryStub` | `!usesRemotePatientFileMetadata` | “Bu alan henüz etkin değil.” |
| `TimelineRepositoryStub` | `!usesRemoteTimeline` | “Hasta geçmişi henüz etkin değil…” |
| `SupabaseAssistantClinicalSummaryRepositoryStub` | supabase mode + role gate fail | notConfigured mapped |
| `SupabasePhysiotherapistClinicalSummaryRepositoryStub` | aynı | notConfigured mapped |

### 6.2 Mock-only modüller (Supabase yok)

Payments, inventory, consents (+ templates), surgery, exercise, post-op, imaging, messages, patient tags, legacy `FileRepository`, audit log list, physiotherapy operations, PDF list repository.

### 6.3 UI placeholder / coming soon

| Alan | Dosya |
|------|-------|
| PDF detail: Yazdır, Hastaya Verildi | `pdf_output_detail_screen.dart` |
| Consent template: PDF/imza | `consent_template_prepare_screen.dart` |
| Message send: Önizle | `message_send_screen.dart` |
| Settings: display region, password change | `display_region_settings_screen.dart`, `system_security_settings_screen.dart` |
| SaaS subscription preview | `saas_subscription_settings_content.dart` |
| Demo usage | `demo_usage_settings_screen.dart` |
| Clinic PDF header preview | `clinic_settings_screen.dart` |

### 6.4 Sınıflandırma özeti

| Sınıf | Adet (modül) | Örnek |
|-------|--------------|-------|
| **A — Gerçek fonksiyonel** | ~8 | Patients/appointments/encounters mock CRUD; settings workflow |
| **B — Kısmi fonksiyonel** | ~12 | PDF hybrid; patient detail reflection; dashboard mix |
| **C — Mock-only** | ~14 | Payments, inventory, FTR ops, surgery… |
| **D — Stub/notConfigured** | 4 active | Timeline, file metadata, summary stubs |
| **E — Placeholder** | ~8 UI | Coming soon, SaaS, demo |
| **F — Bilinçli kapsam dışı** | P2 | Portal, OCR, WhatsApp, billing prod |

---

## 7. Remote / Mock Uyumsuzlukları

| # | Uyumsuzluk | Etki |
|---|------------|------|
| 1 | Sync mock singleton vs async registry | Patient detail clinical, bazı dashboard KPI |
| 2 | PDF: remote insert + mock list | Yeni PDF listede görünmeyebilir (remote mod) |
| 3 | File metadata: remote DB + mock legacy file list | `/files` patientId’siz legacy mock |
| 4 | Encounter create → `go('/clinical-records')` vs appointment → detail | Tutarsız post-save UX |
| 5 | Assistant diagnosis summary remote RPC vs doctor full encounter table | Bilinçli role projection — OK |
| 6 | `internalDoctorNote` remote column vs mock field | Save guard OK; list DTO excludes — OK |
| 7 | Staff leave mock vs remote | Parity iyi; availability motoru etkilemiyor — bilinçli |

---

## 8. Refresh / Cache / Stale Riskleri

| Mekanizma | Durum | Risk |
|-----------|--------|------|
| `RepositoryCacheCoordinator.resetForSessionContextChange` | ✓ logout/tenant | Düşük |
| `AppointmentListRefresh` | markStale + isStale | İyi |
| `PatientListRefresh` | markStale **only** | **Orta** — isStale yok; dead signal |
| `RemoteListRefreshCoordinator` | file upload → all stale | İyi |
| Clinical encounter list | activate always reload | İyi ama token yok |
| Patient detail `_PatientFileMetadataSection` | initState only | **Orta** — upload sonrası stale |
| Dashboard | pull-to-refresh only; no activate | **Orta** |
| Mock appointment `DateTime.now()` at import | Flaky today filter | **Düşük–Orta** |

---

## 9. Security Text Leak Riskleri

| Risk | Konum | Şiddet |
|------|-------|--------|
| Raw exception in SnackBar | `pdf_output_detail_screen.dart` | **P1** |
| Maintenance screens show tenant_id/profile_id | Bilinçli operator UI | P2 (gated) |
| `ClinicalUiTextSanitizer` + `safeErrorDescription` | List/detail errors | ✓ iyi |
| `internalDoctorNote` | Doctor-only detail | ✓ audit logged |
| `operational_list_security_test` | 5 list | PDF detail SnackBar **dışarıda** |

---

## 10. P0 / P1 / P2 Bulgular

### P0
1. **Patient detail clinical rows** remote veriyi göstermiyor (sync mock).
2. **Timeline + file metadata** mock backend’de kullanılamaz (stub); staging’de remote şart.

### P1
1. PDF list/detail remote parity.
2. Dashboard mock KPI karışımı (PDF, consent, inventory).
3. Patient file metadata section parent reload.
4. Operasyonel modüller mock-only (payments, inventory, consents, FTR, surgery…).
5. PDF detail exception SnackBar.
6. Clinical encounter post-create navigation tutarsızlığı.

### P2
1. Mock import-time date flakiness.
2. Coming-soon settings actions.
3. Dead orphan stub files.
4. 19 list screen’de activate() refresh yok (mock modda düşük risk).

---

## 11. MVP Functional Readiness Score (0–3)

| Modül | Skor | Gerekçe |
|-------|------|---------|
| Auth / session | **2** | Remote + mock; bootstrap chain staging’de çalışıyor |
| Maintenance | **3** | Env-gated Supabase RPC; operatör akışı tam |
| Dashboard | **1** | KPI mix mock/remote; activate refresh yok |
| Patients | **2** | Remote CRUD iyi; detail clinical gap |
| Appointments | **2** | Remote + handoff; stale iyi; mock date risk |
| Clinical encounters | **2** | Form/list/detail remote; patient detail gap |
| Patient files | **1** | Storage OK; metadata stub in mock |
| PDF outputs | **1** | Hybrid; list mock; detail partial |
| Payments | **1** | Mock-only tam CRUD UI |
| Consents | **1** | Mock-only; template PDF placeholder |
| Inventory | **1** | Mock-only |
| Settings | **2** | Workflow/leave remote; SaaS demo |
| Timeline | **1** | Remote-only; stub otherwise |
| Audit | **1** | Access remote append; log list mock |
| Safe summaries | **2** | RPC remote + mock fallback |
| Physiotherapy | **1** | Summary remote; ops mock-only |
| Surgery / Post-op | **1** | Mock-only UI |

**Ortalama:** **~1.6 / 3**

---

## 12. Stub Retirement Stratejisi

### Faz 1 — Reflection & parity (4–6 hafta ürün paketleri)
1. Patient detail + dashboard veri kaynağı hizalama (async registry).
2. PDF remote list completion + refresh token.
3. Timeline/file metadata mock-friendly read path **veya** UI’da mock mod gizleme.
4. Refresh/stale consistency batch.

### Faz 2 — Operasyonel remote (8–12 hafta)
1. Payments, inventory, consents Supabase schema + repository.
2. FTR referrals/sessions remote.
3. Surgery/post-op/exercise remote veya bilinçli MVP freeze.

### Faz 3 — Temizlik
1. Orphan stub dosyalarını kaldır veya test-only yap.
2. Sync mock singleton kullanımını UI’dan kaldır (registry-only).
3. Security text leak sweep.
4. Mock data factory (import-time date fix).

---

## 13. Önerilen Paket Sırası

| # | Paket | Öncelik | Hedef |
|---|--------|---------|-------|
| 1 | **Patient Detail Remote Reflection Fix v1** | P0 | Clinical rows + file metadata reload + async source |
| 2 | **PDF Output Remote List Completion v1** | P1 | List remote + create→list + detail error sanitize |
| 3 | **Timeline & File Metadata Mock Path v1** | P0/P1 | Mock read adapter veya feature flag hide |
| 4 | **Dashboard Workbench Remote Parity v1** | P1 | KPI kaynakları registry’ye |
| 5 | **Refresh/Stale Consistency Batch v1** | P1 | PatientListRefresh isStale; encounter token; dashboard activate |
| 6 | **Operational Records Remote Foundation v1** | P1 | Payments + inventory + consents schema/repo |
| 7 | **FTR Functional Activation v1** | P1 | Referrals/sessions Supabase |
| 8 | **Security Text Leak Sweep v1** | P1 | PDF SnackBar + security test genişletme |

---

## 14. İlk Uygulama Paketi Prompt Taslağı

```
DrMem Clinic — Patient Detail Remote Reflection Fix v1

Kapsam:
- patient_detail_screen.dart clinical preview bölümleri
- PatientDetailDataSource / clinical_encounter_patient_scoped_display
- _PatientFileMetadataSection parent reload
- Dashboard workbench yalnızca bu pakette clinical count preview değil; sadece patient detail

Yap:
1. ClinicalEncounterRepository.instance kullanımını patient detail’den kaldır
2. RepositoryRegistry.clinicalEncountersAsync veya patient-scoped summary RPC kullan
3. Upload sonrası metadata section reload (activate veya key)
4. Remote + mock test regression
5. flutter analyze 0 error

Dokunma: RLS, migration (mevcut RPC/view yeterliyse), sidebar, form logic

Kabul:
- Remote modda yeni muayene patient detail’de görünür
- Mock modda mevcut davranış korunur
- internalDoctorNote preview edilmez
```

---

## Ek: Modül Audit Soru Matrisi (özet)

Her P0 modül için 16 soru — tam tablo `docs/audits/` altında modül notları olarak genişletilebilir.

**Patients:** Remote ✓ | Mock ✓ | Stub unused | Create/list/detail/edit ✓ | Refresh kısmi | Patient detail self ✓ | Score 2

**Clinical encounters:** Remote ✓ | Mock ✓ | Create/list/detail/edit ✓ | Patient detail **✗ mock** | Handoff ✓ | Score 2

**Appointments:** Remote ✓ | Mock ✓ | Handoff ✓ | Stale ✓ | Score 2

**PDF:** Remote insert ✓ | List mock | Detail partial | Score 1

**Timeline / files metadata:** Remote ✓ | Mock stub | Score 1

---

*Audit v1 — kod değişikliği yapılmamıştır. Sonraki adım: Patient Detail Remote Reflection Fix v1.*
