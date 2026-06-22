# Staging Trial Workbook v1

> **Paket türü:** Operatör manuel QA / gerçek veri girişi / staging PDF-RLS kanıtı  
> **Kod değişikliği:** Yok  
> **Önceki rapor:** [first_full_app_trial_v1_report.md](first_full_app_trial_v1_report.md) — mock login smoke; **Blocked / Operator Required**  
> **İlgili:** [staging_seed_data_v1.md](staging_seed_data_v1.md), [staging_live_e2e_readiness_execution_v1.md](staging_live_e2e_readiness_execution_v1.md), [pdf_storage_staging_smoke_v1_report.md](smoke/pdf_storage_staging_smoke_v1_report.md), [scripts/staging/pdf_storage_smoke_checks.sql](../scripts/staging/pdf_storage_smoke_checks.sql)

---

## Nasıl kullanılır?

1. **Ön koşullar** (§2–§4) tamamlanmadan veri girişine geçmeyin.  
2. Her madde için **Sonuç** sütununu doldurun: `Pass` | `Fail` | `Partial` | `N/A` | `Blocked`  
3. **Kanıt** sütununa kısa not: tarih/saat, ekran adı, screenshot dosya adı (repoya secret commit etmeyin).  
4. **Fail/Partial** için §9 bulgu tablosuna satır ekleyin (P0/P1/P2).  
5. Tüm workbook bitince §10 karar tablosunu işaretleyin ve [staging_trial_report_v1.md](staging_trial_report_v1.md) veya yeni trial raporuna özet aktarın.

**Trial kimliği (doldurun):**

| Alan | Değer |
|------|--------|
| Trial ID | `STAGING-TRIAL-________` |
| Operatör | |
| Tarih | ____-____-____ |
| Süre (dk) | |
| Flutter sürümü / commit | |
| Supabase proje ref (staging) | |
| Platform | ☐ Windows desktop ☐ Web ☐ Tablet |

---

## 1. Ortam doğrulama tablosu

| # | Kontrol | Beklenen | Sonuç | Kanıt / not |
|---|---------|----------|--------|-------------|
| ENV-01 | Ortam = **staging/dev** (production değil) | Prod DB’ye bağlı değil | ☐ | |
| ENV-02 | `DATA_BACKEND=supabase` | Mock değil | ☐ | |
| ENV-03 | `SUPABASE_URL` + `SUPABASE_ANON_KEY` dolu | `.env` / `secrets/staging.json` (repoda yok) | ☐ | |
| ENV-04 | Flutter çalıştırma | `flutter run --dart-define-from-file=secrets/staging.json` veya eşdeğeri | ☐ | |
| ENV-05 | Login ekranı | drMem Clinic; gradient panel bozulmamış | ☐ | |
| ENV-06 | Gerçek hasta verisi yok | Yalnız demo/seed + trial girişi | ☐ | |
| ENV-07 | `service_role` istemcide yok | DevTools/network’te service_role anahtarı görünmez | ☐ | |
| ENV-08 | Evidence klasörü | `evidence/staging-trial-v1/` (local, gitignore) | ☐ | |

**Ortam özeti:**

| Alan | Değer |
|------|--------|
| Backend mode | |
| Platform | |
| Ekran çözünürlüğü | |
| Ağ (VPN / ofis) | |

---

## 2. Kullanıcı / rol matrisi

> Şifreler repoda yazılmaz. Staging secret store’dan alın.

### 2.1 Demo hesaplar (Tenant A — ana trial)

| Rol | E-posta | Profile ID (seed) | Tenant | Giriş denendi? | Sonuç | Kanıt |
|-----|---------|-------------------|--------|----------------|--------|-------|
| Doktor / Admin | `doctor-a@example.test` | `b0000001-0001-4001-8001-000000000001` | Clinic A | ☐ | ☐ | |
| Asistan / Sekreter | `assistant-a@example.test` | `b0000001-0001-4001-8001-000000000011` | Clinic A | ☐ | ☐ | |
| Fizyoterapist | `physio-a@example.test` | `b0000001-0001-4001-8001-000000000021` | Clinic A | ☐ | ☐ | |
| Hemşire | `nurse-a@example.test` | `b0000001-0001-4001-8001-000000000031` | Clinic A | ☐ | ☐ | |

