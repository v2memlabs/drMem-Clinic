import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/consents/consent_list_screen.dart';
import 'package:v2mem_clinic/features/consents/models/consent_record.dart';
import 'package:v2mem_clinic/features/consents/widgets/consent_clinical_list_row.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_separated_list_body.dart';
import 'package:v2mem_clinic/shared/widgets/status_chip.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('consent list uses clinical rows and legend', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ConsentListScreen(),
        ),
        GoRoute(
          path: '/consents/:id',
          builder: (context, state) =>
              Scaffold(body: Text('Consent ${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(ConsentClinicalListRow), findsWidgets);
    expect(find.byType(ClinicalSeparatedListBody), findsWidgets);
    expect(find.text('Durum renkleri'), findsOneWidget);
    expect(find.text('Onam Evrakı'), findsOneWidget);

    expect(find.textContaining('storage_path'), findsNothing);
    expect(find.textContaining('signed_url'), findsNothing);
    expect(find.textContaining('tenant_id'), findsNothing);

    await tester.tap(find.byType(ConsentClinicalListRow).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Consent'), findsOneWidget);
  });

  testWidgets('received consent hides semantic status chip', (tester) async {
    final record = ConsentRecord(
      id: 'c-test',
      patientId: 'p1',
      patientName: 'Test Hasta',
      createdAt: DateTime(2024, 1, 1),
      consentType: ConsentType.kvkkAydinlatma,
      status: ConsentStatus.alindi,
      recordedBy: 'Test',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConsentClinicalListRow(
            record: record,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(StatusChip), findsNothing);
  });
}
