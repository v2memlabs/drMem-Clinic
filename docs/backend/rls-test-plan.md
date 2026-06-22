# RLS Test Planı (Draft v1)

> Policy’ler staging’de uygulandıktan sonra çalıştırılır. Bu pakette **deploy veya otomatik test yok**.

**Policy SQL:** [20260522100000_draft_rls_policies_v1.sql](../../supabase/migrations/20260522100000_draft_rls_policies_v1.sql) (draft, uygulanmadı)

## Önemli: RLS açık, policy yok

Tablolarda yalnızca `ENABLE ROW LEVEL SECURITY` varken **hiç policy yoksa** PostgREST/Supabase Data API **boş sonuç** döner (403/empty). Bu bir Flutter bug’ı değildir.

- Policy taslağı review + staging apply edilmeden **Flutter Supabase bağlantısına geçmeyin**.
- Testler **rol başına ayrı JWT** ile yapılmalı (doctor, assistant, physio, nurse).
- `internal_doctor_note`: assistant’ın `clinical_encounters` SELECT’i **başarısız** olmalı; `clinical_encounter_operational_summary` **başarılı** olmalı.

Matris: [permission-rls-matrix.md](permission-rls-matrix.md)  
Seed: [seed-plan.md](seed-plan.md)  
Policy özeti: [rls-policies-v1.md](rls-policies-v1.md)

## Test ortamı

- JWT: gerçek kullanıcı oturumu (`anon` key + RLS)
- İkinci tenant (`tenant-b`) + hasta: **cross-tenant** testleri için önerilir
- `service_role` yalnızca setup; RLS testlerinde **kullanılmaz**

## Genel kontroller (tüm roller)

| # | Senaryo | Beklenen |
|---|---------|----------|
| G1 | Tenant A kullanıcısı Tenant B `patients` SELECT | **0 satır** veya hata |
| G2 | INSERT `patients` with wrong `tenant_id` | **Red** |
| G3 | UPDATE başka tenant kaydı | **Red** |
| G4 | `patients` WHERE `deleted_at` NOT NULL (normal SELECT) | **Gizli** |
| G5 | `audit_logs` UPDATE/DELETE | **Red** |
| G6 | `tenant_id` manipülasyonu (client payload) | **Red** |

---

## doctor_admin

| Tablo | SELECT | INSERT | UPDATE | DELETE |
|-------|:------:|:------:|:------:|:------:|
| patients | ✓ | ✓ | ✓ | soft delete policy’ye göre |
| appointments | ✓ | ✓ | ✓ | — |
| clinical_encounters (full) | ✓ | ✓ | ✓ | — |
| internal_doctor_note (kolon) | ✓ | ✓ | ✓ | — |
| clinical_encounter_operational_summary | ✓ | — | — | — |
| patient_files | ✓ | ✓ | ✓ | — |
| pdf_outputs | ✓ | ✓ | ✓ | — |
| payments | ✓ | ✓ | ✓ | — |
| consents | ✓ | ✓ | ✓ | — |
| audit_logs | ✓ | ✓ (append) | ✗ | ✗ |
| inventory | ✓ | ✓ | ✓ | — |
| physiotherapy* | ✓ | ✓ | ✓ | — |

\* Tablo adı migration’a göre (FTR modülü).

**Kritik:** Timeline UI = doctor only → ilgili view/tablo SELECT ✓.

---

## assistant_secretary

| Tablo | SELECT | INSERT | UPDATE |
|-------|:------:|:------:|:------:|
| patients | ✓ | ✓ | ✓ |
| appointments | ✓ | ✓ | ✓ |
| clinical_encounters (full table) | ✗ | ✗ | ✗ |
| operational_summary view | ✓ | — | — |
| **internal_doctor_note** | **✗** | **✗** | **✗** |
| patient_files | ✓ | ✓ | ✓ |
| payments | ✓ | ✓ | ✓ |
| consents | ✓ | ✓ | ✓ |
| pdf_outputs | ✗ | ✗ | ✗ |
| audit_logs | ✗ | ✗ | ✗ |
| inventory | ✗ | ✗ | ✗ |
| physiotherapy | ✗ | ✗ | ✗ |

**Kritik test A1:** `SELECT internal_doctor_note FROM clinical_encounters` → erişim yok.  
**Kritik test A2 (view):** View üzerinde RLS policy **yok** (PG kısıtı). `security_invoker` + alt tablo RLS ile doğrulanacak — [rls-policies-v1.md](rls-policies-v1.md).  
**v1 beklenen:** Asistan/FTR `clinical_encounter_operational_summary` SELECT → **0 satır** (fail-closed); özet erişimi sonraki RPC/faz.