### 2.2 Cross-tenant / negatif (PDF-RLS)

| Rol | E-posta | Tenant | Amaç | Sonuç | Kanıt |
|-----|---------|--------|------|--------|-------|
| Doktor B | `doctor-b@example.test` | Clinic B | Tenant A verisine erişim **olmamalı** | ☐ | |
| Asistan B | `assistant-b@example.test` | Clinic B | Tenant A hasta/randevu **0** | ☐ | |

### 2.3 Auth bootstrap (SETUP)

| # | Kontrol | Beklenen | Sonuç | `auth_user_id` / not |
|---|---------|----------|--------|----------------------|
| AUTH-01 | `profiles.auth_user_id` doctor-a bağlı | NOT NULL | ☐ | |
| AUTH-02 | doctor-a login | Dashboard açılır; “aktif klinik üyeliği yok” **yok** | ☐ | |
| AUTH-03 | assistant-a / physio-a / nurse-a bağlı | Hepsi login (veya bilinçli N/A + not) | ☐ | |
| AUTH-04 | UI’da `tenant_id` / `profile_id` görünmez | ☐ | |

---

## 3. Migration / staging readiness checklist

| # | Kontrol | Nasıl doğrulanır | Sonuç | Kanıt |
|---|---------|------------------|--------|-------|
| MIG-01 | Ana şema migration uygulandı | `supabase db push` / pipeline log | ☐ | |
| MIG-02 | `20260530100000_patient_files_private_storage_bucket_v1.sql` | Bucket `patient-files-private` | ☐ | |
| MIG-03 | Seed uygulandı | `staging_seed_data_v1.sql` veya `supabase db reset` | ☐ | |
| MIG-04 | Tenant A aktif | `DrMem Demo Clinic A` — `a0000001-0001-4001-8001-000000000001` | ☐ | |
| MIG-05 | Tenant B aktif (cross-tenant) | `DrMem Demo Clinic B` | ☐ | |
| MIG-06 | SQL spot: yasak metadata anahtarları | `scripts/staging/pdf_storage_smoke_checks.sql` §4 → **0 satır** | ☐ | |
| MIG-07 | Bucket `public = false` | SQL §1 veya Dashboard | ☐ | |
| MIG-08 | Storage SELECT/INSERT policy; UPDATE/DELETE yok | SQL §2 | ☐ | |
| MIG-09 | Clinic Workflow Settings (opsiyonel) | Randevu slot smoke için tenant ayarı yüklü | ☐ | |

**Readiness özeti:** ☐ Hazır ☐ Kısmen ☐ Blokaj — blokaj notu: _______________________________

---

## 4. Doktor veri giriş workbook’u (Tenant A)

**Hedef minimum veri (trial):** 2 hasta · 2 randevu · 1 muayene · quick patient create · 1 dosya · 1 PDF · 1 ödeme · 1 onam · 1 stok

**Oturum:** `doctor-a@example.test` · Tenant A

### 4.1 Login & Dashboard

| # | Adım | Beklenen | Sonuç | Kanıt |
|---|------|----------|--------|-------|
| DOC-01 | Giriş | Dashboard açılır | ☐ | |
| DOC-02 | Workbench hissi | Modül launcher değil; KPI + bugün akışı + quick actions | ☐ | |
| DOC-03 | Quick actions (max 4) | Yeni Muayene, Yeni Randevu, PDF Çıktı; **Hastalar / Muayene listesi tekrarı yok** | ☐ | |
| DOC-04 | Header’da global “Yeni …” CTA yok | Dedupe v1 | ☐ | |

### 4.2 Hasta (≥ 2 yeni)

| # | Adım | Beklenen | Sonuç | Kayıt ID / ad |
|---|------|----------|--------|--------------|
| DOC-10 | Hasta 1 oluştur | Zorunlu alanlar mantıklı; kayıt başarılı | ☐ | |
| DOC-11 | Hasta 2 oluştur | Aynı | ☐ | |
| DOC-12 | Hasta listesi | ClinicalListRow; demografi okunabilir | ☐ | |
| DOC-13 | Hasta detay | Kimlik bandı sade | ☐ | |
| DOC-14 | Eksik profil banner | Kısmi profilde banner görünür | ☐ | |
| DOC-15 | Profili tamamla → düzenleme | Banner azalır/kaybolur | ☐ | |

