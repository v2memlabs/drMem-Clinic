import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';
import 'package:v2mem_clinic/features/patients/widgets/patient_compact_card.dart';
import 'package:v2mem_clinic/features/patients/widgets/patient_compact_list_row.dart';

void main() {
  final patient = Patient(
    id: 'p1',
    fileNumber: 'H-2026-0002',
    firstName: 'Ayşe',
    lastName: 'Demir',
    phone: '+90 533 444 5566',
    birthDate: DateTime(1994, 9, 3),
    lastVisitDate: DateTime(2026, 5, 20),
    primaryComplaint: 'Bel ağrısı',
    bodyRegion: 'Bel',
    tags: ['VIP'],
  );

  testWidgets('compact row shows SOYAD, Ad format', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientCompactListRow(
            patient: patient,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('DEMİR, Ayşe'), findsOneWidget);
    expect(find.textContaining('tenant'), findsNothing);
    expect(find.textContaining('auth'), findsNothing);
  });

  testWidgets('compact card shows name and file number', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientCompactCard(
            patient: patient,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('DEMİR, Ayşe'), findsOneWidget);
    expect(find.text('H-2026-0002'), findsOneWidget);
  });
}
