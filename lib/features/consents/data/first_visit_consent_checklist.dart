import '../models/consent_record.dart';
import 'consent_completion_rules.dart';
import 'first_visit_consent_requirements.dart';

class FirstVisitConsentChecklistItem {
  final ConsentType consentType;
  final bool isComplete;
  final ConsentRecord? latestRecord;

  const FirstVisitConsentChecklistItem({
    required this.consentType,
    required this.isComplete,
    this.latestRecord,
  });

  String get label => consentTypeLabel(consentType);
}

class FirstVisitConsentChecklist {
  final String patientId;
  final List<FirstVisitConsentChecklistItem> items;

  const FirstVisitConsentChecklist({
    required this.patientId,
    required this.items,
  });

  bool get isComplete => items.every((item) => item.isComplete);

  List<FirstVisitConsentChecklistItem> get incompleteItems =>
      items.where((item) => !item.isComplete).toList();

  static FirstVisitConsentChecklist evaluate({
    required String patientId,
    required List<ConsentRecord> consents,
  }) {
    final items = <FirstVisitConsentChecklistItem>[];

    for (final type in FirstVisitConsentRequirements.requiredTypes) {
      ConsentRecord? latest;
      for (final record in consents) {
        if (record.consentType != type) continue;
        if (latest == null || record.createdAt.isAfter(latest.createdAt)) {
          latest = record;
        }
      }
      final complete = latest != null &&
          ConsentCompletionRules.isFullyCompleted(latest);
      items.add(
        FirstVisitConsentChecklistItem(
          consentType: type,
          isComplete: complete,
          latestRecord: latest,
        ),
      );
    }

    return FirstVisitConsentChecklist(patientId: patientId, items: items);
  }
}
