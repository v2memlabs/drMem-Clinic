/// FTR modülü — Supabase şema hazırlık bayrakları.
///
/// Migration/RLS yokken remote gate kapalı kalır; mock adapter kullanılır.
abstract final class FtrRemoteCapabilities {
  static const bool referralsTableReady = true;
  static const bool sessionsTableReady = true;
}
