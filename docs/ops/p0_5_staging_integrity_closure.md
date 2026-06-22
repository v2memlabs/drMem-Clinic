# P0.5 Staging Integrity Closure

> **Paket:** Migration bütünlüğü, staging history hizalama, JWT/RLS doğrulama  
> **Tarih:** 2026-06-07  
> **Proje:** drmem-clinic-dev (`dgzmybbgrofapjptjspf`)  
> **Genel karar:** **Conditional Pass**

## Özet

| Alan | Sonuç |
|------|--------|
| Migration history repair | **Tamam** — local/remote hizalı |
| Staging P0 aktif nesneler | **Pass** |
| `supabase db push --dry-run` | **Up to date** — blind push gerekmez |
| Fresh local `supabase db reset` | **Blocked** — Docker Desktop yok |
| JWT role-matrix smoke (canlı) | **Kısmi** — yapısal SQL pass; canlı JWT matrisi operatör adımı |

---

## 1. Fresh DB reset sonucu

**Blocked** — ortam ön koşulu karşılanmadı.

```text
docker: command not found
supabase status → docker_engine pipe yok
```

**Gerekli aksiyon (operatör):**

1. Docker Desktop kurulumu ve başlatma
2. `supabase start`
3. `supabase db reset`
4. Bu dokümandaki §3 contract sorgularını local DB'de tekrarla

Forward-compat migrationlar fresh chain için hazır:

- `20260602125000_ftr_forward_compat_stub_v1.sql`
- `20260607095900_user_mgmt_helpers_forward_compat_v1.sql`
- `20260805100000_p0_stabilization_integrity_pack_v1.sql`

---

## 2. Migration repair — öncesi

| Kategori | Kayıt |
|----------|-------|
| Local-only | `20260602125000`, `20260607095900`, `20260805100000` |
| Remote-only | `20260608192058` (MCP alias) |
| Eşdeğer hotfix | Remote MCP SQL ≈ Local `20260805100000` |

`supabase migration list --linked` (repair öncesi): 3 satır fark.

---

## 3. Uygulanan repair komutları

History-only repair (schema SQL çalıştırmaz):

```powershell
supabase migration repair --status applied 20260602125000
supabase migration repair --status applied 20260607095900
supabase migration repair --status applied 20260805100000
supabase migration repair --status reverted 20260608192058
supabase migration list --linked
```

**Sonuç:** Tüm satırlar local | remote eşleşti (32 migration).

---

## 4. Canonical migration kararı

| Migration | Rol |
|-----------|-----|
| `20260602125000` | Forward-compat FTR stub (fresh chain) |
| `20260607095900` | Forward-compat user mgmt helpers |
| `20260805100000` | **Canonical P0 hotfix** |
| `20260608192058` | **Reverted** — MCP alias, çift kayıt kaldırıldı |

**Kural:** MCP `apply_migration` kullanılırsa aynı gün local canonical dosya + `migration repair` ile history hizalanmalı.

---

## 5. Staging aktif nesne doğrulaması

| Nesne | Durum |
|-------|--------|
| `update_tenant_membership_status_v1` | `invitation_acceptance_required` + `invitation_flow_required` |
| `record_audit_access_event` | `profiles.auth_user_id` + tenant membership guard |
| `_storage_object_metadata_visible` | Mevcut |
| `patient_files_storage_select_v1` | `_storage_object_metadata_visible(name)` kullanıyor |
| FTR INSERT | Tek policy: `physiotherapy_sessions_insert_doctor_physio_hardened_v1` |

`supabase db push --dry-run` → **Remote database is up to date.**

---

## 6. JWT role matrix

### Yapısal smoke (SQL)

Script: `scripts/staging/p0_5_staging_integrity_jwt_smoke_checks.sql`

```powershell
supabase db query --linked -f scripts/staging/p0_5_staging_integrity_jwt_smoke_checks.sql
```

### Demo test hesapları (parola repoda yok)

| E-posta | Rol | Tenant A |
|---------|-----|----------|
| `doctor-a@example.test` | doctor_admin | A |
| `assistant-a@example.test` | assistant_secretary | A |
| `physio-a@example.test` | physiotherapist | A |
| `nurse-a@example.test` | nurse | A |
| `doctor-b@example.test` | doctor_admin | B (cross-tenant) |

Şifreler staging secret store'da; rapora yazılmaz.

### Beklenen matris (authenticated JWT)

**Invitation**

- Doctor: `invited→active` deny (`invitation_acceptance_required`)
- Doctor: `disabled→invited` deny (`invitation_flow_required`)
- Invited user: `accept_my_tenant_invitation_v2` → active

**Storage metadata/object parity** (Tenant A seed)

| Dosya scope | doctor | assistant | physio | nurse |
|-------------|--------|-----------|--------|-------|
| `doctor_admin` | allow | deny | deny | deny |
| `clinic_operations` | allow | allow | deny | deny |
| `physiotherapy` | allow | deny | allow | deny |

**FTR INSERT**

- doctor: allow (referral/patient/tenant eşleşmesi)
- physio: allow (`physiotherapist_profile_id = current_profile_id()`)
- assistant / nurse: deny

### Canlı JWT smoke durumu

Yapısal contract ve policy tanımları doğrulandı. Tam JWT matrisi (PostgREST/Flutter ile RPC çağrıları) operatör tarafından demo hesaplarla tamamlanmalı — bu pakette otomatik auth credential mevcut değildi.

---

## 7. Test sonuçları

| Suite | Sonuç |
|-------|--------|
| P0 odaklı (`test/supabase/`, membership, maintenance, audit, storage) | **145/145 pass** |
| Tam `test/settings/` | **3 compile fail** (önceden var; fake repo stub eksik — P0.5 kapsamı dışı) |
| Tam `test/features/physiotherapy/` | **318/321 pass** (3 fail yok; 3 settings load error) |

---

## 8. flutter analyze

Lib değişikliği yapılmadı — analyze atlandı.

---

## 9. Cleanup adımları

JWT invitation smoke sırasında oluşturulan test membership'leri:

```sql
-- Yalnız smoke test membership'leri için; gerçek kullanıcıları etkileme
update memberships set status = 'disabled', updated_at = now()
where id = '<smoke_test_membership_id>' and status = 'invited';
```

FTR test session kayıtları:

```sql
update physiotherapy_sessions set deleted_at = now()
where notes like '%P0.5 smoke%' and deleted_at is null;
```

---

## 10. Gelecek migration deploy kuralları

1. **Geçmiş migration rewrite etme**
2. **Blind `db push` yapma** — önce `migration list --linked` + `db push --dry-run`
3. Security hotfix → yeni ileri tarihli forward migration (`20260805100000` modeli)
4. Fresh chain kırığı → forward-compat migration (`20260602125000` modeli)
5. MCP `apply_migration` → aynı gün local dosya + `migration repair`
6. Fresh doğrulama → `supabase db reset` (Docker gerekli)
7. Staging doğrulama → `p0_5_staging_integrity_jwt_smoke_checks.sql` + JWT matris

---

## 11. Sonraki paket önerisi

1. **Docker + Fresh Reset Closure** — local chain kanıtı
2. **Session Restore v1**
3. **Remote-Only Fail-Fast v1**
4. **Remote Parity Sprint**
