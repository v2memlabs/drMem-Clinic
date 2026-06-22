# UI/UX Restructure Design Spec v1

> **Paket türü:** Tasarım spesifikasyonu / bilgi mimarisi / wireframe (dokümantasyon only).  
> **Üretim tarihi:** 2026-05-24  
> **Kaynak:** Canlı staging/manual deneme + kullanıcı ürün kararları ([staging_trial_report_v1.md](staging_trial_report_v1.md)).  
> **Kod değişikliği:** Yok (bu pakette).

| İlgili doküman | Rol |
|----------------|-----|
| [staging_trial_report_v1.md](staging_trial_report_v1.md) | Canlı trial özeti, UX-001… placeholder |
| [first_full_app_trial_v1_report.md](first_full_app_trial_v1_report.md) | Rol/güvenlik sınırları |
| [role_navigation_permission_matrix_v1.md](role_navigation_permission_matrix_v1.md) | Route visibility (implementasyonda korunacak) |

**Mevcut kod referansı (bilgi amaçlı, değiştirilmedi):**

- Ayarlar: `lib/features/settings/settings_screen.dart` — Profil, Klinik, Demo, SaaS kartları tek sayfada
- Sidebar: `lib/core/navigation/app_nav_config.dart` — Timeline, Etiketler, Arşiv, Klinik Uyarılar vb.

---

## Canlı Deneme Sonrası UI/UX Bulguları

Kullanıcı canlı staging denemesi ve önceki sürüm karşılaştırmasına dayanır ([staging_trial_report_v1.md](staging_trial_report_v1.md) §9 UX-001…).

| # | Bulgu | Etki |
|---|--------|------|
| 1 | **Ayarlar ekranı boş ve eksik** — kategori yapısı yok; profil/klinik/demo dağınık tek kolon | Yapılandırma zor; SaaS/demo bilgisi gömülü |
| 2 | **Demo / Kullanım Durumu** ve **SaaS / Abonelik Bilgisi** korunmalı; doğru IA’ya taşınmalı | Mevcut `_DemoUsageCard`, `_SaasInfoCard` mantığı kaybolmamalı |
| 3 | **Sidebar** gereksiz/dummy/legacy öğeler içeriyor (Timeline global, Arşiv bölümü, Klinik Uyarılar, Hasta Etiketleri) | Navigasyon gürültüsü |
| 4 | **Önceki UI daha sade** algısı — yeni sürümde kart yoğunluğu arttı | Bilişsel yük |
| 5 | **Tutarsız gradient kart başlıkları** detay/form ekranlarında göz yoruyor | Okunabilirlik düşük |
| 6 | **Hasta liste** fazla büyük satırlar; kompakt tablo-liste ihtiyacı | Desktop verimsizliği |
| 7 | **Hasta temel bilgiler** eksik alanlar (uyruk, kimlik tipi, kan grubu, acil kişi vb.) | Klinik kayıt tamamlanamıyor |
| 8 | **Muayene detay/form** yeniden yapılandırılmalı — 7 bölüm, tek yüzey | Veri girişi yavaş |
| 9 | **Yeni muayene kaydı** yeterince görünür değil | İş akışı kesintisi |
| 10 | **Hasta seçiliyken** bazı formlar “hasta ismi giriniz” uyarısı | Bug — BUG-UX-003 |
| 11 | **Muayene kayıtları filtreleri** — başvuru tipi/durum overflow | Bug — BUG-UX-004 |
| 12 | **Auth kurulumu** (`auth_user_id`) staging sürtünmesi — UI değil; onboarding | SETUP-001 (çözüldü) |

**Genel ürün durumu:** Denenebilir MVP; UI polish ve IA ayrı implementation paketlerinde.

---

## Global UI/UX Prensipleri

### Ürün tonu

- **Premium, sade, klinik, hızlı veri girişi** odaklı.
- Gereksiz süsleme yok; içerik öncelikli.

### Yüzey ve kart

| Prensip | Karar |
|---------|--------|
| Kart yoğunluğu | Detay/veri girişinde **az kart**; mümkünse **tek ana yüzey** + ince `Divider` / section başlığı |
| Gradient | **Yalnız login ekranı + sidebar** (app shell). Detay/form/liste kart başlıklarında gradient **yok** |
| Kart başlıkları | **Sade, düz, uniform** — `titleSmall` + ikon opsiyonel; gradient şerit yok |
| Okunabilirlik | Uzun klinik metinlerde satır aralığı ve section spacing tutarlı |

