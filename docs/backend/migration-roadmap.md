# Backend Migration Roadmap

Kısa geliştirici referansı — analiz raporu ile uyumlu.

| Faz | Amaç | Flutter paket örneği |
|-----|------|----------------------|
| **0** | Şema/RLS/auth taslağı, repository contract | SaaS Backend Hazırlık v1 ✓ |
| **0b** | Patient/Appointment contract derinleştirme | Patients/Appointments Contract v1 ✓ |
| **0c** | Supabase şema + RLS SQL/doküman taslağı | Supabase Şema + RLS Taslağı v1 ✓ |
| **1** | Supabase Auth + tenant + membership + policy apply | Auth/Tenant Entegrasyon v1 |
| **2** | Patients + appointments remote CRUD | Patients/Appointments Remote v1 |
| **3** | Clinical encounters + FTR + inventory | Clinical Remote v1 |
| **4** | Audit + storage + PDF metadata | Audit Storage PDF v1 |
| **5** | Subscription + usage metadata | Subscription Usage v1 |
| **6** | Realtime (filtreli) | Realtime Filtered v1 |
| **7** | KVKK / production hardening | Production Hardening v1 |

## Bağımlılıklar

- Faz 2 → Faz 1 (auth + tenant claim)
- Faz 3 → Faz 2 (patient FK)
- Faz 4 → Faz 3 (kaynak modül metadata)
- Faz 6 → Faz 1–3 (RLS oturmuş olmalı)

## Flutter geçiş kuralı

- Varsayılan `AppBackendConfig.activeBackend = DataBackend.mock`
- Yeni kod: `RepositoryRegistry.*` contract
- Eski kod: `XRepository.instance` — paket paket taşınır
