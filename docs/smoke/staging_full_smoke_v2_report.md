# Staging Full Smoke v2 — Rapor (Operatör Sonuçları)

| Alan | Değer |
|------|--------|
| Paket | Staging Full Smoke v2 |
| Tarih | 2026-05-28 |
| Ortam | `DATA_BACKEND=supabase`, `secrets/staging.json`, Windows desktop |
| Kanıt | `screenshots/staging_full_smoke_v2/` (operatör ekleyebilir) |
| Önceki | [staging_trial_result_report_v1.md](../staging_trial_result_report_v1.md) |

## Genel karar

| Karar | **Blocked** (v2 FTR + operasyonel remote paketler) |
|-------|-----------------------------------------------------|
| Gerekçe | FTR yönlendirme listesi yüklenmiyor → FTR v2 delta doğrulanamadı; ödeme/onam/stok remote yüklemeleri kırık; PDF create/open kısmen kırık |
| Sınırlı devam | Hasta/randevu/temel muayene + rol sınırları kısmen kullanılabilir; **production / satış sign-off yok** |

| Metrik | Sayı |
|--------|------|
| P0 | 0 |
| P1 | 8 |
| P2 | 5 |

---

## 1. Ortam doğrulama

| Kontrol | Sonuç | Not |
|---------|--------|-----|
| Staging build + login | **Geçti** | Oturum açılabildi |
| Aktif tenant / rol etiketi | **Geçti** (varsayılan) | Detay kanıt operatörde |
| Sidebar / dashboard rol uyumu | **Geçti** (kısmi) | Operasyonel modüllerde yükleme hataları |
| Teknik id / ham URL UI | **Geçti** | PDF storage sızıntısı yok (v1 ile uyumlu) |

---

## 2. Doktor smoke

### 2.1 Hasta

| Madde | Sonuç | Not |
|-------|--------|-----|
| Yeni hasta / detay / düzenle / liste güncelleme | **Geçti** | v1 ile uyumlu |
| Teknik id görünmez | **Geçti** | |
| TC/telefon maskeleme | **Kaldı** | Doğrulanmadı |

### 2.2 Randevu

| Madde | Sonuç | Not |
|-------|--------|-----|
| Yeni randevu, patientId lock, FTR prefill | **Geçti** | |
| Detay, Muayene Başlat, planlandı→geldi | **Geçti** | |

### 2.3 Muayene

| Madde | Sonuç | Not |
|-------|--------|-----|
| Create / detay / hasta bandı | **Kısmen geçti** | Hasta bandı **çift** görünüyor → SMK-v2-002 |
| `internalDoctorNote` yalnız doktor | **Geçti** | |
| Liste + hasta detay clinical rows stale | **Kısmen geçti** | Etiket ve renk kodu **çift bilgilendirme** → SMK-v2-003 |
| FTR flag / encounter bridge | **Kaldı** | “Yönlendirmeler yüklenemedi…” → SMK-v2-001 |

### 2.4 PDF

| Madde | Sonuç | Not |
|-------|--------|-----|
| Hasta / muayene / randevu / FTR referral PDF | **Kaldı** | Muayene: kaynak bulunamadı; Hasta: kaydedilemedi; Randevu: yok; FTR: yönlendirme listesi yok → SMK-v2-004, SMK-v2-005 |
| Liste / detay / Aç / signed URL | **Kısmen geçti** | Liste + detay OK; **Aç** hata; signed URL belirsiz → SMK-v2-006 |
| storage_path / signed_url / public_url UI’da yok | **Geçti** | |

### 2.5 Ödeme / Onam / Stok

| Madde | Sonuç | Not |
|-------|--------|-----|
| Create + list + detay (ödeme, onam) | **Kaldı** | Ödeme yüklenemedi; onam hasta listesi hatalı; onam kayıtları yüklenemedi → SMK-v2-007, SMK-v2-008 |
| Stok item + hareket + miktar | **Kaldı** | Liste yok; yeni kayıt yapılamıyor → SMK-v2-009 |

### 2.6 FTR (v2 odak)

| Madde | Sonuç | Not |
|-------|--------|-----|
| FTR yönlendirme oluştur | **Kaldı** | Remote referral listesi erişilemiyor |
| Referral detail, FTR randevu CTA | **Kaldı** | Yönlendirmeler yüklenemedi |
| Seans oluştur (remote v2) | **Kaldı** | Hasta listesi yok (bağımlı akış) |
| Seans liste / detay | **Kaldı** | Liste yok |
| Status bridge | **Kaldı** | Seans oluşturulamadı |
| Hasta detay rehab + son seans | **Kaldı** | Referral/session verisi yok |
| PDF referral lookup | **Kaldırıldı** | Bağımlı modül kırık |

