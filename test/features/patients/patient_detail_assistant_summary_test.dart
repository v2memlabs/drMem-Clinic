import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_repository.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_role_summary_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/assistant_clinical_summary.dart';
import 'package:v2mem_clinic/features/clinical_encounter/widgets/patient_scoped_clinical_encounter_row.dart';
import 'package:v2mem_clinic/features/patients/patient_detail_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/detail_actions_panel.dart';

class _FakeAssistantPatientDetailRepo
    implements AssistantClinicalSummaryRepository {
  _FakeAssistantPatientDetailRepo(this._byPatient);

  final Map<String, List<AssistantClinicalSummary>> _byPatient;

  @override
  Future<List<AssistantClinicalSummary>> listAssistantClinicalSummaries({
    String? patientId,
  }) async {
    if (patientId == null || patientId.trim().isEmpty) {
      return const [];
    }
    return List<AssistantClinicalSummary>.from(
      _byPatient[patientId.trim()] ?? const [],
    );
  }

  @override
  Future<AssistantClinicalSummary?> getAssistantClinicalSummary(
    String encounterId,
  ) async => null;
}

void main() {
  tearDown(() {
    AuthSession.clear();
    ClinicalRoleSummaryRepositoryProvider.clearTestOverrides();
    ClinicalRoleSummaryRepositoryProvider.resetCache();
  });

  testWidgets('assistant clinical section uses active safe summary source', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );
    ClinicalRoleSummaryRepositoryProvider.resetCache();
    ClinicalRoleSummaryRepositoryProvider.assistantTestOverride =
        _FakeAssistantPatientDetailRepo({
      'p1': [
        AssistantClinicalSummary(
          encounterId: 'as-p1',
          tenantId: 't1',
          patientId: 'p1',
          patientDisplayName: 'Özet Hasta',
          encounterDate: DateTime(2026, 3, 15),
          visitType: 'kontrol',
          status: 'tamamlandi',
          diagnosisSummary: 'Aktif güvenli tanı özeti',
        ),
      ],
    });

    final router = GoRouter(
      initialLocation: '/patients/p1',
      routes: [
        GoRoute(
          path: '/patients/:id',
          builder: (context, state) =>
              PatientDetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Klinik Özet'), findsOneWidget);
    expect(find.textContaining('Aktif güvenli tanı özeti'), findsWidgets);
    expect(find.textContaining('1 kayıtlı muayene özeti'), findsOneWidget);
    expect(find.byType(PatientScopedClinicalEncounterRow), findsNothing);
    expect(find.text('Muayene Kayıtları'), findsNothing);
    expect(find.textContaining('as-p1'), findsNothing);
    expect(find.textContaining('internalDoctorNote'), findsNothing);
    expect(find.byType(DetailActionsPanel), findsNothing);
  });
}
