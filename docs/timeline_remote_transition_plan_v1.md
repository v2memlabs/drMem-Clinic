# Timeline Remote Transition Plan v1

> **Paket türü:** Analiz ve geçiş planı (kod/migration/UI değişikliği yok)  
> **İlgili dokümanlar:** [audit_kvkk_access_event_extension_v1.md](audit_kvkk_access_event_extension_v1.md), [patient_file_pdf_storage_metadata_v1.md](patient_file_pdf_storage_metadata_v1.md), [backend/permission-rls-matrix.md](backend/permission-rls-matrix.md), [negative_rls_test_checklist_v1.md](negative_rls_test_checklist_v1.md)  
> **Sonraki paket:** Timeline DB Projection/RPC Migration v1

---

## 1. Mevcut timeline durumu

### 1.1 Ekran ve routing

| Bileşen | Konum | Not |
|---------|--------|-----|
| **Ekran** | `lib/features/patients/patient_timeline_screen.dart` → `PatientTimelineScreen` | StatefulWidget; arama + olay tipi filtresi |
| **Route** | `lib/core/router/app_router.dart` → `/patient-timeline` | Query: `?patientId=<uuid>` |
| **Nav guard** | `AuthSession.canViewPatientTimeline` | **Yalnızca doctor** (`_isDoctor`) |
| **Hasta detay girişi** | `patient_detail_screen.dart` | Quick link + action panel → `/patient-timeline?patientId=` (doctor only) |
| **Global nav** | `app_nav_config.dart` | `/patient-timeline` (patientId opsiyonel) |

**patientId akışı:** Route query parametresinden; `tenant_id` UI'dan verilmez.

### 1.2 Veri kaynağı (mock / client-side)

