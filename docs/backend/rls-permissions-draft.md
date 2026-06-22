# RLS ve Permission Taslağı

> Güncel detay: [permission-rls-matrix.md](permission-rls-matrix.md), SQL: `supabase/migrations/20260521100000_draft_saas_schema_rls_v1.sql`

## Temel ilke

1. **UI permission (`AuthSession.canView*`) yalnızca UX içindir** — route gizleme ve buton devre dışı bırakma.
2. **Backend RLS (veya eşdeğer policy) zorunludur** — istemci bypass edilebilir.
3. **Realtime** olayları da aynı tenant + rol filtresinden geçmelidir.

## Tenant izolasyonu

- JWT veya session claim: `tenant_id` (aktif membership).
- Her SELECT/INSERT/UPDATE/DELETE policy’si `tenant_id` eşleşmesi ister.
- `memberships.status = 'active'` ve `user_id = auth.uid()` kontrolü.

## Rol kontrolü

| Rol | Örnek kısıt |
|-----|-------------|
| doctor_admin (Flutter: doctor) | Tam klinik veri, audit, PDF |
| assistant_secretary (Flutter: assistant) | Hasta/randevu/onam/ödeme; tam muayene yok |
| physiotherapist | FTR/egzersiz/post-op; ödeme/audit yok |
| nurse | Hasta temel + stok; PDF/audit/tam muayene yok |

Rol → permission matrisi `role_permissions` + policy helper fonksiyonları (`has_permission('clinical_encounter.read_full')`).

## Hassas alanlar

- `clinical_encounters.internal_doctor_note`: ayrı kolon veya JSONB alt alanı.
- Fizyoterapist/asistan için **projection view** (`clinical_encounter_operational_summary`) — iç not yok.
- Realtime subscription fizyoterapiste tam encounter satırı push etmemeli.

## Audit

- İstemci `audit_logs` INSERT yapmaz (trigger / edge function).
- Okuma yalnızca doctor (veya tenant admin).

## Storage

- Object path: `{tenant_id}/...`
- Signed URL öncesi DB’de dosya kaydı + rol kontrolü.

## Test checklist (Faz 1+)

- [ ] Tenant A kullanıcısı Tenant B `patients` satırını SELECT edemez
- [ ] Asistan `internal_doctor_note` göremez
- [ ] Realtime channel başka tenant event almaz
