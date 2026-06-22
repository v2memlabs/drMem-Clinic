# Staging Trial Result Report v1

> **Paket türü:** Ürün / QA — canlı staging gerçek veri girişi sonuç raporu (dokümantasyon only)  
> **Kod / migration / test:** Yok (bu pakette)  
> **Önceki:** [staging_trial_workbook_v1.md](staging_trial_workbook_v1.md), [staging_trial_report_v1.md](staging_trial_report_v1.md)  
> **Üretim:** 2026-05-28  
> **Trial kararı:** **Conditional Go / Practical Pass**

| Alan | Değer |
|------|--------|
| Trial ID | `STAGING-TRIAL-RESULT-v1` |
| Ortam | Supabase staging (`drmem-clinic-dev` / `dgzmybbgrofapjptjspf`, eu-central-1) |
| İstemci | Flutter Windows desktop, `DATA_BACKEND=supabase`, `secrets/staging.json` (local) |
| Operatör | İç ekip (kullanıcı bildirimi) |
| Auth düzeltmeleri | Auth Context Helper Hotfix v1 + aktif tenant mock ezilmesi giderildi (oturum sırasında) |

---

## 1. Özet karar

| Boyut | Sonuç |
|-------|--------|
| **Genel** | **Conditional Go / Practical Pass** |
| **Gerçek veri girişi** | Ana varlıklar oluşturulabildi; listeler ve detaylar oturum düzeltmesi sonrası yüklendi |
| **Rol güvenliği** | Doktor / asistan / FTR / hemşire sınırları pratikte doğrulandı |
| **PDF / storage** | UI sızıntısı yok; signed URL TTL ve cross-tenant negatif geçti |
| **P0** | **Yok** |
| **Production / satış sign-off** | **Hayır** — dahili staging ve sınırlı QA için yeterli |

**Conditional Go gerekçesi (kısa):** Kritik auth/bootstrap ve tenant bağlamı sorunları giderildi; çekirdek create + list + rol/PDF güvenlik kontrolleri operatör tarafından geçildi. Tam otomatik test arşivi, PDF liste ekranının remote bağlantısı ve üretim operasyonları bu raporun kapsamı dışında veya sonraki fazda.

---

## 2. Ortam ve kapsam

### 2.1 Ortam

| Öğe | Durum |
|-----|--------|
| Backend | `DATA_BACKEND=supabase` |
| Supabase init | Başarılı (`Supabase init completed`) |
| Platform | Windows desktop |
| Veri | Seed + trial sırasında girilen gerçek kayıtlar (prod değil) |
| `service_role` istemcide | Kullanılmıyor (beklenen) |

### 2.2 Kapsam dahil

- Hasta, randevu, muayene, dosya/PDF, ödeme, onam, stok create akışları  
- Rol bazlı erişim (doktor, asistan, FTR, hemşire)  
- PDF/storage güvenlik spot (UI, public URL, signed URL TTL, cross-tenant)  
- Genel UI stabilitesi (overflow, kırmızı ekran, bariz metin hatası)

### 2.3 Kapsam dışı (bu rapor)

| Madde | Not |
|-------|-----|
| Kod değişikliği / migration / RLS değişikliği | Bu pakette yok |
| Otomatik `flutter test` arşivi | Ayrı CI / regresyon |
| Tam SMK / RLS checklist arşivi (`evidence/rls/*.json`) | Kısmi — operatör Pass bildirimi |
| Üretim onboarding, faturalama, SLA | Ürün fazı değil |
| UI redesign | Yalnız P1 ergonomi notu |

---

## 3. Auth / bootstrap düzeltme notu

| Olay | Sonuç |
|------|--------|
| **Auth Context Helper Hotfix v1** | `current_profile_id()` / `current_tenant_id()` JWT claim yerine `profiles` + `memberships` — login/bootstrap **çözüldü** |
| **İlk belirti** | “Bu kullanıcı için aktif klinik üyeliği bulunamadı” (JWT `profile_id` eksik) |
| **Hotfix sonrası** | `doctor-a@example.test` giriş **tamam** |
| **Liste/detay regression** | Oturumda aktif tenant’ın mock `tenant-demo-1` ile ezilmesi; Supabase sorguları boş dönüyordu (“bulunamadı”) |
| **Tenant bağlam düzeltmesi** | Supabase modunda `MockTenantContextBridge` artık gerçek tenant’ı ezmiyor; **yeniden giriş sonrası listeler düzeldi** |

**Operatör notu:** Hotfix + tenant bağlam düzeltmesinden sonra tam uygulama yeniden başlatma ve çıkış/giriş önerilir.

---

## 4. Veri giriş sonucu

| Varlık | Create | Liste / detay | Sonuç |
|--------|--------|---------------|--------|
| Hasta | ✓ | ✓ (düzeltme sonrası) | **Pass** |
| Randevu | ✓ | ✓ | **Pass** |
| Muayene (clinical encounter) | ✓ | ✓ (doktor) | **Pass** |
| Dosya / PDF | ✓ | Metadata / görüntüleme | **Pass** |
| Ödeme | ✓ | — | **Pass** |
| Onam | ✓ | — | **Pass** |
| Stok | ✓ | — | **Pass** |

**Operatör özeti:** “Takılmadı” — ana akışlar staging’de sorunsuz tamamlandı.

---

## 5. Rol bazlı güvenlik sonucu