**Doktor özeti:** **Partial** — çekirdek hasta/randevu OK; muayene UX sorunları; FTR/operasyonel remote **Blocked**

---

## 3. Asistan smoke

| Madde | Sonuç | Not |
|-------|--------|-----|
| Dashboard operasyon | **Geçti** | |
| Hasta list/detay, randevu, FTR randevu | **Geçti** | Randevu detayda “randevu oluştur?” gereksiz his → SMK-v2-013 (P2) |
| Ödeme / onam / dosya | **Kaldı** | Ödeme sidebar’da yok / kaydedilemiyor; onam sidebar yok; onam hataları doktor ile aynı → SMK-v2-007, SMK-v2-008 |
| Full CE yok | **Geçti** | |
| `internalDoctorNote` yok | **Geçti** | |
| FTR referral route yok | **Geçti** | |
| Rehabilitasyon Özeti yok | **Geçti** | |
| Timeline / audit yok | **Geçti** | |

**Asistan özeti:** **Partial**

---

## 4. Fizyoterapist smoke

| Madde | Sonuç | Not |
|-------|--------|-----|
| Dashboard “Yeni yönlendirmeler” KPI | **Belirsiz** | Doktor yönlendirme oluşturamıyor → KPI doğrulanamadı |
| Referral list/detail, status | **Kaldı** | Yönlendirmeler yüklenemedi; filtrede **overflow** → SMK-v2-001, SMK-v2-010 |
| Session create/list/detail | **Belirsiz** | Hasta listesi yok |
| Referral lookup form | **Belirsiz** | |
| Exercise mock | **Geçti** | |
| Full CE / internalDoctorNote yok | **Geçti** | |
| Hasta detay route yok | **Geçti** | |
| Appointment / PDF create | **Ürün uyumsuzluğu** | Operatör: ikisinin de olması gerekir; mevcut karar: yok → SMK-v2-011 (ürün backlog) |

**Fizyoterapist özeti:** **Partial / Blocked** (FTR remote)

---

## 5. Hemşire smoke

| Madde | Sonuç | Not |
|-------|--------|-----|
| Dashboard stok/sarf, KPI | **Geçti** | |
| Stok list/detail/create/movement | **Kaldı** | Liste görüntülenemiyor; item oluşturulamıyor → SMK-v2-009 |
| Hasta temel sınırlar | **Geçti** | |
| Ödeme/onam/CE/FTR/PDF/timeline yok | **Geçti** | |

**Hemşire özeti:** **Partial**

---

## 6. Cross-tenant / RLS negatif

| Madde | Sonuç | Not |
|-------|--------|-----|
| Tenant B hastası A’da görünmez | **Bekliyor** | Bu oturumda koşulmadı |
| Tenant B dosyası açılmaz | **Bekliyor** | |
| payment/consent/inventory/FTR/session | **Bekliyor** | FTR önce yüklenmeli |
| Cross-tenant insert reddi | **Bekliyor** | |
| Public URL / signed URL TTL | **Bekliyor** | PDF Aç kısmen kırık |

**Cross-tenant özeti:** **Bekliyor**

---

## 7. Refresh / stale

| Madde | Sonuç | Not |
|-------|--------|-----|
| create → list/detail güncel | **Bekliyor** | Modüller kırıkken anlamlı değil |
| Dashboard KPI güncel | **Bekliyor** | |
| Tenant switch | **Bekliyor** | |
| FTR referral + session stale | **Bekliyor** | |

---

## 8. UI/UX notları

| Rol | Gözlem |
|-----|--------|
| Doktor | Muayene formu yorucu (UX-CE-001); çift hasta bandı / çift etiket |
| Asistan | Gereksiz randevu CTA; ödeme durumu alanı gereksiz (miktarla otomatik olabilir) → SMK-v2-012 |
| Fizyoterapist | Referral filtre overflow |
| Genel | **Çıkışta oturum kapatma onayı** isteniyor → SMK-v2-014; **muayene otomatik kaydet** önerisi → SMK-v2-015 |

---

## 9. P0 / P1 / P2 bulgu tablosu

