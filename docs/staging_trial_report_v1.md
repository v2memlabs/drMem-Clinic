# Staging Trial Report v1

> **Paket türü:** Canlı staging / manuel deneme sonuç raporu (dokümantasyon only).  
> **Üretim tarihi:** 2026-05-24  
> **Ortam:** Supabase staging (`dgzmybbgrofapjptjspf` — kullanıcı bildirimi; secret repoda yok).  
> **Kod değişikliği:** Yok (bu pakette).

| İlgili doküman | Rol |
|----------------|-----|
| [first_full_app_trial_v1_report.md](first_full_app_trial_v1_report.md) | Statik/otomatik trial + Live Workbook (agent oturumu Blocked → canlı sonuç bu raporda) |
| [staging_live_e2e_readiness_execution_v1.md](staging_live_e2e_readiness_execution_v1.md) | Readiness R-01…R-27, yürütme runbook |
| [remote_manual_smoke_test_checklist_v1.md](remote_manual_smoke_test_checklist_v1.md) | UI smoke (SMK-*) |
| [supabase_rls_manual_smoke_v1.md](supabase_rls_manual_smoke_v1.md) | Authenticated JWT RLS/API smoke |
| [staging_seed_data_v1.md](staging_seed_data_v1.md) | Seed + Auth `profiles.auth_user_id` bağlama |

---

## 1. Yönetici özeti (canlı deneme)

| Boyut | Sonuç |
|-------|--------|
| **Canlı staging/manual deneme** | **Yapıldı** — kullanıcı bildirimi esas alındı. |
| **Majör blokaj** | **Bildirilmedi** — uygulama genel akışları denenebilir seviyede. |
| **Küçük hatalar** | **Var** — kullanıcı tarafından onaylandı; **detay listesi henüz doldurulmadı** (BUG-001…). |
| **UI/UX** | **Göze çarpan sorunlar var** — detaylar henüz doldurulmadı (UX-001…). |
| **Ürün olgunluğu** | **Kısıtlı / eksik MVP** — birçok modül metadata-only, storage/PDF/realtime/subscription yok. |
| **Genel karar** | **Conditional Go** — dahili staging ve sınırlı rol bazlı testlere devam edilebilir. |
| **Production / satış / demo sign-off** | **Hayır** — bu rapor ticari hazırlık onayı değildir. |
| **“Satılabilir SaaS”** | **Hayır** — **denenebilir MVP** ile ayrım aşağıda §12. |

### Denenebilir MVP vs satılabilir ürün

| | Denenebilir MVP (şimdi) | Satılabilir ürün (değil) |
|---|-------------------------|---------------------------|
| **Amaç** | İç ekip / staging QA, rol ve güvenlik mimarisini doğrulama | Müşteri onboarding, SLA, faturalama, tam dosya/PDF, compliance sign-off |
| **Auth** | Email/şifre + manuel `auth_user_id` bağlama | Otomatik provizyon, self-service, MFA politikası |
| **Klinik veri** | Seed demo; doctor full CE; assistant/physio safe summary | Üretim verisi, tam audit write, KVKK süreçleri |
| **Dosya** | Metadata listesi | Upload/download, signed URL, virus scan |
| **Güvenlik kanıtı** | Tasarım + kısmi canlı; RLS seti **Needs Evidence** | Arşivlenmiş RLS/UI negatif test kanıtı |

---

## 2. Canlı deneme kapsamı (bildirilen)

Kullanıcı özetine göre:

- Staging Supabase + Flutter (`DATA_BACKEND=supabase`, `secrets/staging.json` — repoda yok) ile manuel deneme yapıldı.
- Migration/seed kurulumu sırasında SQL Editor ile blokajlar yaşandı (UUID, eksik migration, view hotfix) — **ortam kurulumu**; çözüm sonrası akış devam etti.
- **Auth:** `doctor-a@example.test` için Auth kullanıcısı oluşturuldu; `profiles.auth_user_id` manuel bağlandı (`1d8982fd-5cbf-420c-9d02-abfde551821e`) — öncesinde *“aktif klinik üyeliği bulunamadı”* (SETUP-001).
- **Majör sıkıntı:** Bildirilmedi.
- **Ufak hatalar + UI/UX:** Bildirildi; **spesifik adım/adım repro henüz kayda geçmedi** — placeholder tablolar §8–§9.
- **Tüm roller / tüm SMK-*** checklist:** Kullanıcı tarafından tam kapsamlı Pass/Fail listesi **sağlanmadı** — ilgili satırlar **Partial** veya **Needs Evidence**.