**Veri özeti:** Hasta 1: _______________ · Hasta 2: _______________

### 4.3 Randevu (≥ 2)

| # | Adım | Beklenen | Sonuç | Kayıt |
|---|------|----------|--------|-------|
| DOC-20 | Hasta detayından yeni randevu | Hasta lock / seçili | ☐ | |
| DOC-21 | Tarih + slot seç | Kapalı/çalışma dışı mesajları anlaşılır | ☐ | |
| DOC-22 | Randevu 1 kaydet | Listede görünür | ☐ | |
| DOC-23 | Randevu 2 (farklı hasta veya aynı) | Kayıt başarılı | ☐ | |
| DOC-24 | Randevu listesi | ClinicalListRow + legend dengeli | ☐ | |
| DOC-25 | Dashboard bugün akışı | Yeni randevulardan en az biri görünür | ☐ | |

### 4.4 Muayene (≥ 1)

| # | Adım | Beklenen | Sonuç | Kayıt |
|---|------|----------|--------|-------|
| DOC-30 | Hasta detayından Yeni Muayene | Hasta lock | ☐ | |
| DOC-31 | Form doldurma hızı | ICD, tedavi, ilaç, enjeksiyon/ortez yerinde | ☐ | |
| DOC-32 | **Özel Not** görünür | Yalnız doktor path | ☐ | |
| DOC-33 | Kaydet | Muayene listesinde marker/chip makul | ☐ | |
| DOC-34 | Muayene detay | “Detaylar aşağıda” gereksiz yönlendirme yok | ☐ | |
| DOC-35 | `internalDoctorNote` ∉ `clinical_data` UI | Ham JSON / clinical_data görünmez | ☐ | |

**Muayene ID:** _______________

### 4.5 Quick Patient Create (muayene formu)

| # | Adım | Beklenen | Sonuç | Kanıt |
|---|------|----------|--------|-------|
| DOC-40 | Yeni Muayene — hasta seçmeden | Form açılır | ☐ | |
| DOC-41 | “Yeni Hasta” minimal oluştur | Ad, soyad, telefon zorunlu | ☐ | |
| DOC-42 | Hasta otomatik seçilir | lockSelection zorunlu değil | ☐ | |
| DOC-43 | Form verisi korunur | ☐ | |
| DOC-44 | Hasta değiştirilebilir | ☐ | |
| DOC-45 | Duplicate soft warning | Hard-block yok | ☐ | |
| DOC-46 | Eksik profil uyarısı | Hasta detayda banner | ☐ | |

**Quick create hasta:** _______________

### 4.6 Dosya & PDF

| # | Adım | Beklenen | Sonuç | Kanıt |
|---|------|----------|--------|-------|
| DOC-50 | Hasta dosyası yükle | Başarılı | ☐ | |
| DOC-51 | Dosya listesi ClinicalListRow | `storage_path` / `signed_url` / `public_url` **UI’da yok** | ☐ | |
| DOC-52 | Dosya aç (view) | Signed URL launcher; hata teknik değil | ☐ | |
| DOC-53 | PDF çıktı oluştur | Kayıt oluşur | ☐ | |
| DOC-54 | PDF listesi ClinicalListRow | PdfDocumentCard yok; `contentSummary` listede yok | ☐ | |
| DOC-55 | PDF detay → PDF Aç | Açılır veya anlaşılır hata | ☐ | |

**Dosya ID:** _______________ · **PDF ID:** _______________

### 4.7 Ödeme · Onam · Stok (doktor veya rol izin veriyorsa)

| # | Adım | Beklenen | Sonuç | Kayıt |
|---|------|----------|--------|-------|
| DOC-60 | Ödeme kaydı (≥1) | Liste + özet yoğunluğu uygun | ☐ | |
| DOC-61 | Onam kaydı (≥1) | ClinicalListRow | ☐ | |
| DOC-62 | Stok kartı (≥1) | Erişim varsa oluşturuldu | ☐ | |

