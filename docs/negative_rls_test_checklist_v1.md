# Negative RLS Test Checklist v1

> **Paket türü:** Dokümantasyon / manuel QA checklist (kod, migration, RLS, UI değişikliği yok)  
> **Hedef ortam:** Staging (Supabase + gerçek JWT)  
> **İlgili migration:** `supabase/migrations/20260524100000_safe_clinical_role_summary_projection_v1.sql`  
> **İlgili analiz:** [clinical_safe_summary_role_projection_analysis_v1.md](clinical_safe_summary_role_projection_analysis_v1.md)  
> **Genel RLS planı (draft):** [backend/rls-test-plan.md](backend/rls-test-plan.md)

---

## 1. Mevcut güvenlik mimarisi özeti

| Katman | Davranış |
|--------|----------|
| **Full clinical path** | `clinical_encounters` tablosu — RLS ile **yalnız `doctor_admin`** (SELECT/INSERT/UPDATE). Assistant, physiotherapist, nurse **geniş SELECT policy yok**. |
| **Assistant safe summary** | `list_assistant_clinical_summaries(p_patient_id?)`, `get_assistant_clinical_summary(p_encounter_id)` |
| **Physiotherapist safe summary** | `list_physiotherapist_clinical_summaries(p_patient_id?)`, `get_physiotherapist_clinical_summary(p_encounter_id)` |
| **Views (allowlist projection)** | `clinical_encounter_assistant_summary`, `clinical_encounter_physiotherapist_summary` — `security_invoker = true` |
| **View direct access** | `REVOKE ALL` → `authenticated` ve `public` — doğrudan `SELECT` **yasak** |
| **RPC execute** | `GRANT EXECUTE` → `authenticated` (dört RPC) |
| **Internal gate** | `_clinical_summary_access_allowed(tenant_id, allowed_roles)` — client’tan **revoke**; SECURITY DEFINER RPC içinde |
| **Tenant / üyelik** | `auth.uid()`, `current_tenant_id()`, `is_tenant_member()`, `has_tenant_role()`, `tenants.status = 'active'` |
| **Fail-closed** | Gate false → **0 satır** (exception fırlatılmaz) |
| **Yasak alanlar** | `internal_doctor_note` ve **ham `clinical_data`** RPC/view çıktısında **yok**; yalnız allowlist scalar extract |
| **Soft delete** | View `ce.deleted_at is null` — silinmiş encounter summary’de görünmez |
| **Cross-tenant** | `p_tenant_id = current_tenant_id()` + membership — başka tenant satırı dönmez |
| **Service role** | Client/test akışında **kullanılmaz**; RLS doğrulaması için uygun değil |

**Assistant RPC rol allowlist:** `doctor_admin`, `assistant_secretary`  
**Physiotherapist RPC rol allowlist:** `doctor_admin`, `physiotherapist`  
**Bilinçli dışlama:** `nurse` — her iki summary RPC’de de **0 satır**

---

## 2. Staging test veri matrisi

### 2.1 Tenant’lar

| ID (örnek) | Kod | `tenants.status` | Amaç |
|------------|-----|------------------|------|
| `tenant-a-uuid` | Tenant A | `active` | Birincil pozitif/negatif tenant |
| `tenant-b-uuid` | Tenant B | `active` | Cross-tenant izolasyon |
| `tenant-c-uuid` | Tenant C | `suspended` veya `inactive` | Inactive tenant (N11) |

### 2.2 Test kullanıcıları (JWT başına bir oturum)

| Kullanıcı | Rol (`memberships.role`) | Tenant | `memberships.status` | Amaç |
|-----------|--------------------------|--------|----------------------|------|
| `doctor.admin.a@…` | `doctor_admin` | A | `active` | P1, full CE pozitif |
| `assistant.a@…` | `assistant_secretary` | A | `active` | P2, N1, N4 negatif cross |
| `physio.a@…` | `physiotherapist` | A | `active` | P3, N2 |
| `nurse.a@…` | `nurse` | A | `active` | N3, N8, N9 |
| `doctor.admin.b@…` | `doctor_admin` | B | `active` | Tenant B full CE |
| `assistant.b@…` | `assistant_secretary` | B | `active` | N4 (B→A) |
| `physio.b@…` | `physiotherapist` | B | `active` | N5 (B→A) |
| `inactive.member@…` | `assistant_secretary` (veya physio) | A | `inactive` / `suspended` | N10 |
| `no.member@…` | — | — | üyelik yok | N12 |
| Anon / oturumsuz | — | — | — | N13 |

