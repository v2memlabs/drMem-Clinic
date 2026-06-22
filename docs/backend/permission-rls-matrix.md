# Permission / RLS Matrix (Draft v1)

> UI (`AuthSession`) + hedef backend RLS uyumu. **Draft** — uygulama öncesi gözden geçirilmeli.

## Rol eşlemesi

| DB `memberships.role` | Flutter `AppRoles` |
|----------------------|-------------------|
| `doctor_admin` | `doctor` |
| `assistant_secretary` | `assistant` |
| `physiotherapist` | `physiotherapist` |
| `nurse` | `nurse` |

## Matris

| Modül | doctor_admin | assistant_secretary | physiotherapist | nurse |
|-------|:------------:|:-------------------:|:---------------:|:-----:|
| patients | select, insert, update | select, insert, update | — | select (temel) |
| appointments | select, insert, update | select, insert, update | — | — |
| clinical_encounters (full) | select, insert, update | — | — | — |
| clinical_encounter_operational_summary | select | select (özet) | select (özet) | — |
| internal_doctor_note | select | **no** | **no** | **no** |
| physiotherapy | select, write | — | select, write | — |
| inventory | select, write | — | — | select, write |
| pdf_outputs | select, write | — | — | — |
| patient_files | select, write | select, write | — | — |
| payments | select, write | select, write | — | — |
| consents | select, write | select, write | — | — |
| audit_logs | select | — | — | — |
| settings (clinic) | write | read (kısıtlı) | read | read |
| timeline | select | — | — | — |

**Kısaltma:** select = okuma, write = oluşturma/güncelleme, — = erişim yok.

## Korunan sınırlar (ürün kararı)

- **Timeline:** yalnızca doctor_admin (Flutter: `canViewPatientTimeline`).
- **Audit:** yalnızca doctor_admin.
- **PDF:** yalnızca doctor_admin.
- **Tam muayene:** yalnızca doctor_admin; diğer roller özet view.

## Backend notu

RLS policy’ler `has_tenant_role` / `has_permission` ile bu matrise map edilecek. UI tek başına yeterli değildir.
