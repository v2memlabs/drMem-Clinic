# Backend Yapılandırma

Gerçek URL/key **commit edilmez**. İstemci yalnızca **anon key** kullanır; `service_role` Flutter’da **asla** tutulmaz.

## Dart-define

| Anahtar | Varsayılan | Açıklama |
|---------|------------|----------|
| `DATA_BACKEND` | `mock` | `mock` veya `supabase` |
| `SUPABASE_URL` | (boş) | Proje URL |
| `SUPABASE_ANON_KEY` | (boş) | Anon (public) key |

```bash
# Demo (varsayılan)
flutter run

# Supabase modu isteği — URL/key yoksa uygulama mock’a düşer, crash olmaz
flutter run --dart-define=DATA_BACKEND=supabase

# Supabase Auth v1 (dev/staging) — gerçek değerleri repoya yazmayın
flutter run \
  --dart-define=DATA_BACKEND=supabase \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Supabase modda yalnızca **auth + membership bootstrap** remote’dur; hasta/randevu/muayene mock kalır.

## .env.example

Kök dizinde [.env.example](../../.env.example) — kopyalayıp `.env.local` oluşturun; `.gitignore` altında.

## Kod

- `SupabaseEnvConfig` — `lib/core/config/supabase_env_config.dart`
- `AppEnvBootstrap.ensureInitialized()` — `main.dart` açılışında
- `AppBackendConfig.applyEnvironment()` — `activeBackend` etkin mod

`DATA_BACKEND=supabase` + boş URL/key → `activeBackend` = **mock**, login demo UI.

## Build / ortam (ileride)

| Ortam | `DATA_BACKEND` | Not |
|-------|----------------|-----|
| dev / demo | `mock` | Rol dropdown |
| staging / prod | `supabase` | Rol membership’ten; demo dropdown kapalı |

Flavor sistemi henüz yok — yalnız dokümantasyon.

## CI (GitHub Actions)

| Workflow | Tetikleyici | Ne yapar |
|----------|-------------|----------|
| [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) | push/PR → main | `flutter analyze`, architecture + unit test, release web build with production `--dart-define` |
| [`.github/workflows/migration-drift.yml`](../.github/workflows/migration-drift.yml) | haftalık / manual | `supabase migration list --linked` drift kontrolü |

Release build örneği (CI ile aynı):

```bash
flutter build web --release \
  --dart-define=DATA_BACKEND=supabase \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Production şablon: [assets/config/production.json.example](../assets/config/production.json.example) (commit edilebilir; gerçek key değil).

Migration drift için repo secrets: `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF`.

## Gerçek bağlantı öncesi şartlar

- [supabase-connection-prerequisites.md](supabase-connection-prerequisites.md) (Go/No-Go)
- [seed-plan.md](seed-plan.md)
- [rls-test-plan.md](rls-test-plan.md)