---

## 3. Genel karar tablosu

| Alan | Durum | Gerekçe | Sonraki aksiyon |
|------|--------|---------|-----------------|
| **Auth / Login** | **Partial** | Auth + membership bootstrap çalışır hale geldi (SETUP-001 çözüldü); seed Auth bağlama manuel ve hataya açık. | Dokümante onboarding; opsiyonel staging helper (ayrı paket). |
| **Dashboard** | **Partial** | Canlıda gezildi; majör blok yok; sayı/tarih tutarlılığı ve UX detayı **kanıt bekliyor**. | Bugfix/Polish — kullanıcı detayı sonrası. |
| **Patients** | **Partial** | Temel akış denendi; tam CRUD/arama smoke kanıtı yok. | SMK-DOC-020… + Fail → Bugfix Batch. |
| **Appointments** | **Partial** | Aynı. | SMK-DOC-030… |
| **Clinical encounters** | **Partial** | Doctor akışı hedeflendi; tam CRUD + canlı internal note UI kanıtı yok. | LIVE-DOC-05 + RLS |
| **internalDoctorNote safety** | **Needs Evidence** | Kodda doctor-only path (**Pass design**); canlı assistant/physio sızıntı testi arşivlenmedi. | [supabase_rls_manual_smoke_v1.md](supabase_rls_manual_smoke_v1.md) S1–S7, SMK-SEC-* |
| **Assistant safe summary** | **Needs Evidence** | DTO allowlist **Pass design**; canlı RPC/UI teyidi yok. | RLS smoke + assistant walkthrough |
| **Physiotherapist safe summary** | **Needs Evidence** | Aynı. | RLS S8–S14 + physio walkthrough |
| **PatientFile / PDF metadata** | **Partial** | Metadata listesi hedeflenir; upload/download kapalı (beklenen). Canlı liste kanıtı eksik. | SMK-DOC-050… |
| **Timeline** | **Partial** | Doctor route var; canlı timeline smoke kanıtı eksik. | LIVE-DOC-07 |
| **Role-based navigation** | **Partial** | Route guard unit testleri geçti; çoklu rol canlı walkthrough tam değil. | SMK-NAV-* tüm roller |
| **RLS / cross-tenant** | **Needs Evidence** | Critical sızıntı **bildirilmedi**; authenticated API seti tam çalıştırılmadı. | RLS-RLS-* + `evidence/rls/*.json` |
| **Mock mode** | **Partial** | `flutter test` 66+ geçti; tam manuel mock UI walkthrough yapılmadı. | LIVE-MCK-01 (opsiyonel) |
| **UI/UX** | **Partial** | Kullanıcı göze çarpan sorunlar bildirdi; detay pending. | Remote Trial Polish Batch v1 |
| **Overall staging readiness** | **Conditional Go** | Majör blokaj yok; MVP kısıtlı; güvenlik kanıtı eksik. | Bugfix → Polish → Storage/PDF planları |

**Durum sözlüğü:** Pass | Partial | Needs Evidence | Fail | Not Tested

---

## 4. Severity sınıflandırması

### 4.1 Critical

| Durum | Açıklama |
|-------|----------|
| **Canlı bildirim** | Kullanıcı tarafından **Critical güvenlik bug’ı bildirilmedi**. |
| **Risk** | Cross-tenant, `internalDoctorNote`, ham `clinical_data` için **canlı negatif kanıt saklanmalı** — şu an **Critical risk not observed, evidence should be retained**. |
| **Statik inceleme** | [first_full_app_trial_v1_report.md](first_full_app_trial_v1_report.md) — kod katmanında bilinen Critical defect yok (design). |

> **service_role** ile “RLS Pass” kabul edilmez. SQL Editor admin görünümü RLS sign-off yerine geçmez.

### 4.2 High

| Durum | Açıklama |
|-------|----------|
| **Onaylı High blocker** | **No confirmed High blocker reported** (canlı deneme özeti). |
| **Açık High risk** | RLS/API ve çoklu rol E2E tamamlanmadı — Fail çıkarsa **Security Hotfix** öncelikli (bkz. §11). |

