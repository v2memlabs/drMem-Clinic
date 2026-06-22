# Demo / Freemium — Backend Taslağı

> Bu pakette **limit enforcement yok**; yalnızca metadata şeması.

## Tablolar

| Tablo | Amaç |
|-------|------|
| `subscriptions` | Tenant planı (`plan_key`: demo, starter, pro) |
| `usage_limits` | Limit tanımı |
| `usage_events` | Kontörlü kullanım olayları (SMS, PDF paylaşım, …) |

## Demo hasta limiti (bilgilendirme)

| Alan | Değer |
|------|--------|
| `metric_key` | `patient_records` |
| `limit_value` | `3` |
| `period` | `lifetime` |

Flutter `DemoFreemiumConfig` ile uyumlu. Gerçek INSERT engeli **sonraki faz** kararı.

## Kontörlü servisler (metadata only)

- `sms_sent`, `whatsapp_sent`
- `pdf_shared`
- `ai_summary`
- `storage_mb`

`usage_events` append-only; faturalama entegrasyonu yok.
