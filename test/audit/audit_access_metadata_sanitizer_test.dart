import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/audit/access/audit_access_metadata_sanitizer.dart';

void main() {
  group('AuditAccessMetadataSanitizer', () {
    test('strips forbidden clinical keys', () {
      final out = AuditAccessMetadataSanitizer.sanitize({
        'internal_doctor_note': 'secret',
        'clinical_data': {'x': 1},
        'result_count': 3,
        'source': 'data_source',
      });

      expect(out.containsKey('internal_doctor_note'), isFalse);
      expect(out.containsKey('clinical_data'), isFalse);
      expect(out['result_count'], 3);
      expect(out['source'], 'data_source');
    });

    test('rejects nested objects and long strings', () {
      final out = AuditAccessMetadataSanitizer.sanitize({
        'note': 'x' * 600,
        'nested': {'a': 1},
      });

      expect(out.isEmpty, isTrue);
    });
  });
}
