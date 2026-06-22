import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_tags/data/mock_patient_tag_repository.dart';
import 'package:v2mem_clinic/features/patient_tags/data/patient_tag_repository_contract.dart';
import 'package:v2mem_clinic/features/patient_tags/models/patient_tag.dart';
import 'package:v2mem_clinic/features/patients/data/mock_patients.dart';

void main() {
  const repo = MockPatientTagRepository();

  test('create tag and assign to patient', () async {
    final beforeCount = (await repo.listAll()).length;
    final tag = await repo.create(
      name: 'Test Etiket ${DateTime.now().millisecondsSinceEpoch}',
      color: PatientTagColor.blue,
    );
    expect((await repo.listAll()).length, beforeCount + 1);

    final patientId = mockPatients.first.id;
    await repo.assignToPatient(patientId: patientId, tagId: tag.id);
    final ids = await repo.getTagIdsForPatient(patientId);
    expect(ids, contains(tag.id));
    expect(await repo.countPatientsWithTag(tag.id), greaterThanOrEqualTo(1));
  });

  test('duplicate active name is rejected', () async {
    final existing = (await repo.listActive()).first;
    expect(
      () => repo.create(name: existing.name, color: PatientTagColor.gray),
      throwsA(
        isA<PatientTagRepositoryException>().having(
          (e) => e.failure,
          'failure',
          PatientTagRepositoryFailure.duplicateName,
        ),
      ),
    );
  });
}