### Platform

| Prensip | Karar |
|---------|--------|
| Desktop/tablet | Veri yoğun ekranlarda **öncelik** (tablo-liste hibrit, geniş form) |
| Mobil | Responsive korunur; hasta liste **2–3 satır** kompakt kart |
| Rol güvenliği | `AuthRoutePermissions` / session gate **değişmez**; IA sadeleşmesi yetkiyi genişletmez |

### Referans koruma

| Prensip | Karar |
|---------|--------|
| **Login ekranı** | **Bozulmayacak** — mevcut layout, sol kart gradient, tipografi referans alınır |
| Sidebar renk | Login **sol kart ile aynı renk/gradient ailesi**; uygulama `AppShell` içinde |

### Ürün dili

| Eski / teknik | Yeni UI etiketi |
|---------------|-----------------|
| `doctor_admin` / doctor/admin | **Doktor** |
| İç Klinik Not (kullanıcıya) | **Özel Not** (backend: `internalDoctorNote` — güvenlik aynı) |

---

## Ayarlar IA: Kategori Kartları + Alt Sayfalar

### Geçiş modeli

**Şimdi:** Tek `SettingsScreen` — yan yana/alt alta kartlar (`_ProfileCard`, `_ClinicCard`, `_DemoUsageCard`, `_SaasInfoCard`, …).

**Hedef:** Ayarlar **hub** → kategori **kart ızgarası** → her kategori **alt sayfa** (tam genişlik form/liste).

```
┌─────────────────────────────────────────────────────────────┐
│  Ayarlar                                    [Klinik adı?]   │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │ Profil       │ │ Klinik       │ │ Görünüm      │  ...   │
│  │ Bilgileri    │ │ Bilgileri    │ │ ve Bölge     │        │
│  └──────────────┘ └──────────────┘ └──────────────┘        │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │ Klinik       │ │ Hasta        │ │ Kullanıcılar │        │
│  │ İşleyiş      │ │ Ayarları     │ │ ve Roller *  │        │
│  └──────────────┘ └──────────────┘ └──────────────┘        │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │ Sistem ve    │ │ Demo /       │ │ SaaS /       │        │
│  │ Güvenlik     │ │ Kullanım     │ │ Abonelik     │        │
│  └──────────────┘ └──────────────┘ └──────────────┘        │
│  * Yalnız Doktor / sistem yöneticisi                        │
└─────────────────────────────────────────────────────────────┘
        │ tap
        ▼
┌─────────────────────────────────────────────────────────────┐
│  ← Ayarlar    Profil Bilgileri                              │
├─────────────────────────────────────────────────────────────┤
│  [avatar]  Fotoğraf yükle / değiştir                        │
│  Ad, Soyad, Ünvan, E-posta, Telefon                         │
│  Oturum / şifre (ileride)                                   │
│                                    [Kaydet]                 │
└─────────────────────────────────────────────────────────────┘
```

### Ana kategori kartları

| Kart | Alt sayfa içeriği | Rol |
|------|-------------------|-----|
| **Profil Bilgileri** | Fotoğraf, ad soyad, ünvan, e-posta, telefon; şifre/oturum (ileride) | Tüm giriş yapmış roller (düzenleme kendi profili) |
| **Klinik Bilgileri** | Klinik adı, logo, tabela/fotoğraf, telefon, e-posta, adres, web; PDF üst bilgi önizleme | **Doktor** düzenler; diğerleri salt okunur |
| **Görünüm ve Bölge** | Dil, tarih/saat formatı, para birimi, hafta başlangıcı; tema (ileride) | Doktor + ileride rol bazlı |
| **Klinik İşleyiş** | Çalışma günleri/saatleri, varsayılan randevu süresi, slot aralığı, kapalı tarihler, personel izinleri, çakışma uyarıları | **Doktor** |
| **Hasta Ayarları** | Hasta etiketleri (sidebar’dan), dosya no formatı, kimlik tipi seçenekleri, zorunlu alanlar (ileride) | Doktor; etiket listesi yönetimi |
| **Kullanıcılar ve Roller** | Kullanıcı listesi, rol atama, davet (ileride) | **Yalnız Doktor / sistem yöneticisi** |
| **Sistem ve Güvenlik** | KVKK metinleri, audit bağlantısı, oturum, uygulama sürümü | Doktor ağırlıklı; KVKK tüm roller okuyabilir |
| **Demo / Kullanım Durumu** | Aşağı § Demo mimarisi | Tüm roller (salt okunur alanlar) |
| **SaaS / Abonelik** | Aşağı § SaaS mimarisi | Doktor tam; diğerleri compact özet |

