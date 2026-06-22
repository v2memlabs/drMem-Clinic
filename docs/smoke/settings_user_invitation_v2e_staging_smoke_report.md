# Settings User Invitation v2e — Staging Deep-link E2E Smoke Raporu

| Alan | Değer |
|------|--------|
| Paket | Settings User Invitation v2e — Staging deep-link E2E smoke |
| Tarih | 2026-06-07 |
| Ortam | `drmem-clinic-dev` (`dgzmybbgrofapjptjspf`) |
| Runbook | [settings_user_invitation_v2e_runbook.md](../ops/settings_user_invitation_v2e_runbook.md) |
| Ön paketler | v2a–v2d |

## Genel karar

| Karar | **Kısmen geçti** (E2E accept OK — operatör DL-8 onaylı; mail redirect + audit v2d eksik) |
|-------|---------------------------------------------------------------------|
| Gerekçe | Davet → **Aktif** üyelik doğrulandı (`bd589f99-…`). Mail/recovery linkleri `localhost:3000` yüzünden şifre UI yok; operatör **Admin API şifre** + Chrome `/invite/accept` ile tamamladı. `invitation.accepted` audit kaydı staging’de yok. |

---

## 1. Deploy / infra sonuçları

| Bileşen | Sonuç | Not |
|---------|--------|-----|
| `settings_user_invitation_v2d` migration | **Geçti** | `schema_migrations` kayıtlı (`20260609100000`) |
| `bootstrap_tenant_invited_user_v2` 5-arg overload | **Geçti** | `p_target_membership_id uuid` |
| `accept_my_tenant_invitation_v2(uuid)` EXECUTE | **Geçti** | `authenticated` grant OK |
| Edge Function `tenant-invite-user-v2` | **Geçti** | v2 ACTIVE (deep-link redirect) |
| v2c regression base (maintenance isolation) | **Geçti** | `maintenance_config.enabled = false` |

---

## 2. Otomatik SQL smoke (2026-06-07)

Komut:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/staging/run_settings_invitation_v2e_smoke.ps1
```

| Kontrol | Sonuç | Kanıt |
|---------|--------|-------|
| v2d migration kaydı | **Geçti** | `found=1`, `expected=1` |
| bootstrap 5-arg overload | **Geçti** | `found=1`, `expected=1` |
| accept RPC EXECUTE grant | **Geçti** | `accept_exec=true` |
| Pending invite (DL-2 sonrası) | **Geçti** | `bd589f99-…` invited, `auth_linked=true`, `last_invited_at` set |
| Deep-link accept audit (`settings_invitation_v2d`) | **Bekliyor** | Henüz kayıt yok — manuel E2E sonrası doldurulacak |
| Invite send/resend audit (target_membership_id) | **Bekliyor** | Staging audit tablosu boş — operatör davet gönderimi sonrası doğrulanacak |

Unit test: `flutter test test/supabase/settings_user_invitation_v2e_smoke_script_test.dart` → **2/2 geçti**.

---

## 3. Manuel deep-link E2E (operatör checklist)

Test e-postası: `mehmetyalcinozan+dl20260607@gmail.com`

| Madde | Sonuç | Not |
|-------|--------|-----|
| DL-1 — Davet gönder | **Geçti** | SnackBar “Davet gönderildi.” |
| DL-2 — Liste Davetli | **Geçti** | `membership_id=bd589f99-c837-492e-a8d8-bea8349063ec` |
| DL-3 — Mail geldi | **Geçti** | Mail gövdesinde ID yok (beklenen) |
| DL-4 — SQL snapshot | **Geçti** | `bd589f99-c837-492e-a8d8-bea8349063ec` |
| DL-5…DL-7 — Accept akışı | **Geçti** | Admin API şifre + Chrome `/invite/accept?membership_id=…` |
| DL-8 — Liste Aktif | **Geçti** | Operatör onayı + SQL: `status=active` |
| DL-9…DL-11 — Login fallback | **Geçti** | Invite accept URL + giriş (operatör) |
| DL-12…DL-14 — Negatif / güvenlik | **Bekliyor** | Opsiyonel kapanış |
| Audit `invitation.accepted`, source=`settings_invitation_v2d` | **Eksik** | `audit_logs`’ta invitation kaydı yok — accept muhtemelen login bootstrap yolu |

---

## 4. Güvenlik / izolasyon

| Kontrol | Sonuç |
|---------|--------|
| `membership_id` UI’da gösterilmiyor | **Kod review** — yalnızca deep-link query / pending store |
| Audit secret-free (`email`/`token` yok) | **Bekliyor** — E2E sonrası SQL ile doğrulanacak |
| Geçersiz UUID güvenli hata | **Bekliyor** — DL-12 |
| Cross-tenant membership_id | **Bekliyor** — DL-13 |

---

## 5. Sonraki adım

1. Opsiyonel: DL-12 (geçersiz UUID) hızlı negatif kontrol.
2. Audit boşluğu: accept RPC’nin `settings_invitation_v2d` audit yazdığını doğrulamak için tekrar invite + `/invite/accept?membership_id=` ile accept (veya kod incelemesi).
3. Ürün backlog: Auth Site URL / recovery UI / `localhost` redirect staging playbook (runbook §5 Admin API).
4. v2a–v2e **fonksiyonel sign-off** (audit hariç veya takip maddesi).
