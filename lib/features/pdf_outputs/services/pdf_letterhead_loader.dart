import '../../../core/constants/app_branding.dart';
import '../../settings/data/tenant_settings_repository.dart';
import '../../settings/data/tenant_settings_repository_provider.dart';
import 'pdf_letterhead_config.dart';

/// Ayarlar → Klinik Bilgileri'nden antet yükler; hata durumunda yerel ayarlara düşer.
abstract final class PdfLetterheadLoader {
  static Future<PdfLetterheadConfig> load({String? generatedBy}) async {
    try {
      final info =
          await TenantSettingsRepositoryProvider.repository.loadBasicInfo();
      return _fromTenantBasicInfo(info, generatedBy: generatedBy);
    } catch (_) {
      return PdfLetterheadConfig.fromCurrentSettings(generatedBy: generatedBy);
    }
  }

  static PdfLetterheadConfig _fromTenantBasicInfo(
    TenantBasicInfo info, {
    String? generatedBy,
  }) {
    final clinicName = info.name.trim().isNotEmpty
        ? info.name.trim()
        : AppBranding.clinicName;

    return PdfLetterheadConfig(
      productName: AppBranding.productName,
      tagline: AppBranding.productTagline,
      clinicName: clinicName,
      specialty: info.specialty.trim(),
      address: info.contact.address.trim(),
      phone: info.contact.phone.trim(),
      email: info.contact.email.trim(),
      website: info.contact.website.trim(),
      logoStoragePath: info.branding.logoStoragePath.trim(),
      logoAssetPath: AppBranding.logoAsset,
      generatedAt: DateTime.now(),
      generatedBy:
          generatedBy?.trim().isNotEmpty == true ? generatedBy!.trim() : null,
    );
  }
}