> **Not:** Her test kullanıcısı staging’de **ayrı auth user** olmalı; aynı browser’da rol değiştirmek JWT karışıklığına yol açar.

### 2.3 Test kayıtları (`clinical_encounters`)

| Kayıt | Tenant | Özellik | Testler |
|-------|--------|---------|---------|
| `enc-a-1` | A | Normal encounter | P1–P3, N14 negatif (B ile) |
| `enc-b-1` | B | Normal encounter | Cross-tenant N4, N5, N14 |
| `enc-a-sensitive` | A | `internal_doctor_note` dolu | N17 |
| `enc-a-json` | A | `clinical_data` içinde hassas key’ler (`anamnesis`, `examination`, `clinicalImpression`, vb.) | N18, N19 |
| `enc-a-ftr` | A | `clinical_data.plan.physiotherapyReferral = true` | Physio pozitif, assistant `has_physiotherapy_referral` |
| `enc-a-deleted` | A | `deleted_at IS NOT NULL` | N15 |

**Hazırlık (yalnız setup aşaması):** Seed/migration sonrası doctor_admin JWT ile kayıtlar oluşturulur. Setup için gerekirse DB admin kullanılabilir; **RLS doğrulama adımlarında service_role kullanılmaz.**

### 2.4 Aktif tenant context

RPC’ler `current_tenant_id()` kullanır. Test öncesi:

- Kullanıcı giriş yapmış (`auth.uid()` dolu)
- Aktif tenant seçilmiş (uygulama `active_tenant` / membership store ile — staging’de doctor/assistant/physio UI veya test helper)
- **No active tenant** senaryosu: tenant seçilmeden RPC → N11 benzeri **0 satır** (client’ta `noActiveTenant`; DB’de `current_tenant_id()` null)

---

## 3. Positive control testleri (önce çalıştır)

Başarısız pozitif kontrol → negatif testlere geçme; ortam/seed/JWT hatalı olabilir.

| ID | Kullanıcı | Tenant context | İşlem | Beklenen | Pass notu |
|----|-----------|----------------|-------|----------|-----------|
| **P1** | Doctor/Admin A | Tenant A active | `SELECT * FROM clinical_encounters WHERE tenant_id = current_tenant_id() LIMIT 5` | ≥1 satır; `internal_doctor_note` kolonu **doctor için okunabilir** (full path) | ☐ |
| **P2** | Assistant A | Tenant A active | `SELECT * FROM list_assistant_clinical_summaries()` | Tenant A encounter’ları; yalnız allowlist kolonlar | ☐ |
| **P2b** | Assistant A | Tenant A | `SELECT * FROM get_assistant_clinical_summary('enc-a-1')` | 1 satır, `encounter_id = enc-a-1` | ☐ |
| **P3** | Physiotherapist A | Tenant A active | `SELECT * FROM list_physiotherapist_clinical_summaries()` | Tenant A FTR summary satırları | ☐ |
| **P3b** | Physiotherapist A | Tenant A | `SELECT * FROM get_physiotherapist_clinical_summary('enc-a-ftr')` | 1 satır; `physiotherapy_referral` true olabilir | ☐ |
| **P4** | Doctor/Admin A | Tenant A | `list_assistant_clinical_summaries()` + `list_physiotherapist_clinical_summaries()` | Her ikisi de Tenant A verisi (doctor_admin compat) | ☐ |
| **P5** | Assistant A | Tenant A | `list_assistant_clinical_summaries('patient-a-uuid')` | Yalnız o hastanın özetleri | ☐ |
| **P6** | Herhangi yetkili rol | Tenant A, kayıt yok | `list_*` boş tenant’ta | `[]` / 0 satır, **hata değil** | ☐ |
| **P7** | Assistant A | Tenant A | `get_assistant_clinical_summary('00000000-0000-0000-0000-000000000000')` | 0 satır (geçersiz id) | ☐ |

**Kanıt:** SQL sonuç ekran görüntüsü veya PostgREST response JSON (kolon adları listesi dahil).

---

## 4. Negative RLS test senaryoları (N1–N20)

