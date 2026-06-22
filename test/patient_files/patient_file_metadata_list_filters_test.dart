import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_list_filters.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata_enums.dart';

PatientFileMetadata _file(String name) {
  return PatientFileMetadata(
    id: 'id-$name',
    tenantId: 't',
    patientId: 'p',
    fileKind: PatientFileKind.other,
    clinicalContext: PatientFileClinicalContext.patient,
    displayName: name,
    storageBucket: 'b',
    storagePath: 'p',
    status: PatientFileStatus.active,
    visibilityScope: PatientFileVisibilityScope.clinicOperations,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  test('applySearch matches display name only', () {
    final list = [_file('Rapor A'), _file('Belge B')];
    final filtered =
        PatientFileMetadataListFilters.applySearch(list, 'rapor');
    expect(filtered, hasLength(1));
    expect(filtered.first.displayName, 'Rapor A');
  });
}
