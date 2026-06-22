import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_list_row.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_list_status_tones.dart';
import 'package:v2mem_clinic/shared/widgets/status_chip.dart';

void main() {
  group('shouldShowAppointmentStatusChip', () {
    test('planlandi and geldi hide chip', () {
      expect(
        ClinicalListStatusTones.shouldShowAppointmentStatusChip(
          AppointmentStatus.planlandi,
        ),
        isFalse,
      );
      expect(
        ClinicalListStatusTones.shouldShowAppointmentStatusChip(
          AppointmentStatus.geldi,
        ),
        isFalse,
      );
    });

    test('gelmedi iptal ertelendi show chip', () {
      expect(
        ClinicalListStatusTones.shouldShowAppointmentStatusChip(
          AppointmentStatus.gelmedi,
        ),
        isTrue,
      );
      expect(
        ClinicalListStatusTones.shouldShowAppointmentStatusChip(
          AppointmentStatus.iptal,
        ),
        isTrue,
      );
      expect(
        ClinicalListStatusTones.shouldShowAppointmentStatusChip(
          AppointmentStatus.ertelendi,
        ),
        isTrue,
      );
    });
  });

  group('shouldShowClinicalEncounterStatusChip', () {
    test('tamamlandi and fizyoterapi hide chip', () {
      expect(
        ClinicalListStatusTones.shouldShowClinicalEncounterStatusChip(
          ClinicalEncounterStatus.tamamlandi,
        ),
        isFalse,
      );
      expect(
        ClinicalListStatusTones.shouldShowClinicalEncounterStatusChip(
          ClinicalEncounterStatus.fizyoterapiyeYonlendirildi,
        ),
        isFalse,
      );
    });

    test('taslak kontrol ameliyat plan show chip', () {
      expect(
        ClinicalListStatusTones.shouldShowClinicalEncounterStatusChip(
          ClinicalEncounterStatus.taslak,
        ),
        isTrue,
      );
      expect(
        ClinicalListStatusTones.shouldShowClinicalEncounterStatusChip(
          ClinicalEncounterStatus.kontrolPlanlandi,
        ),
        isTrue,
      );
    });
  });

  testWidgets('status chip hidden when showSemanticStatusChip is false',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClinicalListRow(
            title: 'Test Hasta',
            semanticChipLabel: 'Planlandı',
            semanticChipTone: StatusChipTone.warning,
            showSemanticStatusChip: false,
            statusMarkerColor: Color(0xFFF9A825),
          ),
        ),
      ),
    );

    expect(find.text('Planlandı'), findsNothing);
  });

  testWidgets('status chip visible when showSemanticStatusChip is true',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClinicalListRow(
            title: 'Test Hasta',
            semanticChipLabel: 'Gelmedi',
            semanticChipTone: StatusChipTone.danger,
            showSemanticStatusChip: true,
            statusMarkerColor: Color(0xFFE53935),
          ),
        ),
      ),
    );

    expect(find.text('Gelmedi'), findsOneWidget);
  });
}
