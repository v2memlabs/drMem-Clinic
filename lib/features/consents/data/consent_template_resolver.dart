import '../models/consent_record.dart';
import '../models/consent_template.dart';
import 'consent_template_repository.dart';
import 'consent_template_repository_provider.dart';

/// [ConsentType] → aktif onam şablonu eşlemesi.
abstract final class ConsentTemplateResolver {
  static String? categoryForConsentType(ConsentType type) {
    switch (type) {
      case ConsentType.kvkkAydinlatma:
        return ConsentTemplateCategories.kvkkAydinlatma;
      case ConsentType.acikRiza:
        return ConsentTemplateCategories.acikRiza;
      case ConsentType.whatsappIzin:
      case ConsentType.smsIzin:
        return ConsentTemplateCategories.whatsappSms;
      case ConsentType.emailIzin:
        return ConsentTemplateCategories.email;
      case ConsentType.fizyoterapistPaylasim:
        return ConsentTemplateCategories.fizyoterapistPaylasim;
      case ConsentType.fotoVideoIzin:
        return ConsentTemplateCategories.fotoVideo;
      case ConsentType.ameliyatOnami:
        return ConsentTemplateCategories.ameliyatOnami;
    }
  }

  /// Mock backend veya test — senkron mock depo.
  static ConsentTemplate? resolveActiveTemplate(ConsentType type) {
    return _pickActive(
      ConsentTemplateRepository.instance.getAll(),
      type,
    );
  }

  /// Supabase / async depo — UI akışları bunu kullanır.
  static Future<ConsentTemplate?> resolveActiveTemplateAsync(
    ConsentType type,
  ) async {
    final templates =
        await ConsentTemplateRepositoryProvider.asyncRepository.getAll();
    return _pickActive(templates, type);
  }

  static Future<ConsentTemplate?> resolveForConsentAsync(
    ConsentRecord consent,
  ) async {
    final templateId = consent.templateId?.trim();
    if (templateId != null && templateId.isNotEmpty) {
      final byId =
          await ConsentTemplateRepositoryProvider.asyncRepository.getById(
        templateId,
      );
      if (byId != null) return byId;
    }
    return resolveActiveTemplateAsync(consent.consentType);
  }

  static ConsentTemplate? resolveForConsent(ConsentRecord consent) {
    final templateId = consent.templateId?.trim();
    if (templateId != null && templateId.isNotEmpty) {
      final byId = ConsentTemplateRepository.instance.getById(templateId);
      if (byId != null) return byId;
    }
    return resolveActiveTemplate(consent.consentType);
  }

  static ConsentTemplate? _pickActive(
    List<ConsentTemplate> templates,
    ConsentType type,
  ) {
    final category = categoryForConsentType(type);
    if (category == null) return null;

    for (final template in templates) {
      if (template.isActive && template.category == category) {
        return template;
      }
    }
    return null;
  }
}
