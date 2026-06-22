# Settings User Invitation v2d — Deep-link Accept Runbook

Davet e-postasındaki redirect → uygulama `/invite/accept?membership_id=<uuid>` → oturum + kabul.

## Redirect URL (Supabase Auth allowlist)

Allowlist’e uygulama kök URL’sini ekleyin. Edge Function davet/resend sonrası şu path’i üretir:

```
/invite/accept?membership_id=<target_membership_id>
```

Opsiyonel secret: `TENANT_INVITE_REDIRECT_URLS` (virgülle ayrılmış tam URL kökleri).

## Akış

1. Doktor davet gönderir (v2a EF) — EF önceden `membership_id` üretir, redirect’e yazar.
2. Davetli e-posta → şifre belirleme → redirect uygulamaya.
3. **Oturum var:** `InviteAcceptScreen` → `accept_my_tenant_invitation_v2(p_membership_id)` → dashboard.
4. **Oturum yok:** pending `membership_id` saklanır → login → bootstrap accept → dashboard.

## Deploy

```powershell
supabase db query --linked -f supabase/migrations/20260609100000_settings_user_invitation_v2d.sql
supabase functions deploy tenant-invite-user-v2 --project-ref dgzmybbgrofapjptjspf
```

## Smoke

1. Davet gönder → e-posta linkinde `membership_id` query var mı?
2. Link aç → accept ekranı → giriş/accept → **Aktif**
3. Audit: `invitation.accepted`, source=`settings_invitation_v2d`
4. Yanlış/geçersiz UUID → güvenli hata, teknik id UI’da yok

Staging deep-link E2E (otomatik infra + operatör checklist): [v2e runbook](./settings_user_invitation_v2e_runbook.md) · [v2e smoke raporu](../smoke/settings_user_invitation_v2e_staging_smoke_report.md)

## Kapsam dışı

Multi-tenant pending invite picker, custom URL scheme (app_links), orphan Auth cleanup.
