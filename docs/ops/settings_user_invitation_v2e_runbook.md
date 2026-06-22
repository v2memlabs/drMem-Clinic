# Settings User Invitation v2e — Staging Deep-link E2E Smoke

**Amaç:** v2d deep-link accept akışını staging’de uçtan uca doğrulamak (mail → redirect → accept → aktif üyelik).

| Alan | Değer |
|------|--------|
| Ortam | `drmem-clinic-dev` (`dgzmybbgrofapjptjspf`) |
| Ön paketler | v2a–v2d (invite/resend/cancel + deep-link) |
| İlgili | [v2c runbook](./settings_user_invitation_v2c_runbook.md), [v2d runbook](./settings_user_invitation_v2d_runbook.md) |

---

## 1. Ön koşullar

1. v2a–v2d migration + `tenant-invite-user-v2` EF staging’de (v2 ≥ deep-link redirect).
2. Supabase Auth:
   - **Redirect URLs** allowlist’te uygulama kökü (web staging URL veya custom scheme hedefi).
   - Opsiyonel EF secret: `TENANT_INVITE_REDIRECT_URLS`.
3. Flutter staging build:
   ```powershell
   flutter run -d windows --dart-define-from-file=secrets/staging.json
   ```
4. Demo doktor: `doctor-a@example.test` (parola secret store’da).
5. `maintenance_config.enabled = false`.

---

## 2. Otomatik smoke (infra)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/staging/run_settings_invitation_v2e_smoke.ps1
```

**Beklenen:**
- `settings_user_invitation_v2d` migration kayıtlı
- `bootstrap_tenant_invited_user_v2` 5-arg overload mevcut
- `accept_my_tenant_invitation_v2(uuid)` EXECUTE grant OK
- Edge Function `tenant-invite-user-v2` ACTIVE

Rapor: [settings_user_invitation_v2e_staging_smoke_report.md](../smoke/settings_user_invitation_v2e_staging_smoke_report.md)

---

## 3. Manuel deep-link E2E checklist

Test e-postası (bugün için örnek): **`mehmetyalcinozan+dl20260607@gmail.com`** (Gmail `+` alias)

> **Önemli — `@example.test` davet maili:** Seed kullanıcılar (`doctor-a@example.test`) admin ile oluşturulur; Auth **`inviteUserByEmail` `@example.test` adreslerini reddedebilir** (`email_address_invalid`). DL-1 için gerçek bir domain kullanın (Gmail `+alias` önerilir).

> `{YYYYMMDD}` runbook **şablonudur** — süslü parantez yazmayın.

Her DL oturumunda benzersiz suffix kullanın (`+dl20260607`, `+dl20260607b`).

### A — Davet + redirect URL

| # | Adım | Beklenen |
|---|------|----------|
| DL-1 | Doctor → Settings → Kullanıcı davet et → yeni e-posta | “Davet gönderildi.” |
| DL-2 | Liste | Satır **Davetli** |
| DL-3 | Davet maili geldi; redirect URL kontrolü (opsiyonel) | Mail **gövdesinde** `membership_id` yok — beklenen. Redirect zincirinde veya operatör SQL ile doğrulanır (aşağıya bakın) |
| DL-4 | SQL: pending invites snapshot | `auth_linked=true`, `has_last_invited_at=true` |

`membership_id` **e-posta metninde ve uygulama UI’da gösterilmez.** Operatör kaynakları:

1. **SQL snapshot** (birincil — DL-4):
   ```sql
   select m.id as membership_id, p.email, m.status
   from public.memberships m
   join public.profiles p on p.id = m.profile_id
   where lower(p.email) = lower('mehmetyalcinozan+dl20260607@gmail.com');
   ```
2. **Tarayıcı adres çubuğu** — davet linkine tıklayıp şifre/redirect adımında URL’de `membership_id=` (localhost hatasından önce kopyalanabilir).
3. Maildeki Supabase linkinin **Query String’i değil** — link `supabase.co/auth/v1/verify?...` ile başlar; `membership_id` hosted redirect hedefindedir.

### B — Şifre + deep-link accept (birincil yol)

| # | Adım | Beklenen |
|---|------|----------|
| DL-5 | Davet linki → şifre belirle | Supabase hosted sayfa OK |
| DL-5b | Redirect sonrası (web) | `/auth/update-password` şifre formu (birincil) |
| DL-6 | Şifre kaydı sonrası | `/invite/accept?membership_id=...` veya doğrudan dashboard |
| DL-7 | Accept ekranı | “Davetiniz işleniyor…” → dashboard |
| DL-8 | Doctor listesi | Davetli → **Aktif** |

### C — Login fallback (oturum yok)

| # | Adım | Beklenen |
|---|------|----------|
| DL-9 | `/invite/accept?membership_id=<uuid>` (geçerli) oturumsuz aç | “Giriş yap” CTA |
| DL-10 | Login davetli e-posta + şifre | Dashboard; üyelik **Aktif** |
| DL-11 | Pending store | Accept sonrası temiz (tekrar login normal) |

### D — Negatif / güvenlik

| # | Adım | Beklenen |
|---|------|----------|
| DL-12 | `/invite/accept?membership_id=not-a-uuid` | “Davet bağlantısı geçersiz.” |
| DL-13 | Yanlış tenant membership_id (başka klinik UUID) | Güvenli hata; cross-tenant accept yok |
| DL-14 | UI | Teknik id / token / invite URL görünmez |

### E — Audit (E2E sonrası SQL)

```sql
select action, metadata->>'source' as source,
       metadata ? 'email' as has_email,
       metadata ? 'token' as has_token,
       created_at
