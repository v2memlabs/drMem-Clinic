import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_list_load_result.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_state_message.dart';

/// Patient selector hata dalı — [PatientSelectorField] ile aynı güvenli metin hattı.
String patientSelectorErrorText(PatientListLoadResult result) {
  if (!result.hasError) return '';
  return ClinicalStateMessage.safeErrorDescription(result.errorMessage);
}

void main() {
  test('simulated failure returns safe text without technical tokens', () {
    final result = PatientListLoadResult.failure(
      'PostgREST AuthException tenant_id=abc Supabase RLS JWT secret',
    );
    final text = patientSelectorErrorText(result);

    expect(text, ClinicalStateMessage.genericLoadFailure);
    expect(text.toLowerCase(), isNot(contains('tenant_id')));
    expect(text.toLowerCase(), isNot(contains('supabase')));
    expect(text.toLowerCase(), isNot(contains('jwt')));
  });

  testWidgets('patient selector error UI hides raw exception text', (tester) async {
    final result = PatientListLoadResult.failure(
      'Exception: stack trace tenant_id profile_id storage_path',
    );
    final message = patientSelectorErrorText(result);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text(message)),
        ),
      ),
    );

    expect(find.textContaining('tenant_id'), findsNothing);
    expect(find.textContaining('stack trace'), findsNothing);
    expect(find.text(ClinicalStateMessage.genericLoadFailure), findsOneWidget);
  });
}