### Profil Bilgileri — alanlar

- Kullanıcı **fotoğrafı** (avatar picker, crop ileride)
- Ad, soyad, ünvan
- E-posta (salt okunur Supabase auth’tan)
- Telefon
- Rol etiketi: **Doktor** / Asistan / Fizyoterapist / Hemşire (teknik `doctor_admin` gösterilmez)

### Klinik Bilgileri — alanlar

- Klinik adı
- **Logo** (kare, PDF/header)
- **Tabela / klinik fotoğrafı** (geniş banner, isteğe bağlı)
- Telefon, e-posta, adres, web sitesi
- “PDF çıktılarında kullanılacak bilgiler” önizleme bloğu

### Klinik İşleyiş — alanlar

| Grup | Alanlar |
|------|---------|
| Mesai | Pazartesi–Pazar açık/kapalı; günlük başlangıç/bitiş |
| Randevu | Varsayılan süre (dk); slot aralığı (dk) |
| Kapalı günler | Tarih listesi + tekrarlayan tatil (ileride) |
| İzinler | Personel/doktor izin tarih aralığı |
| Davranış | Çakışma uyarısı / engelleme politikası (tasarım) |

> Randevu oluşturma UX bu veriyi tüketir (§ Randevu akışı). Implementasyon: **Appointment Availability** paketleri.

### Hasta Ayarları — taşıma

- **Hasta Etiketleri** → `/settings/patient-settings/tags` (veya eşdeğer alt route)
- Sidebar `/patient-tags` **kaldırılır** (doktor/asistan/physio nav’dan)

### Kullanıcılar ve Roller

- Liste: ad, e-posta, rol (**Doktor**, Asistan, …)
- Rol atama / devre dışı (membership status)
- **Assistant/Physio/Nurse bu karta erişemez** — kart hub’da gizli + route guard

---

## Demo, Kullanım Durumu ve SaaS / Abonelik Bilgi Mimarisi

### Demo / Kullanım Durumu — koruma kararı

**Mevcut bölüm kaldırılmaz.** `_DemoUsageCard` içeriği alt sayfaya taşınır.

| Gösterilecek (kullanıcı dostu) | Gösterilmeyecek |
|-------------------------------|-----------------|
| Demo modu aktif/pasif | `tenant_id`, `profile_id`, `auth_user_id` |
| Backend modu: **Mock** / **Supabase** | Anon key, JWT, secret token |
| Aktif klinik adı (tenant display name) | Ham UUID |
| Aktif rol etiketi (**Doktor**, …) | DB rol kodu `doctor_admin` |
| Hasta kaydı sayısı / demo limit | PostgREST hata dump |
| Seed/demo veri uyarısı | Debug console çıktısı |
| Sistem durumu: Bağlı / Mock / Yapılandırılmadı | Internal exception stack |

**Wireframe (alt sayfa):**

```
Demo / Kullanım Durumu
──────────────────────
Mevcut mod          [Demo]
Backend             Supabase
Aktif klinik        DrMem Demo Clinic A
Aktif rol           Doktor
Hasta kaydı         12 / 50
Limit notu          Demo sınırına yaklaşıyorsunuz…
Sistem durumu       ● Bağlı
⚠ Bu ortam demo verisi içerir.
```

### SaaS / Abonelik — koruma kararı

**Ayrı kategori kartı** — `_SaasInfoCard` genişletilir; ödeme implementasyonu **bu fazda yok**.