| Katman | Dosya | Davranış |
|--------|--------|----------|
| **Builder** | `lib/features/patients/data/patient_timeline_builder.dart` | `PatientTimelineBuilder.build(patientId:)` — **13 kaynaktan** client-side birleştirme |
| **Model** | `lib/features/patients/models/patient_timeline_event.dart` | `PatientTimelineEvent`, `TimelineEventType` enum |
| **UI kart** | `lib/shared/widgets/timeline_event_card.dart` | `TimelineEventCard` |
| **Statik mock liste** | `lib/features/patients/data/mock_patient_timeline_events.dart` | **Kullanılmıyor** (dead data; builder repo'ları kullanıyor) |

**Builder kaynakları (sıra `build()` içinde):**

1. `ClinicalEncounterRepository` → muayene (tanı özeti: `finalDiagnosis` / `preliminaryDiagnosis`, 80 char truncate)
2. `AppointmentRepository` → randevu
3. `ImagingRepository` → görüntüleme
4. `SurgeryRepository` → ameliyat/girişim
5. `PostOpProtocolRepository` → post-op
6. `PhysiotherapyRepository` → FTR yönlendirme + seans
7. `ExercisePlanRepository` → egzersiz programı
8. `FileRepository` (legacy mock dosya) → dosya
9. `ConsentRepository` → onam
10. `PaymentRepository` → ödeme
11. `MessageRepository` → mesaj
12. `PdfOutputRepository` (legacy mock PDF) → PDF çıktı
13. **`AuditLogRepository` → audit/işlem kaydı** ⚠️

Sonra `eventDate` desc sıralama.

### 1.3 Mevcut olay tipleri (`TimelineEventType`)

Faz 1–4 grupları (`patient_timeline_event.dart`):

| Faz | Tipler |
|-----|--------|
| 1 | `muayeneNotu`, `randevu`, `goruntuleme`, `ameliyatGirisim`, `postOpProtokol` |
| 2 | `fizyoterapiYonlendirme`, `fizyoterapiSeansi`, `egzersizProgrami`, `dosya`, `kvkkOnam` |
| 3 | `odeme`, `mesaj`, `pdfCikti` |
| 4 | `auditLog` |

Enum'da tanımlı ama builder'da **üretilmeyen:** `anamnez`, `tani`, `tedaviPlani` (yalnızca `mock_patient_timeline_events.dart` içinde).

### 1.4 Hasta kapsamı

- `patientId` dolu → tek hasta olayları
- `patientId` boş/null → **tüm hastalar** (global timeline; tüm repo `getAll()`)

### 1.5 İlişkili modüller

| Modül | Timeline'da nasıl |
|-------|-------------------|
| Clinical | Full mock `ClinicalEncounter`; route `/clinical-records/:id` |
| Appointment | Mock appointment; `/appointments/:id` |
| Files | Legacy `PatientFile` (metadata v2 değil) |
| PDF | Legacy `PdfOutput` |
| Audit | Mock `AuditLog` → `TimelineEventType.auditLog` ⚠️ |
| Patient file metadata (yeni) | Henüz timeline'a bağlı değil |
| Safe summary RPC | Timeline'da yok |

### 1.6 Hassas veri — mevcut mock builder analizi

| Alan | Timeline'da görünür mü? | Risk |
|------|-------------------------|------|
| `internalDoctorNote` | **Hayır** — builder yalnızca `_clinicalDiagnosisSummary` kullanır | Mock repo modelinde alan var; remote'da full encounter çekilmemeli |
| `clinical_data` (raw JSONB) | **Hayır** — doğrudan okunmuyor; model scalar alanları kullanılıyor | Remote projection full row çekmemeli |
| PDF/dosya içeriği | **Hayır** — yalnızca başlık/meta | ✓ |
| `storagePath` / signed URL | **Hayır** | ✓ |
| Audit access events (`clinical.summary.*.view`) | Mock audit farklı şema; KVKK RPC event'leri henüz timeline'da değil | Faz 4 `auditLog` tipi **timeline ile karışıyor** — kaldırılacak |

### 1.7 Remote altyapı durumu

- `TimelineRepository` / Supabase timeline RPC: **yok**
- `RepositoryRegistry` timeline getter: **yok**
- DB `patient_timeline_events` tablosu: **yok**
- Migration/RLS timeline-specific: **yok**

---

## 2. Timeline vs Audit ayrımı

### 2.1 Tanımlar

| | **Timeline** | **Audit (KVKK / güvenlik)** |
|---|-------------|----------------------------|
| **Amaç** | Hasta geçmişini klinik/operasyonel okunabilir akışta göstermek | Kim, ne zaman, hangi veriye erişti/değiştirdi |
| **Kitle** | Klinik roller (role-based subset) | Compliance / doctor-admin audit ekranı |
| **Örnek** | "Muayene kaydı oluşturuldu", "PDF metadata eklendi", "Randevu iptal edildi" | "Assistant tanı özeti görüntüledi", "Doctor internal note görüntüledi", "Yetkisiz erişim denendi" |
| **Veri kaynağı (hedef)** | `list_patient_timeline_events` projection | `audit_logs` + `record_audit_access_event` RPC |
| **UI** | `PatientTimelineScreen` | `AuditLogListScreen` (doctor) |

### 2.2 Kesin kararlar (remote v1+)

**Timeline'a konmayacak:**

- `clinical.summary.assistant.view` / `clinical.summary.physiotherapist.view` ve tüm `*.list` access audit event'leri
- `permission.denied`
- `clinical.internal_note.view` / `clinical.internal_note.update`
- `auth.login` / `auth.logout`
- Ham `audit_logs` satırlarının timeline kartı olarak gösterimi (mevcut mock `_fromAuditLogs` **kaldırılacak**)
- SQL/error/debug event'leri
- Signed URL açılış / storage download event'leri

**Audit'e konmayacak (veya ayrı taxonomy):**

- Saf operasyonel "hasta geçmişi" olayları (randevu oluşturuldu vb.) — bunlar timeline projection'dır; isteğe bağlı ileride `timeline_events` write-side duplicate audit ile eşlenebilir (v1.1+).

### 2.3 Mevcut teknik borç

`PatientTimelineBuilder._fromAuditLogs` audit modülünü timeline ile birleştiriyor. Remote geçişte bu kaynak **silinmeli**; audit okuma yalnızca audit ekranı/RPC üzerinden kalmalı.

---

## 3. Timeline event taxonomy

### 3.1 Önerilen `event_type` (dot-notation, remote)

| event_type | event_group | Kaynak tablo / not |
|------------|-------------|-------------------|
| `patient.created` | patient | `patients` |
| `patient.updated` | patient | `patients` (anlamlı alan değişimi) |
| `appointment.created` | appointment | `appointments` |
| `appointment.updated` | appointment | `appointments` |
| `appointment.cancelled` | appointment | status |
| `appointment.completed` | appointment | status |
| `clinical.encounter.created` | clinical | `clinical_encounters` |
| `clinical.encounter.updated` | clinical | `clinical_encounters` |
| `clinical.encounter.completed` | clinical | status (varsa) |
| `file.metadata.created` | file | `patient_files` |
| `file.metadata.archived` | file | `patient_files.status=archived` |
| `pdf.metadata.created` | pdf | `pdf_outputs` veya unified metadata |
| `consent.created` | consent | `consents` |
| `consent.updated` | consent | `consents` |
| `physiotherapy.referral.created` | rehab | FTR yönlendirme |
| `physiotherapy.session.created` | rehab | FTR seans |
| `physiotherapy.session.completed` | rehab | seans status |
| `payment.recorded` | billing | `payments` (role-gated) |
| `imaging.report.created` | clinical | görüntüleme (opsiyonel v1) |
| `surgery.procedure.recorded` | clinical | ameliyat notu (opsiyonel v1) |
| `postop.protocol.created` | clinical | post-op (opsiyonel v1) |
| `exercise.plan.created` | rehab | egzersiz (opsiyonel v1) |
| `message.sent` | communication | mesaj (opsiyonel v1) |
| `note.operational.created` | other | ileride; allowlist metin |

### 3.2 Timeline'a alınmayacak event'ler

- Tüm `audit_logs.action` access taxonomy (`clinical.full.view`, `clinical.summary.*`, `permission.denied`, …)
- `internalDoctorNote.*`
- Raw `clinical_data` expose
- `file.content.*` / `storage.download.*` / `signed_url.*`
- Auth session event'leri
- Client exception / PostgREST hata kodları

### 3.3 Klinik olay başlık içeriği (projection allowlist)

Muayene timeline satırı için **yalnızca:**

- `visit_type`, `body_region`, `side`, `status` etiketleri
- `diagnosis_summary` veya güvenli özet alan (DB column / derived; **not** `internal_doctor_note`)
- **Asla:** `internal_doctor_note`, ham `clinical_data` JSONB, anamnez tam metin blokları

Assistant timeline subset'te muayene için:

- `clinical.encounter.created` başlığı + **operasyonel tanı özeti** (assistant RPC ile uyumlu alanlar) veya yalnızca "Muayene kaydı" generic başlık — navigation safe summary'e.

---

## 4. Role-based visibility

### 4.1 Matris (hedef remote)

| Olay grubu | doctor_admin | assistant_secretary | physiotherapist | nurse |
|------------|:------------:|:-------------------:|:---------------:|:-----:|
| patient.* | ✓ | ✓ (temel) | — | — |
| appointment.* | ✓ | ✓ | — | — |
| clinical.encounter.* (güvenli başlık) | ✓ | ✓ (özet başlık; full detay yok) | — | — |
| file.metadata.* / pdf.metadata.* | ✓ | ✓ (`visibility_scope` clinic_operations) | ✓ (`physiotherapy`) | — |
| consent.* | ✓ | ✓ | — | — |
| payment.* | ✓ | ✓ | — | — |
| physiotherapy.* | ✓ | — | ✓ | — |
| exercise.* / postop.* | ✓ | — | ✓ (egzersiz) | — |
| imaging.* / surgery.* | ✓ | — | — | — |
| message.* | ✓ | ✓ | — | — |
| audit / access / permission | **✗** | **✗** | **✗** | **✗** |

### 4.2 Flutter mevcut vs hedef

| Rol | Mevcut Flutter | Hedef (RPC sonrası) |
|-----|----------------|---------------------|
| Doctor | `canViewPatientTimeline` → tam ekran | Geniş timeline (internal note içerik **yok**) |
| Assistant | Timeline route **yok** | Operasyonel subset; route açılması **ayrı ürün kararı** (bu planda RPC hazır, UI guard sonraki paket) |
| Physiotherapist | Timeline **yok** | FTR/rehab subset only |
| Nurse | Timeline **yok** | **Kapalı** (bu fazda yeni erişim yok) |

### 4.3 Navigation matrisi (UI smoke sonrası)

| event_type | doctor_admin | assistant | physio |
|------------|--------------|-----------|--------|
| `clinical.encounter.*` | `/clinical-records/:id` | `/clinical-records/diagnosis-summary` veya detay yok | — |
| `file.metadata.*` | metadata list/detail smoke | metadata smoke | metadata smoke (RLS) |
| `pdf.metadata.*` | metadata only; download yok | aynı | — |
| `physiotherapy.*` | FTR ekranları | — | FTR ekranları |

---

## 5. Remote source strategy değerlendirmesi

### Seçenek A — Birleşik SQL view / SECURITY DEFINER RPC ✅ **Önerilen MVP**

- `list_patient_timeline_events(p_patient_id uuid)` → tek read-only projection
- Farklı tablolar `UNION ALL` + ortak kolon şeması
- Role/tenant/patient gate **server-side**
- Event başlık/subtitle SQL'de allowlist ile üretilir

| Artı | Eksi |
|------|------|
| Tek round-trip; tutarlı sıralama | Migration + RPC bakımı |
| RLS + role filter merkezi | Yeni tablo event'leri için migration güncellemesi |
| Audit'ten ayrık contract | İlk UNION kapsamı sınırlı tutulmalı (MVP subset) |

### Seçenek B — `timeline_events` dedicated tablo (v1.1+)

- Write path'lerde allowlist payload ile insert
- Okuma basit; performans iyi
- Audit ile karışmaz

| Artı | Eksi |
|------|------|
| Olgun SaaS modeli | Backfill + dual-write geçiş maliyeti |
| Tutarlı event şeması | Tüm modüllerde trigger/service |

### Seçenek C — Client multi-repository merge ❌ **Production için red**

| Artı | Eksi |
|------|------|
| Hızlı prototip | Fazla veri çekme riski (full clinical) |
| | Cross-tenant tutarsızlık |
| | Role filter client'ta bypass edilebilir |
| | Performans (N+1 repo) |

**Karar:** MVP = **Seçenek A**. v1.1 = Seçenek B değerlendirmesi. Seçenek C yalnızca mevcut mock builder ile sınırlı kalır; remote'a taşınmaz.

---

## 6. Önerilen MVP yaklaşımı

1. **Migration v1:** `list_patient_timeline_events` RPC + internal staging view(s); authenticated execute; `REVOKE` direct SELECT on raw union view.
2. **MVP event subset:** `appointment.*`, `clinical.encounter.created/updated`, `file.metadata.created/archived`, `pdf.metadata.created`, `consent.created`, `physiotherapy.referral.created`, `physiotherapy.session.created` — doctor_admin tam set; assistant/physio role filter.
3. **Audit çıkarımı:** Mevcut mock builder'dan audit kaynağı kaldırma (ayrı paket, UI remote smoke öncesi veya paralel).
4. **Clinical:** Projection'da `diagnosis_summary` / safe column; `internal_doctor_note` ve `clinical_data` SELECT listesinde **yok**.
5. **Files:** `patient_files` metadata kolonları; `storage_path` RPC çıktısında **yok**.
6. **tenant_id:** `current_tenant_id()` RPC içinde; parametre olarak UI'dan alınmaz.
7. **Pagination:** `p_limit` / `p_offset` veya cursor (`occurred_at`, `id`) — performans riski için zorunlu.

---

## 7. DTO / repository / provider tasarımı

### 7.1 Domain — `TimelineEvent` (önerilen)

```dart
// lib/features/timeline/models/timeline_event.dart (gelecek paket)
class TimelineEvent {
  final String id;              // stable: "{source}:{uuid}" veya uuid
  final String tenantId;        // domain'de olabilir; UI'da gösterilmez
  final String patientId;
  final String eventType;       // dot-notation
  final String eventGroup;      // patient | appointment | clinical | ...
  final String title;
  final String? subtitle;
  final DateTime occurredAt;
  final String? actorDisplayName;
  final String sourceEntityType;  // e.g. clinical_encounter
  final String sourceEntityId;
  final String visibilityScope;   // doctor_admin | clinic_operations | physiotherapy
  final String? iconKey;
  final String? statusLabel;
  final Map<String, Object?> metadata; // allowlist only
}
```

### 7.2 Yasak alanlar (DTO/mapper/UI contract)

- `internalDoctorNote`, `internal_doctor_note`
- `clinicalData`, `rawClinicalData`, `clinical_data`
- `fileContent`, `pdfContent`
- `signedUrl`, `publicUrl`, `storagePath`, `storageBucket` (UI state)
- `serviceRole`, secret, token
- `exception`, `postgrest`, SQL fragment

### 7.3 Repository contract

```dart
abstract interface class TimelineRepository {
  Future<List<TimelineEvent>> listPatientTimelineEvents({
    required String patientId,
    int limit = 50,
    int offset = 0,
  });
  // Future<TimelineEvent?> getTimelineEvent(String eventId); // opsiyonel v1.1
}
```

### 7.4 Provider / registry (hedef)

| Bileşen | Dosya (önerilen) |
|---------|------------------|
| Gate | `timeline_repository_backend_gate.dart` |
| Provider | `timeline_repository_provider.dart` |
| Registry | `RepositoryRegistry.patientTimeline` veya `timeline` |
| Stub | `TimelineRepositoryStub` → `notConfigured` |
| Remote | `SupabaseTimelineRepository.fromSupabase()` |

**Gate koşulları** (patient/file metadata provider ile uyumlu):

- `DATA_BACKEND=supabase`
- Supabase configured + initialized
- `AuthSession.isLoggedIn`
- `SessionReadiness.isReady`
- `ActiveTenantContextStore.current != null`
- Role: `canViewPatientTimeline` (doctor) — assistant/physio genişletmesi **ayrı gate flag** ile sonraki paket

### 7.5 Mapper

- `TimelineEventDto.fromRpcRow(Map)`
- `TimelineEventMapper.toDomain(dto)`
- Metadata sanitizer: `TimelineEventMetadataSanitizer` (audit sanitizer pattern)

---

## 8. DB / RLS / RPC yaklaşımı

### 8.1 Önerilen RPC

```sql
-- İmza taslağı (Migration v1 paketinde netleştirilecek)
list_patient_timeline_events(
  p_patient_id uuid,
  p_limit int default 50,
  p_offset int default 0
)
returns table (
  id text,
  patient_id uuid,
  event_type text,
  event_group text,
  title text,
  subtitle text,
  occurred_at timestamptz,
  actor_display_name text,
  source_entity_type text,
  source_entity_id uuid,
  visibility_scope text,
  icon_key text,
  status_label text,
  metadata jsonb
)
```

**Not:** `tenant_id` return kolonu istemci DTO'da tutulabilir; UI render etmez.

### 8.2 RPC güvenlik kontrol listesi

- [ ] `auth.uid()` not null
- [ ] `p_patient_id` tenant scope (`patients.tenant_id = current_tenant_id()`)
- [ ] `is_tenant_member(current_tenant_id())`
- [ ] `has_tenant_role(...)` — role → event_type allowlist
- [ ] `deleted_at is null` kaynak satırlarda
- [ ] SELECT listesinde `internal_doctor_note`, `clinical_data` **yok**
- [ ] `storage_path`, signed URL **yok**
- [ ] `SECURITY DEFINER` + `SET search_path = public`
- [ ] `GRANT EXECUTE` authenticated; union view direct SELECT **REVOKE**

### 8.3 RLS ilişkisi

- Kaynak tablolar kendi RLS'ini korur.
- Timeline projection RPC içinde role filter **tekrar** uygulanır (defense in depth).
- Assistant: `clinical_encounters` full SELECT yok → projection yalnızca allowlist kolonları.
- Nurse: RPC boş set veya `FORBIDDEN` (tercih: boş set + client not configured).

### 8.4 Örnek UNION kaynağı (MVP)

| Branch | Kaynak | visibility |
|--------|--------|------------|
| appointments | `appointments` | clinic_operations |
| clinical | `clinical_encounters` (safe columns) | doctor_admin / assistant başlık kısıtlı |
| files | `patient_files` | `visibility_scope` |
| pdf | `pdf_outputs` | `visibility_scope` |
| consent | `consents` | clinic_operations |
| physio | `physiotherapy_referrals`, session tables | physiotherapy |

---

## 9. UI geçiş planı

### 9.1 Mevcut UI korunumu (geçiş sırasında)

- `PatientTimelineScreen` layout korunur; veri kaynağı değişir.
- `PatientTimelineBuilder` mock path: feature flag veya `usesRemoteTimeline == false` iken kalır (geçiş paketleri arası).

### 9.2 Remote UI smoke (paket 5)

| Madde | Plan |
|-------|------|
| Veri | `RepositoryRegistry.patientTimeline.listPatientTimelineEvents(patientId:)` |
| Loading | `ClinicalRoleSummaryUiStates` pattern — "Zaman çizelgesi yükleniyor…" |
| Empty | "Bu hasta için timeline olayı bulunamadı." |
| notConfigured | "Zaman çizelgesi şu anda görüntülenemiyor." |
| Error | Generic mesaj; PostgREST/stack yok |
| Kart | `TimelineEventCard` refactor → `TimelineEvent` domain |
| Tap navigation | Role-aware route map; assistant full clinical **yok** |
| PDF/file tap | Metadata smoke veya snackbar; download yok |
| Hasta detay | İsteğe bağlı embedded son 3 olay (doctor); ayrı paket olabilir |

### 9.3 Kaldırılacak mock davranışlar (remote sonrası)

- `_fromAuditLogs` timeline birleşimi
- Global timeline'da tüm tenant verisi (remote'da `patientId` zorunlu tutulabilir)
- Legacy `FileRepository` / `PdfOutputRepository` timeline branch → `PatientFileMetadata` projection event'leri