| ID | Senaryo | Kullanıcı / rol | Tenant context | İşlem | Beklenen sonuç | Pass |
|----|---------|-----------------|----------------|-------|----------------|------|
| **N1** | Assistant full `clinical_encounters` SELECT yapamaz | `assistant_secretary` A | Tenant A active | `SELECT id, internal_doctor_note, clinical_data FROM clinical_encounters LIMIT 5` | **0 satır** veya permission denied; `internal_doctor_note` **asla dönmez** | ☐ |
| **N2** | Physiotherapist full CE SELECT yapamaz | `physiotherapist` A | Tenant A active | `SELECT * FROM clinical_encounters LIMIT 5` | **0 satır** veya permission denied | ☐ |
| **N3** | Nurse full CE SELECT yapamaz | `nurse` A | Tenant A active | `SELECT * FROM clinical_encounters LIMIT 5` | **0 satır** veya permission denied | ☐ |
| **N4** | Assistant B, Tenant A summary göremez | `assistant_secretary` B | Tenant B active (`current_tenant_id` = B) | `list_assistant_clinical_summaries()` | **0 satır**; Tenant A `enc-a-*` yok | ☐ |
| **N5** | Physiotherapist B, Tenant A summary göremez | `physiotherapist` B | Tenant B active | `list_physiotherapist_clinical_summaries()` | **0 satır** | ☐ |
| **N6** | Assistant, physio RPC alamaz | `assistant_secretary` A | Tenant A active | `list_physiotherapist_clinical_summaries()` + `get_physiotherapist_clinical_summary('enc-a-ftr')` | **0 satır** (fail-closed) | ☐ |
| **N7** | Physiotherapist, assistant RPC alamaz | `physiotherapist` A | Tenant A active | `list_assistant_clinical_summaries()` + `get_assistant_clinical_summary('enc-a-1')` | **0 satır** | ☐ |
| **N8** | Nurse assistant RPC alamaz | `nurse` A | Tenant A active | `list_assistant_clinical_summaries()` | **0 satır** | ☐ |
| **N9** | Nurse physio RPC alamaz | `nurse` A | Tenant A active | `list_physiotherapist_clinical_summaries()` | **0 satır** | ☐ |
| **N10** | Inactive membership summary alamaz | `inactive.member` (membership ≠ active) | Tenant A | Her dört RPC | **0 satır** | ☐ |
| **N11** | Suspended/inactive tenant summary dönmez | Assistant veya Physio A | Tenant C veya inactive tenant seçili | `list_*` / `get_*` | **0 satır** | ☐ |
| **N12** | No membership user | `no.member` | — | Her dört RPC | **0 satır** veya auth hatası | ☐ |
| **N13** | No auth / anon | Anon key, oturum yok | — | `list_assistant_clinical_summaries()` (RPC) | Permission denied / JWT invalid; veri **dönmez** | ☐ |
| **N14** | Cross-tenant `get_*` | Assistant A | Tenant A active | `get_assistant_clinical_summary('enc-b-1')` | **0 satır** / null | ☐ |
| **N14b** | Cross-tenant physio get | Physio A | Tenant A active | `get_physiotherapist_clinical_summary('enc-b-1')` | **0 satır** | ☐ |
| **N15** | Soft-deleted encounter | Assistant A | Tenant A | `get_assistant_clinical_summary('enc-a-deleted')` | **0 satır**; list’te de yok | ☐ |
| **N16** | View direct SELECT revoke | Assistant A | Tenant A | `SELECT * FROM clinical_encounter_assistant_summary LIMIT 1` | **Permission denied** (42501) veya erişim yok | ☐ |
| **N16b** | Physio view direct SELECT | Physio A | Tenant A | `SELECT * FROM clinical_encounter_physiotherapist_summary LIMIT 1` | **Permission denied** | ☐ |
| **N17** | Response’ta `internal_doctor_note` yok | Assistant A + Physio A | Tenant A | `list_*` / `get_*` sonra JSON key taraması | Kolon/key listesinde `internal_doctor_note` / `internalDoctorNote` **yok** | ☐ |
| **N18** | Response’ta `clinical_data` yok | Assistant A + Physio A | Tenant A | Aynı | `clinical_data` / `clinicalData` **yok** | ☐ |
| **N19** | Hassas türetilmiş key yok | Assistant A + Physio A | Tenant A | `enc-a-json` için get/list | `anamnesis`, `physical_exam`, `clinicalImpression`, `privateNote`, ham JSON blob **yok** | ☐ |
| **N20** | Client `tenant_id` manipülasyonu | Assistant A | Tenant A | RPC çağrısına **ekstra tenant_id parametresi yok**; Flutter/PostgREST body’de tenant inject | Başka tenant verisi **alınamaz**; yalnız `current_tenant_id()` scope | ☐ |

---

## 5. Manuel SQL / RPC test şablonları

### 5.1 ⚠️ Service role ve SQL Editor uyarısı

| Yöntem | RLS gerçekliği | Öneri |
|--------|----------------|-------|
| **Supabase SQL Editor (varsayılan)** | Çoğunlukla **service_role / postgres** → RLS **bypass** | Negatif RLS testi için **uygun değil** |
| **PostgREST + kullanıcı JWT** | RLS **açık** | **Birincil yöntem** |
| **Flutter app staging build** | Gerçek `authenticated` oturumu | UI smoke + API birlikte |
| **psql `SET request.jwt.claims`** | Rol simülasyonu (ileri) | CI/automation sonraki faz |

