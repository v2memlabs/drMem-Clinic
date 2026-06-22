# Maintenance / Bootstrap Console v1 — Spec

> **Durum:** Uygulandı  
> **Migration:** `supabase/migrations/20260602100000_maintenance_bootstrap_console_v1.sql`  
> **Runbook:** [staging_bootstrap_runbook_v1.md](../ops/staging_bootstrap_runbook_v1.md)

## Ortam

| Define | Değer |
|--------|--------|
| `DATA_BACKEND` | `supabase` |
| `APP_ENV` | `staging` veya `dev` |
| `MAINTENANCE_MODE` | `true` |

## DB

- `maintenance_config.enabled` — production: `false`; staging seed: `true`
- `profiles.maintenance_operator` — staging: `doctor-a` profile

## RPC (authenticated)

| RPC | Tür |
|-----|-----|
| `maintenance_ping` | Okuma |
| `maintenance_get_bootstrap_chain` | Okuma |
| `maintenance_list_tenants` | Okuma |
| `maintenance_list_memberships` | Okuma |
| `maintenance_list_profile_auth_gaps` | Okuma |
| `maintenance_list_audit_events` | Okuma |
| `maintenance_link_profile_auth` | Yazma + audit |
| `maintenance_create_profile` | Yazma + audit |
| `maintenance_update_profile` | Yazma + audit |
| `maintenance_update_tenant_status` | Yazma + audit |
| `maintenance_create_membership` | Yazma + audit |
| `maintenance_update_membership_role` | Yazma + audit |
| `maintenance_update_membership_status` | Yazma + audit |

## Flutter routes

- `/maintenance` — yalnız `AppMaintenanceConfig.isAvailable`

## Güvenlik

- `service_role` istemcide yok
- `doctor_admin` tek başına yetmez
- Production route register edilmez
