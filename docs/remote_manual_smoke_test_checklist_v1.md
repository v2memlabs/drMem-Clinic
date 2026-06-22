# Remote Manual Smoke Test Checklist v1

> **Paket türü:** Manuel QA / smoke test checklist (dokümantasyon only).  
> **Kod değişikliği yok.** Migration, RLS, repository, provider, UI, route değişikliği yok.

| Alan | Değer |
|------|--------|
| Versiyon | v1 |
| İlgili seed | [staging_seed_data_v1.md](staging_seed_data_v1.md) |
| Rol matrisi | [role_navigation_permission_matrix_v1.md](role_navigation_permission_matrix_v1.md) |
| Route guard | `lib/core/auth/auth_route_permissions.dart` |

---

## Uyarılar (zorunlu)

| # | Kural |
|---|--------|
| 1 | **Production’da test yapılmaz** — yalnız staging/dev + seed verisi. |
| 2 | **Gerçek hasta verisi kullanılmaz** — seed/demo kayıtlar (`SEED-A-*`, `Demo *`). |
| 3 | **SQL Editor / service_role ile UI testi yapılmaz** — RLS bypass eder, sonuç yanıltıcıdır. |
| 4 | Tüm Supabase smoke testleri **authenticated** oturum + JWT `tenant_id` / `profile_id` ile yapılır. |
| 5 | `internal_doctor_note` yalnız doctor/admin full clinical path’te görünür. |
| 6 | `raw clinical_data`, `signedUrl`, `publicUrl`, `fileContent`, `pdfContent` UI’da **hiçbir rolde** görünmez. |

---

## 1. Test kapsamı özeti

| Alan | Supabase remote | Mock |
|------|-----------------|------|
| Auth / login / logout | ✓ | ✓ (rol dropdown) |
| Active tenant / membership | ✓ | ✓ (simüle) |
| Dashboard (rol bazlı) | ✓ | ✓ |
| Patients (list/detail/form) | ✓ | ✓ |
| Appointments | ✓ | ✓ |
| Clinical encounters (full) | ✓ (doctor) | ✓ (doctor) |
| Assistant safe summary | ✓ | ✓ (mock mapper) |
| Physiotherapist safe summary | ✓ | ✓ |
| Patient file / PDF metadata | ✓ | ✓ |
| Timeline | ✓ (doctor) | ✓ |
| Role-based navigation / URL guard | ✓ | ✓ |
| Cache / session / tenant switch | ✓ | Kısıtlı |
| Cross-tenant / RLS negative | ✓ | N/A |
| internalDoctorNote güvenlik | ✓ | ✓ (mock davranış) |
| Loading / error / empty UX | ✓ | ✓ |

---

## 2. Ortam ve ön koşullar

### 2.1 Supabase remote mod

| Ön koşul | Doğrulama |
|----------|-----------|
| Build | `DATA_BACKEND=supabase` (`lib/core/data/backend_config.dart`) |
| Supabase URL + anon key | Staging/dev projesi; repoda secret yok |
| Migrations | Staging’de uygulanmış (timeline, safe summary, file metadata dahil) |
| Seed | `supabase db reset` veya `staging_seed_data_v1.sql` uygulanmış |
| Auth kullanıcıları | `doctor-a@`, `assistant-a@`, `physio-a@`, `nurse-a@`, `doctor-b@` … `@example.test` |
| Profile bağlantısı | `profiles.auth_user_id` ↔ Auth user; JWT claims set |
| Tenant A aktif | `a0000001-0001-4001-8001-000000000001` — DrMem Demo Clinic A |
| Tenant B aktif | `a0000001-0001-4001-8001-000000000002` — cross-tenant test |
| Referans hasta | `p0000001-0001-4001-8001-000000000001` (SEED-A-001), internal note encounter `ce000001-0001-4001-8001-000000000001` |
| Cihaz | Web veya hedef platform (en az bir primary target) |
| Ağ | Staging Supabase erişilebilir |

### 2.2 Mock mod

| Ön koşul | Doğrulama |
|----------|-----------|
| Build | `DATA_BACKEND=mock` (varsayılan) |
| Supabase | Bağlantı gerekmez |
| Login | Mock rol dropdown: doctor / assistant / physiotherapist / nurse |
| Amaç | Remote entegrasyon kırılmadan temel UI/regression |

