# Clinical Safe Summary + Role Projection + RLS/View/RPC Analizi v1

**Paket türü:** Analiz ve teknik tasarım only — **implementasyon yok**  
**Tarih:** 2026-05-24  
**Hedef roller:** `assistant_secretary` (Flutter: `assistant`), `physiotherapist` (Flutter: `physiotherapist`)  
**Kapsam dışı:** Nurse clinical summary (ayrı minimal plan), timeline/audit/PDF remote, full `clinical_encounters` doctor dışı erişim

---

## Mevcut durum

### Veri modeli (`clinical_encounters`)

Draft şema (`supabase/migrations/20260521100000_draft_saas_schema_rls_v1.sql`):

| Kolon | Hassasiyet | Not |
|-------|------------|-----|
| `id`, `tenant_id`, `patient_id` | Orta | Tenant scope zorunlu |
| `appointment_id` | Orta | Operasyonel bağlantı; özet projection’da ayrı karar |
| `encounter_date`, `visit_type`, `status` | Düşük | Operasyonel |
| `diagnosis_summary`, `treatment_plan_summary` | Orta | Üst kolon özet (doctor write path builder) |
| `clinical_data` jsonb | **Yüksek** | Anamnez, muayene, tanı detayı, plan detayı — **asistan/FTR’ye doğrudan verilmez** |
| `internal_doctor_note` | **Çok yüksek** | Ayrı kolon; yalnız `doctor_admin` |
| `created_by`, timestamps, `deleted_at` | Düşük | Audit/soft delete |

`clinical_data` şema v1 (`ClinicalEncounterClinicalData`) içinde: `anamnesis`, `examination`, `imaging`, `diagnosis`, `plan`, `sports`, `meta` — **`internalDoctorNote` dahil değil** (uygulama katmanı doğru).

### Mevcut view: `clinical_encounter_operational_summary`

**Eski draft** (`20260521100000`): View `clinical_data` içeriyordu — **güvenlik riski** (JSONB sızıntısı).

**Güncel draft policy SQL** (`20260522100000_draft_rls_policies_v1.sql`):

- View **yeniden oluşturuluyor** (`DROP` + `CREATE`, `security_invoker = true`).
- Projeksiyon: `id`, `tenant_id`, `patient_id`, `encounter_date`, `visit_type`, `status`, `diagnosis_summary`, `treatment_plan_summary`, `created_at`, `updated_at`.
- **Yok:** `internal_doctor_note`, `clinical_data`, `appointment_id`, `created_by`.
- View üzerinde RLS/policy **yok** (PostgreSQL kısıtı); güvenlik `security_invoker` + alt tablo RLS ile.

### RLS (draft v1 — uygulanmadı)

| Obje | doctor_admin | assistant | physio | nurse |
|------|:------------:|:---------:|:------:|:-----:|
| `clinical_encounters` (full table) | SELECT/INSERT/UPDATE | **—** | **—** | **—** |
| `clinical_encounter_operational_summary` (view) | Pratikte SELECT* | **0 satır*** | **0 satır*** | **—** |

\* `security_invoker` + alt tablo yalnız doctor SELECT → asistan/FTR view sorgusu **fail-closed (0 satır)**.  
Ürün matrisi (`permission-rls-matrix.md`) asistan/FTR için view SELECT öngörüyor; **RLS gap** — sonraki migration ile kapatılmalı.

### Flutter — doctor/admin full path (remote smoke tamam)

| Katman | Davranış |
|--------|----------|
| `SupabaseClinicalEncounterRepository` | Full-table CRUD; `internal_doctor_note` ayrı kolon; `clinical_data` mapper |
| `ClinicalEncounterRepositoryProvider` | `usesRemoteClinicalEncounters` yalnız doctor + tenant + Supabase koşulları |
| `ClinicalEncounterRepositoryBackendGate` | `isDoctorFullTableEligible` zorunlu |
| UI | Liste, detay, form → `clinicalEncountersAsync` (koşullu remote) |