### 9.4 Permission

- Route guard genişletmesi **bu plan paketinde yapılmaz**.
- Assistant/physio timeline route: **RPC hazır olduktan sonra** ayrı guard paketi (`Timeline Role Navigation Guard Audit v1`).

---

## 10. Riskler ve önlemler

| Risk | Etki | Önlem |
|------|------|--------|
| Audit event'lerinin timeline'a karışması | KVKK/UX karışıklığı; yanlış "işlem kaydı" kartı | Mock `_fromAuditLogs` kaldır; RPC allowlist'te audit action yok |
| `internalDoctorNote` sızıntısı | Gizlilik ihlali | RPC SELECT allowlist; mapper redaction; negatif test N-x |
| `clinical_data` sızıntısı | Assistant/physio fazla veri | Safe projection only; full repo timeline'a bağlanmaz |
| Client-side merge (Seçenek C) | Veri fazlalığı | Production'da kullanılmayacak — plan kararı |
| Cross-tenant timeline | KVKK ihlali | `p_patient_id` + `current_tenant_id()` zorunlu gate |
| Role navigation kaçağı | Assistant full clinical detay | `relatedRoute` server'da role'a göre veya client route map |
| `storage_path` / signed URL sızıntısı | Storage güvenliği | RPC çıktısında yok; file event yalnızca `display_name` |
| Performans (çok event) | UI donması | Pagination + index (`patient_id`, `occurred_at desc`) |
| Eski mock full `ClinicalEncounter` | internal note modelde var | Timeline remote mapper encounter'ın tam modelini yüklemez |
| Assistant timeline route açılmadan RPC geniş | Fazla veri assistant'a | RPC role filter önce; UI guard sonra |
| `mock_patient_timeline_events` dead code | Bakım kafa karışıklığı | Remote geçişte sil veya test fixture'a taşı |