### 2.3 Pass / Fail tablo standardı

Her test satırında doldurun:

| Sütun | Açıklama |
|-------|----------|
| **Test ID** | Benzersiz kod (ör. `SMK-DOC-001`) |
| **Rol** | doctor / assistant / physiotherapist / nurse / multi |
| **Ortam** | `Supabase` \| `Mock` \| `Both` |
| **Ön koşul** | Oturum, tenant, seed kaydı |
| **Adımlar** | Kısa, sıralı aksiyonlar |
| **Beklenen sonuç** | Pass kriteri (tek cümle) |
| **Pass/Fail** | ☐ Pass ☐ Fail |
| **Not / SS** | Hata mesajı, ekran görüntüsü dosya adı |

---

## 3. Doctor / Admin — Supabase smoke

### 3.1 Auth

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-DOC-001 | doctor | Supabase | Auth user A bağlı | 1. Login `doctor-a@example.test` 2. Dashboard yüklensin | Login başarılı; `/doctor` veya yönlendirme | ☐ | |
| SMK-DOC-002 | doctor | Supabase | SMK-DOC-001 | Oturum sonrası ayarlar/tenant bilgisi (varsa) kontrol | Active tenant = Clinic A; teknik debug/tenant UUID UI’da görünmez | ☐ | |
| SMK-DOC-003 | doctor | Supabase | SMK-DOC-001 | Logout | Login ekranı; hasta/muayene listesi cache’te görünmez | ☐ | |

### 3.2 Dashboard

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-DOC-010 | doctor | Supabase | Seed randevuları | Dashboard aç; bugünkü randevu özeti | Seed’deki 2026-05-24 randevularıyla tutarlı (≈3 planlı/geldi); stack trace yok | ☐ | |
| SMK-DOC-011 | doctor | Supabase | SMK-DOC-010 | Dashboard kartları — clinical, patients, appointments | İzinli kartlar görünür; forbidden kart yok | ☐ | |

### 3.3 Patients

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-DOC-020 | doctor | Supabase | Tenant A | `/patients` listesi | ≥8 seed hasta (SEED-A-*); remote yükleme | ☐ | |
| SMK-DOC-021 | doctor | Supabase | SMK-DOC-020 | `SEED-A-001` detay aç | Demo Sporcu Diz detayı açılır | ☐ | |
| SMK-DOC-022 | doctor | Supabase | SMK-DOC-020 | Yeni hasta oluştur (fake isim) | Kayıt başarılı; listede görünür | ☐ | |
| SMK-DOC-023 | doctor | Supabase | SMK-DOC-022 | Hasta düzenle (telefon fake) | Güncelleme kaydedilir | ☐ | |
| SMK-DOC-024 | doctor | Supabase | Arama varsa | Liste arama/filtre dene | Sonuçlar mantıklı; crash yok | ☐ | |

### 3.4 Appointments

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-DOC-030 | doctor | Supabase | Tenant A | `/appointments` listesi | Seed randevuları (planned/arrived/cancelled/…) görünür | ☐ | |
| SMK-DOC-031 | doctor | Supabase | SMK-DOC-030 | Randevu detay (`f0000001-...001` bugün) | Detay açılır | ☐ | |
| SMK-DOC-032 | doctor | Supabase | Hasta seçili | Yeni randevu oluştur (gelecek tarih) | Kayıt OK | ☐ | |
| SMK-DOC-033 | doctor | Supabase | SMK-DOC-032 | Randevu düzenle / iptal | Status güncellenir (cancelled vb.) | ☐ | |
| SMK-DOC-034 | doctor | Supabase | SMK-DOC-010 | Dashboard bugün vs appointment list | Tutarlı sayı/saat | ☐ | |