| Alan | v1 tasarım | İleride |
|------|------------|---------|
| Plan adı | Demo / Starter (placeholder) | Gerçek plan API |
| Kullanıcı / koltuk | 1 / 5 (örnek) | Lisans sayımı |
| Aktif cihaz | — | Cihaz limiti |
| Depolama | 0 / 5 GB (placeholder) | Storage metering |
| Modül kullanımı | Timeline, PDF, AI checkbox özeti | Metering |
| Destek seviyesi | E-posta | SLA tier |
| Faturalama / yenileme | “Planlanan” badge | Stripe vb. |
| SMS / WhatsApp / e-posta kredileri | Liste + “Yakında” | Kontör |
| AI / PDF / paylaşım limitleri | `DemoFreemiumConfig` ile uyumlu liste | Enforcement |

**Ticari omurga:** Bu kart ileride faturalama modülünün UI girişi; şimdilik **read-only + planlanan** badge’ler.

---

## Sidebar Navigation Redesign

### Hedef: sade ana navigasyon (Doktor örneği)

**Kalan / birleştirilen ana öğeler:**

| Öğe | Route (mevcut) | Not |
|-----|----------------|-----|
| Dashboard | `/doctor` | Rol bazlı dashboard |
| Hastalar | `/patients` | |
| Randevular | `/appointments` | |
| Muayene Kayıtları | `/clinical-records` | |
| Fizyoterapi | Mevcut alt menü **korunur** | **Redesign planlanmaz** (kapsam dışı) |
| Stok / Sarf | `/inventory` | |
| Ödemeler | `/payments` | Rol göre |
| Audit / KVKK | `/audit-logs`, `/consents` | **Yalnız Doktor** (mevcut matrix) |
| Ayarlar | `/settings` | Hub |

**Kaldır / taşı:**

| Mevcut sidebar | Karar |
|----------------|--------|
| Hasta Zaman Çizelgesi (`/patient-timeline`) | **Kaldır** — hasta detay sekmesi/aksiyon |
| Hasta Etiketleri (`/patient-tags`) | **Taşı** → Ayarlar > Hasta Ayarları |
| Klinik Uyarılar (`/patient-alerts`) | **Kaldır** — ürün kararı bekler; hasta detayda blok opsiyonel |
| Arşiv bölümü (anamnez, muayene notları, tanı, tedavi planları) | **Kaldır** — legacy/mock; veri Muayene Kayıtlarında |
| Görüntüleme Notları, Dosyalar (opsiyonel) | Doktor için hasta bağlamına veya Muayene altına; sidebar’dan çıkarılabilir (v1.1 karar) |

> **Not:** Assistant/Physio/Nurse nav’ları aynı prensiple sadeleştirilir; Fizyoterapi physio menüsü **olduğu gibi** kalır.

### Sidebar görsel

```
┌──────────────────┐
│ [logo] DrMem     │  ← gradient: login sol kart ile aynı aile
│ Demo Clinic A    │     (AppColors / login theme token)
├──────────────────┤
│ ● Ana Ekran      │
│   Hastalar       │
│   Randevular     │
│   Muayene Kayıtları
│   Fizyoterapi ▾  │  ← mevcut yapı, redesign yok
│   Stok / Sarf    │
│   Ödemeler       │
│   Audit Log      │  ← Doktor
│   Ayarlar        │
└──────────────────┘
```

| Karar | Detay |
|-------|--------|
| Login ekranı | **Değiştirilmez** |
| Sidebar gradient | `AppShell` navigation rail / drawer arka planı |
| Detay sayfaları | Beyaz/gri yüzey; gradient yok |

---

## Hasta Liste: Compact Table/List Hybrid

### Desktop / tablet (≥ ~900px)

```
┌─ A ─ B ─ C ─ ... ─ Z ─┐  ← harf indeksi (soyad ilk harfi)
│                         │
│  SOYAD, Ad    Dosya  Yaş  Telefon      Son ziyaret  Etiket  ⋮
│  YILMAZ, Ali  A-001  42M  05xx…        24.05.2026   VIP     [Detay]
│  KAYA, Ayşe   A-002  35K  …            20.05.2026   —       [Detay]
│  ...                    (hover: hafif arka plan)              │
└─────────────────────────────────────────────────────────────┘
```

