# Staging Remote Verification Result v1

> **Tarih:** 2026-05-28  
> **Proje:** drmem-clinic-dev (`dgzmybbgrofapjptjspf`)  
> **Operatör:** Agent (Supabase MCP)  
> **Runbook:** [staging_remote_gate_rls_verification_v1.md](../ops/staging_remote_gate_rls_verification_v1.md)

---

## 1. Özet karar (final)

| Boyut | Önce | Sonra |
|-------|------|-------|
| **202607* tablolar** | ❌ Yok | ✅ Uygulandı |
| **Kök neden (ops “yüklenemedi”)** | Migration eksik (ilişkili) | ✅ Migration’lar uygulandı; ayrıca operasyonel kayıt parse’inde enum uyuşmazlığı tespit edildi ve staging sample değerleri düzeltildi |
| **Auth zinciri Tenant A** | ✅ | ✅ (değişmedi) |
| **PDF/storage schema** | ✅ | ✅ |
| **Flutter UI smoke** | — | ✅ **Final PASS (kritik akışlar)** |

**Karar:** Staging smoke patch hardening sonrası kritik akışlar **PASS**.  
**Not:** PDF source/save/open ayrı paket kapsamında.

---

## 2. Uygulanan migration'lar (MCP `apply_migration`)

| Sıra | Migration adı | Durum |
|------|-----------------|-------|
| 1 | `operational_records_remote_v2a` | ✅ payments + consents |
| 2 | `operational_records_remote_v2b_inventory` | ✅ inventory tablolar + RLS |
| 3 | `operational_records_remote_v2b_inventory_rpc` | ✅ `record_inventory_movement` |
| 4 | `ftr_referral_remote_v1` | ✅ physiotherapy_referrals |
| 5 | `ftr_sessions_remote_v2` | ✅ physiotherapy_sessions |
| 6 | `ftr_sessions_insert_policy_hardening_v1` (repo migration) | ✅ physio seans insert RLS hardening |

**Henüz uygulanmadı:** `20260602100000_maintenance_bootstrap_console_v1` (opsiyonel; smoke v2 bloklayıcı değil)

**Not:** `20260601100000_auth_context_helper_hotfix_v1` staging'de zaten `20260529055501` eşdeğeri ile mevcut.

---

## 3. Schema doğrulama (Script 1 — sonrası)

| Tablo | exists | RLS | policy_count |
|-------|--------|-----|--------------|
| payments | ✅ | ✅ | 3 |
| consents | ✅ | ✅ | 3 |
| inventory_items | ✅ | ✅ | 3 |
| inventory_movements | ✅ | ✅ | 1 |
| physiotherapy_referrals | ✅ | ✅ | 5 |
| physiotherapy_sessions | ✅ | ✅ | 4 |
| `record_inventory_movement` | ✅ | — | — |

---

## 4. Auth / membership (Script 2)

| Kullanıcı | auth_user_id | Membership | Not |
|-----------|--------------|------------|-----|
| doctor-a | ✅ | active / Tenant A | OK |
| assistant-a | ✅ | active | OK |
| physio-a | ✅ | active | OK |
| nurse-a | ✅ | active | OK |
| doctor-b | ❌ NULL | active | Cross-tenant test öncesi bootstrap |

Tenant A aktif hasta: **11**

---

## 5. Yapısal smoke insert (service_role)

| Modül | Sonuç | Kanıt |
|-------|-------|-------|
| Payment INSERT | ✅ | `payments_count = 1` |
| Consent INSERT (bekliyor) | ✅ | `pending_consents = 1` |
| Inventory item INSERT | ✅ | `inventory_count = 1` |
| FTR referral INSERT | ✅ | `id = dc513618-40f7-4901-902d-2f644273371e` |
| FTR session INSERT | ⏳ | MCP kesinti; şema hazır — Flutter ile doğrula |
| `record_inventory_movement` RPC | ⚠️ | `42501 INV_MOV_FORBIDDEN` (service_role, `auth.uid()` yok — **beklenen**) |

### Not: operasyonel UI “yüklenemedi” açıklaması

- Client enum parse için staging sample değerleri kodun beklediği stringlerle uyuşmuyordu:
  - `payments.invoice_status = fatura_yok` → `gerekmiyor`
  - `consents.consent_type = bilgilendirilmis_onam` → `acikRiza`
  - `inventory_items.category = sarf` → `sarfMalzeme`
- Bu değerler staging’de güncellendi; tekrar UI smoke ile kontrol edilmesi gerekiyor.

Sonuç (tekrar smoke): listeler açıldı, create akışları ilerledi.

## 6. UI smoke patch sonucu (final pass)

| Akış | Sonuç |
|------|-------|
| doctor payment create | ✅ PASS |
| doctor consent create | ✅ PASS |
| nurse inventory item/movement | ✅ PASS |
| assistant payment/consent access | ✅ PASS |
| physio referral → session patient prefill/lock | ✅ PASS |
| physio referral → exercise patient prefill/lock | ✅ PASS |
| physio session save | ✅ PASS |
| physio exercise save | ✅ PASS |

### Kapanan kök nedenler

1. `physiotherapy_sessions` INSERT policy physio rolünde `patients` alt sorgusuna bağlıydı → 42501.
2. `PatientSelectorField` locked context’te preview olmasına rağmen lookup null ile notFound’a düşüyordu.
3. Session/exercise save fallback’i route/referral patient id varken dahi gereksiz lookup bağımlılığı taşıyordu.
4. Session repository profile id çözümü store id sapması riski taşıyordu.

---

## 7. PDF / storage (Script 4)

| Kontrol | Durum |
|---------|-------|
| Bucket private | ✅ |
| Storage policies SELECT+INSERT | ✅ |
| pdf_outputs 3/3 storage_path | ✅ |

---

## 8. Operatör — Flutter smoke tekrar listesi

```powershell
flutter run -d windows --dart-define-from-file=secrets/staging.json
```

| # | Kullanıcı | Ekran | Beklenen |
|---|-----------|-------|----------|
| 1 | doctor-a | Ödemeler listesi | Yüklenir (200) |
| 2 | doctor-a | Onamlar | Yüklenir |
| 3 | doctor-a | Stok | Yüklenir |
| 4 | doctor-a | FTR Yönlendirmeler | Yüklenir (smoke referral görünebilir) |
| 5 | physio-a | FTR seans ekle | Başarılı |
| 6 | nurse-a | Stok hareket | RPC JWT ile OK |
| 7 | assistant-a | Ödeme/onam | Liste OK (sidebar route ayrı) |

---

## 9. Kalan riskler

1. **PDF source/save/open** — ayrı stabilization paketi  
2. **doctor-b auth gap** — cross-tenant manuel test için bootstrap  
3. **Maintenance console** migration opsiyonel deploy  
4. **Repo ↔ staging migration kayıt adları** — `supabase db push` ile `schema_migrations` senkronu önerilir (CI tek kaynak)
5. **Physio appointment/PDF permission** — ürün kararı
6. **UI/UX friction** — ayrı polish paketi

---

## 10. Sonraki paket önerisi

1. Flutter smoke v2 tekrar (bu rapor §7)  
2. Remote Failure Debug Logging v1 (log yetersizse)  
3. PDF Remote Source & Save Stabilization Pack