### 3.5 Clinical (full)

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-DOC-040 | doctor | Supabase | Tenant A | `/clinical-records` liste | Muayeneler remote gelir | ☐ | |
| SMK-DOC-041 | doctor | Supabase | Seed CE | `ce000001-...001` detay aç | diagnosis/treatment summary görünür | ☐ | |
| SMK-DOC-042 | doctor | Supabase | SMK-DOC-041 | **internalDoctorNote** alanı | Fake seed internal not görünür (doctor path) | ☐ | |
| SMK-DOC-043 | doctor | Supabase | SMK-DOC-041 | Form/detayda JSON dump / clinical_data ham | **Görünmez** — yalnız form alanları | ☐ | |
| SMK-DOC-044 | doctor | Supabase | SMK-DOC-040 | Yeni muayene oluştur + internal not yaz + kaydet | Not ayrı kolon davranışı; kayıt OK | ☐ | |
| SMK-DOC-045 | doctor | Supabase | SMK-DOC-044 | Muayene düzenle | Güncelleme OK | ☐ | |

### 3.6 Patient file / PDF metadata

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-DOC-050 | doctor | Supabase | SEED-A-001 | Hasta dosya metadata listesi (`/files` veya hasta bağlamı) | MRI/consent vb. metadata satırları | ☐ | |
| SMK-DOC-051 | doctor | Supabase | SMK-DOC-050 | Dosya satırına tıkla / preview | **Download/preview gerçek dosya açmaz** (henüz faz) | ☐ | |
| SMK-DOC-052 | doctor | Supabase | SMK-DOC-050 | UI’da URL/path arama | `signedUrl`, `publicUrl`, `storage_path`, bucket **görünmez** | ☐ | |
| SMK-DOC-053 | doctor | Supabase | Tenant A | `/pdf-outputs` | PDF metadata listesi; içerik yok | ☐ | |

### 3.7 Timeline

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-DOC-060 | doctor | Supabase | SEED-A-001 | `/patient-timeline?patientId=p0000001-...001` (veya UI navigasyon) | Olaylar kronolojik: patient/appointment/clinical/file | ☐ | |
| SMK-DOC-061 | doctor | Supabase | SMK-DOC-060 | Timeline içeriği tara | Audit (`auth.login`, `permission.denied`) **yok** | ☐ | |
| SMK-DOC-062 | doctor | Supabase | SMK-DOC-060 | internal note / clinical_data / signed URL | **Hiçbiri görünmez** | ☐ | |

### 3.8 Audit / KVKK (doctor only)

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-DOC-070 | doctor | Supabase | SMK-DOC-001 | `/audit-logs` aç | Route erişilir; liste veya empty state | ☐ | |

---

## 4. Assistant / Secretary — Supabase smoke

### 4.1 Auth / Dashboard

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-AST-001 | assistant | Supabase | Auth user A | Login `assistant-a@example.test` | `/assistant` dashboard | ☐ | |
| SMK-AST-002 | assistant | Supabase | SMK-AST-001 | Dashboard kartları | Operasyonel kartlar; full clinical kartı **yok** | ☐ | |

### 4.2 Patients / Appointments

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-AST-010 | assistant | Supabase | Tenant A | `/patients` | Hasta listesi görünür | ☐ | |
| SMK-AST-011 | assistant | Supabase | SMK-AST-010 | SEED-A-001 detay | Temel bilgiler; gereksiz full klinik blok yok | ☐ | |
| SMK-AST-012 | assistant | Supabase | SMK-AST-001 | `/appointments` list/detail | Randevular görünür | ☐ | |
| SMK-AST-013 | assistant | Supabase | SMK-AST-012 | Randevu oluştur / düzenle / iptal | Operasyonel CRUD çalışır | ☐ | |

### 4.3 Assistant safe summary

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-AST-020 | assistant | Supabase | Seed CE | `/clinical-records/diagnosis-summary` | Liste yüklenir (RPC) | ☐ | |
| SMK-AST-021 | assistant | Supabase | SMK-AST-020 | `ce000001-...001` satırı | diagnosisSummary, visitType, status, physio referral, next control dolu | ☐ | |
| SMK-AST-022 | assistant | Supabase | SMK-AST-021 | Detayda full clinical link / internal note | **Yok**; full `/clinical-records/:id` açılmaz | ☐ | |
| SMK-AST-023 | assistant | Supabase | SMK-AST-021 | Ekranda JSON / raw clinical_data | **Görünmez** | ☐ | |

