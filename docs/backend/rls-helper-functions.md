# RLS Helper Functions (Draft)

Şema: `20260521100000_draft_saas_schema_rls_v1.sql`  
Policy: `20260522100000_draft_rls_policies_v1.sql` (draft)

| Fonksiyon | Amaç |
|-----------|------|
| `current_auth_user_id()` | `auth.uid()` |
| `current_profile_id()` | JWT `profile_id` veya `profiles.auth_user_id` |
| `current_tenant_id()` | JWT `tenant_id` veya tek active membership |
| `is_tenant_member(tenant_id)` | Aktif membership |
| `has_tenant_role(tenant_id, roles[])` | Rol kontrolü |
| `has_permission(tenant_id, key)` | `role_permissions` join |

## Uyarılar

- Faz 1 öncesi JWT claim’leri **tanımlı değil** — fonksiyonlar staging’de test edilmeli.
- **`service_role` istemcide kullanılmaz** — yalnızca güvenilir sunucu/edge.
- `SECURITY DEFINER` fonksiyonları gözden geçirilmeli (search_path sabit).

## internal_doctor_note

- Tam tablo: `doctor_admin` SELECT policy (draft).
- Diğer roller: `clinical_encounter_operational_summary` view (iç not yok).
