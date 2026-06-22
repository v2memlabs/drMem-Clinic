# drMem Clinic — Premium UI token rehberi

Bu klasör **Premium UI Foundation** token ve `ThemeData` tanımlarını içerir.

## Global UI Surface & Header v1 (içerik workbench)

Login = kapı (gradient marka paneli). Uygulama içi = **klinik workbench** (düz zemin, sınırlı aksan).

### Gradient bütçesi

| Alan | Gradient |
|------|----------|
| Login sol marka paneli | Evet — korunur |
| Sidebar (`AppColors.sidebarBrandGradient`) | Evet — korunur |
| İçerik ekranları (`PageHeader`, `FormSectionCard`, chip, liste) | **Hayır — bütçe 0** |

### Yüzey kuralları

| Kural | Açıklama |
|-------|----------|
| Varsayılan panel | `PremiumSurface.panel()` — border, gölge yok |
| Kart | `PremiumSurface.card(elevated: false)` varsayılan |
| Gölgeli kart | Sayfa başına **en fazla 1** istisna (ör. `DetailHeaderCard`) |
| Liste satırı | Gölgesiz; `DataListCard` ayrı pakette sadeleştirilecek |
| Form bölümü | `FormSectionCard` — alt border / divider, heavy card değil |
| Sayfa başlığı | `PageHeader` — `contentHeaderBand()`, gradient yok |

### Aksan / chip

- Turkuaz (`accentTurquoise`): focus border, aktif nav, **tek** liste rail — dekorasyon yağmuru yok.
- `DateTimeChip`: nötr pill, gradient yok.
- `StatusChip`: listede en fazla **1 semantic + 1 neutral** (hedef; tam audit ayrı paket).
- Section başlığı: badge + çizgi + gradient **üçlüsü kullanılmaz**.

### CTA

- Ekran başına **1 net birincil** aksiyon (Filled / teal).

### Bileşenler

| Bileşen | Dosya |
|---------|--------|
| Yüzey token | `lib/shared/widgets/premium_surface.dart` |
| Sayfa başlığı | `lib/shared/widgets/page_header.dart` |
| Form bölümü | `lib/shared/widgets/form_section_card.dart` |
| Tarih chip | `lib/shared/widgets/date_time_chip.dart` |

## Renk (`app_colors.dart`)

| Token | Kullanım |
|-------|----------|
| `primaryDeepTeal` | Primary CTA, odak çerçevesi |
| `accentTurquoise` | İkincil vurgu, sınırlı aksan |
| `navy` / `navyDark` | Metin / sidebar |
| `backgroundSoft` | Scaffold |
| `surfaceCard` | Panel yüzeyi |
| `success` / `warning` / `danger` / `info` | `StatusChip` |

Paleti değiştirmeyin; yalnızca token adıyla referans verin.

## Radius (`app_radius.dart`)

- Input/button: `small` (8)
- Kart: `card` (16)
- Dialog: `dialog` (20)

## Spacing (`app_spacing.dart`)

`xxs` 4 → `xl` 32.

## Shadow (`app_shadows.dart`)

- `subtle`, `card`, `elevatedCard` — yalnız istisna yüzeylerde
- İçerik varsayılanı: gölge yok

## Sonraki fazlar

| Paket | Kapsam |
|-------|--------|
| Dashboard Clinical Workbench v1 | Launcher grid → KPI + kısayol |
| Clinical List Row v1 | `DataListCard` → gölgesiz satır |
| Patient Detail Workbench v1 | Tab + header band |
| Form Density v1 | Sticky footer |

Ekran dosyalarında doğrudan `Color(0x…)` yerine `AppColors` / `Theme.of(context).colorScheme` kullanın.
