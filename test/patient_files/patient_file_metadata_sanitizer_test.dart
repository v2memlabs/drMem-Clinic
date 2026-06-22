import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_sanitizer.dart';

void main() {
  test('blocks camelCase forbidden keys', () {
    final out = PatientFileMetadataSanitizer.sanitize({
      'signedUrl': 'x',
      'publicUrl': 'y',
      'fileContent': 'z',
      'pdfContent': 'w',
      'serviceRole': 'bad',
    });
    expect(out, isEmpty);
  });

  test('removes forbidden clinical and url keys', () {
    final out = PatientFileMetadataSanitizer.sanitize({
      'template_key': 'encounter_summary',
      'clinical_data': {'x': 1},
      'signed_url': 'https://example.com',
      'internal_doctor_note': 'note',
      'pdf_content': 'binary',
    });

    expect(out.keys, ['template_key']);
    expect(out.containsKey('signed_url'), isFalse);
    expect(out.containsKey('publicUrl'), isFalse);
  });
}
