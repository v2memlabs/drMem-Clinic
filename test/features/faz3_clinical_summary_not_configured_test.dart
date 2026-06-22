import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clinical summary list screens handle notConfigured state', () {
    final assistantList = File(
      'lib/features/clinical_encounter/clinical_diagnosis_summary_list_screen.dart',
    ).readAsStringSync();
    final physioList = File(
      'lib/features/clinical_encounter/screens/physio_clinical_summary_list_screen.dart',
    ).readAsStringSync();

    expect(assistantList, contains('active.isNotConfigured'));
    expect(assistantList, contains('listNotConfigured'));
    expect(assistantList, contains('AssistantClinicalSummaryListUserMessages.notConfigured'));

    expect(physioList, contains('active.isNotConfigured'));
    expect(physioList, contains('listNotConfigured'));
    expect(physioList, contains('PhysiotherapistClinicalSummaryListUserMessages.notConfigured'));
  });

  test('nav config gates clinical summary routes on module availability', () {
    final nav = File('lib/core/navigation/app_nav_config.dart').readAsStringSync();

    expect(nav, contains('ClinicalSummaryModuleAvailability.assistantOperational'));
    expect(nav, contains('ClinicalSummaryModuleAvailability.physiotherapistOperational'));
  });
}