### 4.4 Patient files (assistant scope)

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-AST-030 | assistant | Supabase | SEED-A-002 | Dosya metadata | `clinic_operations` (consent) görünür | ☐ | |
| SMK-AST-031 | assistant | Supabase | SEED-A-001 | doctor_admin only MRI metadata | **Görünmez** (RLS) | ☐ | |

### 4.5 Forbidden (assistant)

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-AST-F01 | assistant | Supabase | Logged in | URL: `/clinical-records/ce000001-...001` | Redirect / forbidden / boş — full CE **yok** | ☐ | |
| SMK-AST-F02 | assistant | Supabase | SMK-AST-001 | URL: `/audit-logs` | Erişim yok | ☐ | |
| SMK-AST-F03 | assistant | Supabase | SMK-AST-001 | URL: `/physiotherapy/clinical-summaries` | Erişim yok | ☐ | |
| SMK-AST-F04 | assistant | Supabase | SMK-AST-001 | URL: `/patient-timeline?patientId=p0000001-...001` | Erişim yok (doctor only route) | ☐ | |
| SMK-AST-F05 | assistant | Supabase | SMK-AST-001 | URL: `/pdf-outputs` | Erişim yok | ☐ | |
| SMK-AST-F06 | assistant | Supabase | SMK-AST-001 | URL: `/inventory` | Erişim yok (nurse path) | ☐ | |

---

## 5. Physiotherapist — Supabase smoke

### 5.1 Auth / Dashboard

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-PHY-001 | physiotherapist | Supabase | Auth user A | Login `physio-a@example.test` | `/physio` dashboard FTR odaklı | ☐ | |
| SMK-PHY-002 | physiotherapist | Supabase | SMK-PHY-001 | Dashboard kartları | FTR/summary; full clinical **yok** | ☐ | |

### 5.2 Physio safe summary

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-PHY-010 | physiotherapist | Supabase | Tenant A | `/physiotherapy/clinical-summaries` | Liste RPC ile gelir | ☐ | |
| SMK-PHY-011 | physiotherapist | Supabase | SMK-PHY-010 | `ce000001-...001` | bodyRegion, side, exercise, rehab, ROM, FTR goal alanları | ☐ | |
| SMK-PHY-012 | physiotherapist | Supabase | SMK-PHY-011 | internalDoctorNote / raw JSON | **Görünmez** | ☐ | |
| SMK-PHY-013 | physiotherapist | Supabase | SMK-PHY-011 | Full muayene detay linki | **Yok** veya açılmaz | ☐ | |

### 5.3 Files / Timeline

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-PHY-020 | physiotherapist | Supabase | SEED-A-005 | PT plan metadata (`physiotherapy` scope) | Görünür | ☐ | |
| SMK-PHY-021 | physiotherapist | Supabase | SMK-PHY-001 | URL `/patient-timeline?...` | Erişim yok (doctor only) | ☐ | |

### 5.4 Forbidden (physio)

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-PHY-F01 | physiotherapist | Supabase | Logged in | URL `/clinical-records` | Forbidden | ☐ | |
| SMK-PHY-F02 | physiotherapist | Supabase | Logged in | URL `/clinical-records/diagnosis-summary` | Forbidden (assistant path) | ☐ | |
| SMK-PHY-F03 | physiotherapist | Supabase | Logged in | URL `/audit-logs`, `/payments`, `/pdf-outputs` | Forbidden | ☐ | |
| SMK-PHY-F04 | physiotherapist | Supabase | Logged in | `/patients` | Forbidden (matrix: physio no patients) | ☐ | |

---

## 6. Nurse — Supabase smoke

### 6.1 Allowed

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-NUR-001 | nurse | Supabase | Auth user A | Login `nurse-a@example.test` | `/nurse` dashboard | ☐ | |
| SMK-NUR-010 | nurse | Supabase | SMK-NUR-001 | `/patients` | Hasta listesi (read) | ☐ | |
| SMK-NUR-011 | nurse | Supabase | SMK-NUR-001 | `/inventory` (varsa) | Stok ekranı açılır | ☐ | |

