# Proje Referansı — Muayenehane Klinik Yönetim Sistemi

Bu dosya proje boyunca referans ve kısa dokümantasyon amacıyla kullanılacaktır. Her önemli adımda (özellik ekleme, wire-up, yapılandırma değişikliği) bu dosya güncellenecektir.

## Amaç
- Android tablet odaklı, mock-data ile çalışan bir klinik yönetim ön yüzü iskeleti oluşturmak.
- Backend veya gerçek kimlik doğrulama şimdilik yok; tüm veriler mock veya placeholder.

## Önemli Kurallar (proje boyunca sabit)
- Sade, okunabilir ve genişletilebilir kod.
- Gereksiz paket eklenmez.
- Feature-first klasör yapısı kullanılır.
- State management için şimdilik ChangeNotifier veya StatefulWidget yeterli.
- Router için `go_router` kullanılabilir.
- Material 3 teması ve Türkçe UI metinleri kullanılır.

## Proje Klasör Yapısı (özet)
```
lib/
  main.dart
  app.dart
  core/
    router/
      app_router.dart
    theme/
      app_theme.dart
    constants/
      app_roles.dart
  shared/
    models/
      app_user.dart
    widgets/
      app_shell.dart
      dashboard_card.dart
  features/
    auth/
      login_screen.dart
    dashboard/
      doctor_dashboard_screen.dart
      assistant_dashboard_screen.dart
      physiotherapist_dashboard_screen.dart
    patients/
      patient_list_screen.dart
      patient_detail_screen.dart
      patient_form_screen.dart
```

## Çalıştırma (kısa)
1. `flutter pub get`
2. `flutter analyze` — analiz hatalarını kontrol edin
3. `flutter run` — hedef cihaz bağlı veya emülatör çalışıyor olmalı

## Mock / Placeholder notları
- Hasta modülü için şimdilik mock listeler ve placeholder ekranlar kullanılır.
- DICOM veya gerçek görüntüleme bu aşamada yok.

## Kodlama Konvansiyonları
- Dosya ve sınıf isimleri İngilizce ama UI metinleri Türkçe.
- Yeni feature eklendiğinde ilgili dosya `PROJE_REFERANSI.md` changelog bölümüne kısa not eklenir.

## Changelog
- 2026-05-19: Proje referans dosyası oluşturuldu. Başlangıç iskeleti eklendi: `main.dart`, `app.dart`, `core/`, `shared/`, `features/auth`, `features/dashboard`, `features/patients` (placeholderlar). Router ve tema eklendi.

---

Not: Bu dosya projenin canlı referansıdır — her önemli commit/özelliğin ardından güncellenecektir.

## Changelog Girdisi Şablonu (Detaylı)
Her önemli değişiklikten sonra, aşağıdaki şablonu kullanarak yeni bir changelog girdisi ekleyin. Bu, proje geçmişinin tutarlı ve okunabilir olmasını sağlar.

```
- Tarih: YYYY-MM-DD
- Yapan: <İsim veya Git kullanıcı>
- Başlık: Kısa özet (tek satır)
- Detay: Kısa açıklama; neden yapıldı, hangi problem çözüldü
- Etkilenen dosyalar: 
  - path/to/file1
  - path/to/file2
- Komutlar / Notlar: (derleme, migration veya özel adımlar)
- Issue/PR: (#123 veya link)
```

### Örnek Girdi

- Tarih: 2026-05-19
- Yapan: Ali Dev
- Başlık: Hasta modülü placeholder eklendi
- Detay: Hasta listesi, detay ve form ekranları placeholder olarak eklendi. Router'a `/patients`, `/patients/new`, `/patients/:id` rotaları eklendi.
- Etkilenen dosyalar:
  - lib/features/patients/patient_list_screen.dart
  - lib/features/patients/patient_detail_screen.dart
  - lib/features/patients/patient_form_screen.dart
  - lib/core/router/app_router.dart
- Komutlar / Notlar:
  - `flutter pub get`
  - Placeholder ekranlar, gerçek veri akışı sonraki aşamada eklenecek.
- Issue/PR: #12

---

Her değişiklik yapıldığında lütfen bu şablonu doldurarak dosyanın sonuna ekleyin. İsterseniz bu eylemi otomatikleştirecek küçük bir git commit hook veya script eklemekte de yardımcı olabilirim.

### Yeni Girdiler

- Tarih: 2026-05-19
- Yapan: Otomatik güncelleme
- Başlık: Randevu (Appointments) modülü eklendi (mock)
- Detay: Randevu modelleme, mock veri ve temel UI eklendi. Aşağıdaki bileşenler mock-only olarak uygulandı: randevu listesi (arama, bugün/hafta/tümü filtreleri, durum filtresi), randevu detay ekranı (aksiyon butonları) ve randevu oluşturma formu (mock kaydetme). Router'a yeni rotalar eklendi ve doktor/asistan dashboard kartları randevu listesine bağlandı.
- Etkilenen dosyalar:
  - lib/features/appointments/models/appointment.dart
  - lib/features/appointments/data/mock_appointments.dart
  - lib/features/appointments/appointment_list_screen.dart
  - lib/features/appointments/appointment_detail_screen.dart
  - lib/features/appointments/appointment_form_screen.dart
  - lib/core/router/app_router.dart
  - lib/features/dashboard/doctor_dashboard_screen.dart
  - lib/features/dashboard/assistant_dashboard_screen.dart
- Komutlar / Notlar:
  - Tüm veri mock olarak tutuluyor; gerçek backend entegrasyonu yok.
  - Yeni randevu oluşturma formu `mockAppointments` listesine ekler (kalıcı değil).
  - Öneri: Düzenleme (edit) rotası ve bildirim/hatırlatma akışı sonraki aşamada eklenebilir.
- Issue/PR: (henüz yok)