| Karar | Detay |
|-------|--------|
| Sıralama | **Soyada göre** alfabetik (locale: tr) |
| Görünen ad | **`SOYAD, Ad`** — soyad BÜYÜK veya semi-bold |
| Satır yüksekliği | ~48–56px; mevcut 4+ satır karttan kaçın |
| Kolonlar | Ad, dosya no, yaş/cinsiyet, telefon, son ziyaret, etiket chip, işlem |
| Arama | Üstte global arama; indeks ile birlikte |
| Seçim | Satır tık → hasta detay |

### Mobil

```
┌─────────────────────────────┐
│ YILMAZ, Ali          A-001  │  ← max 2–3 satır
│ 42M · 05xx… · VIP · 24.05   │
└─────────────────────────────┘
```

---

## Hasta Temel Bilgiler

### Bilgi mimarisi — dört grup

**1. Kimlik Bilgileri**

| Alan | Zorunlu (öneri) |
|------|-----------------|
| Ad | Evet |
| Soyad | Evet |
| Dosya no | Evet (format: Ayarlar > Hasta) |
| Doğum tarihi | Evet |
| Cinsiyet | Evet |
| Uyruk | Evet |
| Kimlik tipi | T.C. / Pasaport / Yabancı kimlik |
| Kimlik no | Tipe göre maskeleme |

**2. İletişim**

- Telefon, ikinci telefon, e-posta, adres, il/ilçe

**3. Klinik / İdari**

- Kan grubu, meslek, spor branşı, hasta etiketi (chip), KVKK/onam durumu

**4. Acil Kişi**

- Ad soyad, yakınlık, telefon, not

### Görünüm

- **Okuma:** tek scroll; section divider (gradient başlık yok)
- **Düzenle:** aynı gruplar; validasyon mesajları alan altında (kırmızı tam ekran bug fix — BUG-UX-001)

### Hasta bağlamı — Timeline

- Sidebar timeline kaldırıldığında: hasta detayda **“Zaman çizelgesi”** sekmesi veya üst aksiyon
- Route: `/patients/:id/timeline` (mevcut `PatientTimelineScreen` bağlamı korunur)
- Rol: yalnız **Doktor** (`canViewPatientTimeline`)

---

## Muayene Detay/Form: 7 Bölümlü Tek Yüzey

### Kaldırılacak / küçültülecek (mevcut UI)

- Büyük hasta + muayene meta **kartı** → ince **kimlik bandı**
- Bölge/taraf/status/son güncelleme/ana şikayet **ayrı geniş kartlar** → band + ilgili section içinde
- Gradient kart başlıkları → **düz section label**

### Üst hasta kimlik bandı (sabit, scroll’da sticky opsiyonel)

```
┌────────────────────────────────────────────────────────────────┐
│ YILMAZ, Ali · A-001 · 42M · 24.05.2026 · Kontrol · Dr. X · [Aktif] │
└────────────────────────────────────────────────────────────────┘
```

### Ana içerik — tek scroll, 7 bölüm

| # | Bölüm | İçerik |
|---|--------|--------|
| 1 | **Şikayet / Hikaye** | Ana şikayet, öykü, süre |
| 2 | **Muayene** | Muayene bulguları, bölge/taraf, durum |
| 3 | **Görüntüleme** | Görüntüleme notları, istek/sonuç özeti |
| 4 | **Ön Tanı / Tanı** | Ön tanı, tanı; **ICD alanı korunur** |
| 5 | **Tedavi Planı** | Yaklaşım: Konservatif / Cerrahi / İzlem; **İlaç**; **Enjeksiyon**; **Ortez**; tedavi notu |
| 6 | **Fizyoterapi / Egzersiz / Kontrol** | FTR notu, egzersiz, kontrol planı (full physio redesign **kapsam dışı**) |
| 7 | **Özel Not** | Yalnız **Doktor** path; backend `internalDoctorNote`; assistant/physio **görmez** |

**Wireframe:**

```
[ Kimlik bandı ]
────────────────────────────────────────
1. Şikayet / Hikaye
   [ multiline fields ]
────────────────────────────────────────
2. Muayene
   ...
────────────────────────────────────────
4. Ön Tanı / Tanı
   ICD-10  [____]  Açıklama [____]
────────────────────────────────────────
5. Tedavi Planı
   ( ) Konservatif  ( ) Cerrahi  ( ) İzlem
   İlaç      [ + ekle ]
   Enjeksiyon [ + ekle ]
   Ortez     [ + ekle ]
   Not [________________]
────────────────────────────────────────
7. Özel Not          🔒 Yalnız Doktor
   [________________]
────────────────────────────────────────
                    [Kaydet] [İptal]
```