### 6.2 Forbidden (nurse)

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-NUR-F01 | nurse | Supabase | Logged in | `/clinical-records`, `/clinical-records/diagnosis-summary`, `/physiotherapy/clinical-summaries` | Hepsi forbidden | ☐ | |
| SMK-NUR-F02 | nurse | Supabase | Logged in | `/patient-timeline`, `/files`, `/pdf-outputs`, `/audit-logs`, `/appointments` | Forbidden veya boş güvenli | ☐ | |
| SMK-NUR-F03 | nurse | Supabase | Logged in | `/payments` | Forbidden | ☐ | |

---

## 7. Cross-tenant / RLS smoke

**Oturum:** Tenant A kullanıcıları (`doctor-a`, `assistant-a`, `physio-a`). JWT tenant = Clinic A.

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-RLS-001 | assistant | Supabase | Tenant A JWT | `/patients` — Tenant B isimleri ara (`SEED-B`) | **0 sonuç** | ☐ | |
| SMK-RLS-002 | assistant | Supabase | Tenant A JWT | `/appointments` — B randevuları | **Görünmez** | ☐ | |
| SMK-RLS-003 | assistant | Supabase | Tenant A JWT | diagnosis-summary — B encounter | **Görünmez** | ☐ | |
| SMK-RLS-004 | physiotherapist | Supabase | Tenant A JWT | clinical-summaries — B | **Görünmez** | ☐ | |
| SMK-RLS-005 | doctor | Supabase | Tenant A JWT | `/patients/p0000002-...001` (Tenant B patient URL) | Forbidden / not found / empty | ☐ | |
| SMK-RLS-006 | doctor | Supabase | Tenant A JWT | `/clinical-records/ce000002-...001` (Tenant B CE) | **Erişim yok** | ☐ | |
| SMK-RLS-007 | assistant | Supabase | Tenant A JWT | diagnosis-summary get B encounterId | Empty / error güvenli | ☐ | |
| SMK-RLS-008 | doctor | Supabase | Tenant A JWT | B file metadata `pf000002-...001` | **Görünmez** | ☐ | |
| SMK-RLS-009 | doctor | Supabase | Tenant A JWT | Timeline `patientId=p0000002-...001` | Empty / scope yok | ☐ | |
| SMK-RLS-010 | doctor | Supabase | Suspended tenant C membership (opsiyonel setup) | Login / veri listesi | Veri dönmez veya oturum kurulamaz | ☐ | |

---

## 8. internalDoctorNote güvenlik smoke

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-SEC-IDN-001 | doctor | Supabase | ce000001-...001 | Full CE detay/form | internalDoctorNote **görünür** | ☐ | |
| SMK-SEC-IDN-002 | doctor | Supabase | SMK-SEC-IDN-001 | Kaydet sonrası yeniden aç | Not korunur; clinical_data dump yok | ☐ | |
| SMK-SEC-IDN-010 | assistant | Supabase | Aynı encounter | diagnosis-summary + dashboard + files + timeline (erişilenler) | **Hiçbir yerde internal not yok** | ☐ | |
| SMK-SEC-IDN-011 | physiotherapist | Supabase | Aynı encounter | clinical-summaries | **Yok** | ☐ | |
| SMK-SEC-IDN-012 | nurse | Supabase | — | Tüm erişilebilir ekranlar | **Yok** | ☐ | |
| SMK-SEC-IDN-020 | multi | Both | Herhangi rol | UI genel tarama: `internalDoctorNote`, `internal_doctor_note`, `privateNote` string | Debug string **görünmez** | ☐ | |
| SMK-SEC-IDN-021 | multi | Both | Doctor form | clinical_data JSON editörü / ham dump | **Görünmez** (yapılandırılmış alanlar only) | ☐ | |

---

## 9. PatientFile / PDF metadata güvenlik smoke

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-SEC-FIL-001 | doctor | Supabase | SEED-A-001 | Metadata listesi | displayName/kind görünür; binary yok | ☐ | |
| SMK-SEC-FIL-002 | multi | Supabase | SMK-SEC-FIL-001 | Download / open / preview | Gerçek dosya açılmaz (beklenen) | ☐ | |
| SMK-SEC-FIL-003 | multi | Both | — | signedUrl, publicUrl, fileContent, pdfContent | **UI’da yok** | ☐ | |
| SMK-SEC-FIL-004 | multi | Both | — | storageBucket, storage_path debug | **UI’da yok** | ☐ | |
| SMK-SEC-FIL-005 | multi | Both | Metadata detay | internalDoctorNote, clinical_data keys | **Yok** | ☐ | |
| SMK-SEC-FIL-006 | assistant | Supabase | — | visibility RLS | clinic_operations OK; doctor_admin hidden | ☐ | |
| SMK-SEC-FIL-007 | physiotherapist | Supabase | — | visibility RLS | physiotherapy OK; diğer scope hidden | ☐ | |
| SMK-SEC-FIL-008 | nurse | Supabase | — | `/files` | **0 satır** veya route forbidden | ☐ | |

