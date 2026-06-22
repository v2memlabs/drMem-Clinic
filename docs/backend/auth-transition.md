# Auth Transition — Mock + Supabase Auth v1

## Mock auth & login (varsayılan)

- `DATA_BACKEND` verilmezse veya boş URL/key ile `supabase` istenirse → **mock**.
- Rol **login dropdown**'dan gelir.
- Login: `RepositoryRegistry.auth.signInMock` → `AuthSessionBridge.setFromMockUser`.
- Hasta, randevu, muayene, stok, PDF → **mock repository** (değişmedi).

## Supabase Auth Gerçek Bağlantı v1

Aktif yalnızca:

```bash
flutter run \
  --dart-define=DATA_BACKEND=supabase \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

- `supabase_flutter` + `SupabaseClientInitializer` (anon key; **service_role yok**).
- Login: e-posta + şifre; **rol dropdown yok**.
- Rol `memberships.role` → `TenantRoleMapper` → Flutter rol.
- Akış: `signInWithPassword` → `profiles` (auth_user_id) → `memberships` + `tenants` → `ActiveTenantSelector` → `AuthSessionBridge.setFromBootstrapContext` → `SessionReadiness` = `ready`.
- Tek aktif membership → otomatik active tenant; çoklu → güvenli failure / sonraki faz mesajı.
- Bootstrap başarısızsa dashboard yok; oturum açılmaz (`_abortAuthenticatedSignIn` + kullanıcı mesajı).

| Durum | Davranış | Kullanıcı mesajı (Supabase) |
|--------|----------|------------------------------|
| Profil yok / üyelik yok | Failure, oturum yok | Aktif klinik üyeliği bulunamadı |
| Pasif membership | Failure | Klinik üyeliğiniz aktif değil |
| Pasif tenant | Failure | Klinik hesabı aktif değil |
| Bilinmeyen rol | Failure (fallback yok) | Rol bilgisi tanınamadı |
| Birden fazla aktif membership | Failure | Klinik seçimi sonraki sürümde aktif edilecektir |
| Yanlış şifre / auth hata | Failure | Giriş bilgileri doğrulanamadı |

## Manuel test checklist — Auth Test v1

### Kod / birim test (otomatik)

- [x] `test/auth_bootstrap_test.dart` — rol eşlemesi, selector failure durumları, mesaj metinleri
- [x] `flutter analyze` — 0 error hedefi

### Mock mod (manuel)

- [x] Kod: `AppBackendConfig.isMock` varsayılan; rol dropdown yalnız mock (`login_screen.dart`)
- [x] Kod: dört rol → `TenantRoleMapper` + `AuthSession.dashboardRoute` (`/doctor`, `/assistant`, `/physio`, `/nurse`)
- [ ] Manuel: demo doctor / assistant / physio / nurse login + sidebar + mock hasta listesi

### Supabase mod (manuel — staging dart-define gerekir)

- [x] Kod: login e-posta + şifre; rol dropdown **yok**
- [x] Kod: dört DB rolü → Flutter dashboard rolü (`auth_bootstrap_test.dart`)
- [ ] Manuel: `doctor@example.test` → `/doctor` + tenant sidebar
- [ ] Manuel: `assistant@example.test` → `/assistant`
- [ ] Manuel: `physio@example.test` → `/physio`
- [ ] Manuel: `nurse@example.test` → `/nurse`
- [ ] Manuel: yanlış şifre → snackbar mesajı
- [ ] Manuel: profil/üyelik eksik kullanıcı → dashboard yok
- [ ] Manuel: logout → `/login`, session temiz

### Failure durumları (kod)

- [x] Bootstrap/bridge başarısız → `_abortAuthenticatedSignIn` (Supabase signOut + bridge + readiness)
- [x] Dashboard yönlendirmesi yalnız `SessionReadiness.isReady` + başarılı login

### Klinik veri

- [x] Kod: `PatientRepositoryProvider` Supabase modda da **mock** adapter döner
- [ ] Manuel: Supabase login sonrası hasta/randevu/muayene ekranları mock veri gösterir

### Seed bağımlılığı

Staging manuel testler için [seed-plan.md](seed-plan.md) kullanıcıları gerekir (`auth.users` + `profiles` + `memberships`). Eksik seed → kod yamasi değil, **Supabase seed düzeltmesi gerekir**.

## Paket sırası

1–9 Supabase Auth v1 ✓  
10. **Auth Manuel Test v1** ✓ (kod düzeltmeleri + test)  
11. Remote klinik veri repository — bekliyor