### Flutter — doctor/admin dışı roller (bugün)

| Katman | Davranış |
|--------|----------|
| `ClinicalEncounterRepositoryProvider.asyncRepository` | Asistan/FTR/hemşire → **MockAsyncClinicalEncounterRepositoryAdapter** (sync mock) |
| Full remote | **Seçilmez** — gate korunuyor |
| `AsyncClinicalEncounterOperationalSummaryContract` | Stub (`notConfigured`); provider/UI bağlı değil |
| Route | `/clinical-records` full liste/detay/form → **yalnız doctor** (`canViewClinicalEncounters`) |

### Flutter — asistan/FTR UI temas (mock, güvenlik borcu)

| Ekran | Route | Veri kaynağı | Risk |
|-------|-------|--------------|------|
| Tanı özeti liste/detay | `/clinical-records/diagnosis-summary` | `ClinicalEncounterRepository.instance` (tam model) | Mock’ta `internalDoctorNote` ve tüm `clinical_data` alanları bellekte |
| FTR klinik özet | `/physiotherapy/clinical-summaries` | Aynı sync repo | Aynı |
| Hasta detay quick link | diagnosis-summary | Rol bazlı link | Full muayene linki doctor’da |

**Kritik:** UI route guard asistanı full muayeneden uzak tutuyor; ancak **mock repo tam encounter döndürüyor**. Remote bağlandığında yanlışlıkla full repository kullanılırsa RLS engeller — **mimari olarak summary repository ayrılmalı**, full repo fallback **yasak**.

### Eksik güvenlik halkaları (özet)

1. Asistan/FTR özet ekranları **safe projection değil**, mock full model.
2. Draft view + doctor-only table RLS → asistan view testi **0 satır** (matris ile uyumsuz).
3. Eski view tanımında `clinical_data` vardı — recreate migration ile giderilmiş (draft).
4. `patient_timeline_builder` doctor route’larına link veriyor — timeline doctor-only (OK).
5. Registry’de role summary repository **yok**.

---

## Güvenlik kararları (değişmez)

1. **Full `clinical_encounters` repository** yalnız `doctor_admin` path.
2. **Asistan/physio/nurse** full liste/detay/create/update **yok**.
3. **`internal_doctor_note`:** yalnız doctor/admin; projection/RPC/DTO/UI’da **asla yok**; `clinical_data` içine **konmaz**; JSONB fallback **yok**.
4. **`clinical_data`:** asistan/FTR client’a **ham JSONB olarak verilmez**; client-side JSONB field pick **yasak**.
5. **Timeline, audit, PDF:** doctor/admin dışına açılmaz; role summary içine alınmaz.
6. **`tenant_id`:** UI’dan gönderilmez; `ActiveTenantContext` / JWT / membership.
7. **`service_role`:** client/repoda **yok**; yalnız ops setup.
8. **Cross-tenant:** membership + RLS `is_tenant_member` + `current_tenant_id()`.

---

## Assistant/Secretary safe summary alanları

Operasyonel rol: randevu, dosya, onam, ödeme — **klinik karar vermez**.

### Allowlist (önerilen projection / DTO)

| Alan | Kaynak | Gerekçe |
|------|--------|---------|
| `encounter_id` | `clinical_encounters.id` | Referans |
| `tenant_id` | tablo | RLS (sunucu) |
| `patient_id` | tablo | Hasta bağlamı |
| `patient_display_name` | `patients` join | Liste kartı |
| `encounter_date` | tablo | Operasyonel |
| `visit_type` | tablo | Başvuru tipi etiketi |
| `status` | tablo | Durum chip |
| `diagnosis_summary` | üst kolon | Kısa operasyonel tanı özeti (doctor-authored builder) |
| `operational_headline` | **yeni opsiyonel kolon** v2 | Tek satır resepsiyon etiketi (ör. “Kontrol — diz”) |
| `next_control_date` | `clinical_data.plan.controlDate` → **yalnızca projection’da extract** | Randevu planlama |
| `appointment_id` | tablo | Randevu bağlantısı (asistan randevu yetkisi var) |
| `has_physiotherapy_referral` | boolean extract | Yönlendirme durumu (bayrak only) |
| `updated_at` | tablo | Liste sıralama |