---

## 11. Fazlara bölünmüş roadmap

### Paket 1 — Timeline DB Projection/RPC Migration v1

| | |
|-|-|
| **Amaç** | `list_patient_timeline_events` RPC + güvenli UNION projection |
| **Kapsam** | SQL migration, role/tenant gate, MVP event subset, negatif test SQL şablonları |
| **Kapsam dışı** | Dart, UI, dedicated `timeline_events` tablosu |
| **Kabul** | RPC authenticated execute; nurse boş; internal_note/clinical_data/storage_path yok; negative RLS checklist maddeleri |

### Paket 2 — Timeline DTO/Mapper/Contract v1

| | |
|-|-|
| **Amaç** | `TimelineEvent` domain, DTO, mapper, sanitizer, `TimelineRepository` interface |
| **Kapsam** | Allowlist metadata; failure enum |
| **Kapsam dışı** | Supabase impl, UI |
| **Kabul** | Unit test: yasak alanlar parse edilmez |

### Paket 3 — Supabase Timeline Repository Smoke v1

| | |
|-|-|
| **Amaç** | `SupabaseTimelineRepository` RPC çağrısı |
| **Kapsam** | Error mapper; tenant UI'dan yok |
| **Kapsam dışı** | Provider, UI |
| **Kabul** | Integration/smoke test; notConfigured path |