### P0

*Bu oturumda P0 (veri sızıntısı, cross-tenant açık, crash, yetkisiz internal note) bildirilmedi.*

### P1

| ID | Başlık | Rol | Ekran | Şiddet | Öneri |
|----|--------|-----|-------|--------|--------|
| **SMK-v2-001** | FTR yönlendirmeler yüklenemiyor | Doktor, Fizyoterapist | `/physiotherapy/referrals` | P1 | Staging: migration/RLS/tenant gate; `PhysiotherapyReferralRepository` hata log; Supabase policy + JWT `tenant_id` |
| **SMK-v2-002** | Muayene detayda çift hasta bandı | Doktor | Muayene detay | P1 | UI: tek `DetailHeaderCard` veya bandı kaldır |
| **SMK-v2-003** | Clinical rows çift etiket/renk | Doktor | Hasta detay muayene listesi | P1 | Chip/Status tek kaynak |
| **SMK-v2-004** | PDF muayene kaynağı bulunamıyor | Doktor | PDF form | P1 | Encounter id lookup / remote mapper |
| **SMK-v2-005** | PDF hasta kaydı kaydedilemiyor | Doktor | PDF form | P1 | Insert RLS + validation |
| **SMK-v2-006** | PDF Aç hatası | Doktor | PDF detay | P1 | Signed URL servis + storage bucket staging |
| **SMK-v2-007** | Ödeme kayıtları yüklenemiyor | Doktor, Asistan | Ödeme listesi | P1 | Remote payment repo + RLS |
| **SMK-v2-008** | Onam kayıtları / hasta listesi hatalı | Doktor, Asistan | Onam form/list | P1 | Consent repo + patient lookup |
| **SMK-v2-009** | Stok listesi / yeni kayıt çalışmıyor | Doktor, Hemşire | Stok | P1 | Inventory remote + INSERT policy |

### P2

| ID | Başlık | Not |
|----|--------|-----|
| **SMK-v2-010** | FTR referral filtre overflow | Fizyoterapist liste |
| **SMK-v2-011** | Fizyoterapist randevu/PDF create yok (ürün beklentisi) | Ürün kararı vs operatör beklentisi — backlog |
| **SMK-v2-012** | Ödeme durumu manuel seçim gereksiz | Miktar → durum türet |
| **SMK-v2-013** | Randevu detayda gereksiz “randevu oluştur” | Asistan UX |
| **SMK-v2-014** | Çıkışta oturum kapat onayı | Operatör isteği |
| **SMK-v2-015** | Muayene otomatik kaydet | Operatör isteği |
| UX-CE-001 | Muayene ergonomisi | v1’den açık |
| OPS-AUTH-001 | Staging auth bootstrap | v1’den risk |

### Kök neden hipotezi (triyaj)

Çoklu “yüklenemedi” hataları **ortak tenant/RLS veya remote repository gate** işaret ediyor:

1. Aktif `tenant_id` / `profile_id` JWT veya `ActiveTenantContextStore`  
2. Staging’de ilgili migration’ların uygulanmaması (`physiotherapy_referrals`, `payments`, `consents`, `inventory`, …)  
3. `PhysiotherapyReferralRepositoryBackendGate` / session readiness false  

**İlk düzeltme paketi önerisi:** **Staging Remote Load Diagnostics v1** — tek doktor oturumunda Supabase network + repository failure reason surfaced (debug banner) + referral/payment/consent/inventory SQL smoke.

---

## 10. Sonuç ve sonraki adımlar

| Soru | Cevap |
|------|--------|
| v2 FTR delta doğrulandı mı? | **Hayır** |
| v1 Conditional Go hâlâ geçerli mi? | **Hayır** — operasyonel remote regresyon |
| Production Go? | **Hayır** |
| **Karar** | **Blocked** (FTR + operasyonel remote); sınırlı hasta/randevu demo |

| Öncelik | Paket |
|---------|--------|
| 1 | Staging FTR referral load fix (SMK-v2-001) |
| 2 | Operational remote load fix — payment, consent, inventory (SMK-v2-007–009) |
| 3 | PDF create/open fix (SMK-v2-004–006) |
| 4 | CE duplicate UI (SMK-v2-002, 003) |
| 5 | Cross-tenant smoke tekrarı (§6) |

---

*Operatör notları bu rapora işlendi. Secret ve şifre repoda tutulmaz.*