**View recreate:** Policy SQL `DROP VIEW IF EXISTS` + `CREATE VIEW` kullanır (`42P16` önlenir). View testleri bu düzeltme sonrası staging’de yapılır.

---

## physiotherapist

| Tablo | SELECT | INSERT | UPDATE |
|-------|:------:|:------:|:------:|
| patients | ✗ veya kısıtlı read* | ✗ | ✗ |
| appointments | ✗ | ✗ | ✗ |
| operational_summary | ✓ | — | — |
| internal_doctor_note | ✗ | ✗ | ✗ |
| physiotherapy / exercise / post_op | ✓ | ✓ | ✓ |
| payments | ✗ | ✗ | ✗ |
| audit_logs | ✗ | ✗ | ✗ |
| pdf_outputs | ✗ | ✗ | ✗ |
| patient_files | ✗ | ✗ | ✗ |
| inventory | ✗ | ✗ | ✗ |

\* Matris: hasta temel SELECT yok; ürün kararı staging’de netleştirilmeli.

**Kritik test P1:** payments SELECT → 0 satır.  
**Kritik test P2:** audit_logs SELECT → 0 satır.

---

## nurse

| Tablo | SELECT | INSERT | UPDATE |
|-------|:------:|:------:|:------:|
| patients | ✓ (temel) | ✗ | ✗ |
| appointments | ✗ | ✗ | ✗ |
| clinical_encounters | ✗ | ✗ | ✗ |
| inventory | ✓ | ✓ | ✓ |
| pdf_outputs | ✗ | ✗ | ✗ |
| audit_logs | ✗ | ✗ | ✗ |
| payments | ✗ | ✗ | ✗ |
| physiotherapy | ✗ | ✗ | ✗ |

**Kritik test N1:** pdf_outputs SELECT → 0.  
**Kritik test N2:** timeline kaynağı SELECT → 0.

---

## Auth / membership (uygulama — Paket 6 sonrası)

Supabase modda **rol dropdown yok**; rol `memberships.role` → `TenantRoleMapper`.

| # | Durum | Beklenen uygulama |
|---|--------|-------------------|
| L1 | doctor, tek active membership | Login → doctor dashboard |
| L2 | assistant, tek active membership | Login → assistant dashboard |
| L3 | physiotherapist, tek active membership | Login → physio dashboard |
| L4 | nurse, tek active membership | Login → nurse dashboard |
| L5 | profile var, membership yok | `/account/no-access?reason=noMembership` |
| L6 | membership `disabled` | `inactiveMembership` |
| L7 | tenant `suspended` | `inactiveTenant` |
| L8 | bilinmeyen DB role | `unknownRole`, oturum açılmaz |
| L9 | 2+ active membership | `needsTenantSelection` (picker sonraki faz) |
| L10 | refresh token expired | `signOut` → `/login` |

Mock mod (`DATA_BACKEND=mock`): yukarıdaki L5–L9 **normal kullanıcıya görünmez** (demo login).

---

## Storage / PDF (plan — entegrasyon yok)

| # | Kontrol | Beklenen |
|---|---------|----------|
| S1 | `storage_path` tenant prefix | `{tenant_id}/...` |
| S2 | Public bucket read | **Yok** |
| S3 | Signed URL olmadan private object | **Erişim yok** |
| S4 | Başka tenant path ile istek | **Red** |
| S5 | pdf_outputs.tenant_id = patient.tenant_id | Tutarlı |
| S6 | Download/share | Sonraki faz |

---

## Demo / freemium test

| # | Senaryo | Beklenen (şimdilik) |
|---|---------|---------------------|
| F1 | 0/3 hasta | UI bilgi metni |
| F2 | 3/3 hasta | Limit mesajı |
| F3 | 4. hasta INSERT (DB) | RLS/enforcement **sonraki faz**; şimdilik bilgilendirme only |
| F4 | `usage_events` kaydı | Metadata; faturalama yok |

---

## Test yürütme notu

1. Staging migration apply + seed ([seed-plan.md](seed-plan.md))
2. Her rol için ayrı JWT ile SQL veya PostgREST test
3. Sonuçları checklist’e işaretle
4. Go/No-Go: [supabase-connection-prerequisites.md](supabase-connection-prerequisites.md)
