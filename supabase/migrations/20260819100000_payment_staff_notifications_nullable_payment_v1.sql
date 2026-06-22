-- Cerrahi teklif bildirimleri payment_id olmadan kaydedilebilsin.

alter table payment_staff_notifications
  alter column payment_id drop not null;
