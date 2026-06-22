/// Teknik olmayan audit hata sınıfları (metadata).
abstract final class AuditAccessFailureCategory {
  static const String forbidden = 'forbidden';
  static const String notConfigured = 'not_configured';
  static const String noActiveTenant = 'no_active_tenant';
  static const String notFound = 'not_found';
  static const String network = 'network';
  static const String invalidData = 'invalid_data';
  static const String unknown = 'unknown';
}