### Güvenlik (değişmez)

| Kural | Tasarım |
|-------|---------|
| `internalDoctorNote` | UI etiketi **Özel Not**; yalnız Doktor form/detay |
| Assistant/Physio | Safe summary RPC; full form route yok |
| `clinical_data` ham JSON | UI’da gösterilmez |

---

## Yeni Muayene Kaydı CTA

| Konum | Öğe | Rol |
|-------|-----|-----|
| Muayene Kayıtları listesi | Birincil **“Yeni Muayene Kaydı”** `FilledButton` (üst sağ) | Doktor |
| Hasta detay | **“Yeni Muayene”** outline/tonal | Doktor |
| Dashboard (doktor) | Hızlı aksiyon kartı “Yeni muayene” | Doktor |
| Assistant/Physio/Nurse | CTA **görünmez** | `canViewFullClinicalEncounter` false |

**Bug:** CTA yetersiz görünürlük → BUG-UX-005 (bugfix batch).

---

## Randevu Oluşturma: Takvim + Saat Bloğu Akışı

> **Bu faz:** tasarım/plan only. Veri kaynağı: Ayarlar > Klinik İşleyiş.

### Akış diyagramı

```
[Hasta seç]
     │
     ▼
[Takvim — ay/hafta]
     │  kapalı gün: disabled
     │  kapalı tarih: disabled
     │  personel izin: disabled veya ⚠
     ▼
[Tarih seçildi]
     │
     ▼
[Saat blokları — grid]
     │  mesai ∩ slot süresi
     │  dolu/rezerve: disabled
     │  boş: selectable
     ▼
[Saat seçildi]
     │
     ▼
[Detay form]
     randevu tipi, başvuru nedeni, not, doktor
     │
     ▼
[Kaydet]
```

### Wireframe — saat blokları

```
24 Mayıs 2026 — Perşembe
┌────┬────┬────┬────┬────┐
│09:00│09:30│10:00│10:30│ ...
│ boş│ DOLU│ boş│ rez │
└────┴────┴────┴────┴────┘
Seçili: 09:00 – 09:30 (30 dk)
```

### Kurallar

| Kural | Kaynak |
|-------|--------|
| Kapalı gün | Klinik İşleyiş — haftalık mesai |
| Kapalı tarih | Kapalı tarihler listesi |
| Slot süresi | Varsayılan randevu süresi + aralık |
| Çakışma | Mevcut appointment aynı tenant/doktor |

---

## Bu Fazda Kapsam Dışı

Aşağıdakiler **bu design spec implementasyonuna dahil değildir**:

