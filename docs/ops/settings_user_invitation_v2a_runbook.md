# Settings User Invitation v2a — Runbook

Normal Ayarlar altında doktor/admin kullanıcı daveti ve davet kabul lifecycle.

## Supabase Auth ayarları

1. **Site URL** — staging/production uygulama kök URL’si.
2. **Redirect URLs allowlist** — hosted invite/set-password sayfası URL’leri.
3. **Edge Function secret (opsiyonel):** `TENANT_INVITE_REDIRECT_URLS` — virgülle ayrılmış allowlist.
4. **Invite email template** — Auth → Email Templates → Invite (Türkçe metin önerilir).
5. **SMTP** — staging’de mail capture (Inbucket/custom SMTP); production’da gerçek SMTP.

## v2a akışı

1. Doktor Settings → Kullanıcılar ve Roller → Kullanıcı davet et.
2. Edge Function `tenant-invite-user-v2` → `auth.admin.inviteUserByEmail`.
3. RPC `bootstrap_tenant_invited_user_v2` → profile + `invited` membership.
4. Davetli e-posta → hosted set-password.
5. Uygulamada normal e-posta/şifre login.
6. Login bootstrap → `accept_my_tenant_invitation_v2` → membership `active`.

Deep-link bu pakette yok; invite sonrası kullanıcı uygulamayı manuel açar.

## Deploy

```bash
supabase db push
supabase functions deploy tenant-invite-user-v2
```

## Staging smoke checklist

1. Doctor admin login.
2. Davet gönder (`*@example.test`).
3. Liste “Davetli”.
4. E-posta alınır, şifre belirlenir.
5. Login → dashboard açılır.
6. Doctor listesinde “Aktif”.
7. Audit’te email/token yok (`user.invite.send`, `invitation.accepted`).

## Kapsam dışı (v2b+)

Deep-link, multi-tenant invite picker, orphan Auth repair.

**v2b (resend/cancel)** ve **v2c (staging smoke)** tamamlandı — bkz. [settings_user_invitation_v2c_runbook.md](./settings_user_invitation_v2c_runbook.md).