### 4.3 Medium

| ID | Bulgu | Kaynak | Sonraki paket |
|----|--------|--------|----------------|
| M-STG-01 | Seed Auth: `profiles.auth_user_id` manuel — login öncesi “aktif klinik üyeliği bulunamadı” | Canlı SETUP-001 | Dokümantasyon + staging onboarding checklist |
| M-STG-02 | Migration/seed SQL Editor sürtünmesi (UUID, migration sırası, view 42P16) | Kurulum oturumu | Readiness doc güncel tutma (yapıldı) |
| M-STG-03 | Küçük fonksiyonel hatalar (detay pending) | Kullanıcı bildirimi | **First Trial Bugfix Batch v1** |
| M-STG-04 | UI/UX göze çarpan sorunlar (detay pending) | Kullanıcı bildirimi | **Remote Trial Polish Batch v1** |
| M-STG-05 | Physio: DB `patient_files` scope var, UI `/files` kapalı | Tasarım/ürün | Ürün kararı veya Polish |
| M-STG-06 | Physio hasta listesi RLS ile boş (beklenen v1) | Tasarım | UX metni / nav |
| M-STG-07 | Timeline: DB subset vs UI yalnız doctor | Tasarım | Timeline nav planı |
| M-STG-08 | `DATA_BACKEND=supabase` + boş URL → mock fallback riski | Config | Build/runbook disiplini |
| M-STG-09 | Eksik MVP modülleri (storage, PDF, realtime, subscription) | Kapsam | Ayrı plan paketleri §10 |

### 4.4 Low

| ID | Bulgu | Sonraki paket |
|----|--------|----------------|
| L-STG-01 | 228 analyzer info/warning (0 error) | Analyzer Warning/Info Cleanup — **en son** |
| L-STG-02 | CE/patient client-side arama sınırları | Backlog |
| L-STG-03 | Mikro metin/hizalama/responsive | Remote Trial Polish Batch v1 |
| L-STG-04 | Seed sabit “bugün” tarihi vs QA takvimi | Seed maintenance (ayrı) |

---

## 5. Kurulum / onboarding bulguları (canlı, çözüldü veya süren)

| ID | Alan | Açıklama | Severity | Durum |
|----|------|----------|----------|--------|
| SETUP-001 | Auth bootstrap | `doctor-a@example.test` Auth UID mevcut; `profiles.auth_user_id` null iken *“Bu kullanıcı için aktif klinik üyeliği bulunamadı”* | Medium | **Çözüldü** — UID `1d8982fd-5cbf-420c-9d02-abfde551821e` bağlandı |
| SETUP-002 | Seed | `auth_user_id` seed’de kasıtlı null — her demo kullanıcı için manuel UPDATE | Medium | **Açık (süreç)** — [staging_seed_data_v1.md](staging_seed_data_v1.md) |
| SETUP-003 | Migrations | Dashboard SQL sırası / hotfix bağımlılığı | Medium | Dokümante — kullanıcı uyguladı |

---

## 6. Güvenlik notları (korunan kararlar)

| Kural | Staging trial durumu |
|-------|----------------------|
| `internalDoctorNote` yalnız doctor/admin path | **Pass (design)** — canlı kanıt: **Needs Evidence** |
| Assistant/Physio full `clinical_encounters` görmemeli | **Pass (design)** — RLS + route; canlı: **Needs Evidence** |
| Ham `clinical_data` UI’da görünmemeli | **Pass (design)** — canlı: **Needs Evidence** |
| PatientFile/PDF metadata içerik veya signed URL taşımaz | **Pass (design/scope)** — upload fazı yok |
| Timeline Audit/KVKK erişim logu değildir | **Pass (design)** — dokümante |
| Cross-tenant izolasyon | **Needs Evidence** — Tenant B JWT ile Tenant A verisi |
| `service_role` RLS bypass | **Kullanılmadı / kabul edilmez** sign-off için |

**Önerilen kanıt saklama:** `evidence/rls/` (gitignore), ekran görüntüsü tarih damgalı, PostgREST 200/empty veya 403/404 — repoya secret commit etmeyin.

---

## 7. Live Results Workbook — staging trial senkronu

> Agent oturumunda tüm LIVE-* satırları **Blocked** idi. Canlı kullanıcı denemesi sonrası **özet** aşağıdadır. Detaylı Pass/Fail için QA hâlâ SMK-* ve RLS-* doldurmalıdır.

