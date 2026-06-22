# Settings User Invitation v2c — Staging Smoke Raporu

| Alan | Değer |
|------|--------|
| Paket | Settings User Invitation v2c — Staging smoke + runbook |
| Tarih | 2026-06-07 |
| Ortam | `drmem-clinic-dev` (`dgzmybbgrofapjptjspf`) |
| Runbook | [settings_user_invitation_v2c_runbook.md](../ops/settings_user_invitation_v2c_runbook.md) |

## Genel karar

| Karar | **Kısmen geçti** (infra deploy OK; manuel E2E operatör bekliyor) |
|-------|---------------------------------------------------------------------|
| Gerekçe | DB migration + Edge Function staging’de doğrulandı. Mail/login/resend/cancel UI E2E operatör oturumu gerektirir. |

---

## 1. Deploy sonuçları

| Bileşen | Sonuç | Not |
|---------|--------|-----|
| `user_membership_management_v1` | **Geçti** | `supabase db query --linked -f` |
| `settings_user_invitation_v2a` | **Geçti** | RPC + status guard |
| `settings_user_invitation_v2b` | **Geçti** | `last_invited_at`, resend/cancel RPC |
| `schema_migrations` kaydı | **Geçti** | 3 satır insert (conflict skip) |
| Edge Function `tenant-invite-user-v2` | **Geçti** | v1 ACTIVE, `verify_jwt=true` |

---

## 2. Otomatik SQL smoke

| Kontrol | Sonuç | Kanıt |
|---------|--------|-------|
| 7 invitation/user-mgmt RPC | **Geçti** | `bootstrap_*`, `accept_*`, `prepare_*`, `complete_*`, `cancel_*`, `list_tenant_memberships_v1`, `_user_mgmt_assert_doctor_admin` |
| `memberships.last_invited_at` | **Geçti** | `timestamptz` kolonu mevcut |
| RPC EXECUTE grants | **Geçti** | bootstrap/accept/cancel → `true` |
| Demo doctor seed | **Geçti** | `doctor-a@example.test`, `doctor-b@example.test` → auth_linked, doctor_admin, active |
| Maintenance isolation | **Geçti** | `maintenance_config.enabled = false` |
| Audit tablo adı | **Düzeltildi** | Smoke script `audit_logs` kullanıyor (staging’de `audit_access_events` yok) |

---

## 3. Manuel smoke (operatör checklist)

| Madde | Sonuç | Not |
|-------|--------|-----|
| Invite → mail → login → active | **Bekliyor** | Operatör: v2c runbook §4-A |
| Resend success | **Bekliyor** | Operatör: §4-B |
| Resend cooldown (60 sn) | **Bekliyor** | Operatör: §4-B |
| Cancel → disabled, Auth korunur | **Bekliyor** | Operatör: §4-C |
| Active/disabled satırda resend/cancel yok | **Bekliyor** | Operatör: §4-D |
| Audit secret-free | **Bekliyor** | Smoke sonrası runbook §5 SQL |

---

## 4. Güvenlik / izolasyon

| Kontrol | Sonuç |
|---------|--------|
| `service_role` Flutter’da yok | **Geçti** (repo standardı) |
| Edge Function JWT zorunlu | **Geçti** |
| Maintenance provisioning ayrı | **Geçti** (`maintenance-provision-user-v2` ayrı slug) |
| Cross-tenant | **Kod review** — RPC `current_tenant_id` gate; E2E operatörde doğrulanacak |

---

## 5. Sonraki adım

1. Operatör manuel checklist (runbook §4) — tek oturumda v2a+v2b birlikte.
2. Audit SQL (§5) sonuçlarını bu rapora ekle.
3. Deep-link accept staging E2E: [v2e runbook](../ops/settings_user_invitation_v2e_runbook.md) · [v2e smoke raporu](./settings_user_invitation_v2e_staging_smoke_report.md).
4. v2a–v2e tamamlandığında Settings paketi sign-off; sonraki paket önerisi **Seat limit enforcement** (ürün önceliğine göre).