---

## 10. Timeline güvenlik smoke

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-SEC-TLN-001 | doctor | Supabase | SEED-A-001 | Timeline aç | Operasyonel olaylar; audit event yok | ☐ | |
| SMK-SEC-TLN-002 | doctor | Supabase | SMK-SEC-TLN-001 | Olay türleri | `permission.denied`, `auth.login`, `safe summary viewed` **yok** | ☐ | |
| SMK-SEC-TLN-003 | doctor | Supabase | SMK-SEC-TLN-001 | internal note / raw clinical / signed URL | **Yok** | ☐ | |
| SMK-SEC-TLN-004 | nurse | Supabase | — | `/patient-timeline` | Forbidden | ☐ | |
| SMK-SEC-TLN-005 | assistant | Supabase | — | `/patient-timeline` | Forbidden (v1 route matrix) | ☐ | |
| SMK-SEC-TLN-006 | physiotherapist | Supabase | — | `/patient-timeline` | Forbidden | ☐ | |

---

## 11. Cache / session / tenant switch smoke

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-CCH-001 | multi | Supabase | doctor → logout → assistant | 1. Doctor clinical list 2. Logout 3. Assistant login | Assistant’ta doctor full CE **görünmez** | ☐ | |
| SMK-CCH-002 | multi | Supabase | assistant → logout → physio | diagnosis-summary → physio summary | Önceki assistant verisi cache’te **kalmaz** | ☐ | |
| SMK-CCH-003 | multi | Supabase | Tenant switch (ürün destekliyorsa) | A → B tenant seç → listeler | Yalnız B verisi; A kalmaz | ☐ | |
| SMK-CCH-004 | multi | Supabase | Expired / no tenant session | Oturum düşür veya tenant temizle | Güvenli empty / notConfigured; stack trace yok | ☐ | |
| SMK-CCH-005 | multi | Supabase | doctor logged in | Browser hard refresh | Session bootstrap; tenant A verisi geri gelir | ☐ | |
| SMK-CCH-006 | multi | Mock | Rol değiştir dropdown | doctor → assistant | Provider gate doğru; crash yok | ☐ | |

---

## 12. Mock mode regression checklist

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-MCK-001 | multi | Mock | `DATA_BACKEND=mock` | Login rol dropdown | 4 rol seçilebilir | ☐ | |
| SMK-MCK-002 | doctor | Mock | — | Dashboard, patients, appointments | Açılır; crash yok | ☐ | |
| SMK-MCK-003 | doctor | Mock | — | Clinical list/detail/form | Mock akış çalışır | ☐ | |
| SMK-MCK-004 | assistant | Mock | — | diagnosis-summary | Crash yok; mock summary | ☐ | |
| SMK-MCK-005 | physiotherapist | Mock | — | clinical-summaries | Crash yok | ☐ | |
| SMK-MCK-006 | doctor | Mock | — | Patient files metadata UI | Crash yok | ☐ | |
| SMK-MCK-007 | doctor | Mock | — | Patient timeline UI | Crash yok; loading/error polish | ☐ | |
| SMK-MCK-008 | multi | Mock | — | Supabase notConfigured mesajları | Ana mock akışı **bozmaz** | ☐ | |
| SMK-MCK-009 | multi | Mock | — | Forbidden URL’ler (assistant → `/clinical-records`) | Guard mock’ta Supabase ile **tutarlı** | ☐ | |
| SMK-MCK-010 | nurse | Mock | — | patients + inventory; clinical forbidden | Tutarlı | ☐ | |

---

## 13. Failure / loading / empty state checklist