| Konu | Not |
|------|-----|
| Fizyoterapi modülü **redesign** | Mevcut menü/ekranlar kalır; ayrı plan **yazılmaz** |
| Operasyon / operasyon adı **redesign** | Kapsam dışı |
| Supabase Storage upload/download | Metadata-only devam |
| Signed URL | Plan paketi |
| PDF generate/refactor | Plan paketi |
| Realtime role-filtered refresh | Plan paketi |
| Demo/freemium/**subscription enforcement** | Tasarım kartı only |
| SaaS **faturalama/ödeme** kodu | Yok |
| Analyzer warning/info cleanup | En son hygiene |
| Büyük theme refactor (Material 3 tam geçiş) | Yok |
| **Login ekranı değişikliği** | **Yasak** — referans korunur |

---

## İlk Bugfix Adayları

### Bugfix (First Trial Bugfix / Clinical Encounter Fix paketleri)

| ID | Alan | Açıklama | Severity |
|----|------|----------|----------|
| BUG-UX-001 | Hasta temel bilgiler | Düzenle ekranında kırmızı tam ekran hata | High |
| BUG-UX-002 | Çoklu form | Hasta seçiliyken “hasta ismi giriniz” | Medium |
| BUG-UX-003 | Muayene listesi | Filtre başvuru tipi/durum **overflow** | Medium |
| BUG-UX-004 | Muayene | Yeni muayene CTA görünürlüğü | Medium |
| BUG-UX-005 | Sidebar | Eski/dummy nav öğeleri kaldırılmadan kafa karışıklığı | Low (IA ile çözülür) |
| BUG-UX-006 | Hasta liste | Fazla büyük satırlar | Medium (hybrid ile) |
| SETUP-001 | Auth | `auth_user_id` — çözüldü; dokümantasyon | Medium |

### Polish (Remote Trial Polish / UI Restructure implementation)

| ID | Alan |
|----|------|
| POL-UX-001 | Sidebar gradient (login ailesi) |
| POL-UX-002 | Kart başlığı sadeleştirme (gradient kaldır) |
| POL-UX-003 | Hasta liste compact hybrid |
| POL-UX-004 | Ayarlar kategori hub IA |
| POL-UX-005 | Muayene form tek yüzey 7 bölüm |

---

## Sonraki Implementation Paketleri (önerilen sıra)

| # | Paket | Kapsam |
|---|--------|--------|
| 1 | **Settings IA + Shell Smoke v1** | Ayarlar hub + kategori kartları; Demo/SaaS alt sayfaları; route shell |
| 2 | **Sidebar Navigation Cleanup + Gradient v1** | Nav sadeleştirme; login-gradient sidebar; Timeline/Etiket/Arşiv kaldır |
| 3 | **Patient List Compact Hybrid v1** | SOYAD, Ad; harf indeksi; tablo-liste |
| 4 | **Patient Basic Info Form Fix + Fields v1** | BUG-UX-001/002; yeni alanlar |
| 5 | **Clinical Encounter UX Restructure v1** | 7 bölüm tek yüzey; Özel Not; ilaç/enjeksiyon/ortez |
| 6 | **Clinical Encounter Filter Overflow + New CTA Fix v1** | BUG-UX-003/004 |
| 7 | **Appointment Availability UX Plan v1** | Bu spec § Randevu — teknik plan |
| 8 | **Appointment Availability Settings/UI v1** | Klinik İşleyiş + takvim/saat UI |

**Yazılmayacak (kullanıcı istemeden):** Fizyoterapi redesign paketi, Operasyon redesign paketi.

### Sonraki paket — Cursor komut taslağı

```text
Şimdi sadece “Settings IA + Shell Smoke v1” paketini yap.

Kapsam:
- docs/ui_ux_restructure_design_spec_v1.md Ayarlar hub + 9 kategori kartı
- Demo / Kullanım Durumu ve SaaS / Abonelik alt sayfaları korunur
- Teknik ID/secret gösterilmez
- Kullanıcılar ve Roller yalnız Doktor
- Login ekranına dokunma
- Sidebar bu pakette opsiyonel/minimal

Güvenlik: internalDoctorNote / rol route değişmez.
flutter analyze → 0 error.
```

---

## Statik analiz (rapor oturumu)

| Komut | Sonuç |
|-------|--------|
| `flutter analyze` | **0 error**, **228** info/warning (temizlik yapılmadı) |

---

## Kabul checklist (paket)

- [x] `docs/ui_ux_restructure_design_spec_v1.md` oluşturuldu
- [x] Canlı deneme UI/UX bulguları
- [x] Global prensipler + login koruma
- [x] Ayarlar IA + wireframe
- [x] Profil fotoğrafı + klinik logo/tabela
- [x] Klinik işleyiş / mesai / izin / kapalı gün
- [x] Demo / SaaS koruma ve ayrı kartlar
- [x] Randevu takvim + saat bloğu
- [x] Sidebar kaldır/taşı
- [x] Hasta liste hybrid wireframe
- [x] Hasta temel bilgiler alanları
- [x] Muayene 7 bölüm + ICD/ilaç/enjeksiyon/ortez + Özel Not
- [x] Yeni muayene CTA
- [x] Fizyoterapi/operasyon kapsam dışı
- [x] Bugfix/polish ayrımı
- [x] Implementation sırası
- [x] Kod değişmedi

---

*Bu spec implementasyon öncesi ürün onayı içindir. Güvenlik kuralları [staging_trial_report_v1.md](staging_trial_report_v1.md) ve [first_full_app_trial_v1_report.md](first_full_app_trial_v1_report.md) ile uyumlu kalır.*