| Execution ID | Live Status (staging v1) | Not |
|--------------|--------------------------|-----|
| LIVE-DOC-01 | **Partial** | doctor-a login çalışır (SETUP-001 sonrası); diğer demo kullanıcılar bağlanmadıysa Partial |
| LIVE-DOC-02 … LIVE-DOC-08 | **Partial** / **Needs Evidence** | Majör blok yok; madde madde kanıt yok |
| LIVE-AST-01 … LIVE-AST-04 | **Needs Evidence** | Assistant tam walkthrough kanıtı yok |
| LIVE-PHY-01 … LIVE-PHY-05 | **Needs Evidence** | Physio tam walkthrough kanıtı yok |
| LIVE-NUR-01 … LIVE-NUR-02 | **Needs Evidence** | Nurse tam walkthrough kanıtı yok |
| LIVE-RLS-01 | **Needs Evidence** | Authenticated API smoke arşivi yok |
| LIVE-CCH-01 … LIVE-CCH-02 | **Needs Evidence** | Çoklu rol oturum kanıtı yok |
| LIVE-UX-01 | **Partial** | UI/UX sorunları bildirildi; detay pending |
| LIVE-MCK-01 | **Pass (auto)** | Unit testler — değişmedi |

Tam satır satır güncelleme: [first_full_app_trial_v1_report.md](first_full_app_trial_v1_report.md) § Live Results Workbook (QA opsiyonel senkron).

---

## 8. First Trial Bugfix Batch v1 — aday liste

> **Uydurma bug yok.** Kullanıcı spesifik repro vermedikçe yalnızca placeholder + doğrulanmış SETUP kaydı.

| ID | Area | Description | Severity | Reproduction | Expected | Actual | Suggested fix | Status |
|----|------|-------------|----------|--------------|----------|--------|---------------|--------|
| BUG-001 | *TBD* | Kullanıcıdan detay bekleniyor — ufak fonksiyonel hata #1 | Medium | *Pending* | *Pending* | *Pending* | *Pending* | Open |
| BUG-002 | *TBD* | Kullanıcıdan detay bekleniyor — ufak fonksiyonel hata #2 | Medium | *Pending* | *Pending* | *Pending* | *Pending* | Open |
| BUG-003 | *TBD* | Kullanıcıdan detay bekleniyor — ufak fonksiyonel hata #3 | Low–Medium | *Pending* | *Pending* | *Pending* | *Pending* | Open |
| SETUP-001 | Auth | `auth_user_id` null → membership unavailable mesajı | Medium | Login doctor-a before link | Dashboard | Türkçe üyelik hatası | `UPDATE profiles SET auth_user_id = …` | **Resolved** |

**First Trial Bugfix Batch v1 kapsam kuralı:** Yalnız **onaylı** BUG-* maddeleri; yeni feature yok; UI polish bu batch’te değil.

---

## 9. Remote Trial Polish Batch v1 — UI/UX aday liste

| ID | Screen | Issue | Impact | Suggested polish | Priority |
|----|--------|-------|--------|------------------|----------|
| UX-001 | *Genel* | Observed by user; details pending | Medium | Kullanıcı notu + ekran görüntüsü sonrası | P2 |
| UX-002 | *Genel* | Observed by user; details pending | Medium | Layout/spacing tutarlılığı | P2 |
| UX-003 | *Genel* | Observed by user; details pending | Low–Medium | Responsive / Windows desktop | P3 |
| UX-004 | Dashboard | Observed by user; details pending | Medium | Kart yoğunluğu, boş durum metinleri | P2 |
| UX-005 | *TBD* | Kullanıcıdan detay bekleniyor | Low | Mikro metin / hizalama | P3 |

**Remote Trial Polish Batch v1 kapsam kuralı:** Görsel/UX only; RLS/migration/repository değişikliği yok.

---

## 10. Eksik / kapsam dışı modüller (v1 bilinçli sınırlar)

Aşağıdakiler **tam ürün olgunluğunda değildir** — staging trial bunları Fail saymaz; **kapsam dışı** olarak işaretlenir:

