import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/patients/data/mock_patients.dart';
import 'package:v2mem_clinic/features/patients/data/patient_lookup_data_source.dart';
import 'package:v2mem_clinic/features/patients/data/patient_repository.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';

void main() {
  setUp(() {
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  group('PatientLookupDataSource', () {
    test('findById returns mock patient when remote patients disabled', () async {
      final seed = mockPatients.first.copyWith(
        id: 'p-lookup-1',
        firstName: 'Ayşe',
        lastName: 'Yılmaz',
        fileNumber: 'F-100',
      );
      PatientRepository.instance.add(seed);

      final found = await PatientLookupDataSource.findById('p-lookup-1');
      expect(found?.fullName, 'Ayşe Yılmaz');
      expect(found?.fileNumber, 'F-100');
    });

    test('resolveName prefers selected patient snapshot', () async {
      final selected = mockPatients.first.copyWith(
        id: 'p-sel',
        firstName: 'Sel',
        lastName: 'Hasta',
      );

      final name = await PatientLookupDataSource.resolveName(
        patientId: 'p-sel',
        selectedPatient: selected,
      );
      expect(name, 'Sel Hasta');
    });

    test('countPatientsWithTagSync counts mock patients', () {
      const tagId = 'tag-count-1';
      PatientRepository.instance.add(
        mockPatients.first.copyWith(
          id: 'p-tag-1',
          tagIds: [tagId],
        ),
      );

      expect(
        PatientLookupDataSource.countPatientsWithTagSync(tagId),
        greaterThanOrEqualTo(1),
      );
    });
  });
}