| Test ID | Rol | Ortam | Ön koşul | Adımlar | Beklenen sonuç | Pass/Fail | Not / SS |
|---------|-----|-------|----------|---------|----------------|-----------|----------|
| SMK-UX-001 | multi | Supabase | Ağ kes (uçak modu / proxy) | Liste yenile | Kullanıcı dostu mesaj; PostgREST/SQL/stack **yok** | ☐ | |
| SMK-UX-002 | multi | Supabase | noActiveTenant | Oturum tenant’sız | Teknik değil; güvenli boş | ☐ | |
| SMK-UX-003 | multi | Both | Forbidden route | assistant → `/audit-logs` | Forbidden UI teknik değil | ☐ | |
| SMK-UX-004 | multi | Supabase | Cross-tenant boş liste | B patient arama | Empty state düzgün; crash yok | ☐ | |
| SMK-UX-005 | multi | Both | Yavaş ağ (throttle) | Timeline / summary yükle | Loading indicator; stale flash minimal | ☐ | |
| SMK-UX-006 | multi | Both | — | Herhangi hata ekranı | `FailureCode`, enum adı, exception string **görünmez** | ☐ | |

---

## 14. Önerilen test sırası

1. **Supabase doctor/admin happy path** — SMK-DOC-001 → 070  
2. **Supabase assistant happy path** — SMK-AST-001 → 031  
3. **Supabase physiotherapist happy path** — SMK-PHY-001 → 021  
4. **Supabase nurse forbidden path** — SMK-NUR-001, 010, F01–F03  
5. **Cross-tenant / RLS** — SMK-RLS-001 → 010  
6. **internalDoctorNote güvenlik** — SMK-SEC-IDN-*  
7. **PatientFile / PDF metadata** — SMK-SEC-FIL-*  
8. **Timeline güvenlik** — SMK-SEC-TLN-*  
9. **Dashboard consistency** — SMK-DOC-010, 034  
10. **Cache / session switch** — SMK-CCH-*  
11. **Mock regression** — SMK-MCK-*  
12. **UX / failure states** — SMK-UX-* (paralel veya son)

**Tahmini süre:** 4–8 saat (tek QA, staging hazır); bulgu kaydı için Not/SS sütununu doldurun.

---

## 15. Sonraki paketler

| Sıra | Paket | Amaç |
|------|--------|------|
| 1 | **Supabase RLS Manual Smoke v1** | PostgREST/RPC düzeyinde RLS negatif matris (authenticated) |
| 2 | **First Full App Trial v1** | Uçtan uca klinik gün senaryosu |
| 3 | **Bugfix Batch v1** | Bu checklist Fail maddeleri |
| 4 | **Staging Trial Report v1** | Pass/fail özeti + riskler |
| 5 | **Realtime Role-Filtered Refresh Plan v1** | Canlı güncelleme tasarımı |
| 6 | **Demo/Freemium/Subscription Plan v1** | Limit enforcement |

---

## Ek: Hızlı seed referansı

| Kayıt | UUID (kısa) |
|-------|-------------|
| Tenant A | `a0000001-0001-4001-8001-000000000001` |
| Tenant B | `a0000001-0001-4001-8001-000000000002` |
| Patient A-001 | `p0000001-0001-4001-8001-000000000001` |
| Patient B-001 | `p0000002-0001-4001-8001-000000000001` |
| CE + internal note (A) | `ce000001-0001-4001-8001-000000000001` |
| CE (B) | `ce000002-0001-4001-8001-000000000001` |
| File doctor_admin (A) | `pf000001-0001-4001-8001-000000000001` |
| File clinic_ops (A) | `pf000001-0001-4001-8001-000000000002` |
| File physio (A) | `pf000001-0001-4001-8001-000000000003` |

---

## Test oturumu özeti (doldurun)

| Alan | Değer |
|------|--------|
| Tarih | |
| Test eden | |
| Build / commit | |
| Supabase proje | staging/dev adı |
| DATA_BACKEND | supabase / mock |
| Toplam Pass | / |
| Toplam Fail | / |
| Blocker Fail ID’ler | |

---

*Bu checklist yalnızca manuel QA içindir. Otomasyon veya kod değişikliği gerektirmez.*
