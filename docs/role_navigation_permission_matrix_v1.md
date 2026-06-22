# Role Navigation Permission Matrix v1

Kaynak: `AuthSession` + `AuthRoutePermissions` + `AppRouter` guard'ları.

## Roller

| Rol | Kod |
|-----|-----|
| Doctor/Admin | `doctor` |
| Assistant/Secretary | `assistant` |
| Physiotherapist | `physiotherapist` |
| Nurse | `nurse` |

## Ekran grupları

| Grup | Doctor | Assistant | Physio | Nurse |
|------|--------|-----------|--------|-------|
| Dashboard | `/doctor` | `/assistant` | `/physio` | `/nurse` |
| Patients list/detail | ✓ | ✓ | ✗ | ✓ |
| Patient form | ✓ | ✓ | ✗ | ✗ |
| Appointments | ✓ | ✓ | ✗ | ✗ |
| Clinical full (`/clinical-records`) | ✓ | ✗ | ✗ | ✗ |
| Assistant diagnosis summary | ✓ | ✓ | ✗ | ✗ |
| Physio clinical summaries | ✓ | ✗ | ✓ | ✗ |
| Timeline | ✓ | ✗ | ✗ | ✗ |
| Patient files metadata | ✓ | ✓ | ✗ | ✗ |
| PDF outputs | ✓ | ✗ | ✗ | ✗ |
| Audit/KVKK log | ✓ | ✗ | ✗ | ✗ |
| Payments | ✓ | ✓ | ✗ | ✗ |
| Inventory | ✓ | ✗ | ✗ | ✓ |
| FTR referrals/sessions | ✓ | ✗ | ✓ | ✗ |
| internalDoctorNote UI | ✓ (full clinical only) | ✗ | ✗ | ✗ |

## Semantic helpers (`AuthSession`)

| Helper | Anlam |
|--------|--------|
| `canViewClinicalEncounters` | Full muayene list/detail/form |
| `canViewClinicalDiagnosisSummary` | `/clinical-records/diagnosis-summary` |
| `canViewClinicalSummary` | `/physiotherapy/clinical-summaries` |
| `canViewPatientTimeline` | `/patient-timeline` (doctor only) |
| `canViewAuditLogs` | `/audit-logs` (doctor only) |
| `canViewPdfOutputs` | `/pdf-outputs` (doctor only) |
| `canViewPayments` | doctor + assistant |
| `canViewInventory` | doctor + nurse |

Route doğrulama: `AuthRoutePermissions.canAccessPath(path)`.
