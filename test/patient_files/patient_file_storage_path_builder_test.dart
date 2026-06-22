import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_storage_path_builder.dart';

void main() {
  test('patient upload path uses tenant patient file id segments only', () {
    expect(
      PatientFileStoragePathBuilder.patientUploadPath(
        tenantId: 'tenant-a',
        patientId: 'patient-b',
        fileId: 'file-c',
        safeSegment: 'scan_01.pdf',
      ),
      'tenants/tenant-a/patients/patient-b/files/file-c/scan_01.pdf',
    );
  });

  test('generated pdf path uses document.pdf segment', () {
    expect(
      PatientFileStoragePathBuilder.generatedPdfPath(
        tenantId: 't-1',
        patientId: 'p-1',
        fileId: 'pdf-9',
      ),
      'tenants/t-1/patients/p-1/pdf/pdf-9/document.pdf',
    );
  });

  test('safeSegment strips path traversal and slashes', () {
    final path = PatientFileStoragePathBuilder.patientUploadPath(
      tenantId: 't1',
      patientId: 'p1',
      fileId: 'f1',
      safeSegment: '../evil/scan.pdf',
    );
    expect(path, isNot(contains('..')));
    expect(path, isNot(contains('/evil/')));
    expect(path.endsWith('.pdf'), isTrue);
  });

  test('default bucket is private', () {
    expect(
      PatientFileStoragePathBuilder.defaultBucket,
      'patient-files-private',
    );
  });
}
