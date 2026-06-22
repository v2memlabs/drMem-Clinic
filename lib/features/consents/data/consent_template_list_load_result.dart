import '../models/consent_template.dart';

class ConsentTemplateListLoadResult {
  final List<ConsentTemplate> templates;
  final String? errorMessage;

  const ConsentTemplateListLoadResult._({
    required this.templates,
    this.errorMessage,
  });

  factory ConsentTemplateListLoadResult.success(List<ConsentTemplate> templates) {
    return ConsentTemplateListLoadResult._(templates: templates);
  }

  factory ConsentTemplateListLoadResult.failure(String message) {
    return ConsentTemplateListLoadResult._(
      templates: const [],
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
