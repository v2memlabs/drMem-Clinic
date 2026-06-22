# Storage ve PDF Path Standardı (Draft)

> Bu pakette bucket oluşturulmaz; download/share yapılmaz.  
> **Güncel metadata v1:** [patient_file_pdf_storage_metadata_v1.md](../patient_file_pdf_storage_metadata_v1.md)

## Path şablonları

| Tür | `storage_path` örneği |
|-----|------------------------|
| Hasta dosyası | `tenants/{tenant_id}/patients/{patient_id}/files/{file_id}/{safe_segment}` |
| PDF çıktı | `tenants/{tenant_id}/patients/{patient_id}/pdf/{file_id}/document.pdf` |
| Bucket | `patient-files-private` (private) |

## Güvenlik

- **Private bucket** — public read yok.
- Erişim: kısa ömürlü **signed URL** + DB kaydı + rol kontrolü.
- İndirme / paylaşım: `usage_events` + entegrasyon sonraki faz.
- Dosya erişiminde **audit_logs** kaydı önerilir.

## Flutter (mevcut)

- PDF üretimi client-side (`PdfGeneratorService`) — metadata `pdf_outputs` tablosunda.
- Binary upload Faz 4.
