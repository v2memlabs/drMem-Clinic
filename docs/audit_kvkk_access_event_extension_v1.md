# Audit / KVKK Access Event Extension v1

> **Paket:** Erişim audit taxonomy + minimal kayıt altyapısı  
> **İlgili migration:** `supabase/migrations/20260525100000_audit_access_event_extension_v1.sql`  
> **Negatif RLS checklist:** [negative_rls_test_checklist_v1.md](negative_rls_test_checklist_v1.md)  
> **Safe summary projection:** `supabase/migrations/20260524100000_safe_clinical_role_summary_projection_v1.sql`

---

## 1. Mevcut mimari özeti (paket öncesi / sonrası)

| Bileşen | Durum |
|---------|--------|
| **DB `audit_logs`** | `tenant_id`, `actor_profile_id`, `action`, `module`, `record_id`, `patient_id`, `metadata` jsonb |
| **RLS SELECT** | Yalnız `doctor_admin` (draft policy) |
| **RLS INSERT (client)** | v1 öncesi yok / belirsiz → **v1: REVOKE INSERT authenticated** |
| **Flutter UI** | `AuditLogListScreen` — doctor only (`AuthSession.canViewAuditLogs`) |
| **Flutter veri** | Mock `AuditLogRepository` + legacy `ActionType` / `ModuleType` |
| **Remote audit read** | Henüz yok (sonraki paket) |
| **Erişim kaydı (bu paket)** | `ClinicalAccessAuditLogger` + `record_audit_access_event` RPC |

**Karar:** Yeni paralel tablo açılmadı; mevcut `audit_logs` + dot-notation `action` genişletildi.

---

## 2. Audit event taxonomy (tam sınıflandırma)

### Patient access
| Event | Açıklama | Implementasyon |
|-------|----------|----------------|
| `patient.view` | Hasta detay | Sonraki paket |
| `patient.list` | Hasta listesi | Sonraki paket |
| `patient.create` / `update` / `delete_or_archive` | CRUD | Sonraki paket |

### Appointment
| Event | Implementasyon |
|-------|----------------|
| `appointment.view` / `list` / `create` / `update` / `cancel` | Sonraki paket |

### Clinical full (doctor/admin)
| Event | Implementasyon |
|-------|----------------|
| `clinical.full.list` | **v1** — `ClinicalEncounterListDataSource` |
| `clinical.full.view` | **v1** — `ClinicalEncounterDetailDataSource` |
| `clinical.full.create` / `update` | Sonraki paket (form save) |
| `clinical.internal_note.view` | **v1** — detayda not alanı dolu + doctor |
| `clinical.internal_note.update` | Sonraki paket |

### Safe summary (assistant / physio — full clinical **değil**)
| Event | Implementasyon |
|-------|----------------|
| `clinical.summary.assistant.list` | **v1** |
| `clinical.summary.assistant.view` | **v1** |
| `clinical.summary.physiotherapist.list` | **v1** |
| `clinical.summary.physiotherapist.view` | **v1** |

### Files / PDF / Consent / Auth
Taxonomy dokümante; implementasyon **sonraki paketler**.

### Security
| Event | Implementasyon |
|-------|----------------|
| `permission.denied` | **v1** — forbidden repository failure |

**Kod:** `lib/features/audit/access/audit_access_event_type.dart`

---

## 3. Güvenli metadata standardı

### İzinli (örnek)
- `tenant_id`, `actor_user_id`, `actor_role` (metadata içinde referans)
- `patient_id`, `encounter_id` → DB kolonları `patient_id`, `record_id`
- `event_type` → `audit_logs.action`
- `event_scope` → `audit_logs.module`
- `success`, `failure_category`, `source` (`ui` / `data_source` / `repository` / `rpc`)
- `result_count`, `filtered_by_patient`, `includes_internal_note_access`
- `correlation_id`, `platform` (minimal)
- `created_at` (DB default)

### Yasak metadata
- `internal_doctor_note` / içerik
- `clinical_data` / ham JSON
- Anamnez, muayene, tanı serbest metinleri
- PDF/dosya içeriği, ödeme kart verisi
- JWT, service_role, stack trace, SQL, PostgREST body

**Sanitizer:** `AuditAccessMetadataSanitizer` (Dart) + `_sanitize_audit_metadata` (SQL RPC)

---

## 4. internalDoctorNote audit yaklaşımı

1. **Ayrı event:** `clinical.internal_note.view` — `clinical.full.view` ile **birleştirilmez**.
2. **Tetikleyici:** Doctor detay yüklendiğinde `internalDoctorNote.trim().isNotEmpty` ve `AuthSession.canViewFullClinicalEncounter`.
3. **Metadata:** Yalnız `includes_internal_note_access: true` + id referansları; **not metni yazılmaz**.
4. **Assistant/Physio:** Bu event oluşmamalı (erişim yok).

