# Settings User Invitation v2c — Staging Smoke + Runbook

Normal Ayarlar davet lifecycle (v2a send/accept + v2b resend/cancel) için **drmem-clinic-dev** staging deploy ve smoke rehberi.

| Alan | Değer |
|------|--------|
| Proje | `drmem-clinic-dev` (`dgzmybbgrofapjptjspf`) |
| Önceki paketler | v2a (send/accept), v2b (resend/cancel) |
| İlgili runbook | [settings_user_invitation_v2a_runbook.md](./settings_user_invitation_v2a_runbook.md) |

---

## 1. Ön koşullar

1. **Migration bağımlılıkları** (sırayla):
   - `user_membership_management_v1`
   - `settings_user_invitation_v2a`
   - `settings_user_invitation_v2b`
2. **Edge Function:** `tenant-invite-user-v2` (`verify_jwt = true`)
3. **Flutter staging build:**
   ```powershell
   flutter run -d windows --dart-define-from-file=secrets/staging.json
   ```
   `DATA_BACKEND=supabase`, `APP_ENV=staging`
4. **Demo doktor:** `doctor-a@example.test` — Auth bağlı, `doctor_admin`, aktif tenant
5. **Auth ayarları:** Site URL + Redirect allowlist + Invite email template (bkz. v2a runbook)
6. **Maintenance:** `maintenance_config.enabled = false` (normal settings smoke için)

---

## 2. Deploy (staging)

Migration geçmişi repodan farklıysa `supabase db push` yerine doğrudan SQL uygulayın:

```powershell
cd d:\v2memlabs\membys

supabase db query --linked -f supabase/migrations/20260803100000_user_membership_management_v1.sql
supabase db query --linked -f supabase/migrations/20260607100000_settings_user_invitation_v2a.sql
supabase db query --linked -f supabase/migrations/20260608100000_settings_user_invitation_v2b.sql

# Opsiyonel: schema_migrations kaydı
supabase db query --linked -- "insert into supabase_migrations.schema_migrations (version, name) values ('20260803100000', 'user_membership_management_v1'), ('20260607100000', 'settings_user_invitation_v2a'), ('20260608100000', 'settings_user_invitation_v2b') on conflict (version) do nothing;"

supabase functions deploy tenant-invite-user-v2 --project-ref dgzmybbgrofapjptjspf
```

---

## 3. Otomatik smoke (SQL)

```powershell
supabase db query --linked -f scripts/staging/settings_user_invitation_v2c_smoke_checks.sql
```

**Beklenen:**
- 7 invitation/user-mgmt RPC mevcut
- `memberships.last_invited_at` kolonu var
- `authenticated` EXECUTE grant’leri true
- `doctor-a@example.test` / `doctor-b@example.test` → `auth_linked=true`
- `maintenance_config.enabled=false`

Rapor: [settings_user_invitation_v2c_staging_smoke_report.md](../smoke/settings_user_invitation_v2c_staging_smoke_report.md)

Deep-link accept (v2d) staging E2E: [v2e runbook](./settings_user_invitation_v2e_runbook.md)

---

## 4. Manuel smoke checklist (operatör)

Staging Flutter uygulaması ile `doctor-a@example.test` oturumu açın.

### A — Invite (v2a)

| # | Adım | Beklenen |
|---|------|----------|
| 1 | Settings → Kullanıcılar ve Roller → Kullanıcı davet et | Form açılır |
| 2 | `invite-smoke-{timestamp}@example.test` + görünen ad + rol (Asistan) | Davet gönderildi SnackBar |
| 3 | Liste | Satır **Davetli** |
| 4 | Auth e-posta / Inbucket | Invite mail gelir |
| 5 | Davetli şifre belirler, uygulamada login | Dashboard açılır |
| 6 | Doctor listesi | Davetli → **Aktif** |

### B — Resend + cooldown (v2b)

| # | Adım | Beklenen |
|---|------|----------|
| 7 | Yeni davet: `resend-smoke-{timestamp}@example.test` | **Davetli** |
| 8 | Satır → **Yeniden gönder** → onay | Başarı SnackBar |
| 9 | Hemen tekrar **Yeniden gönder** | Cooldown mesajı (60 sn) |
| 10 | 60+ sn sonra tekrar | Başarı |

### C — Cancel (v2b)

| # | Adım | Beklenen |
|---|------|----------|
| 11 | Başka davet: `cancel-smoke-{timestamp}@example.test` | **Davetli** |
| 12 | **Daveti iptal et** → onay | “Kullanıcı hesabı silinmeyecek” metni |
| 13 | Başarı sonrası liste | **Pasif**; resend/cancel butonları yok |
| 14 | Supabase Auth Dashboard | Auth user hâlâ mevcut |

### D — Regression

| # | Kontrol | Beklenen |
|---|---------|----------|
| 15 | Aktif satırda resend/cancel yok | UI temiz |
| 16 | Invited satırda manual **Aktif** seçeneği yok | Status picker |
| 17 | `/maintenance` route | Maintenance kapalıysa erişim yok |
| 18 | Teknik id UI’da görünmez | membership/profile id yok |

---

## 5. Audit doğrulama (SQL Editor — doctor JWT veya smoke sonrası)

```sql
select action, metadata->>'source' as source,
       metadata ? 'email' as has_email,
       metadata ? 'token' as has_token,
       metadata->>'operation_result' as operation_result,
       created_at
from public.audit_logs
where action in (
  'user.invite.send',
  'user.invite.resend',
  'user.invite.cancel',
  'invitation.accepted'
)
order by created_at desc
limit 20;
```

**Beklenen:** `has_email=false`, `has_token=false`; source `settings_invitation_v2a` / `settings_invitation_v2b`.

---

## 6. Bilinen staging notları

- Migration geçmişi repodaki dosya adlarından farklı olabilir (`settings_persistence_foundation_v1` vb.). Bu pakette invitation SQL’leri `supabase db query --linked -f` ile uygulandı.
- `supabase db push` repair gerektirebilir; invitation deploy için yukarıdaki `-f` yöntemi tercih edilir.
- E2E mail/login adımları operatör şifresi gerektirir (repoda yok).

---

## 7. Rollback (acil)

1. Edge Function’ı devre dışı bırakmak yerine Flutter’da mock backend kullanın.
2. RPC’leri kaldırmak production riski taşır; staging’de gerekirse önceki function versiyonuna dashboard’dan dönün.
3. `cancel_tenant_invitation_v2` geri alınamaz soft-disable’tır; gerekirse membership status manuel `disabled` kalır.