### 4.8 Doktor güvenlik spot (UI tarama)

Tüm oturum boyunca ekranlarda **görünmemeli** (herhangi birinde görürseniz → **P0**):

| Terim | Görüldü mü? | Ekran |
|-------|-------------|-------|
| `Supabase` / `RLS` / `JWT` | ☐ Hayır ☐ Evet | |
| `tenant_id` / `profile_id` | ☐ Hayır ☐ Evet | |
| `storage_path` / `storage_bucket` | ☐ Hayır ☐ Evet | |
| `signed_url` / `public_url` | ☐ Hayır ☐ Evet | |
| `internalDoctorNote` / `internal_doctor_note` | ☐ Hayır ☐ Evet | |
| `raw clinical_data` / ham `clinical_data` | ☐ Hayır ☐ Evet | |
| `exception` / `stack trace` / `debug` | ☐ Hayır ☐ Evet | |

**Doktor bölümü sonucu:** ☐ Pass ☐ Partial ☐ Fail

---

## 5. Asistan role / security workbook’u

**Oturum:** `assistant-a@example.test` · Tenant A

### 5.1 Dashboard & navigasyon

| # | Adım | Beklenen | Sonuç | Kanıt |
|---|------|----------|--------|-------|
| AST-01 | Giriş | Dashboard operasyonel | ☐ | |
| AST-02 | Quick actions (4) | Yeni Randevu, KVKK/Onam, Ödeme, Dosya Yükle | ☐ | |
| AST-03 | Sidebar tekrarı yok | Hastalar/Randevular dashboard quick’ta **yok** | ☐ | |
| AST-04 | Full clinical route | Menüde / deep link **yok** veya engelli | ☐ | |

### 5.2 Operasyonel akışlar

| # | Adım | Beklenen | Sonuç | Kanıt |
|---|------|----------|--------|-------|
| AST-10 | Yeni randevu | Oluşturulabilir | ☐ | |
| AST-11 | Onam kaydı | Oluşturulabilir / listelenir | ☐ | |
| AST-12 | Ödeme kaydı | Oluşturulabilir | ☐ | |
| AST-13 | Dosya yükle | `clinic_operations` scope | ☐ | |
| AST-14 | Hasta detay duplicate CTA | Gereksiz tekrar yok | ☐ | |

### 5.3 Güvenlik — full clinical & internal note

| # | Adım | Beklenen | Sonuç | Kanıt |
|---|------|----------|--------|-------|
| AST-20 | Muayene kayıtları full form | **Erişim yok** / safe summary only | ☐ | |
| AST-21 | Tanı / Ön Tanı özeti | Safe summary dışında full clinical **açılmaz** | ☐ | |
| AST-22 | `internalDoctorNote` | **Görünmez** | ☐ | |
| AST-23 | `raw clinical_data` | **Görünmez** | ☐ | |
| AST-24 | Seed doctor-only dosya metadata | `doctor_admin` scope listede **yok** | ☐ | |
| AST-25 | Tenant B hasta arama | **0 sonuç** / erişim yok | ☐ | |

**Asistan bölümü sonucu:** ☐ Pass ☐ Partial ☐ Fail

---

## 6. Fizyoterapist workbook’u

**Oturum:** `physio-a@example.test` · Tenant A

| # | Adım | Beklenen | Sonuç | Kanıt |
|---|------|----------|--------|-------|
| PHY-01 | Giriş | Dashboard sade | ☐ | |
| PHY-02 | Quick actions (3) | Yönlendirmeler, Seans Notları, Egzersiz Programları | ☐ | |
| PHY-03 | Klinik Özetler quick’ta yok | Dedupe v1 | ☐ | |
| PHY-04 | Full clinical encounter | **Görünmez** | ☐ | |
| PHY-05 | Safe summary / seans | FTR scope veri okunabilir | ☐ | |
| PHY-06 | `internalDoctorNote` | **Görünmez** | ☐ | |
| PHY-07 | `raw clinical_data` | **Görünmez** | ☐ | |
| PHY-08 | Physio scope dosya metadata | `physiotherapy` scope görünür | ☐ | |
| PHY-09 | Tenant B veri | **Erişim yok** | ☐ | |