### Asistan için sınırlı tanı (opsiyonel v1.1)

| Alan | Karar |
|------|--------|
| `icd_code` | **v1 dışı** veya yalnız kod, başlık yok — KVKK/operasyonel ihtiyaç netleşince |
| `body_region` / `side` | Etiket olarak verilebilir (FTR değil, operasyonel yönlendirme için) |

### Asistan — kesinlikle yasak

- `internal_doctor_note`
- `clinical_data` (ham veya partial)
- Anamnez / muayene bulguları / görüntüleme detayı
- `preliminaryDiagnosis`, `finalDiagnosis`, `differentialDiagnosis` (JSONB içi)
- `clinical_impression`, `conservativeTreatment`, `medicationNotes`, `injectionOrProcedurePlan`
- Timeline, audit, PDF içeriği
- FTR seans/rehab detayı
- Başka tenant verisi

---

## Physiotherapist safe summary alanları

FTR: yönlendirme, egzersiz, post-op, rehab — **sınırlı klinik bağlam**.

### Allowlist (önerilen projection / DTO)

| Alan | Kaynak | Gerekçe |
|------|--------|---------|
| `encounter_id`, `tenant_id`, `patient_id` | tablo | Referans / RLS |
| `patient_display_name` | join | UI |
| `encounter_date` | tablo | Bağlam |
| `body_region`, `side` | **projection kolonları** (DB extract veya summary table) | FTR anatomik bağlam |
| `visit_type`, `status` | tablo | Bağlam |
| `physiotherapy_referral` | boolean | Yönlendirme bayrağı |
| `exercise_recommendation_short` | truncate(120) extract | Egzersiz özeti |
| `rehab_precautions_short` | **yeni safe kolon** veya controlled extract | Yük/kısıt |
| `weight_bearing_status` | **yeni safe kolon** opsiyonel | Post-op |
| `rom_limitation_short` | extract | Rehab planı |
| `control_date` | extract | Kontrol |
| `post_op_context_short` | **yeni safe kolon** | Cerrahi/prosedür özeti (kısa) |
| `ftr_goal_short` | `return_to_sport_goal` extract veya safe kolon | Hedef |
| `diagnosis_summary` | üst kolon | **Kısa** — tam tanı metni değil |
| `treatment_plan_summary` | üst kolon | **Kısa** — hassas ilaç/cerrahi detay içermemeli |

### Physio — kesinlikle yasak

- `internal_doctor_note`
- `clinical_data` ham JSONB
- Tam anamnez, tam muayene, imaging doctor comment
- ICD tam başlık / ayırıcı tanı listesi (v1)
- Ödeme, audit, timeline, PDF
- Asistan operasyonel notları
- Başka branş tenant verisi

### Asistan vs FTR ayrımı

| Konu | Asistan | FTR |
|------|---------|-----|
| Birincil özet | Operasyonel tanı + randevu | Rehab/anatomi + egzersiz |
| `body_region` | Etiket (opsiyonel) | **Zorunlu** |
| `exercise_recommendation` | Yok | Kısa özet |
| `appointment_id` | Evet | Hayır (v1) |
| Ayrı view/RPC | **Evet** | **Evet** |

**Karar:** Tek view ile iki rol **birleştirilmemeli** — alan allowlist farklı; yanlışlıkla fazla alan verme riski.

---

## Yasak alanlar (global)

- `internal_doctor_note` (kolon ve türevleri)
- `clinical_data` jsonb (tamamı)
- Client-side: `clinical_data->'diagnosis'->>'finalDiagnosis'` vb.
- `internalDoctorNote`, `doctorNote`, `privateNote` JSONB key’leri (asla üretilmez/okunmaz)
- Full `ClinicalEncounter` modeli asistan/FTR provider’ında
- `SupabaseClinicalEncounterRepository` asistan/FTR için
- Timeline / audit_logs / pdf_outputs içerikleri
- `service_role` client anahtarı

