import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/pdf_outputs/contextual_pdf_actions.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  AuthSession.setUser(
    AppUser(
      id: 'd1',
      username: 'doc',
      displayName: 'Doc',
      role: AppRoles.doctor,
    ),
  );

  test('canShowCreateAction requires edit permission and patientId', () {
    expect(
      ContextualPdfActions.canShowCreateAction(patientId: 'p1'),
      isTrue,
    );
    expect(ContextualPdfActions.canShowCreateAction(patientId: ''), isFalse);
    expect(ContextualPdfActions.canShowCreateAction(patientId: null), isFalse);

    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asst',
        role: AppRoles.assistant,
      ),
    );
    expect(
      ContextualPdfActions.canShowCreateAction(patientId: 'p1'),
      isTrue,
    );
  });

  test('newFromPatient route', () {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );
    final route = ContextualPdfActions.newFromPatient('p1');
    expect(route, contains('/pdf-outputs/new'));
    expect(route, contains('patientId=p1'));
    expect(route, isNot(contains('appointmentId')));
  });

  test('newFromClinicalEncounter route uses clinical_encounter source', () {
    final route = ContextualPdfActions.newFromClinicalEncounter(
      patientId: 'p1',
      clinicalEncounterId: 'ce1',
    );
    expect(route, contains('patientId=p1'));
    expect(route, contains('source=clinical_encounter'));
    expect(route, contains('id=ce1'));
  });

  test('newFromAppointment route uses appointment source', () {
    final route = ContextualPdfActions.newFromAppointment(
      patientId: 'p1',
      appointmentId: 'a1',
    );
    expect(route, contains('patientId=p1'));
    expect(route, contains('source=appointment'));
    expect(route, contains('id=a1'));
    expect(route, isNot(contains('appointmentId=')));
  });

  test('appointment source module label is human readable', () {
    expect(
      pdfSourceModuleLabel(pdfSourceModuleAppointment),
      'Randevu',
    );
  });
}