**Kural:** N1–N20 sonuçları yalnızca **authenticated kullanıcı JWT** ile geçerli sayılır. SQL Editor’da “çalışıyor” görmek **false positive** üretebilir.

**Service role:** Setup/seed dışında **önerilmez**; client’ta **asla** kullanılmaz.

### 5.2 Assistant RPC şablonları

```sql
-- Önkoşul: Assistant A JWT + Tenant A active context
SELECT * FROM list_assistant_clinical_summaries();
SELECT * FROM list_assistant_clinical_summaries('patient-a-uuid'::uuid);
SELECT * FROM get_assistant_clinical_summary('enc-a-1'::uuid);
```

### 5.3 Physiotherapist RPC şablonları

```sql
-- Önkoşul: Physiotherapist A JWT + Tenant A active context
SELECT * FROM list_physiotherapist_clinical_summaries();
SELECT * FROM list_physiotherapist_clinical_summaries('patient-a-uuid'::uuid);
SELECT * FROM get_physiotherapist_clinical_summary('enc-a-ftr'::uuid);
```

### 5.4 Full table negatif şablonlar (fail beklenir)

```sql
-- Assistant / Physio / Nurse JWT ile — hepsi fail-closed
SELECT * FROM clinical_encounters LIMIT 1;
SELECT id, internal_doctor_note FROM clinical_encounters WHERE id = 'enc-a-sensitive'::uuid;
```

### 5.5 Direct view negatif şablonlar (fail beklenir)

```sql
SELECT * FROM clinical_encounter_assistant_summary LIMIT 1;
SELECT * FROM clinical_encounter_physiotherapist_summary LIMIT 1;
```

### 5.6 PostgREST / curl smoke (JWT ile)

```http
POST /rest/v1/rpc/list_assistant_clinical_summaries
Authorization: Bearer <assistant_a_access_token>
apikey: <anon_key>
Content-Type: application/json

{}
```

```http
POST /rest/v1/rpc/get_assistant_clinical_summary
Authorization: Bearer <assistant_a_access_token>
apikey: <anon_key>
Content-Type: application/json

{"p_encounter_id": "enc-a-1"}
```

> `tenant_id` body’de **gönderilmez**. Yanıtta başka tenant UUID’si (Tenant B) **olmamalı**.

### 5.7 Response key audit (her RPC sonrası)

```text
1. İlk satırın tüm kolon adlarını listele
2. Yasak key listesi ile diff al (Bölüm 7)
3. JSON içinde nested object var mı kontrol et → olmamalı (düz scalar satır)
```

---

## 6. Response schema kontrol checklist’i

### 6.1 Assistant allowlist (yalnızca bu kolonlar olabilir)

| Kolon | Tip (beklenen) |
|-------|----------------|
| `encounter_id` | uuid |
| `tenant_id` | uuid |
| `patient_id` | uuid |
| `patient_display_name` | text |
| `encounter_date` | timestamptz |
| `visit_type` | text |
| `status` | text |
| `diagnosis_summary` | text |
| `operational_headline` | text (nullable) |
| `next_control_date` | timestamptz (nullable) |
| `appointment_id` | uuid (nullable) |
| `has_physiotherapy_referral` | boolean |
| `updated_at` | timestamptz |

### 6.2 Physiotherapist allowlist (yalnızca bu kolonlar olabilir)

| Kolon | Tip (beklenen) |
|-------|----------------|
| `encounter_id` | uuid |
| `tenant_id` | uuid |
| `patient_id` | uuid |
| `patient_display_name` | text |
| `encounter_date` | timestamptz |
| `body_region` | text (nullable) |
| `side` | text (nullable) |
| `visit_type` | text |
| `status` | text |
| `physiotherapy_referral` | boolean |
| `exercise_recommendation_short` | text (nullable) |
| `rehab_precautions_short` | text (nullable) |
| `weight_bearing_status` | text (nullable) |
| `rom_limitation_short` | text (nullable) |
| `control_date` | timestamptz (nullable) |
| `post_op_context_short` | text (nullable) |
| `ftr_goal_short` | text (nullable) |
| `diagnosis_summary` | text |
| `treatment_plan_summary` | text |
| `updated_at` | timestamptz |

### 6.3 Yasak response key’leri (herhangi biri = **FAIL**)