---

## Projection stratejisi seçenekleri

### Seçenek A — Security-invoker view (rol başına)

Örnek: `assistant_clinical_encounter_summary_v`, `physiotherapist_clinical_encounter_summary_v`

| Artı | Eksi |
|------|------|
| SQL tarafında explicit kolon listesi | Alt tablo RLS doctor-only ise **0 satır** (mevcut durum) |
| PostgREST `.from('view')` basit | View’da RLS yok; yanlış kolon ekleme riski |
| `security_invoker` ile RLS mirası | Asistan için tablo policy şart → geniş SELECT riski |

**Sonuç:** View tek başına **yeterli değil**; doctor-only table RLS ile çelişir.

### Seçenek B — SECURITY DEFINER RPC (önerilen MVP çekirdeği)

Örnek:

- `list_assistant_clinical_summaries(p_patient_id uuid default null)`
- `get_assistant_clinical_summary(p_encounter_id uuid)`
- `list_physiotherapist_clinical_summaries(...)`
- `get_physiotherapist_clinical_summary(...)`

| Artı | Eksi |
|------|------|
| Rol + tenant kontrolü fonksiyon içinde | DEFINER yanlış yazılırsa **kritik sızıntı** |
| Full table’a client erişimi yok | Test + code review zorunlu |
| Explicit allowlist SELECT | PostgREST RPC entegrasyonu |
| MVP hızlı | İki fonksiyon seti bakımı |

**Önlemler:** `SET search_path = public`, `is_tenant_member`, `has_tenant_role`, `deleted_at is null`, yalnız allowlist kolonlar, **asla** `internal_doctor_note` / `clinical_data` select.

### Seçenek C — Dedicated summary table

Örnek: `clinical_encounter_role_summaries` (`audience` enum: `assistant` | `physiotherapist`)

| Artı | Eksi |
|------|------|
| En net RLS (tablo policy) | Trigger/sync karmaşıklığı |
| Performans (index) | Doctor write path’e ek iş |
| SaaS ölçeklenebilir | MVP daha yavaş |

**Populate:** Doctor insert/update sonrası trigger veya app-layer job — yalnız safe alanlar kopyalanır.

### Karşılaştırma özeti

| Kriter | A View | B RPC | C Table |
|--------|--------|-------|---------|
| internalDoctorNote sızıntı riski | Orta (kolon hatası) | Düşük (allowlist) | Düşük |
| Tenant isolation | İyi* | İyi | İyi |
| MVP hız | Orta | **Yüksek** | Düşük |
| Mevcut RLS ile uyum | **Kötü** | **İyi** | İyi |
| PostgREST ergonomi | İyi | Orta | İyi |

---

## Önerilen MVP yaklaşımı

**Hibrit — MVP:**

1. **Migration v1:** İki **narrow SQL view** (dokümantasyon ve allowlist referansı; `security_invoker`); kolon setleri bu dokümandaki allowlist ile birebir.
2. **Migration v1:** **SECURITY DEFINER RPC** (asıl erişim yolu) — asistan ve FTR için ayrı fonksiyonlar; tenant + rol doğrulama.
3. **İsteğe bağlı v1.1:** `clinical_encounter_role_summaries` tablosu (performans / audit) — trigger ile doldurulur.
4. **Flutter:** Ayrı DTO + repository + provider; **full repo fallback yok**.
5. **JSONB client filtreleme:** Kesinlikle **yok**.

**Neden RPC önce?** Mevcut draft RLS doctor-only table ile `security_invoker` view asistan'a satır döndürmez; RPC rol kontrollü allowlist SELECT yapabilir.

**View rolü:** RPC içinde kullanılan iç sorgu şablonu veya ileride policy genişletmeden önce allowlist doğrulama referansı.

---

## RLS / permission yaklaşımı

### Tablo: `clinical_encounters`

