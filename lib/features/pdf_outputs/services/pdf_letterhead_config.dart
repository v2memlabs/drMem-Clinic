import '../../../core/constants/app_branding.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/settings/app_settings_controller.dart';

/// Belge üretim anı antet bilgileri (ileride snapshot JSON'a genişletilebilir).
class PdfLetterheadConfig {
  final String productName;
  final String tagline;
  final String clinicName;
  final String specialty;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String logoAssetPath;
  /// Ayarlar → Klinik Bilgileri'nde yüklenen logo depolama yolu.
  final String? logoStoragePath;
  final DateTime generatedAt;
  final String? generatedBy;

  const PdfLetterheadConfig({
    required this.productName,
    required this.tagline,
    required this.clinicName,
    required this.specialty,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.logoAssetPath,
    this.logoStoragePath,
    required this.generatedAt,
    this.generatedBy,
  });

  factory PdfLetterheadConfig.fromCurrentSettings({String? generatedBy}) {
    final settings = appSettingsController.settings;
    final tenant = ActiveTenantContextStore.current?.tenant;

    final tenantName = tenant?.name.trim() ?? '';
    final tenantSpecialty = tenant?.specialty.trim() ?? '';

    final clinicName = tenantName.isNotEmpty
        ? tenantName
        : (settings.clinicName.trim().isNotEmpty
            ? settings.clinicName.trim()
            : AppBranding.clinicName);

    final specialty = tenantSpecialty.isNotEmpty
        ? tenantSpecialty
        : settings.specialty.trim();

    return PdfLetterheadConfig(
      productName: AppBranding.productName,
      tagline: AppBranding.productTagline,
      clinicName: clinicName,
      specialty: specialty,
      address: settings.address.trim(),
      phone: settings.phone.trim(),
      email: settings.email.trim(),
      website: settings.website.trim(),
      logoAssetPath: AppBranding.logoAsset,
      logoStoragePath: null,
      generatedAt: DateTime.now(),
      generatedBy: generatedBy?.trim().isNotEmpty == true ? generatedBy!.trim() : null,
    );
  }

  static const String defaultFooterNotice =
      'Bu belge, klinik değerlendirme sonrası bilgilendirme amacıyla hazırlanmıştır. '
      'Tedavi planı kişiye özeldir; hekim önerisi dışında uygulanmamalıdır. '
      'Kişisel sağlık verisi içerir — yetkisiz paylaşım yapılmamalıdır.';
}
