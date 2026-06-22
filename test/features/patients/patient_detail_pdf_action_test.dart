import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/pdf_outputs/contextual_pdf_actions.dart';
import 'package:v2mem_clinic/features/patients/patient_detail_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/detail_actions_panel.dart';

void main() {
  tearDown(AuthSession.clear);

  Future<void> pumpPatientDetail(
    WidgetTester tester, {
    required String role,
  }) async {
    AuthSession.setUser(
      AppUser(
        id: 'u-$role',
        username: role,
        displayName: 'Test',
        role: role,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1800, 1400));
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

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('doctor sees single PDF Oluştur action', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpPatientDetail(tester, role: AppRoles.doctor);

    expect(find.text(ContextualPdfActions.createLabel), findsOneWidget);
    expect(find.text('PDF Hazırla'), findsNothing);

    final panel = tester.widget<DetailActionsPanel>(
      find.byType(DetailActionsPanel),
    );
    final pdfActions = panel.actions
        .where((a) => a.label == ContextualPdfActions.createLabel)
        .length;
    expect(pdfActions, 1);
  });

  testWidgets('assistant sees PDF Oluştur action', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpPatientDetail(tester, role: AppRoles.assistant);

    expect(find.text(ContextualPdfActions.createLabel), findsOneWidget);
  });
}