- Değişmez: SELECT/INSERT/UPDATE **yalnız** `doctor_admin` + `is_tenant_member` + `current_tenant_id()` write check.

### Yeni erişim: RPC (önerilen)

| Kontrol | Nerede |
|---------|--------|
| `auth.uid()` | Fonksiyon giriş |
| Active tenant | `current_tenant_id()` = kayıt `tenant_id` |
| Rol | `has_tenant_role(tenant_id, array['assistant_secretary'])` vb. |
| Soft delete | `deleted_at is null` |
| Cross-tenant | Yanlış tenant → 0 satır / exception |

### View policy (alternatif/gelecek)

PostgreSQL view’da policy yok. Asistan’a **geniş** `clinical_encounters` SELECT policy **yazılmamalı** (`internal_doctor_note` riski).

### Nurse

v1: **Clinical summary yok** (matris ile uyumlu). İleride minimal “hasta uyarısı” ayrı tablo.

### Test edilmesi gereken negatif senaryolar

| # | Senaryo | Beklenen |
|---|---------|----------|
| N1 | Asistan `SELECT * FROM clinical_encounters` | Red / 0 |
| N2 | Asistan `SELECT internal_doctor_note FROM clinical_encounters` | Red |
| N3 | FTR full table SELECT | Red |
| N4 | Asistan RPC → başka tenant `encounter_id` | 0 / forbidden |
| N5 | JWT tenant A, payload tenant B | Red |
| N6 | Inactive membership | 0 / forbidden |
| N7 | Doctor RPC asistan fonksiyonu | Rol check fail |
| N8 | Response body’de `clinical_data` key | **Yok** |
| N9 | Response’da `internal_doctor_note` | **Yok** |

---

## DTO / repository / provider tasarımı

### DTO (remote row / API)

```text
AssistantClinicalSummaryRow
  - id, tenant_id, patient_id
  - patient_display_name
  - encounter_date, visit_type, status
  - diagnosis_summary
  - operational_headline (nullable)
  - next_control_date (nullable)
  - appointment_id (nullable)
  - has_physiotherapy_referral
  - updated_at

PhysiotherapistClinicalSummaryRow
  - id, tenant_id, patient_id
  - patient_display_name
  - encounter_date, visit_type, status
  - body_region, side
  - diagnosis_summary_short
  - treatment_plan_summary_short
  - physiotherapy_referral
  - exercise_recommendation_short
  - rehab_precautions_short (nullable)
  - control_date (nullable)
  - post_op_context_short (nullable)
  - ftr_goal_short (nullable)
  - updated_at
```

**Not:** `internal_doctor_note` ve `clinical_data` alanları DTO’da **tanımsız**.

### Domain modeller

- `AssistantClinicalSummary`
- `PhysiotherapistClinicalSummary`

Mapper: row → domain; **JSONB parse yok**.

### Repository contract

```text
abstract interface AssistantClinicalSummaryRepository {
  Future<List<AssistantClinicalSummary>> list({String? patientId});
  Future<AssistantClinicalSummary?> getById(String encounterId);
}

abstract interface PhysiotherapistClinicalSummaryRepository {
  Future<List<PhysiotherapistClinicalSummary>> list({String? patientId});
  Future<PhysiotherapistClinicalSummary?> getById(String encounterId);
}
```

Alternatif tek contract + `ClinicalSummaryAudience` enum — **tercih: ayrı contract** (yanlış alan karışımını azaltır).

### Provider / registry

```text
ClinicalRoleSummaryRepositoryProvider
  - assistantSummaryRepository  → Mock | Supabase RPC
  - physiotherapistSummaryRepository → Mock | Supabase RPC
  - usesRemoteAssistantSummaries
  - usesRemotePhysiotherapistSummaries
```

**Gate (önerilen):**

| Koşul | Assistant remote | Physio remote |
|--------|------------------|---------------|
| Supabase + login + session + tenant | ✓ | ✓ |
| Rol | `assistant` | `physiotherapist` |
| Full clinical gate | **false** | **false** |

`RepositoryRegistry`:

