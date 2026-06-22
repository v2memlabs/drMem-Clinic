# Realtime (Draft Not)

MVP dışı — Faz 6.

- Kanallar tenant prefix: `tenant:{id}:...`
- Postgres changes + RLS — kullanıcı yalnızca policy’den geçen satırları alır.
- `internal_doctor_note` içeren satırlar fizyoterapist/asistan subscription’ına düşmemeli.
- Audit realtime push önerilmez (pull/liste yeterli).