| Rol | Beklenen sınır | Gözlem | Sonuç |
|-----|----------------|--------|--------|
| **Doktor / Admin** | Tam klinik + dosya + PDF | Create + list; full muayene | **Pass** |
| **Asistan** | Full muayene yok; `internalDoctorNote` yok | Full CE detayına giremiyor; not görünmüyor; randevu / onam / ödeme / dosya akışları çalışıyor | **Pass** |
| **Fizyoterapist** | Full CE yok; safe summary | Full encounter görmüyor; FTR özet sınırında | **Pass** |
| **Hemşire** | Stok/sarf odaklı | Hasta / full clinical / timeline / dosya erişimi yok | **Pass** |

> **Kanıt türü:** Manuel UI walkthrough (operatör bildirimi). Arşivlenmiş JWT/RLS JSON seti bu raporda zorunlu değil; production sign-off için ayrıca önerilir.

---

## 6. PDF / storage güvenlik sonucu

| Kontrol | Beklenen | Sonuç |
|---------|----------|--------|
| `storage_path` UI’da | Görünmez | Görünmüyor | **Pass** |
| `signed_url` UI’da | Görünmez | Görünmüyor | **Pass** |
| `public_url` UI’da | Görünmez | Görünmüyor | **Pass** |
| Public URL ile dosya açma | Çalışmamalı | Açmıyor | **Pass** |
| Signed URL ile açma | Çalışmalı | Açıyor | **Pass** |
| Signed URL ~121 sn sonra | Geçersiz | Eski URL çalışmıyor | **Pass** |
| Cross-tenant (Tenant A ↔ B) | Dosya görünmez / açılmaz | Görünmüyor / açılmıyor | **Pass** |

**İlgili:** [pdf_storage_staging_smoke_v1_report.md](smoke/pdf_storage_staging_smoke_v1_report.md), [scripts/staging/pdf_storage_smoke_checks.sql](../scripts/staging/pdf_storage_smoke_checks.sql)

---

## 7. UI / UX gözlemleri

| Gözlem | Şiddet | Not |
|--------|--------|-----|
| Muayene ekranı veri girişi yorucu | **P1 adayı** | Fonksiyonel hata değil; ergonomi |
| Overflow / fazla kart-chip | Yok | — |
| Hatalı metin / kırmızı ekran | Yok | — |
| Genel stabilite | İyi | Operatör: akış takılmadı |

---

## 8. P0 / P1 / P2 bulgular

| ID | Şiddet | Başlık | Durum | Aksiyon |
|----|--------|--------|-------|---------|
| — | **P0** | — | **Yok** | — |
| UX-CE-001 | **P1** | Muayene veri giriş ergonomisi | Açık | Clinical Encounter Data Entry Ergonomics v1 |
| — | **P2** | — | Trial’da bildirilmedi | Backlog |

---

## 9. Conditional Go gerekçesi (detay)

| Kriter | Durum |
|--------|--------|
| Auth + aktif tenant | Geçti (hotfix + tenant bağlam) |
| Çekirdek CRUD create | Geçti |
| Liste/detay (düzeltme sonrası) | Geçti |
| Rol sınırları | Pratikte geçti |
| PDF/storage güvenlik spot | Geçti |
| P0 güvenlik | Yok |
| Tam otomasyon / prod hazırlık | Tamamlanmadı |

**Sonuç:** Dahili staging, demo ve sınırlı pilot kullanım için **devam edilebilir**. Müşteri prodüksiyonu veya “satılabilir SaaS” onayı **verilmez**.

---

## 10. Kalan riskler

| Risk | Etki | Azaltma |
|------|------|---------|
| Manuel auth `profiles.auth_user_id` bağlama | Yeni staging kullanıcıda login hatası | Maintenance / Bootstrap Console v1 |
| RLS kanıtı arşivlenmedi | Regülasyon / audit zayıf | `supabase_rls_manual_smoke_v1` + `evidence/rls/` |
| PDF çıktı **listesi** mock repo | Remote PDF listesi boş görünebilir | Ayrı paket: listeyi Supabase’e bağlama |
| Ayarlar → klinik adı (Supabase) | Yalnız local prefs; tenant adı DB’den | İleride tenant settings API |
| App / paket adı (`muayenehane_*`) | Marka / store tutarsızlığı | App / Package Rename Audit v1 |
| Muayene UX | Operatör yorgunluğu, hata riski | CE Data Entry Ergonomics v1 |

---

## 11. Sonraki yol haritası

| Öncelik | Paket | Amaç |
|---------|--------|------|
| 1 | **Maintenance / Bootstrap Console v1** | Staging auth bağlama, membership, tenant seçimi — manuel SQL azaltma |
| 2 | **App / Package Rename Audit v1** | `DrMem Clinic` marka ile kod/paket adı uyumu |
| 3 | **Clinical Encounter Data Entry Ergonomics v1** | P1 — muayene formu akışı, alan gruplama, klavye/scroll |
| Opsiyonel | PDF list remote bağlantısı | Create sonrası listede görünürlük |
| Opsiyonel | RLS evidence batch | JWT negatif test arşivi |

---

## 12. Karar özeti (tek tablo)

| Soru | Cevap |
|------|--------|
| Staging’de gerçek veri girişi yapıldı mı? | **Evet** |
| Login/bootstrap çalışıyor mu? | **Evet** (hotfix + tenant düzeltmesi sonrası) |
| Rol güvenliği pratikte OK mi? | **Evet** |
| PDF/storage spot OK mi? | **Evet** |
| P0 var mı? | **Hayır** |
| Production Go mu? | **Hayır** |
| **Trial kararı** | **Conditional Go / Practical Pass** |

---

*Bu rapor operatör bildirimi ve oturum içi düzeltme notlarına dayanır. Secret, şifre ve `service_role` değerleri repoda tutulmaz.*