- `assistantClinicalSummaries` / `physiotherapistClinicalSummaries`
- **Asla** `clinicalEncountersAsync` fallback

### Mock

- `MockAssistantClinicalSummaryRepository` — mock encounter listesinden **allowlist map** (test için `internalDoctorNote` strip).
- Full `ClinicalEncounterRepository` **kullanılmaz** production path’te.

---

## UI temas noktaları (kod yazılmadan plan)

### Assistant/Secretary

| Ekran | Mevcut | Hedef veri |
|-------|--------|------------|
| `/clinical-records/diagnosis-summary` | Mock full encounter | `AssistantClinicalSummaryRepository` |
| `/clinical-records/diagnosis-summary/:id` | Mock full | Aynı |
| Hasta detay quick link | diagnosis-summary | Kart: kısa tanı + tarih |
| Randevu detay | (gelecek) | `diagnosis_summary` one-liner embed |
| Dosya/onam/ödeme | hasta id | Minimal başlık (opsiyonel) |

**Açılmayacak:** `/clinical-records` full, detay full, form, timeline, audit, PDF viewer.

### Physiotherapist

| Ekran | Mevcut | Hedef veri |
|-------|--------|------------|
| `/physiotherapy/clinical-summaries` | Mock full | `PhysiotherapistClinicalSummaryRepository` |
| `/physiotherapy/clinical-summaries/:id` | Mock full | Aynı |
| FTR yönlendirme formu | `clinicalEncounterId` | Summary getById (kısa) |
| Hasta detay (gelecek kart) | — | FTR özet kartı |
| Seans planlama | — | `exercise_recommendation_short`, precautions |

**Açılmayacak:** Full muayene, internal note, timeline, audit, PDF.

### Route guard (mevcut — korunacak)

- `canViewClinicalDiagnosisSummary` → asistan özet
- `canViewClinicalSummary` → FTR özet
- `canViewClinicalEncounters` → yalnız doctor

---

## Riskler ve önlemler

| Risk | Önlem |
|------|--------|
| JSONB’den hassas alan sızması | RPC/table allowlist; client parse yok |
| View’a fazla kolon eklenmesi | Migration review checklist; iki ayrı view |
| SECURITY DEFINER bypass | Rol+tenant test; minimal `search_path`; code review |
| Full repo fallback | Provider’da compile-time ayrı contract; lint/test |
| inactive membership | `is_tenant_member` + session readiness |
| Multi-tenant JWT karışıklığı | `current_tenant_id()` eşitliği |
| Mock’ta internal note görünür | Mock summary mapper strip; UI DTO’da alan yok |
| KVKK minimum necessary | Rol başına ayrı allowlist; dokümante |
| Audit eksikliği | v2: `audit_logs` read on summary access (ayrı paket) |
| `diagnosis_summary` içinde hassas metin | Doctor builder kuralları; opsiyonel `operational_headline` kolonu |

---

## Fazlara bölünmüş implementation roadmap

### 1. Safe Summary DB Projection Migration v1

| | |
|--|--|
| **Amaç** | Narrow view tanımları + SECURITY DEFINER RPC iskeleti (allowlist SELECT) |
| **Kapsam** | SQL migration draft; asistan/FTR fonksiyonları; grant execute |
| **Kapsam dışı** | Flutter; full table policy değişikliği (doctor-only kalır) |
| **Kabul** | N1–N9 SQL testleri geçer; response’da `internal_doctor_note` / `clinical_data` yok |

### 2. AssistantClinicalSummary DTO/Mapper/Repository Contract v1

| | |
|--|--|
| **Amaç** | Dart DTO + mapper + contract (query yok) |
| **Kapsam** | Row model, domain, failure enum |
| **Kapsam dışı** | UI, Supabase çağrısı |
| **Kabul** | Unit test mapper; DTO’da yasak alan yok |

### 3. PhysiotherapistClinicalSummary DTO/Mapper/Repository Contract v1