**Fizyoterapist bölümü sonucu:** ☐ Pass ☐ Partial ☐ Fail

---

## 7. Hemşire workbook’u

**Oturum:** `nurse-a@example.test` · Tenant A

| # | Adım | Beklenen | Sonuç | Kanıt |
|---|------|----------|--------|-------|
| NUR-01 | Giriş | Dashboard stok odaklı | ☐ | |
| NUR-02 | Quick action | Stok / Sarf (Görevlerim placeholder **yok**) | ☐ | |
| NUR-03 | Hastalar menüsü | **Yok** veya erişim kapalı | ☐ | |
| NUR-04 | Full clinical / muayene | **Erişim yok** | ☐ | |
| NUR-05 | Timeline | **Erişim yok** veya klinik olay yok | ☐ | |
| NUR-06 | `internalDoctorNote` | **Görünmez** | ☐ | |
| NUR-07 | Dosya / PDF listesi | **Erişim yok** | ☐ | |
| NUR-08 | Stok / Sarf akışı | Liste + kart oluşturma erişilebilir | ☐ | |
| NUR-09 | Stok kartı (≥1) trial | Oluşturuldu veya N/A + not | ☐ | |

**Hemşire bölümü sonucu:** ☐ Pass ☐ Partial ☐ Fail

---

## 8. PDF / storage security workbook’u

> Canlı staging zorunlu. Mock modda public URL / 121 sn testi **geçersiz** (N/A işaretleyin).

**Operatör:** _______________ · **Platform:** ☐ Windows ☐ Web

### 8.1 Altyapı (SQL + Dashboard)

| # | Kontrol | Beklenen | Sonuç | Kanıt |
|---|---------|----------|--------|-------|
| PDF-01 | Bucket private | `public = false` | ☐ | |
| PDF-02 | Public URL negatif | Public path ile dosya **açılmaz** (403/404) | ☐ | |
| PDF-03 | SQL metadata spot | `signed_url` / `clinical_data` DB metadata’da **0 satır** | ☐ | |
| PDF-04 | UPDATE/DELETE storage policy yok | SQL §2 | ☐ | |

### 8.2 Signed URL davranışı (canlı)

| # | Adım | Beklenen | Sonuç | Kanıt |
|---|------|----------|--------|-------|
| PDF-10 | Dosya veya PDF aç | Signed URL ile viewer açılır | ☐ | |
| PDF-11 | URL UI’da kalıcı değil | Liste/detay/state’te `signed_url` metni yok | ☐ | |
| PDF-12 | Aynı URL **121 sn** bekle | İkinci açılış **başarısız** veya yenileme gerekir | ☐ | |
| PDF-13 | Tekrar “Aç” | **Yeni** signed URL ile açılır | ☐ | |
| PDF-14 | TTL ~120 sn | Birinci açılış 120 sn içinde OK | ☐ | |

**İlk signed URL (kopyalamayın — sadece var/yok):** ☐ Oluştu ☐ Oluşmadı  
**121 sn test saati:** ____:____

### 8.3 Rol & cross-tenant

| # | Adım | Beklenen | Sonuç | Kanıt |
|---|------|----------|--------|-------|
| PDF-20 | Assistant → doctor-only dosya | Görünmez / açılamaz | ☐ | |
| PDF-21 | Nurse → dosya/PDF | **Erişim yok** | ☐ | |
| PDF-22 | Doctor A → Tenant B hasta dosyası | **Erişim yok** | ☐ | |
| PDF-23 | Doctor B login → Tenant A veri | **Görünmez** | ☐ | |

**PDF/storage bölümü sonucu:** ☐ Pass ☐ Partial ☐ Fail ☐ N/A (mock)

---

## 9. Veri giriş özeti (operatör doldurur)

| Varlık | Hedef | Gerçekleşen | Not |
|--------|-------|-------------|-----|
| Yeni hasta | ≥ 2 | | |
| Randevu | ≥ 2 | | |
| Muayene | ≥ 1 | | |
| Quick patient create | 1 deneme | | |
| Hasta dosyası upload | ≥ 1 | | |
| Dosya aç (view) | 1 | | |
| PDF oluştur | ≥ 1 | | |
| PDF aç | 1 | | |
| Ödeme | ≥ 1 | | |
| Onam | ≥ 1 | | |
| Stok kartı | ≥ 1 | | |

