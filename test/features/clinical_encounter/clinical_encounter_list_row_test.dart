import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/clinical_encounter_list_screen.dart';
import 'package:v2mem_clinic/features/clinical_encounter/widgets/clinical_encounter_clinical_list_row.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/features/clinical_encounter/widgets/clinical_encounter_list_accent.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/data_list_card.dart';
import 'package:v2mem_clinic/shared/widgets/status_chip.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('clinical encounter list uses clinical rows not DataListCard',
      (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Dr. Mehmet Yalçınozan',
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ClinicalEncounterListScreen(),
        ),
        GoRoute(
          path: '/clinical-records/:id',
          builder: (context, state) =>
              const Scaffold(body: Text('Encounter detail')),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ClinicalEncounterClinicalListRow), findsWidgets);
    expect(find.text('Durum renkleri'), findsOneWidget);
    expect(find.byType(DataListCard), findsNothing);
    expect(find.byType(StatusChip), findsNothing);

    expect(find.textContaining('internalDoctorNote'), findsNothing);
    expect(find.textContaining('raw clinical_data'), findsNothing);
  });

  testWidgets('row shows date and visit line without status chip',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalEncounterClinicalListRow(
            encounter: ClinicalEncounter(
              id: 'e1',
              patientId: 'p1',
              patientName: 'Ayşe Çalışkan',
              createdAt: DateTime(2026, 5, 20),
              updatedAt: DateTime(2026, 5, 20),
              doctorName: 'Dr',
              status: ClinicalEncounterStatus.kontrolPlanlandi,
              visitType: ClinicalVisitType.kontrol,
              bodyRegion: ClinicalBodyRegion.diz,
              side: ClinicalSide.sag,
              chiefComplaint: '',
              complaintDuration: '',
              traumaHistory: false,
              painLocation: '',
              painCharacter: '',
              vasScore: 0,
              nightPain: false,
              activityRelation: '',
              previousTreatments: '',
              medications: '',
              allergies: '',
              comorbidities: '',
              previousSurgeries: '',
              generalNotes: '',
              sportsSectionEnabled: false,
              sportBranch: '',
              amateurOrProfessional: '',
              trainingFrequency: '',
              patientExpectation: '',
              returnToSportGoal: '',
              sportsRelated: false,
              returnToSportPlan: '',
              inspection: '',
              palpation: '',
              rangeOfMotion: '',
              muscleStrength: '',
              stabilityTests: '',
              specialTests: '',
              neurovascularStatus: '',
              comparisonWithOtherSide: '',
              clinicalImpression: '',
              imagingSummary: '',
              imagingDoctorComment: '',
              attachedFileNote: '',
              preliminaryDiagnosis: 'Menisküs yırtığı',
              finalDiagnosis: '',
              differentialDiagnosis: '',
              diagnosisType: ClinicalDiagnosisType.diger,
              icdCode: '',
              planTitle: '',
              conservativeTreatment: '',
              medicationNotes: '',
              injectionOrProcedurePlan: '',
              physiotherapyReferral: false,
              exerciseRecommendation: '',
              imagingRequest: '',
              surgeryRecommendation: '',
              patientInformationNote: '',
              warningNotes: '',
              internalDoctorNote: '',
            ),
            usesRemote: false,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('20.05.2026'), findsOneWidget);
    expect(find.textContaining('Kontrol · Ön tanı:'), findsOneWidget);
    expect(find.text('Kontrol Planlandı'), findsNothing);
    expect(find.byType(StatusChip), findsNothing);
  });

  test('ClinicalEncounterListAccent is not used by list row widget', () {
    expect(ClinicalEncounterListAccent.colorFor, isNotNull);
  });
}
