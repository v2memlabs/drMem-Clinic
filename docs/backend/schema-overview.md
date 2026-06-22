# drMem Clinic — Backend Şema Özeti (Draft v1)

> **Aktif migration taslağı:** `supabase/migrations/20260521100000_draft_saas_schema_rls_v1.sql`  
> **Eski taslak:** `20260521000000_draft_saas_schema.sql` (superseded — referans)  
> Durum: **Review before applying** — uygulanmadı.

## Tablolar (v1 omurga)

| Grup | Tablolar |
|------|----------|
| Tenant / auth | `tenants`, `profiles`, `memberships` |
| RBAC | `permissions`, `role_permissions` |
| Klinik | `patients`, `appointments`, `clinical_encounters` |
| Dosya / PDF | `patient_files`, `pdf_outputs` |
| Audit | `audit_logs` |
| Freemium | `subscriptions`, `usage_limits`, `usage_events` |

## tenant_id

Tüm iş verisinde `tenant_id UUID NOT NULL` → `tenants(id)`.

## Roller (CHECK constraint)

`doctor_admin`, `assistant_secretary`, `physiotherapist`, `nurse`  
→ Flutter: `doctor`, `assistant`, `physiotherapist`, `nurse`

## RLS

- Tüm iş tablolarında RLS **enable** (draft migration).
- Policy’ler yorumlu / draft — bkz. `permission-rls-matrix.md`, `rls-helper-functions.md`.

## View

- `clinical_encounter_operational_summary` — `internal_doctor_note` hariç.

## İlgili dokümanlar

- [permission-rls-matrix.md](permission-rls-matrix.md)
- [migration-review-checklist.md](migration-review-checklist.md)
- [storage-and-pdf-paths.md](storage-and-pdf-paths.md)
- [demo-freemium-schema.md](demo-freemium-schema.md)
- [migration-roadmap.md](migration-roadmap.md)

## Flutter

`AppBackendConfig.activeBackend = mock` — değişmedi.
