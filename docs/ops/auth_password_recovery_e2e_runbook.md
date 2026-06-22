# Auth — Şifre belirleme / sıfırlama E2E (staging)

Uygulama rotaları: `/auth/update-password`, `/auth/forgot-password` (giriş gerektirmez).

## Supabase Dashboard — URL Configuration

**Authentication → URL Configuration**

| Alan | Örnek (Chrome dev) |
|------|---------------------|
| Site URL | `http://localhost:3000` (kullandığınız port) |
| Redirect URLs | `http://localhost:**/**` |

Aşağıdaki path'ler allowlist içinde olmalı:

- `/auth/update-password`
- `/auth/forgot-password`
- `/invite/accept` (davet akışı)

## PR — Şifre sıfırlama (mevcut kullanıcı)

| # | Adım | Beklenen |
|---|------|----------|
| PR-1 | Login → “Şifremi unuttum” veya `/auth/forgot-password` | E-posta formu |
| PR-2 | Kayıtlı e-posta gönder | “E-posta gönderildi” |
| PR-3 | Mail linki | Supabase verify → redirect `.../auth/update-password` |
| PR-4 | Yeni şifre (≥8 karakter) + onay | Başarı → dashboard veya login |
| PR-5 | Yeni şifre ile giriş | OK |

## DL-B — Davet + şifre (invite accept ile birleşik)

Davet maili → Supabase şifre sayfası → redirect:

1. **İdeal:** `/auth/update-password` (hash ile `passwordRecovery`) → şifre kaydet → invite accept / dashboard
2. **Alternatif:** `/invite/accept?membership_id=...` → giriş veya şifre ekranı

`AuthCallbackCoordinator` `passwordRecovery` ve davet `signedIn` olaylarında `/auth/update-password` açar.

Chrome dev:

```powershell
flutter run -d chrome --web-port=3000 --dart-define-from-file=secrets/staging.json
```

## Admin API (son çare)

Yalnızca redirect tamamen kırık ve uygulama şifre ekranına ulaşılamıyorsa. Ayrıntı: [v2e runbook §5](./settings_user_invitation_v2e_runbook.md).

## Otomatik testler (CI)

```powershell
flutter test test/core/router/auth_route_guard_password_test.dart
flutter test test/core/router/auth_route_guard_invite_test.dart
flutter test test/core/auth/auth_password_setup_intent_test.dart
```
