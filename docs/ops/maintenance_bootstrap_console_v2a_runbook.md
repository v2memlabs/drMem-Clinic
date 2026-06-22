# Maintenance Bootstrap Console v2a — Staging Runbook

IT operatörü staging/dev ortamında tenant oluşturma (v2a-1) ve ilk `doctor_admin` hesabı (v2a-2) bu runbook ile yönetilir.

**Önkoşullar**

- `DATA_BACKEND=supabase`
- `APP_ENV=dev` veya `staging` (production değil)
- `MAINTENANCE_MODE=true` (Flutter build flag)
- `maintenance_config.enabled = true` (DB)
- Operatör profili: `profiles.maintenance_operator = true`
- Gerçek parola bu dokümana yazılmaz

---

## Paket ayrımı

| Paket | Migration | UI |
|-------|-----------|-----|
| **v2a-1** Tenant Create | `20260804100000_maintenance_bootstrap_console_v2a1_tenant_create.sql` | `/maintenance/tenants/new` |
| **v2a-2** Auth + Initial Admin | `20260804200000_maintenance_bootstrap_console_v2a2_admin_bootstrap.sql` | `/maintenance/bootstrap/new` |

---

## 1. v2a-2 migration push

```bash
supabase db push --project-ref dgzmybbgrofapjptjspf
```

Sıra: v2a-1 uygulanmış olmalı → ardından v2a-2.

Doğrulama:

```sql
SELECT proname FROM pg_proc
WHERE proname IN ('maintenance_bootstrap_user_v2', 'maintenance_bootstrap_status_v2');
```

## 2. Edge Function deploy

```bash
supabase functions deploy maintenance-provision-user-v2 --project-ref dgzmybbgrofapjptjspf
```

`supabase/config.toml`: `verify_jwt = true`

## 3. Function secrets set

Supabase Dashboard → Edge Functions → Secrets:

| Secret | Açıklama |
|--------|----------|
| `SUPABASE_URL` | Proje URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Yalnız Edge Function secret (Flutter’da yok) |
| `SUPABASE_ANON_KEY` | Anon/publishable key |
| `APP_ENV` | `staging` veya `dev` |
| `MAINTENANCE_PROVISIONING_ENABLED` | `true` |

Production’da `MAINTENANCE_PROVISIONING_ENABLED` **açılmaz**.

## 4. Operator hazırlığı

1. Auth user (Dashboard veya seed)
2. `profiles.maintenance_operator = true`, `auth_user_id` bağlı
3. Membership’siz maintenance-only oturum desteklenir

## 5. maintenance_config enable

```sql
UPDATE public.maintenance_config
SET enabled = true, updated_at = now()
WHERE id = 1;
```

Smoke bitince staging’de **kapatmayı değerlendirin** (operasyonel karar):

```sql
UPDATE public.maintenance_config SET enabled = false, updated_at = now() WHERE id = 1;
```

## 6. Flutter build (staging)

```powershell
flutter run -d windows --dart-define=MAINTENANCE_MODE=true --dart-define-from-file=secrets/staging.json
```

## 7. Tenant oluştur (v2a-1)

1. Maintenance operatörü ile login
2. **Yeni Klinik** → `/maintenance/tenants/new`
3. Klinik bilgilerini kaydet

## 8. Tenant seç + ilk admin (v2a-2)

1. **İlk Yönetici** → `/maintenance/bootstrap/new`  
   veya Klinikler listesinden **İlk yönetici ekle**
2. Aktif/deneme durumunda klinik seç (veya query param ile gel)
3. E-posta + görünen ad (rol: Doktor, durum: Aktif — sabit)
4. **Oluştur ve doğrula**

## 9. Temporary password secure capture

- Geçici parola **yalnız bir kez** gösterilir
- **Parolayı kopyala** → password manager
- Ekrandan çıkınca tekrar gösterilmez
- Parolayı chat, ticket, repo veya smoke raporuna yazmayın
- Screenshot’ta parolayı blur’layın

## 10. chain_ok doğrula

Doğrulama ekranında **Login zinciri: Hazır** (`chain_ok = true`).

Eksik halka → v2c onarım backlog; Auth user’ı manuel silmeyin.

## 11. Logout

Maintenance operatör oturumunu kapatın.

## 12. Yeni doktor login

1. Normal login ekranından yeni doktor e-postası
2. Geçici parola ile giriş
3. `/doctor` erişir; `/maintenance` **reddedilir**

## 13. Audit secret scan

```sql
SELECT action, metadata FROM audit_logs
WHERE module = 'maintenance'
ORDER BY created_at DESC LIMIT 20;
```

Metadata’da email, password, jwt, token olmamalı. `source` = `maintenance_v2a1` veya `maintenance_v2a2`.

---

## Rollback / hata

| Durum | Beklenen davranış |
|-------|-------------------|
| RPC bootstrap başarısız | Edge Function `deleteUser` best-effort |
| Rollback başarısız | `rollback_failed` — teknik müdahale |
| Auth var, zincir eksik | `auth_user_exists` — v2c onarım |
| Zincir tamam | `already_exists` — yeni Auth oluşturulmaz |

## Kapsam dışı

- Ek rol provisioning (v2b)
- Repair wizard (v2c)
- Production maintenance
- Settings User Invitation v2
- Cross-tenant authenticated smoke (ayrı paket)
