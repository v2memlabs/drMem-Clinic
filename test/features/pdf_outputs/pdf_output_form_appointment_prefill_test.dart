import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';
import 'package:v2mem_clinic/features/pdf_outputs/pdf_output_form_screen.dart';
import 'package:v2mem_clinic/features/patients/widgets/patient_selector_field.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  Future<void> pumpAppointmentPdfForm(WidgetTester tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Dr. Test',
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      initialLocation:
          '/pdf-outputs/new?patientId=p1&source=$pdfSourceModuleAppointment&id=a1',
      routes: [
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
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Yeni PDF Çıktı').evaluate().isNotEmpty &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
  }

  testWidgets('appointment async prefill fills form without not-found', (
    tester,
  ) async {
    await pumpAppointmentPdfForm(tester);

    expect(find.textContaining('Kaynak: Randevu'), findsOneWidget);
    expect(find.textContaining('Kaynak randevu bulunamadı'), findsNothing);
    expect(find.textContaining('a1'), findsNothing);

    final selector = tester.widget<PatientSelectorField>(
      find.byType(PatientSelectorField),
    );
    expect(selector.lockSelection, isTrue);
    expect(selector.selectedPatientId, 'p1');
  });
}