from public.audit_logs
where action = 'invitation.accepted'
order by created_at desc
limit 5;
```

**Beklenen:** `source=settings_invitation_v2d`, `has_email=false`, `has_token=false`.

---

## 4. DL-1 sorun giderme (davet e-postası gitmiyor)

Staging Auth loglarında görülen tipik nedenler:

| Belirti / log | Neden | Çözüm |
|---------------|--------|--------|
| `email_address_invalid`, e-postada `{` veya `}` var | Şablon literal kopyalandı | Tarihi **süslü parantezsiz** yazın: `deeplink-smoke-20260607@example.test` |
| `over_email_send_rate_limit` / 429 | Supabase **saatlik** mail kotası (bugün çok deneme) | **30–60 dk bekleyin**; tekrar denemeyin (kotayı tüketir). Sonra Gmail `+alias` |
| UI: “E-posta gönderim limiti aşıldı…” | `auth_email_rate_limited` | Yukarıdaki bekleme + gerçek domain e-posta |
| UI: “Davet kısa süre önce gönderildi” | Resend 60 sn cooldown (v2b) | 60 sn bekle veya **Yeniden gönder** değil yeni adres |
| `@example.test` davet | Auth `email_address_invalid` | Gmail `+dl…` kullanın; `@example.test` yalnızca seed login içindir |
| `email_exists` / generate_link 422 | Aynı e-posta Auth’ta zaten kayıtlı (önceki deneme) | Yeni benzersiz `@example.test` kullanın veya Auth’tan orphan kullanıcıyı temizleyin |
| UI: “Davet e-postası gönderilemedi” | Auth invite / redirect hatası | Dashboard → Auth → Redirect URLs allowlist; EF `TENANT_INVITE_REDIRECT_URLS` (opsiyonel) |
| UI: “Geçerli bir e-posta adresi girin” | EF `invalid_email` veya eski `self_invite_blocked` eşlemesi | Format düzeltin; **doctor-a@example.test ile giriş yaptıysanız aynı adresi davet etmeyin** |
| UI: “Kendi e-posta adresinize…” | `self_invite_blocked` | Giriş yaptığınız e-postadan farklı bir adres kullanın |
| UI: “Bu e-posta adresi zaten bir hesap…” | `auth_user_exists` — Gmail staging Auth’ta kayıtlı | `@example.test` test adresi kullanın; Gmail için 15–60 dk bekleyin |
| UI: “İşlem tamamlanamadı” | Eski sürüm / parse edilemeyen EF hatası | Uygulamayı hot restart; Gmail `+alias` deneyin |
| Redirect `localhost:3000` / siteye ulaşılamıyor | Auth Site URL = localhost; Windows desktop HTTP yok | Runbook §5 — Chrome fallback veya Dashboard URL config |

Hızlı doğrulama (operatör):

1. E-posta: `deeplink-smoke-20260607@example.test`, görünen ad + rol (Asistan).
2. Başarı → SnackBar **“Davet gönderildi.”** + listede **Davetli**.
3. Başarısız → Flutter’daki kırmızı hata metnini not edin; Edge Function log: Dashboard → Edge Functions → `tenant-invite-user-v2` → Logs.

---

## 5. Windows desktop — localhost:3000 redirect

**Belirti:** Davet mailinde `membership_id` var (DL-3 ✓), şifre sayfasından sonra `http://localhost:3000/invite/accept?...` → “siteye ulaşılamıyor”.