| Kategori | Yasak key örnekleri |
|----------|---------------------|
| İç hekim notu | `internal_doctor_note`, `internalDoctorNote` |
| Ham klinik JSON | `clinical_data`, `clinicalData`, `rawClinicalData` |
| Geniş klinik alanlar | `anamnesis`, `physical_exam`, `physicalExam`, `chiefComplaint`, `clinicalImpression`, `preliminaryDiagnosis`, `finalDiagnosis` |
| Özel notlar | `doctor_private_note`, `privateNote`, `doctorPrivateAssessment` |
| Diğer modüller | `timeline`, `audit`, `pdf`, `payment` |
| Debug / auth | `service_role`, `jwt`, `auth_uid`, debug tenant override alanları |

**Not:** View katmanında `clinical_data` içinden **scalar extract** yapılır; RPC çıktısında yalnız `exercise_recommendation_short` gibi allowlist kolonlar görünür — **parent `clinical_data` objesi dönmez**.

---

## 7. Pass / fail kriteri (standart kayıt şablonu)

Her test için QA kaydı:

```text
Test ID:
Tarih:
Tester:
Ortam: staging
Kullanıcı / rol:
Tenant context (current_tenant_id):
İşlem (SQL/RPC/UI):
Beklenen:
Gerçekleşen:
Sonuç: PASS | FAIL
Kanıt: (ekran görüntüsü / response snippet / request-id)
Notlar:
```

**PASS:** Beklenen güvenli sonuçlardan biri (Bölüm 8).  
**FAIL:** Yasak veri, başka tenant satırı, yasak kolon, veya full CE sızıntısı.

---

## 8. Güvenli failure yorumları (standardize)

### Kabul edilebilir (güvenli) failure

| Sonuç | Yorum |
|-------|-------|
| **0 satır** | Fail-closed; yetkisiz erişim yok sayılır |
| **null** / boş array | `get_*` eşleşmedi |
| **permission denied** (42501) | Direct view / CE SELECT revoke |
| **forbidden** / **not authorized** | API/auth katmanı |
| JWT invalid / oturum yok | N13 |

### Kabul edilemez (güvenlik ihlali)

| Sonuç | Yorum |
|-------|-------|
| Başka tenant `encounter_id` / hasta verisi | Cross-tenant sızıntı |
| `internal_doctor_note` değeri | Kritik ihlal |
| `clinical_data` (ham JSON veya geniş nested) | Kritik ihlal |
| Full `clinical_encounters` satırı assistant/physio/nurse’e | Policy ihlali |
| `service_role` ile “test geçti” saymak | Yanıltıcı kanıt |
| UI’da SQL/PostgREST/stack trace | Kullanıcıya teknik sızıntı |

---

## 9. Çalıştırma sırası (önerilen)

1. Migration `20260524100000_*` staging’de uygulandığını doğrula  
2. Seed / test kayıtları (Bölüm 2.3)  
3. Positive controls P1–P7  
4. Negative N1–N20  
5. Response schema audit (N17–N19, Bölüm 6)  
6. Flutter staging: Assistant diagnosis-summary + Physio clinical-summaries UI smoke (read-only, hata mesajları teknik değil)  
7. Sonuçları Pass/Fail tablosuna işle  

---

## 10. Sonraki aksiyonlar (bu checklist sonrası)

| Paket / karar | Açıklama |
|---------------|----------|
| **Audit/KVKK Access Event Extension v1** | Summary RPC erişimlerinin audit log’a yazılması |
| **Staging Role Summary RPC Smoke v1** | Bu checklist’in staging’de resmi koşumu + kanıt arşivi (ayrı paket) |
| **Dedicated summary table v1.1** | Performans / index ihtiyacı doğarsa |
| **Nurse clinical summary** | Ürün kararı sonrası; şu an **bilinçli kapalı** |
| **Otomasyon** | JWT fixture + CI RPC testleri (bu pakette yok) |

---

## 11. Hızlı referans — migration içi smoke notları

Migration dosyası sonundaki manuel checklist ile bu doküman uyumludur:

- `doctor_admin` → her iki `list_*` RPC Tenant A satır  
- `assistant_secretary` → assistant RPC ✓, physio RPC 0, CE SELECT ✗  
- `physiotherapist` → physio RPC ✓, assistant RPC 0, CE SELECT ✗  
- `nurse` → dört RPC 0 satır  
- inactive membership / inactive tenant → 0 satır  
- cross-tenant `get_*` → 0 satır  
- response’ta `internal_doctor_note` / `clinical_data` key yok  
- authenticated direct view SELECT → denied  

---

*Belge sürümü: v1 — Negative RLS Test Checklist (dokümantasyon only)*