---

## 10. P0 / P1 / P2 bulgu tablosu

| Bug ID | P | Rol / ekran | Repro adımları | Beklenen | Gözlenen | Kanıt | Durum |
|--------|---|-------------|----------------|----------|----------|-------|-------|
| BUG-001 | | | | | | | ☐ Açık ☐ Kapalı |
| BUG-002 | | | | | | | ☐ Açık ☐ Kapalı |
| BUG-003 | | | | | | | ☐ Açık ☐ Kapalı |
| UX-001 | P2 | | | | | | |
| SETUP-001 | P1 | Auth | `auth_user_id` null | Login OK | Üyelik hatası | | |

**P0 tanımı (hatırlatma):** veri kaybı, kayıt oluşturulamıyor, role/RLS ihlali, forbidden UI sızıntısı, crash, PDF public erişim, cross-tenant sızıntı.

---

## 11. Go / Conditional Go / Blocked karar tablosu

| Boyut | Sonuç | Gerekçe (1 cümle) |
|-------|--------|-------------------|
| Ortam readiness (§3) | ☐ Go ☐ Conditional ☐ Blocked | |
| Doktor veri girişi (§4) | ☐ Go ☐ Conditional ☐ Blocked | |
| Asistan güvenlik (§5) | ☐ Go ☐ Conditional ☐ Blocked | |
| Fizyoterapist (§6) | ☐ Go ☐ Conditional ☐ Blocked | |
| Hemşire (§6) | ☐ Go ☐ Conditional ☐ Blocked | |
| PDF/storage canlı (§8) | ☐ Go ☐ Conditional ☐ Blocked ☐ N/A | |
| UI forbidden token taraması | ☐ Go ☐ Fail | |
| **Genel trial** | ☐ **Go** ☐ **Conditional Go** ☐ **Blocked** | |

### Karar kuralları

| Genel sonuç | Koşul |
|-------------|--------|
| **Go** | Tüm bölümler Pass; P0 yok; PDF/storage Pass; minimum veri tablosu dolu |
| **Conditional Go** | Ana akışlar çalışıyor; P1 var; PDF/storage Partial veya eksik rol |
| **Blocked** | P0 var; staging hazır değil; doctor login yok; minimum veri girişi yapılamadı |

**Production / satış / demo sign-off:** ☐ Hayır (varsayılan) ☐ Evet — gerekçe: _______________

---

## 12. Sonraki paket önerisi (trial sonrası)

Trial sonucuna göre **birini** işaretleyin:

| ☐ | Paket | Ne zaman |
|---|--------|----------|
| ☐ | **PDF Storage Staging Operator Smoke** (kapatma) | §8 Fail/Partial ise önce |
| ☐ | **First Trial Bugfix Batch v1** | P1 BUG listesi ≥ 3 |
| ☐ | **Security / RLS Hotfix** | P0 role/sızıntı |
| ☐ | **UI Polish Batch** | Yalnız P2 UX |
| ☐ | **Auth bootstrap / onboarding helper** | SETUP-001 tekrarlıyorsa |
| ☐ | **Roadmap devam** | Trial Go + P0 yok |

---

## Ek A — Hızlı komutlar (operatör)

```bash
# Staging Flutter (secrets repoda yok — local dosyanız)
flutter run -d windows --dart-define-from-file=secrets/staging.json

# SQL spot (Dashboard SQL Editor)
# scripts/staging/pdf_storage_smoke_checks.sql
```

## Ek B — İlgili execution ID eşlemesi

| Workbook | Eski LIVE-ID |
|----------|----------------|
| DOC-01…08 | LIVE-DOC-01… |
| AST-20…25 | LIVE-AST-03…04 |
| PDF-20…23 | LIVE-RLS-01, RLS cross-tenant |
| Mock UI walkthrough | LIVE-MCK-01 |

---

**Workbook sürümü:** v1 · **Durum:** Operatör doldurmalı · **Trial:** Blocked / Operator Required → tamamlanınca [staging_trial_report_v1.md](staging_trial_report_v1.md) güncellenir.
