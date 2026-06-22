import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final providerFiles = [
    'lib/features/patients/data/patient_repository_provider.dart',
    'lib/features/appointments/data/appointment_repository_provider.dart',
    'lib/features/clinical_encounter/data/clinical_encounter_repository_provider.dart',
    'lib/features/payments/data/payment_repository_provider.dart',
    'lib/features/payments/data/payment_staff_notification_repository_provider.dart',
    'lib/features/consents/data/consent_repository_provider.dart',
    'lib/features/exercises/data/exercise_plan_repository_provider.dart',
    'lib/features/imaging/data/imaging_repository_provider.dart',
    'lib/features/inventory/data/inventory_repository_provider.dart',
    'lib/features/post_op_protocols/data/post_op_protocol_repository_provider.dart',
    'lib/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart',
    'lib/features/physiotherapy/data/physiotherapy_session_repository_provider.dart',
    'lib/features/pdf_outputs/data/pdf_output_repository_provider.dart',
    'lib/features/audit/data/audit_log_repository_provider.dart',
    'lib/features/timeline/data/timeline_repository_provider.dart',
    'lib/features/prescriptions/data/prescription_repository_provider.dart',
    'lib/features/radiology_orders/data/radiology_order_repository_provider.dart',
    'lib/features/clinical_reports/data/clinical_report_repository_provider.dart',
    'lib/features/settings/data/profile_settings_repository_provider.dart',
    'lib/features/settings/data/tenant_settings_repository_provider.dart',
    'lib/features/settings/data/clinic_workflow_settings_repository_provider.dart',
    'lib/features/settings/data/staff_leave_record_repository_provider.dart',
    'lib/features/settings/data/tenant_membership_repository_provider.dart',
    'lib/features/settings/data/tenant_invite_repository_provider.dart',
    'lib/features/settings/data/tenant_subscription_repository_provider.dart',
    'lib/features/settings/data/settings_image_storage_repository_provider.dart',
    'lib/features/patient_tags/data/patient_tag_repository_provider.dart',
    'lib/features/lab_orders/data/lab_order_repository_provider.dart',
    'lib/features/lab_orders/data/lab_order_template_repository_provider.dart',
    'lib/features/messages/data/message_template_repository_provider.dart',
    'lib/features/messages/data/sent_message_repository_provider.dart',
  ];

  for (final relativePath in providerFiles) {
    test('$relativePath uses RemoteRepositoryResolver', () {
      final content = File(relativePath).readAsStringSync();
      expect(
        content.contains('RemoteRepositoryResolver.resolve'),
        isTrue,
        reason: '$relativePath must use central resolver',
      );
      expect(
        content.contains('return MockAsync'),
        isFalse,
        reason: '$relativePath must not directly return MockAsync adapter',
      );
      expect(
        RegExp(r'return\s+(const\s+)?Mock').hasMatch(content) &&
            !content.contains('mockFactory:'),
        isFalse,
        reason: '$relativePath must not directly return Mock repository',
      );
    });
  }

  test('consent_template_prepare_screen does not use sync mock writes', () {
    const path = 'lib/features/consents/consent_template_prepare_screen.dart';
    final content = File(path).readAsStringSync();
    expect(content.contains('ConsentRepository.instance'), isFalse);
    expect(content.contains('PdfOutputRepository.instance'), isFalse);
  });
}
