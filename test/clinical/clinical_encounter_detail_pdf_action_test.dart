import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/clinical_encounter_detail_screen.dart';
import 'package:v2mem_clinic/features/pdf_outputs/contextual_pdf_actions.dart';
import 'package:v2mem_clinic/features/pdf_outputs/pdf_output_form_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('doctor sees PDF Oluştur on encounter detail and navigates',
      (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Dr. Mehmet Yalçınozan',
        role: AppRoles.doctor,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/clinical-records/ce1',
      routes: [
        GoRoute(
          path: '/clinical-records/:id',
          builder: (context, state) =>
              ClinicalEncounterDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/pdf-outputs/new',
          builder: (context, state) {
            final params = Uri.parse(state.location).queryParameters;
            return PdfOutputFormScreen(
              patientId: params['patientId'],
              source: params['source'],
              sourceRecordId: params['id'],
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text(ContextualPdfActions.createLabel), findsOneWidget);
    expect(find.textContaining('internalDoctorNote'), findsNothing);
    expect(find.textContaining('tenant_id'), findsNothing);

    await tester.ensureVisible(find.text(ContextualPdfActions.createLabel));
    await tester.tap(find.text(ContextualPdfActions.createLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(PdfOutputFormScreen), findsOneWidget);
    expect(find.textContaining('ce1'), findsNothing);
    expect(find.textContaining('Kaynak: Muayene'), findsOneWidget);
  });

  testWidgets('assistant cannot create PDF from full encounter detail',
      (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asst',
        role: AppRoles.assistant,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/clinical-records/ce1',
      routes: [
        GoRoute(
          path: '/clinical-records/:id',
          builder: (context, state) =>
              ClinicalEncounterDetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text(ContextualPdfActions.createLabel), findsNothing);
  });
}
