/// Aktif veri kaynağı — uygulama varsayılanı [DataBackend.mock].
enum DataBackend {
  /// Mevcut in-memory mock repository'ler (MVP/demo).
  mock,

  /// Supabase/PostgreSQL remote (gelecek faz; henüz bağlanmıyor).
  supabase,
}
