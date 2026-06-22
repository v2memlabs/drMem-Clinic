# RLS Policies Draft v1

**Dosya:** `supabase/migrations/20260522100000_draft_rls_policies_v1.sql`  
**Durum:** Draft — **uygulanmadı**; staging review zorunlu.

## Önkoşul

`20260521100000_draft_saas_schema_rls_v1.sql` (tablolar + RLS enable, policy yok).

## View güvenliği (düzeltme v1 + recreate v1)

PostgreSQL **view** üzerinde doğrudan şunlar **uygulanamaz**:

- `ALTER … ENABLE ROW LEVEL SECURITY`
- `CREATE POLICY … ON view_name`

**Kolon azaltımı:** `CREATE OR REPLACE VIEW` yeterli değildir (`42P16: cannot drop columns from view`). Dev/staging’de:

```sql
DROP VIEW IF EXISTS clinical_encounter_operational_summary;  -- CASCADE kullanılmaz
CREATE VIEW clinical_encounter_operational_summary WITH (security_invoker = true) AS ...
```

Dependent object varsa `DROP VIEW` hata verir → manuel review (CASCADE bu pakette yok).

`clinical_encounter_operational_summary` için yaklaşım:

| Mekanizma | Açıklama |
|-----------|----------|
| `security_invoker = true` | View, çağıran kullanıcının RLS bağlamında alt tabloyu okur |
| Alt tablo RLS | `clinical_encounters` SELECT yalnız `doctor_admin` (fail-closed v1) |
| Kolon projeksiyonu | `internal_doctor_note`, `clinical_data`, `appointment_id` **yok** |

### Assistant / FTR özet erişimi (v1)

**Seçenek A (bu paket):** View tanımlı; asistan/FTR için satır dönmez (alt tablo policy doctor only). Ürün özet ekranları mock/sonraki faz.

**Seçenek B (sonraki faz):** `SECURITY DEFINER` RPC veya ayrı özet tablo/view stratejisi — hassas alan sızıntısı olmadan tasarlanacak.

Geniş `clinical_encounters` SELECT policy’si **yazılmadı** (`internal_doctor_note` öncelikli).

## Helper functions

| Fonksiyon | Kaynak |
|-----------|--------|
| `current_auth_user_id()` | `auth.uid()` |
| `current_profile_id()` | JWT `profile_id` veya `profiles.auth_user_id` |
| `current_tenant_id()` | JWT `tenant_id` veya tek active membership |
| `is_tenant_member(tenant_id)` | `memberships` |
| `has_tenant_role(tenant_id, roles[])` | `memberships.role` |
| `has_permission(tenant_id, key)` | `role_permissions` |

## Policy özeti (tablo × rol)

| Tablo | doctor_admin | assistant_secretary | physiotherapist | nurse |
|-------|:------------:|:-------------------:|:---------------:|:-----:|
| tenants | SELECT | SELECT | SELECT | SELECT |
| profiles | own | own | own | own |
| memberships | own + peer | own + peer | own + peer | own + peer |
| patients | R/W | R/W | — | SELECT |
| appointments | R/W | R/W | — | — |
| clinical_encounters | R/W | — | — | — |
| ce_operational_summary (view) | SELECT* | —* | —* | — |
| patient_files | R/W | R/W | — | — |
| pdf_outputs | R/W | — | — | — |
| audit_logs | SELECT | — | — | — |
| subscriptions / usage_limits | SELECT | SELECT | SELECT | SELECT |
| usage_events | SELECT | — | — | — |

\* View: `security_invoker` + doctor-only table RLS → v1’de pratikte doctor görür; asistan/FTR testi sonraki faz.

## internal_doctor_note

- Tam tablo `clinical_encounters`: yalnızca **doctor_admin**.
- View’da kolon **yok** (`clinical_data` da yok).

## Eksik tablolar

Inventory, FTR, consents, payments — şemada yok; policy sonraki migration.

## Idempotent apply

SQL Editor’da tekrar çalıştırma: her policy öncesi `DROP POLICY IF EXISTS`; helper’lar `CREATE OR REPLACE FUNCTION`.

## Test

[rls-test-plan.md](rls-test-plan.md) — policy apply sonrası; view testleri recreate sonrası doğrulanacak.