---

## 5. Safe summary audit yaklaşımı

| Çağrı | Event |
|--------|-------|
| `listAssistantClinicalSummaries` | `clinical.summary.assistant.list` |
| `getAssistantClinicalSummary` | `clinical.summary.assistant.view` |
| `listPhysiotherapistClinicalSummaries` | `clinical.summary.physiotherapist.list` |
| `getPhysiotherapistClinicalSummary` | `clinical.summary.physiotherapist.view` |

- **0 satır / notFound:** Audit yine yazılabilir (`success: true`, `result_count: 0`) — erişim denemesi değil, yetkili boş sonuç.
- **Forbidden:** `permission.denied` + ilgili list/view `success: false`.
- **Summary içeriği** (diagnosis text, FTR short fields) metadata’ya **yazılmaz**.

**Kayıt katmanı:** Data source (UI başına tek kayıt); repository her satır için tekrarlamaz.

---

## 6. DB / migration kararı

| Soru | Karar |
|------|--------|
| Yeni tablo gerekli mi? | **Hayır** — `audit_logs` yeterli |
| Client INSERT? | **Hayır** — `REVOKE INSERT` + `record_audit_access_event` RPC |
| Sahtecilik riski | Client RPC ile insert mümkün; olay actor = `auth.uid()`. İleride: yalnızca SECURITY DEFINER read-path RPC içinden audit veya Edge Function |
| Uzun vadeli | Summary RPC içi audit insert (server-side) — Staging Role Summary RPC Smoke paketi |

**Migration:** `20260525100000_audit_access_event_extension_v1.sql`

---

## 7. RLS / permission

| İşlem | Politika |
|-------|----------|
| `audit_logs` SELECT | `doctor_admin` + tenant member (mevcut draft) |
| `audit_logs` INSERT (direct) | **Revoke** authenticated |
| `record_audit_access_event` EXECUTE | `authenticated` (tenant member + active tenant gate) |
| Audit UI | `canViewAuditLogs` → doctor only (değişmedi) |
| Route/permission | **Genişletilmedi** |

---

## 8. Kayıt stratejisi

| Katman | v1 | Uzun vade |
|--------|-----|-----------|
| UI-only | ✗ | ✗ |
| Data source | ✓ (clinical + summary) | Genişletme |
| Repository | Opsiyonel | Full write path |
| Summary RPC içi | Dokümante | Önerilen |
| DB trigger | ✗ | Seçili write |
| service_role client | **Yasak** | — |

**Provider:** `AuditAccessEventProvider` — mock → `MockAuditAccessEventRecorder`; supabase → RPC recorder.

---

## 9. Manuel test checklist

| # | Senaryo | Beklenen |
|---|---------|----------|
| A1 | Doctor clinical detail view | `clinical.full.view` audit satırı |
| A2 | Doctor + dolu internal note | Ek `clinical.internal_note.view` (içerik yok) |
| A3 | Assistant summary list/view | `clinical.summary.assistant.*` |
| A4 | Physio summary list/view | `clinical.summary.physiotherapist.*` |
| A5 | Nurse summary (forbidden) | `permission.denied` veya başarısız list + UI 0 satır |
| A6 | Audit metadata JSON | `internal_doctor_note`, `clinical_data` key **yok** |
| A7 | Doctor audit UI | Mock’ta legacy satır görünür; teknik SQL yok |
| A8 | Assistant audit SELECT | **0 satır** (doctor-only) |
| A9 | `INSERT INTO audit_logs` authenticated | **Denied** |
| A10 | SQL Editor service_role insert | RLS test sayılmaz — JWT ile doğrula |

---

## 10. Sonraki paketler

1. **Staging Role Summary RPC Smoke v1** — RPC içi audit hook  
2. **Audit Event Repository Integration v1** — remote audit list/read UI  
3. **Patient / appointment / file / PDF access events**  
4. **PDF/Timeline/FTR remote transition** veya **PatientFile/PDF Storage Metadata v1**  
5. **Nurse clinical summary** — ürün kararı sonrası  

---

## 11. Kod haritası

```
lib/features/audit/access/
  audit_access_event_type.dart
  audit_access_event_scope.dart
  audit_access_failure_category.dart
  audit_access_event.dart
  audit_access_metadata_sanitizer.dart
  audit_access_event_recorder.dart
  mock_audit_access_event_recorder.dart
  supabase_audit_access_event_recorder.dart
  no_op_audit_access_event_recorder.dart
  audit_access_event_provider.dart
  clinical_access_audit_logger.dart
  audit_access_legacy_display_mapper.dart
```

---

*Belge sürümü: v1 — Audit/KVKK Access Event Extension*
