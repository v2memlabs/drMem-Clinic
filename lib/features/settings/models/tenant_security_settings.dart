import '../../../core/settings/app_settings.dart';

/// Tenant-scoped güvenlik tercihleri (`tenants.settings_json.security`).
class TenantSecuritySettings {
  final AutoLockDurationKind autoLockDuration;

  const TenantSecuritySettings({
    this.autoLockDuration = AutoLockDurationKind.min15,
  });

  static const TenantSecuritySettings defaults = TenantSecuritySettings();

  TenantSecuritySettings copyWith({
    AutoLockDurationKind? autoLockDuration,
  }) {
    return TenantSecuritySettings(
      autoLockDuration: autoLockDuration ?? this.autoLockDuration,
    );
  }
}
