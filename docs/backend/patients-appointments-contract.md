# Patients / Appointments — Contract Geçişi

## Durum

| Bileşen | Durum |
|---------|--------|
| `PatientRepositoryContract` | Sync — **aktif UI** (`PatientRepository.instance`, daima mock) |
| `AsyncPatientRepositoryContract` | Provider switch — koşullu remote |
| `PatientRepositoryProvider.current` | Sync mock (legacy tag/selector yardımcıları) |
| `PatientRepositoryProvider.asyncRepository` | Mock veya `SupabasePatientRepository` |
| `RepositoryRegistry.patientsAsync` | Async erişim |
| `RepositoryRegistry.patients` | Sync mock |
| Randevu / muayene / PDF / … | Randevu liste+detay+form remote; muayene **liste** remote smoke (v1); muayene detay/form mock sync |

## Backend switch (v1)

| Koşul | Async repository |
|--------|------------------|
| Varsayılan / `DATA_BACKEND` yok / mock | `MockAsyncPatientRepositoryAdapter` |
| `DATA_BACKEND=supabase` + URL/key yok | `activeBackend` mock → mock async |
| Supabase client init yok | Mock async (crash yok) |
| Giriş yok / session hazır değil | Mock async |
| Active tenant yok | Mock async (fallback; remote çağrıda `noActiveTenant`) |
| Hepsi sağlanıyorsa | `SupabasePatientRepository` |

`usesRemotePatients` = true yalnızca son satır.

## Patient remote mapping (v1)

