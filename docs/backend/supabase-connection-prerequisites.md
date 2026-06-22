# Supabase Gerçek Bağlantı Önkoşulları

## Supabase Auth v1 (tamamlandı — kapsam)

- [x] `supabase_flutter` eklendi; `SupabaseClientInitializer` gerçek init (koşullu)
- [x] Auth: `SupabaseAuthRepository` — `signInWithPassword` + profile/membership/tenant bootstrap
- [x] Yalnızca **anon key** istemcide; **service_role yok**
- [x] `DATA_BACKEND=supabase` + URL + anon key ile aktif; aksi halde mock
- [x] Rol Supabase modda membership’ten; demo rol dropdown yalnız mock
- [ ] Hasta/randevu/muayene **remote CRUD** — sonraki faz (hâlâ mock)

## Yapılandırma

- [ ] `SUPABASE_URL` ve `SUPABASE_ANON_KEY` CI/CD veya güvenli secret store’dan verilir
- [ ] **service_role** yalnızca sunucu / admin seed tooling; Flutter istemcisinde **yok**
- [ ] `.env` / gerçek key repoda commit edilmedi

## Veritabanı

- [ ] [migration-review-checklist.md](migration-review-checklist.md) tamamlandı
- [ ] RLS policy taslakları staging’de uygulandı ve test edildi
- [ ] [seed-plan.md](seed-plan.md) — test tenant + 4 rol kullanıcısı
- [ ] [rls-test-plan.md](rls-test-plan.md) staging’de çalıştırıldı
- [ ] `internal_doctor_note` asistana kapalı

## Uygulama çalıştırma

```bash
flutter run \
  --dart-define=DATA_BACKEND=supabase \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Varsayılan (define yok): **mock** — gerçek Supabase init denenmez.

## Go / No-Go — remote klinik veri (henüz No-Go)

Remote hasta/randevu/muayene için ek şartlar:

- RLS testleri geçti
- Test tenant seed tamam
- Gerçek hasta verisi ile ilk test **yapılmadı**
- `service_role` client bundle’da yok

Auth v1 için staging Go: seed + RLS + test kullanıcıları + dart-define ile manuel checklist ([auth-transition.md](auth-transition.md)).

## Auth Manuel Test v1 (kod tarafı)

- Birim test: `test/auth_bootstrap_test.dart` (rol eşlemesi, failure selector, mesajlar)
- Bootstrap hata sonrası oturum temizliği: `SupabaseAuthRepository._abortAuthenticatedSignIn`
- PostgREST yükleme hatası → `notLoaded` (teknik “backend not configured” mesajı gösterilmez)
- Staging’de canlı login doğrulaması için seed + dart-define zorunlu; seed eksikse **Supabase seed düzeltmesi gerekir**

## İlgili dokümanlar

- [auth-transition.md](auth-transition.md)
- [config.example.md](config.example.md)
- [seed-plan.md](seed-plan.md)
- [rls-test-plan.md](rls-test-plan.md)
