import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/appointments/appointment_detail_screen.dart';
import 'package:v2mem_clinic/features/pdf_outputs/contextual_pdf_actions.dart';
import 'package:v2mem_clinic/features/pdf_outputs/pdf_output_form_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  Future<void> pumpAppointmentDetail(
    WidgetTester tester, {
    required String appointmentId,
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

    await tester.binding.setSurfaceSize(const Size(1200, 1400));

    final router = GoRouter(
      initialLocation: '/appointments/$appointmentId',
      routes: [
        GoRoute(
          path: '/appointments/:id',
          builder: (context, state) =>
              AppointmentDetailScreen(id: state.pathParameters['id']!),
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
  }

  testWidgets('doctor sees PDF Oluştur on appointment detail', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAppointmentDetail(
      tester,
      appointmentId: 'a1',
      role: AppRoles.doctor,
    );

    expect(find.text(ContextualPdfActions.createLabel), findsOneWidget);
    expect(find.textContaining('a1'), findsNothing);
  });

  testWidgets('tap navigates with appointment source prefill', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAppointmentDetail(
      tester,
      appointmentId: 'a1',
      role: AppRoles.doctor,
    );

    await tester.ensureVisible(find.text(ContextualPdfActions.createLabel));
    await tester.tap(find.text(ContextualPdfActions.createLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(PdfOutputFormScreen), findsOneWidget);
    expect(find.textContaining('Kaynak: Randevu'), findsOneWidget);
    expect(find.textContaining('appointmentId'), findsNothing);
    expect(find.textContaining('a1'), findsNothing);
  });

  testWidgets('assistant sees PDF Oluştur on appointment detail', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAppointmentDetail(
      tester,
      appointmentId: 'a1',
      role: AppRoles.assistant,
    );

    expect(find.text(ContextualPdfActions.createLabel), findsOneWidget);
  });
}