**Neden:** Supabase Auth **Site URL** varsayılanı `http://localhost:3000`. Windows desktop build bu portta HTTP sunucusu çalıştırmaz.

### Hemen (DL-5 → accept) — önerilen yol

1. **Şifre:** Mail linkindeki Supabase sayfasında şifreyi belirleyin. Redirect hata verse bile şifre çoğu zaman kaydedilir.
2. **Accept (Chrome fallback — v2e Windows birincil yol):**
   ```powershell
   flutter run -d chrome --dart-define-from-file=secrets/staging.json
   ```
3. Terminalde görünen port ile tarayıcıda açın:
   ```
   http://localhost:<port>/invite/accept?membership_id=bd589f99-c837-492e-a8d8-bea8349063ec
   ```
4. **Giriş yap** → `mehmetyalcinozan+dl20260607@gmail.com` + yeni şifre → dashboard (DL-8, DL-10).
5. Doctor listesinde **Aktif** doğrulayın.

> Yalnızca Windows desktop ile `/invite/accept` route’una OS deep link yok; Chrome yolu v2e kabul kriterlerini karşılar (`settings_invitation_v2d` audit).

### Kalıcı (opsiyonel) — Supabase Dashboard

**Authentication → URL Configuration:**

| Alan | Staging smoke önerisi |
|------|------------------------|
| Site URL | Chrome dev kökü, örn. `http://localhost:7357` (kullandığınız port) |
| Redirect URLs | `http://localhost:**/**` ( `/auth/update-password`, `/invite/accept` dahil ) |

Edge Function secret (opsiyonel): `TENANT_INVITE_REDIRECT_URLS=http://localhost:7357`

Yeni davet/resend sonrası mail redirect doğru porta gider. Mevcut davet için yukarıdaki manuel URL yeterli.

### Şifre ekranı açılmıyor

1. Redirect URLs allowlist'te `/auth/update-password` ve kullandığınız port var mı?
2. Chrome ile `flutter run -d chrome --web-port=3000` deneyin.
3. Checklist: [auth_password_recovery_e2e_runbook.md](./auth_password_recovery_e2e_runbook.md)

### Admin API (son çare — operatör)

Dashboard’da yalnızca “Send password recovery” / “Send magic link” varsa; mail linkleri `localhost:3000`’e gider ve uygulamada şifre ekranı yok. **service_role** ile şifre set edin:

```powershell
$sr = "YOUR_SERVICE_ROLE"   # Dashboard → Project Settings → API
$headers = @{
  apikey = $sr
  Authorization = "Bearer $sr"
  "Content-Type" = "application/json"
}
$body = '{"password":"StagingDl2026!Test"}'
Invoke-RestMethod -Method PUT `
  -Uri "https://dgzmybbgrofapjptjspf.supabase.co/auth/v1/admin/users/21a1b95c-97cd-4fbc-812f-13f89d83645a" `
  -Headers $headers -Body $body
```

Sonra Chrome → `/invite/accept?membership_id=<uuid>` → giriş. (v2e smoke’da operatör kanıtı: API şifre + invite accept URL.)

---

## 6. Karar kriterleri

| Karar | Koşul |
|-------|--------|
| **Geçti** | DL-1…DL-14 + audit v2d + otomatik infra smoke |
| **Kısmen** | Infra geçti; mail/redirect platform kısıtı (Windows scheme) |
| **Blocked** | Redirect allowlist eksik, EF eski sürüm, accept RPC yok |

---

## 7. Kapsam dışı

Native `app_links` entegrasyonu, multi-tenant invite picker, otomatik mail crawler.