### Paket 4 — Timeline Provider Backend Switch v1

| | |
|-|-|
| **Amaç** | `TimelineRepositoryProvider` + `RepositoryRegistry.patientTimeline` |
| **Kapsam** | Gate: supabase + session + tenant + doctor role (MVP) |
| **Kapsam dışı** | UI, assistant route |
| **Kabul** | Mock → stub; ready → remote; resetCache |

### Paket 5 — Patient Timeline UI Remote Smoke v1

| | |
|-|-|
| **Amaç** | `PatientTimelineScreen` remote repository bağlantısı |
| **Kapsam** | Loading/empty/error/notConfigured; patientId query |
| **Kapsam dışı** | Assistant route açma; download |
| **Kabul** | Manual smoke checklist; 0 analyze error |

### Paket 6 — Timeline Loading/Error Polish v1

| | |
|-|-|
| **Amaç** | Mesaj standardizasyonu, retry, refresh |
| **Kapsam** | User messages, state widget |
| **Kapsam dışı** | Yeni event tipleri |
| **Kabul** | Widget test; clinical polish pattern uyumu |

### Paket 7 — Timeline Role Navigation Guard Audit v1

| | |
|-|-|
| **Amaç** | Role-based `relatedRoute`; assistant/physio subset UI |
| **Kapsam** | Route map; guard audit; RPC role filter ile uyum testi |
| **Kapsam dışı** | Nurse timeline |
| **Kabul** | Assistant full clinical navigation imkansız; checklist |