| Konu | Karar |
|------|--------|
| `id` | Insert'te gönderilmez; sunucu `gen_random_uuid()` |
| `tenant_id` | `ActiveTenantContextStore` (UI'dan yok) |
| `file_number` | Tenant unique |
| Soft delete | `deleted_at` + `archived` |
| Demo limit 3 | Enforcement **yok** |
| Migration MVP | Gerekmez; tam parity → v2 / JSONB |

### Search (remote v1)

`file_number`, `first_name`, `last_name`, `phone`, `national_id` — **yok:** `primaryComplaint`, `bodyRegion`, `tags`

### Hatalar

`PatientRepositoryFailure` + `PatientRepositoryErrorMapper` (23505 → duplicate file number)

## Patient remote polish + liste refresh (v1)

| | |
|--|--|
| Liste refresh | `activate()` + `await context.push` (detay/yeni hasta) + `PatientListRefresh.markStale()` (form) |
| Loading | İlk yüklemede spinner; yenilemede üstte ince progress + önbellekli liste |
| Empty | Boş DB: “Henüz hasta kaydı yok”; arama: “Hasta bulunamadı” |
| Error | `PatientListUserMessages` — teknik detay yok; “Tekrar dene” |
| Remote fallback UI | `PatientRemoteDisplay` — boş şikayet/bölge/chip/kimlik/uyruk/sigorta satırları gizlenir |
| Search hint | Remote: şikayet hariç; mock: mevcut geniş hint |
| Demo count | `PatientDemoCountLabel` — 4/3 bilgilendirme; enforcement yok |

### Hasta modülü remote çekirdek (v1 tamam)

Liste, detay, form, selector, ayarlar count → `patientsAsync` (koşullu).

### Kalan eksikler (sonraki faz)

- Metadata JSONB / tag parity
- Downstream randevu, muayene, PDF, klinik remote geçişi
- Demo limit sert enforcement (SaaS/subscription)

## Patient selector + ayarlar count remote smoke (v1)

| | |
|--|--|
| Selector | `PatientSelectorField` → `PatientSelectorDataSource` → `patientsAsync` getAll/search/getById |
| Arama remote | `file_number`, `first_name`, `last_name`, `phone`, `national_id` (350ms debounce) |
| Seçilen hasta | UUID id formlara gider; etiket `_resolvedPatient` ile korunur |
| Downstream | Randevu/muayene/PDF/FTR **mock** — remote patient id ile mock kayıt eşleşmeyebilir (geçiş) |
| Ayarlar count | `PatientCountDataSource` → `patientsAsync.count()` |
| Dashboard count | **Yok** — mevcut kartlarda hasta sayısı KPI eklenmedi |
| Demo limit | Enforcement **yok**; count bilgilendirme |

## Hasta form remote create/update (v1)

| | |
|--|--|
| Ekran | `patient_form_screen` → `PatientFormDataSource` → `patientsAsync` |
| Yeni kayıt | `add` → sunucu `id` ile detaya yönlendirme |
| Güncelleme | `update` → detaya dönüş |
| `nextFileNumber` | Async repository (mock / remote DEMO-### veya H-YYYY-####) |
| Demo limit | Enforcement **yok** |

### Remote v1 DB’ye yazılan alanlar

`file_number`, `first_name`, `last_name`, `phone`, `birth_date`, `national_id` (kimlik no), `insurance_type`, `status` (insert: active)

**Patient Basic Info v1** (`20260528100000_patient_profile_fields_v1.sql`): `gender`, `identity_type`, `nationality`, `blood_type`, `occupation`, `sports_branch`, `secondary_phone`, `email`, `address`, `city`, `district`, `emergency_contact_name`, `emergency_contact_relation`, `emergency_contact_phone`, `emergency_contact_note`

### Formda kalıp remote’ta yazılmayan (v2 / metadata)

`primaryComplaint`, `bodyRegion`, `notes`, `insuranceCompany`, `policyNumber`, `tags`/`tagIds` — mock modda bellek içi kalır; Supabase modda kaydedilmez.

### Hatalar

`duplicateFileNumber`, `forbidden`, `noActiveTenant`, genel create/update mesajları — teknik detay yok.

## Hasta detay remote smoke (v1)

| | |
|--|--|
| Ekran | `patient_detail_screen` → `PatientDetailDataSource.loadById` → `patientsAsync.getById` |
| Mock mod | Mock async adapter — mevcut detay |
| Supabase mod | Remote hasta çekirdek bilgileri (uuid id) |
| Klinik / rehab / PDF / timeline | **Mock** — remote id ile eşleşmeyebilir; boş özet/EmptyState normal |
| Etiketler | Mock `PatientRepository` / tag repo |
| Form düzenle | `patient_form_screen` — remote update (v1) |

## Hasta listesi remote smoke (v1)

| | |
|--|--|
| Ekran | `patient_list_screen` → `PatientListDataSource` → `RepositoryRegistry.patientsAsync` |
| Mock mod | `MockAsyncPatientRepositoryAdapter` — önceki mock veri |
| Supabase mod | `SupabasePatientRepository` `getAll` / `search` |
| Arama remote | `file_number`, `first_name`, `last_name`, `phone`, `national_id` |
| Arama dışı (v1) | `primaryComplaint`, `bodyRegion`, `tags` |
| Detay / form | Remote (v1) |
| Diğer modüller | Randevu, muayene, PDF, stok, audit → mock |

## Appointment remote v1 — DTO / mapper / async contract (hazırlık)

| Konu | Karar |
|------|--------|
| DTO | `AppointmentRemoteRow` — DB kolonları + opsiyonel embed `patients` |
| `id` | Insert’te gönderilmez; sunucu UUID |
| `tenant_id` | `ActiveTenantContextStore` (UI’dan yok) |
| `patientName` | DB’de yok; embed veya `patientsAsync` lookup |
| `appointment_at` | UTC ISO yaz; UI’da `toLocal()` göster |
| İstanbul gün filtresi | `AppointmentDateTimeHelper` UTC+3 sabit |
| Status | `planned` / `arrived` / `no_show` / `cancelled` / `postponed` |
| Type | `first_visit` / `follow_up` / `physiotherapy` / `procedure` / `post_op_follow_up` |
| İptal | `toCancelRow` → `status: cancelled` |
| Arşiv | `toArchiveRow` → `deleted_at` (status korunur) |
| `reason` / `durationMinutes` / `controlDate` | Remote v1 DB’ye **yazılmaz**; mapper fallback: `''` / `30` / `null` |
| Parity | `reason` + `duration` için migration v2 veya metadata JSONB |
| Async contract | `AsyncAppointmentRepositoryContract` |
| Mock async | `MockAsyncAppointmentRepositoryAdapter` (UI bağlı değil) |
| Remote stub | `SupabaseAsyncAppointmentRepositoryStub` → `notConfigured` |
| Failure | `AppointmentRepositoryFailure` (+ `23503` → `patientNotFound`) |
| UI / CRUD | Liste smoke (v1); detay/form **henüz remote değil** |

## SupabaseAppointmentRepository v1 (izole)

| Metod | Davranış |
|-------|----------|
| `getAll` / `getByPatientId` / `getById` | tenant + `deleted_at is null` + `patients(first_name,last_name)` embed |
| `getToday` | İstanbul takvim günü UTC aralığı |
| `getThisWeek` | Yerel Pazartesi–Pazar UTC aralığı (mock uyumlu) |
| `search` | MVP: `getAll` + client-side (`patientName`, notes, status/type label) — **reason yok** |
| `countToday` | İstanbul gün count |
| `add` / `update` | mapper insert/update; server UUID döner |
| `cancel` | `status: cancelled` |
| `archiveAppointment` | `deleted_at` only |
| Failure | `AppointmentRepositoryErrorMapper` |
| Provider/UI | Liste smoke (v1); detay/form sync mock |

## AppointmentRepositoryProvider backend switch (v1)

| | |
|--|--|
| Sync `current` / `instance` | **Daima mock** (`MockAppointmentRepositoryAdapter`) |
| `asyncRepository` | `MockAsyncAppointmentRepositoryAdapter` veya `SupabaseAppointmentRepository` |
| `usesRemoteAppointments` | Tüm gate’ler geçince true |
| Gate | `DATA_BACKEND=supabase` + configured + init + login + session ready + active tenant |
| `RepositoryRegistry` | `appointmentsAsync`, `usesRemoteAppointments` |
| Randevu UI | Liste + detay + form → `appointmentsAsync` (koşullu) |
| Diğer modüller | Muayene/stok/PDF/audit mock |
| `reason` / `duration` / `controlDate` | Remote v1 DB’ye yazılmaz (devam) |

## Randevu listesi remote smoke (v1)

| | |
|--|--|
| Ekran | `appointment_list_screen` → `AppointmentListDataSource` → `RepositoryRegistry.appointmentsAsync` |
| Mock mod | `MockAsyncAppointmentRepositoryAdapter` — önceki mock veri ve filtreler |
| Supabase mod | `SupabaseAppointmentRepository` `getAll` / `getToday` / `getThisWeek` / `getByPatientId` / `search` |
| Period | Bugün → `getToday()`; Bu hafta → `getThisWeek()`; Tümü → `getAll()`; hasta filtresi → `getByPatientId` + gerekirse client period |
| Durum filtresi | Client-side (`AppointmentListFilters.applyStatus`) — yükleme sonrası |
| Arama remote | `patientName`, `notes`, status/type label — **reason yok** (350ms debounce) |
| Arama mock | Sync `search` — hasta adı + reason |
| Fallback UI | `reason` boş, `durationMinutes` 30, `controlDate` null — kartta sahte reason yok; remote’ta not varsa kısa not; süre fallback gizlenir |
| Detay | **Randevu Detay Remote Smoke v1** — `getById` |
| Yeni randevu | Remote `add` — detaya yönlendirme |
| Permission | Doctor/admin + assistant/secretary; nurse/physio route guard (değişmedi) |
| Diğer modüller | Muayene/stok/PDF/audit/timeline → mock |

### Kombine filtre notu

Arama + period + hasta: remote `search` sonrası client-side period/hasta filtresi. İleride büyük veri setinde query optimizasyonu gerekebilir.

## Randevu detay remote smoke (v1)

| | |
|--|--|
| Ekran | `appointment_detail_screen` → `AppointmentDetailDataSource.loadById` → `appointmentsAsync.getById` |
| Mock mod | `MockAsyncAppointmentRepositoryAdapter` — mevcut mock detay |
| Supabase mod | `SupabaseAppointmentRepository.getById` + `patients(first_name,last_name)` embed |
| Hasta dosya no | Mock: sync `PatientRepository`; remote: `patientsAsync.getById` (yoksa satır gizlenir) |
| Hasta bağlantısı | “Dosyayı Görüntüle” → `/patients/{patientId}` (remote UUID destekli) |
| Fallback UI | `reason` boş → neden kartı yok; `durationMinutes` 30 remote’ta gizli; `controlDate` null → satır yok; `notes` varsa Notlar kartı |
| Form / cancel / update | **Randevu Form Remote Smoke v1** — create/update; cancel API hazır, UI yok |
| Timeline | Mock |
| Diğer modüller | Muayene/stok/PDF/audit mock |

## Randevu form remote create/update/cancel smoke (v1)

| | |
|--|--|
| Ekran | `appointment_form_screen` → `AppointmentFormDataSource` → `appointmentsAsync` |
| Yeni kayıt | `add(Appointment)` — sunucu UUID ile detaya yönlendirme |
| Düzenleme | `/appointments/:id/edit` → `update(Appointment)` — detaya dönüş |
| İptal API | `cancel(id)` → `status: cancelled` — **UI’da ayrı iptal aksiyonu yok** (durum dropdown ile update mümkün) |
| Mock mod | `MockAsyncAppointmentRepositoryAdapter` — mevcut add/update/cancel |
| Remote DB alanları | `patient_id`, `appointment_at`, `status`, `appointment_type`, `notes` |
| Remote yazılmayan | `reason`, `durationMinutes`, `controlDate` — migration v2 / metadata JSONB sonraki karar |
| Form remote UX | `reason` / süre alanları gizli; `notes` yalnız notes olarak yazılır |
| Hasta seçimi | `PatientSelectorField` — remote patient UUID; edit modda hasta kilitli |
| Archive / hard delete | Yok |
| Timeline / dashboard | Mock |
| Diğer modüller | Muayene/stok/PDF/audit mock |

## Randevu remote polish + liste refresh (v1)

| | |
|--|--|
| Liste refresh | `AppointmentListRefresh.markStale()` + `activate()` stale kontrolü + `await context.push` dönüşü |
| Detay refresh | Önbellekli detay + ince `LinearProgressIndicator`; edit dönüşünde `reload` |
| Loading | İlk yükleme spinner; refresh’te üst progress + mevcut liste/detay |
| Empty | Boş DB: “Henüz randevu kaydı yok”; arama/filtre: ayrı mesajlar |
| Error | `AppointmentListUserMessages` / `AppointmentDetailUserMessages` / `AppointmentFormUserMessages` — teknik detay yok |
| Fallback UI | `AppointmentRemoteDisplay` — reason/süre/controlDate gizleme; patientName → “Hasta bilgisi” |
| Remote v1 yazılmayan | `reason`, `durationMinutes`, `controlDate` — migration v2 / metadata JSONB sonraki karar |
| Timeline / dashboard | Mock |
| Randevu remote çekirdeği | Liste + detay + form — **ilk faz tamam** |

## Clinical remote v1 — DTO / mapper / async contract (hazırlık)

| Konu | Karar |
|------|--------|
| DTO | `ClinicalEncounterRemoteRow` — DB kolonları + opsiyonel `patients` embed |
| `clinical_data` | JSONB şema v1: `anamnesis`, `sports`, `examination`, `imaging`, `diagnosis`, `plan`, `meta` |
| `internalDoctorNote` | **Ayrı kolon** `internal_doctor_note` — JSONB’ye **yok** |
| Üst kolonlar | `diagnosis_summary`, `treatment_plan_summary` — builder ile |
| Enum mapping | `ClinicalVisitTypeMapping`, `ClinicalEncounterStatusMapping`, body/side/diagnosisType |
| `tenant_id` | `ActiveTenantContextStore` (UI’dan yok) |
| Soft delete | `toArchiveRow` → `deleted_at` |
| Async contract | `AsyncClinicalEncounterRepositoryContract` — doctor full-table |
| Safe summary | `AsyncClinicalEncounterOperationalSummaryContract` stub — **ayrı paket** |
| Mock async | `MockAsyncClinicalEncounterRepositoryAdapter` (UI bağlı değil) |
| Remote stub | `SupabaseAsyncClinicalEncounterRepositoryStub` → `notConfigured` |
| Remote CRUD v1 | `SupabaseClinicalEncounterRepository` — **izole**, provider/UI bağlı değil |
| Failure | `ClinicalEncounterRepositoryFailure` + `ClinicalEncounterRepositoryErrorMapper` |
| UI liste | **Muayene listesi remote smoke v1** — doctor/admin; detay/form sonraki paket |
| UI detay/form | **Henüz remote yok** — sync mock |
| Asistan/FTR | Full `ClinicalEncounter` remote kullanılmayacak; RLS/view/RPC ayrı paket |
| Migration tablo | **Gerekmez**; safe summary RLS **gerekir** (sonraki faz) |

## Clinical remote v1 — SupabaseClinicalEncounterRepository (izole CRUD)

| Konu | Karar |
|------|--------|
| Contract | `AsyncClinicalEncounterRepositoryContract` |
| Sınıf | `SupabaseClinicalEncounterRepository` — `fromSupabase()` factory |
| Path | **Doctor full-table only** (`clinical_encounters` + `internal_doctor_note`) |
| Metodlar | `getAll`, `getByPatientId`, `getById`, `getLatestByPatientId`, `search`, `add`, `update`, `archiveEncounter` |
| Tenant | `ActiveTenantContextStore.current?.tenantId` — UI'dan yok; yoksa `noActiveTenant` |
| Soft delete | Okuma: `deleted_at is null`; arşiv: `toArchiveRow()` → `deleted_at` |
| Hasta adı | `patients(first_name,last_name)` embed — DB'ye yazılmaz |
| `internalDoctorNote` | Yalnız `internal_doctor_note` kolonu — **JSONB'ye konmaz** |
| `clinical_data` | JSONB v1 — mapper `toInsertRow` / `toUpdateRow` |
| Search v1 | Boş sorgu → `getAll`; dolu → client-side (`ClinicalEncounterSearchHelper`, `internalDoctorNote` hariç) |
| Error map | `23503` patient/appointment FK; `42501`/RLS → `forbidden`; `PGRST116` → `notFound`; network/unknown |
| Provider UI | Liste bağlı; varsayılan mock backend |
| Safe summary | Bu pakette yok — asistan/FTR ayrı contract/stub |

## Clinical remote v1 — Repository provider backend switch

| Konu | Karar |
|------|--------|
| Provider | `ClinicalEncounterRepositoryProvider` — `asyncRepository`, `usesRemoteClinicalEncounters` |
| Registry | `RepositoryRegistry.clinicalEncountersAsync` |
| Varsayılan | `DATA_BACKEND` yok / mock → `MockAsyncClinicalEncounterRepositoryAdapter` |
| Remote seçim | `DATA_BACKEND=supabase` + configured + initialized + login + `SessionReadiness` + active tenant + **doctor** (`canViewFullClinicalEncounter`) → `SupabaseClinicalEncounterRepository` |
| Rol gate | Asistan / FTR / hemşire → full-table remote **seçilmez** (mock async) |
| Sync UI | Detay/form/PDF/FTR/timeline — `ClinicalEncounterRepository.instance` (mock) |
| Async UI liste | `ClinicalEncounterListScreen` → `ClinicalEncounterListDataSource` |
| Async UI detay | `ClinicalEncounterDetailScreen` → `ClinicalEncounterDetailDataSource` |
| Async UI form | `ClinicalEncounterFormScreen` → `ClinicalEncounterFormDataSource` |
| Safe summary | Ayrı DTO/repository/RLS/view/RPC — asistan/FTR bu provider kullanmaz |
| PDF / timeline / FTR / stok / audit | Mock |

## Clinical remote v1 — Muayene listesi remote smoke (doctor only)

| Konu | Karar |
|------|--------|
| Ekran | `ClinicalEncounterListScreen` |
| Veri | `ClinicalEncounterListDataSource` → `RepositoryRegistry.clinicalEncountersAsync` |
| Remote gate | `usesRemoteClinicalEncounters` — doctor/admin + active tenant + Supabase koşulları |
| Rol | Asistan / FTR / hemşire → full-table remote **seçilmez** |
| Yükleme | `getAll` / `getByPatientId`; arama remote: `search` |
| Filtre | visit / status / body region — client-side (remote v1) |
| Mock arama | Şikayet + bölge + ön tanı + plan (mevcut davranış) |
| `internalDoctorNote` | Kartlarda **gösterilmez**; aramada **yok** |
| Detay | **Muayene detay remote smoke v1** — doctor/admin; `getById` + `internal_doctor_note` |
| Form | **Muayene form create/update remote smoke v1** — doctor/admin |
| Asistan tanı özeti / FTR klinik özeti | Remote **yok** |
| Timeline / PDF / FTR | Mock |

## Clinical remote v1 — Muayene detay remote smoke (doctor + internalDoctorNote)

| Konu | Karar |
|------|--------|
| Ekran | `ClinicalEncounterDetailScreen` |
| Veri | `ClinicalEncounterDetailDataSource` → `clinicalEncountersAsync.getById` |
| Remote gate | Liste ile aynı — `usesRemoteClinicalEncounters` |
| `internalDoctorNote` | Yalnız doctor/admin detayında; `internal_doctor_note` kolonu — **JSONB yok** |
| Liste | `internalDoctorNote` gösterilmez (önceki paket) |
| Rol | Route + `canViewFullClinicalEncounter` + provider gate |
| Form create/update | **Bu pakette yok** |

## Clinical remote v1 — Muayene form create/update remote smoke (doctor only)

| Konu | Karar |
|------|--------|
| Ekran | `ClinicalEncounterFormScreen` |
| Veri | `ClinicalEncounterFormDataSource` → `clinicalEncountersAsync` add/update/getById |
| Remote gate | Liste/detay ile aynı — `usesRemoteClinicalEncounters` |
| `clinical_data` | `ClinicalEncounterClinicalData.toMap` — **internalDoctorNote yok** |
| `internal_doctor_note` | `ClinicalEncounterRemoteMapper.toInsertRow` / `toUpdateRow` ayrı kolon |
| Create id | Remote: boş id → sunucu UUID; mock: `ce{timestamp}` |
| Navigasyon | Edit → detay; create → liste (mevcut) |
| Rol | Route + provider gate — asistan/FTR/hemşire write yok |

## Sonraki karar / paket

- Safe summary / role projection + RLS/view/RPC
- Timeline / PDF / FTR remote

## UI

- Hasta liste/detay/form/selector/ayarlar count: async remote (koşullu)
- Randevu **liste + detay + form**: async remote (koşullu)
- Muayene **liste + detay + form**: async remote smoke (doctor/admin, koşullu)
- Muayene **PDF/FTR/timeline**: sync mock
