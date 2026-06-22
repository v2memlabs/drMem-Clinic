import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/clinical_diagnosis_summary_detail_screen.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_repository.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_role_summary_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/assistant_clinical_summary.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_state_message.dart';

class _FakeAssistantDetailRepo implements AssistantClinicalSummaryRepository {
  _FakeAssistantDetailRepo(this._items);

  final Map<String, AssistantClinicalSummary> _items;

  @override
  Future<List<AssistantClinicalSummary>> listAssistantClinicalSummaries({
    String? patientId,
  }) async =>
      _items.values.toList();

  @override
  Future<AssistantClinicalSummary?> getAssistantClinicalSummary(
    String encounterId,
  ) async =>
      _items[encounterId];
}

void main() {
  tearDown(() {
    AuthSession.clear();
    ClinicalRoleSummaryRepositoryProvider.clearTestOverrides();
    ClinicalRoleSummaryRepositoryProvider.resetCache();
  });

  testWidgets('detail shows safe projection without full clinical actions', (
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
        _FakeAssistantDetailRepo({
      'as-99': AssistantClinicalSummary(
        encounterId: 'as-99',
        tenantId: 't-hidden',
        patientId: 'p1',
        patientDisplayName: 'Güvenli Hasta',
        encounterDate: DateTime(2026, 4, 1),
        visitType: 'ilk_muayene',
        status: 'tamamlandi',
        diagnosisSummary: 'Güvenli tanı satırı',
        nextControlDate: DateTime(2026, 5, 1),
      ),
    });

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final router = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(
          path: '/detail',
          builder: (context, state) =>
              const ClinicalDiagnosisSummaryDetailScreen(id: 'as-99'),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Güvenli Hasta'), findsOneWidget);
    expect(find.textContaining('Güvenli tanı satırı'), findsWidgets);
    expect(find.text('Düzenle'), findsNothing);
    expect(find.text('Muayene detayı'), findsNothing);
    expect(find.textContaining('as-99'), findsNothing);
    expect(find.textContaining('t-hidden'), findsNothing);
    expect(find.textContaining('internalDoctorNote'), findsNothing);
  });

  testWidgets('unknown id shows safe not-found state', (tester) async {
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
        _FakeAssistantDetailRepo({});

    final router = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(
          path: '/detail',
          builder: (context, state) =>
              const ClinicalDiagnosisSummaryDetailScreen(id: 'missing'),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(ClinicalStateMessage), findsWidgets);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('StackTrace'), findsNothing);
  });
}