| Modül | v1 durumu |
|-------|-----------|
| Gerçek dosya upload/download | Yok — metadata only |
| Supabase Storage private bucket + signed URL | Plan aşaması |
| PDF generate / download / refactor | Metadata only |
| Realtime role-filtered refresh | Plan aşaması |
| Demo / freemium / subscription enforcement | Plan aşaması |
| Inventory / Stok remote tam geçiş | Kısmi / nurse mock ağırlıklı — tam remote doğrulanmadı |
| Online consultation | Kapsam dışı veya minimal |
| Advanced audit event write integration | Tasarım/plan; timeline audit log değil |
| Analyzer warning/info cleanup (228 issue) | Ertelendi |
| Windows desktop final responsive polish | Polish batch |

---

## 11. Sonraki aksiyon planı (önerilen sıra)

| # | Paket | Amaç |
|---|--------|------|
| 1 | **First Trial Bugfix Batch v1** | Onaylı küçük hatalar; High/Medium bugfix only |
| 2 | **Remote Trial Polish Batch v1** | UI/UX (UX-001…) — detay: [ui_ux_restructure_design_spec_v1.md](ui_ux_restructure_design_spec_v1.md) |
| 3 | Storage Upload/Download + Signed URL Plan v1 | |
| 4 | PDF Generate/Download Remote v1 | |
| 5 | Inventory/Stok Remote Transition v1 | |
| 6 | Audit Event Write Integration v1 | |
| 7 | Realtime Role-Filtered Refresh Plan v1 | |
| 8 | Demo/Freemium/Subscription Plan v1 | |
| 9 | Windows Desktop Responsive Polish v1 | |
| 10 | Analyzer Warning/Info Cleanup | **En son** |

**Paralel QA (sign-off öncesi önerilir):**

- [ ] [supabase_rls_manual_smoke_v1.md](supabase_rls_manual_smoke_v1.md) — authenticated JWT, evidence sakla  
- [ ] [remote_manual_smoke_test_checklist_v1.md](remote_manual_smoke_test_checklist_v1.md) — tüm hedef roller  
- [ ] Demo Auth: assistant-a, physio-a, nurse-a, doctor-b `auth_user_id` bağla  

**Critical Fail çıkarsa:** Security Hotfix → RLS/Projection Hotfix → Role Permission Hotfix → Cache Isolation (bkz. first full trial §13).

---

## 12. First Trial Bugfix Batch v1 — Cursor komut taslağı

Aşağıdaki metni bir sonraki Cursor oturumunda paket isteği olarak kullanın:

```text
Şimdi sadece “First Trial Bugfix Batch v1” paketini yap.

Kapsam:
- Yalnız docs/staging_trial_report_v1.md içindeki ONAYLI bug’lar (BUG-001… kullanıcı detayı doldurulduktan sonra).
- SETUP-001 çözüldü; tekrar implemente etme.
- Yeni feature, migration, RLS policy, route/permission genişletmesi YOK.
- UI/UX polish YOK (Remote Trial Polish Batch v1 ayrı).

Önce kullanıcıdan BUG-001… için: ekran, rol, repro adımları, expected/actual alın.
Critical/High güvenlik Fail varsa bu paketi durdur; Security Hotfix öncelikli.

flutter analyze → 0 error korunmalı.
```

---

## 13. Statik analiz (rapor oturumu)

| Komut | Sonuç | Tarih |
|-------|--------|-------|
| `flutter analyze` | **0 error**, **228** info/warning | 2026-05-24 |

Warning/info **temizlenmedi** (bilinçli — ayrı hygiene paketi).

---

## 14. QA tamamlama — staging trial sonrası

- [x] Canlı staging denemesi yapıldı (kullanıcı bildirimi)  
- [x] **Staging Trial Report v1** oluşturuldu  
- [ ] Tüm SMK-* checklist Pass/Fail  
- [ ] RLS-* authenticated smoke + evidence  
- [ ] BUG-001… kullanıcı detayları dolduruldu  
- [ ] UX-001… ekran bazlı detay + screenshot  
- [ ] First Trial Bugfix Batch v1 başlatıldı  

---

## 15. Karar özeti (tek satır)

**Conditional Go for continued internal/staging testing** — majör blokaj bildirilmedi; küçük hatalar ve UI/UX iyileştirmesi ayrı batch’lerde; güvenlik ve çoklu rol smoke **Needs Evidence**; **production / satış / demo sign-off değildir**.

---

*Bu rapor kod, migration, RLS, repository, provider, UI veya route değiştirmez.*
