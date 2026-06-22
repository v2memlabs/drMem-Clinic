import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/patients/data/patient_alerts_data_source.dart';
import 'package:v2mem_clinic/features/patients/models/patient_alert.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  test('loads payment and consent alerts from live repositories in mock mode',
      () async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );

    final result = await PatientAlertsDataSource.load();

    expect(result.hasError, isFalse);
    expect(result.alerts, isNotEmpty);
    expect(
      result.alerts.any((a) => a.alertType == PatientAlertType.odemeBekliyor),
      isTrue,
    );
    expect(
      result.alerts.any((a) => a.actionRoute?.startsWith('/payments') ?? false),
      isTrue,
    );
  });
}