### Paket 8 — Timeline Dedicated Event Table v1.1 (sonra)

| | |
|-|-|
| **Amaç** | `timeline_events` tablo + write-side emitters |
| **Kapsam** | Backfill planı; RPC read switch |
| **Kapsam dışı** | Audit birleştirme |
| **Kabul** | Performans test; migration rollback notu |

---

## 12. Açık sorular / sonraya kalanlar

1. **Assistant timeline route:** RPC role filter hazır olsa da Flutter `canViewPatientTimeline` yalnızca doctor — ürün onayı ile genişletilecek.
2. **Global timeline (`patientId` boş):** Remote'da kapatılsın mı, yoksa doctor için tenant-wide feed mi?
3. **Imaging / surgery / post-op / exercise / message:** MVP RPC'ye dahil mi yoksa Faz 2 UNION branch mi?
4. **`pdf_outputs` vs unified metadata:** Timeline event tek tip `pdf.metadata.*` — `pdf_outputs` tablosundan projection.
5. **Legacy mock builder:** Remote switch sonrası tamamen silinsin mi, mock backend için kalsın mı?
6. **`mock_patient_timeline_events.dart`:** Silme / test fixture.
7. **Hasta detay embedded timeline:** Ayrı mini paket mi, UI smoke içinde mi?
8. **Operasyonel audit vs timeline write duplicate:** v1.1 `timeline_events` ile iş operasyonu audit'i ayrıştırma.
9. **Pagination default:** 50 vs 100; "daha fazla yükle" UX.
10. **Event deduplication:** Aynı kayıt için created+updated çift kart — business rule.

---

## Ek: Mevcut dosya envanteri (referans)

| Dosya | Rol |
|-------|-----|
| `patient_timeline_screen.dart` | UI |
| `patient_timeline_builder.dart` | Mock aggregator ⚠️ audit dahil |
| `patient_timeline_event.dart` | Model + enum |
| `mock_patient_timeline_events.dart` | Unused static fixtures |
| `timeline_event_card.dart` | Kart widget |
| `app_router.dart` | Route + doctor guard |
| `auth_session.dart` | `canViewPatientTimeline` |

**Değiştirilmeyen (bu paket):** Tüm yukarıdaki kod dosyaları — yalnızca bu doküman eklendi.
