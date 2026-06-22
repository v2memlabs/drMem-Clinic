import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';
import 'package:v2mem_clinic/features/patients/widgets/patient_selector_field.dart';

void main() {
  testWidgets('lockSelection validator accepts route patient id', (tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: const PatientSelectorField(
              selectedPatientId: 'p1',
              lockSelection: true,
              enabled: false,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('lockSelection keeps preview when lookup is unavailable', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final now = DateTime.now();
    final preview = Patient(
      id: 'remote-patient-1',
      fileNumber: '—',
      firstName: 'Ayse',
      lastName: 'Yilmaz',
      phone: '',
      birthDate: now,
      lastVisitDate: now,
      primaryComplaint: '',
      bodyRegion: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PatientSelectorField(
              selectedPatientId: 'remote-patient-1',
              selectedPatientPreview: preview,
              lockSelection: true,
              enabled: false,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(formKey.currentState!.validate(), isTrue);
    expect(find.text('Ayse Yilmaz'), findsOneWidget);
    expect(find.textContaining('remote-patient-1'), findsNothing);
  });

  testWidgets('required empty selection fails validation', (tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: const PatientSelectorField(
              selectedPatientId: null,
              isRequired: true,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(formKey.currentState!.validate(), isFalse);
    expect(find.text('Hasta seçiniz'), findsWidgets);
  });
}
