import 'post_encounter_document_kind.dart';

/// Belge formu kaydedildiğinde sihirbaza döndürülen sonuç.
class PostEncounterWizardStepResult {
  final PostEncounterDocumentKind kind;
  final String documentId;

  const PostEncounterWizardStepResult({
    required this.kind,
    required this.documentId,
  });
}
