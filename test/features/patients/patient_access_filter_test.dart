import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/auth/user_display_names.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/patients/data/mock_patients.dart';
import 'package:v2mem_clinic/features/patients/data/patient_access_filter.dart';
import 'package:v2mem_clinic/features/patients/data/patient_repository.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('remote backend skips mock physio patient filter', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    AuthSession.setUser(
      AppUser(
        id: 'physio-1',
        username: 'physio',
        displayName: UserDisplayNames.mockPhysioLabel,
        role: AppRoles.physiotherapist,
      ),
    );

    final patients = List.of(mockPatients);
    expect(
      PatientAccessFilter.filterVisible(patients).length,
      patients.length,
    );
  });

  test('mock physio sees only assigned referral patients', () {
    AuthSession.setUser(
      AppUser(
        id: 'physio-1',
        username: 'physio',
        displayName: 'Fizyoterapist A',
        role: AppRoles.physiotherapist,
      ),
    );

    final visible = PatientAccessFilter.filterVisible(List.of(mockPatients));
    final visibleIds = visible.map((p) => p.id).toSet();

    expect(visibleIds, containsAll(['p1', 'p3', 'p7']));
    expect(visibleIds, isNot(contains('p2')));
    expect(visibleIds, isNot(contains('p4')));
  });

  test('mock physio cannot load unassigned patient by id', () {
    AuthSession.setUser(
      AppUser(
        id: 'physio-1',
        username: 'physio',
        displayName: 'Fizyoterapist B',
        role: AppRoles.physiotherapist,
      ),
    );

    expect(PatientRepository.instance.getById('p1'), isNull);
    expect(PatientRepository.instance.getById('p2'), isNotNull);
  });

  test('mock doctor sees all patients', () {
    AuthSession.setUser(
      AppUser(
        id: 'doc-1',
        username: 'doc',
        displayName: UserDisplayNames.mockDoctorLabel,
        role: AppRoles.doctor,
      ),
    );

    expect(
      PatientAccessFilter.filterVisible(List.of(mockPatients)).length,
      mockPatients.length,
    );
  });
}