| | |
|--|--|
| **Amaç** | FTR özet DTO ayrı (rehab alanları) |
| **Kapsam** | Ayrı contract + mapper |
| **Kapsam dışı** | Assistant ile birleştirme |
| **Kabul** | internalDoctorNote mapping testi yok |

### 4. Supabase Role Summary Repository İzole Smoke v1

| | |
|--|--|
| **Amaç** | RPC çağıran repository; izole test |
| **Kapsam** | `SupabaseAssistantClinicalSummaryRepository`, `SupabasePhysiotherapistClinicalSummaryRepository` |
| **Kapsam dışı** | UI |
| **Kabul** | Staging manuel smoke; forbidden tenant red |

### 5. Role Summary Provider Backend Switch v1

| | |
|--|--|
| **Amaç** | Mock/Supabase seçimi; rol gate |
| **Kapsam** | Provider + registry |
| **Kapsam dışı** | Full clinical provider değişikliği |
| **Kabul** | Doctor dışı `usesRemoteClinicalEncounters` false kalır |

### 6. Assistant Safe Summary UI Smoke v1

| | |
|--|--|
| **Amaç** | diagnosis-summary liste/detay → summary repository |
| **Kapsam** | İki ekran; loading/error minimal |
| **Kapsam dışı** | Full clinical route |
| **Kabul** | Mock mod regresyon; remote asistan satır görür |

### 7. Physiotherapist Safe Summary UI Smoke v1

| | |
|--|--|
| **Amaç** | clinical-summaries ekranları → physio repository |
| **Kapsam** | Liste/detay |
| **Kapsam dışı** | FTR modül remote (ayrı) |
| **Kabul** | internal note UI’da yok |

### 8. Role Summary Loading/Error Polish v1

| | |
|--|--|
| **Amaç** | Tutarlı mesajlar; retry |
| **Kapsam** | Summary ekranları only |
| **Kapsam dışı** | Doctor clinical polish (yapıldı) |

### 9. Negative RLS Test Checklist v1

| | |
|--|--|
| **Amaç** | Manuel/otomatik negatif test dokümantasyonu |
| **Kapsam** | rls-test-plan genişletme |
| **Kapsam dışı** | Production deploy |

### 10. Audit/KVKK Access Event Extension v1

| | |
|--|--|
| **Amaç** | Summary görüntüleme audit |
| **Kapsam** | `audit_logs` append |
| **Kapsam dışı** | Bu analiz paketi |

---

## Açık sorular / sonraya kalanlar

1. **Asistan için `appointment_id`:** Operasyonel gerekli mi? (Öneri: evet, projection’da ver.)
2. **Asistan için `icd_code`:** v1 dahil mi? (Öneri: hayır — v1.1 ürün kararı.)
3. **`diagnosis_summary` hassasiyeti:** Doctor builder ile kısaltma kuralları yazılmalı mı?
4. **Dedicated summary table:** RPC MVP sonrası performans ihtiyacı değerlendirmesi.
5. **Nurse:** Klinik özet gerekir mi? (v1: hayır.)
6. **Draft RLS apply sırası:** View recreate + RPC birlikte staging doğrulama.
7. **Hasta detay FTR kartı:** Hangi pakette (UI smoke sonrası).

---

## Sonraki paket (önerilen)

**Safe Summary DB Projection Migration v1** — bu dokümandaki allowlist ile RPC + narrow view SQL; doctor-only `clinical_encounters` RLS korunarak.

---

## Referanslar (repo içi)

- `supabase/migrations/20260521100000_draft_saas_schema_rls_v1.sql` — tablo + eski view
- `supabase/migrations/20260522100000_draft_rls_policies_v1.sql` — doctor RLS + güvenli view recreate
- `docs/backend/permission-rls-matrix.md`
- `docs/backend/rls-policies-v1.md`
- `docs/backend/rls-test-plan.md`
- `lib/features/clinical_encounter/data/clinical_encounter_repository_provider.dart`
- `lib/features/clinical_encounter/data/async_clinical_encounter_operational_summary_contract.dart`
