# Staging Bootstrap Runbook v1

SQL Editor yerine **Maintenance / Bootstrap Console** kullanımı.

## Ön koşullar

1. Migration `20260602100000_maintenance_bootstrap_console_v1.sql` staging’de uygulandı.
2. Seed veya manuel:
   ```sql
   update maintenance_config set enabled = true where id = 1;
   update profiles set maintenance_operator = true
   where email = 'doctor-a@example.test';
   ```
3. Supabase Auth’ta kullanıcı oluşturuldu; UID kopyalandı.
4. Flutter:
   ```powershell
   flutter run -d windows --dart-define-from-file=secrets/staging.json
   ```
   `secrets/staging.json` içinde:
   - `DATA_BACKEND`: `supabase`
   - `APP_ENV`: `staging`
   - `MAINTENANCE_MODE`: `true`

## Akış: Yeni staging kullanıcı

1. Giriş yap (`doctor-a` — operatör flag’li).
2. Tarayıcı/uygulama: `/maintenance` (veya dashboard sonrası URL).
3. **Auth / Profil** → Auth UUID yapıştır → `auth_user_id` bağla.
4. **Bootstrap tanı** → zincir yeşil mi kontrol et.
5. Üyelik yoksa **Üyelikler** → yeni → tenant + profile + rol.

## Auth user oluşturma

Bu konsol Auth user **oluşturmaz**. Supabase Dashboard → Authentication → Add user.

## Production

- `MAINTENANCE_MODE` tanımlı olmamalı veya `false`.
- `APP_ENV=production`.
- `maintenance_config.enabled=false`.
