import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/patients/patient_detail/patient_detail_action_context.dart';
import 'package:v2mem_clinic/features/patients/patient_detail/patient_detail_action_registry.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  PatientDetailActionContext doctorCtx({bool fileCard = true}) {
    return PatientDetailActionContext(
      patientId: 'p1',
      latestClinicalEncounterId: 'enc-1',
      showsFilePreviewCard: fileCard,
      showsRehabPreviewCard: true,
      showsAssistantSummaryCard: false,
    );
  }

  PatientDetailActionContext assistantCtx() {
    return const PatientDetailActionContext(
      patientId: 'p1',
      showsFilePreviewCard: true,
      showsRehabPreviewCard: false,
      showsAssistantSummaryCard: true,
    );
  }

  List<String> ids(List<PatientDetailAction> actions) =>
      actions.map((a) => a.id).toList(growable: false);

  test('doctor list omits card-only actions when preview cards are visible', () {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );

    final list = PatientDetailActionRegistry.listActions(doctorCtx());
    expect(
      ids(list),
      [
        PatientDetailActionIds.materialCharge,
        PatientDetailActionIds.appointments,
        PatientDetailActionIds.newAppointment,
        PatientDetailActionIds.ftrAppointment,
      ],
    );
    expect(
      ids(list),
      isNot(contains(PatientDetailActionIds.pdfCreate)),
    );
    expect(
      ids(list),
      isNot(contains(PatientDetailActionIds.physioRefer)),
    );
    expect(ids(list), isNot(contains(PatientDetailActionIds.files)));
  });

  test('doctor file card trailing exposes PDF and files link', () {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );

    final trailing = PatientDetailActionRegistry.cardTrailingActions(
      doctorCtx(),
      PatientDetailCardKind.file,
    );
    expect(
      ids(trailing),
      [
        PatientDetailActionIds.pdfCreate,
        PatientDetailActionIds.files,
      ],
    );
  });

  test('doctor rehab card trailing exposes physio refer', () {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );

    final trailing = PatientDetailActionRegistry.cardTrailingActions(
      doctorCtx(),
      PatientDetailCardKind.rehab,
    );
    expect(ids(trailing), [PatientDetailActionIds.physioRefer]);
  });

  test('assistant list omits diagnosis summary and files when cards visible', () {
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );

    final list = PatientDetailActionRegistry.listActions(assistantCtx());
    expect(
      ids(list),
      [
        PatientDetailActionIds.materialCharge,
        PatientDetailActionIds.appointments,
        PatientDetailActionIds.consents,
        PatientDetailActionIds.payments,
        PatientDetailActionIds.messages,
        PatientDetailActionIds.patientTags,
      ],
    );
    expect(ids(list), isNot(contains(PatientDetailActionIds.diagnosisSummary)));
    expect(ids(list), isNot(contains(PatientDetailActionIds.files)));
    expect(ids(list), isNot(contains(PatientDetailActionIds.pdfCreate)));
  });

  test('assistant summary card trailing exposes Tüm özetler', () {
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );

    final trailing = PatientDetailActionRegistry.cardTrailingActions(
      assistantCtx(),
      PatientDetailCardKind.assistantSummary,
    );
    expect(ids(trailing), [PatientDetailActionIds.diagnosisSummary]);
    expect(trailing.single.label, 'Tüm özetler');
  });
}
