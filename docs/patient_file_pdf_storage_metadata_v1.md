# Patient File / PDF Storage Metadata v1

> **Paket türü:** Metadata model + DB extension + Dart contract (upload/signed URL yok)  
> **Migration:** `supabase/migrations/20260525200000_patient_file_pdf_storage_metadata_v1.sql`  
> **Audit taxonomy:** [audit_kvkk_access_event_extension_v1.md](audit_kvkk_access_event_extension_v1.md)  
> **Path draft:** [backend/storage-and-pdf-paths.md](backend/storage-and-pdf-paths.md)

---

## 1. Mevcut mimari özeti (paket öncesi)

| Bileşen | Durum |
|---------|--------|
| **Flutter hasta dosyası** | `lib/features/files/` — mock `PatientFile`, `FileRepository`, upload/detail UI |
| **Flutter PDF** | `lib/features/pdf_outputs/` — mock `PdfOutput`, client-side `PdfGeneratorService` |
| **Supabase tablolar** | `patient_files`, `pdf_outputs` (temel kolonlar vardı) |
| **Storage** | Dokümante private path; bucket/sign **yok** |
| **Timeline** | Mock audit/PDF/dosya olayları |
| **Remote metadata repo** | **Yok** → v1 contract + stub |

**Karar:** Yeni `patient_file_metadata` tablosu açılmadı; mevcut iki tablo **genişletildi** (aynı sorumluluk alanı).

---

## 2. Metadata alanları (birleşik görünüm)

| Alan | patient_files | pdf_outputs | Not |
|------|:-------------:|:-------------:|-----|
| id | ✓ | ✓ | uuid |
| tenant_id | ✓ | ✓ | UI'dan verilmez |
| patient_id | ✓ | ✓ | FK |
| created_by | ✓ | ✓ | → profiles |
| file_kind | ✓ | ✓ | check constraint |
| clinical_context | ✓ | ✓ | encounter/consent/… |
| encounter_id | ✓ | ✓ | nullable FK |
| appointment_id | ✓ | ✓ | nullable FK |
| display_name | ✓ | ✓ | |
| original_file_name | ✓ | ✓ | path'te kullanılmaz |
| mime_type | ✓ | ✓ | |
| file_size_bytes / size_bytes | size_bytes | file_size_bytes | |
| storage_bucket | ✓ | ✓ | default `patient-files-private` |
| storage_path | ✓ | ✓ | unique (tenant, path) active |
| checksum | ✓ | ✓ | ileride |
| status | active/archived/deleted | workflow + deleted_at | PDF: taslak/hazır… metadata'da |
| visibility_scope | ✓ | ✓ | role gate |
| metadata | jsonb | jsonb | template_key only |
| created_at / updated_at | ✓ | ✓ | |
| deleted_at | ✓ | ✓ | soft delete |

### Yasak (DB/code review)

- Dosya/PDF binary içeriği
- `internal_doctor_note`, `clinical_data`, anamnez/muayene tam metin
- `signed_url`, `public_url`, JWT, service_role
- Ham exception/SQL

---

## 3. Storage bucket / path

| Kural | Değer |
|-------|--------|
| Bucket | `patient-files-private` (private, ileride oluşturulacak) |
| Upload path | `tenants/{tenant_id}/patients/{patient_id}/files/{file_id}/{safe_segment}` |
| PDF path | `tenants/{tenant_id}/patients/{patient_id}/pdf/{file_id}/document.pdf` |
| Path PII | Hasta adı, TC, orijinal dosya adı **path'te yok** |
| Erişim | İleride kısa ömürlü **signed URL** (bu pakette yok) |
| Public URL | **Yasak** |

**Kod:** `PatientFileStoragePathBuilder`

---

## 4. file_kind / visibility_scope

### file_kind
`patient_upload`, `generated_pdf`, `consent_document`, `imaging_report`, `lab_report`, `physiotherapy_document`, `other`

### visibility_scope
| Scope | SELECT (v1 RLS) |
|-------|-------------------|
| `doctor_admin` | doctor_admin (tüm scope'lar tenant içinde) |
| `clinic_operations` | doctor_admin + assistant_secretary |
| `physiotherapy` | doctor_admin + physiotherapist |
| `patient_share_later` | doctor_admin only (ileride paylaşım) |

**Nurse:** patient_files SELECT **yok** (policy yok = deny)

### pdf_outputs
- Varsayılan `visibility_scope = doctor_admin`
- SELECT: doctor_admin only (mevcut ürün kararı)

---

## 5. PDF output metadata

| Alan | Kaynak |
|------|--------|
| file_kind | `generated_pdf` |
| clinical_context | `encounter` / `consent` / `physiotherapy` (source_module'dan backfill) |
| encounter_id | clinical_encounter → source_record_id |
| metadata.template_key | İleride PDF şablonu |
| metadata.template_version | İleride |
| metadata.document_type | document_type kolonu (referans) |

**Yasak:** `contentSummary`, `warningNote`, PDF bytes, internalDoctorNote

**Flutter:** Mevcut `PdfOutput` UI modeli **değiştirilmedi**; remote metadata `PatientFileMetadata` ile hizalanacak (sonraki paket).

---

## 6. Audit / KVKK bağlantısı

İleride (içerik/log yok):

| Event | Metadata örneği |
|-------|-----------------|
| `patient_file.view` | file_id, patient_id, file_kind |
| `patient_file.upload` | file_id, success |
| `patient_file.download` | file_id |
| `patient_file.archive` | file_id |
| `pdf.generate` | file_id, template_key |
| `pdf.view` / `pdf.download` | file_id, encounter_id? |

**Yasak audit metadata:** file content, signed_url, PDF body, clinical_data, internal_doctor_note

---

## 7. Dart contract (v1)

```
lib/features/patient_files/
  models/patient_file_metadata.dart
  data/patient_file_metadata_dto.dart
  data/patient_file_metadata_mapper.dart
  data/patient_file_metadata_create_input.dart
  data/patient_file_metadata_sanitizer.dart
  data/patient_file_storage_path_builder.dart
  data/patient_file_metadata_repository.dart
  data/supabase_patient_file_metadata_repository_stub.dart
```

- **Supabase implementasyon:** Sonraki paket (`Supabase PatientFile Metadata Repository Smoke v1`)
- **UI bağlantısı:** Sonraki paket
- **Upload / signed URL:** Sonraki paket

Legacy `lib/features/files/models/patient_file.dart` mock UI için kalır.

---

## 8. Manuel test checklist (staging JWT)

| # | Senaryo | Beklenen |
|---|---------|----------|
| F1 | doctor_admin patient_files | Tüm visibility_scope tenant içinde |
| F2 | assistant | Yalnız `clinic_operations` |
| F3 | physiotherapist | Yalnız `physiotherapy` |
| F4 | nurse patient_files | 0 satır |
| F5 | cross-tenant | 0 satır |
| F6 | deleted_at / status=deleted | Listede yok |
| F7 | storage_path | Public URL değil; signed_url kolonu yok |
| F8 | metadata JSONB | İçerik / internal_doctor_note / clinical_data yok |
| F9 | pdf_outputs assistant | 0 satır (doctor only) |
| F10 | DB binary column | Yok |

---

## 9. Sonraki paketler

1. **PatientFile Metadata DTO/Mapper/Contract v1** — tamamlandı (bu paket ile birlikte)
2. **Supabase PatientFile Metadata Repository Smoke v1**
3. Storage bucket + signed URL service
4. UI / upload entegrasyonu
5. Audit event wiring (`patient_file.*`, `pdf.*`)

---

*Belge sürümü: v1 — Patient File / PDF Storage Metadata*
