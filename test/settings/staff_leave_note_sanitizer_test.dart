import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/settings/data/staff_leave_note_sanitizer.dart';

void main() {
  group('StaffLeaveNoteSanitizer', () {
    test('removes forbidden keys from text', () {
      const input =
          'Yıllık izin internalDoctorNote clinical_data signed_url token';
      final out = StaffLeaveNoteSanitizer.sanitize(input);
      expect(out, isNotNull);
      expect(out!.toLowerCase(), isNot(contains('internaldoctornote')));
      expect(out.toLowerCase(), isNot(contains('clinical_data')));
      expect(out.toLowerCase(), isNot(contains('signed_url')));
      expect(out.toLowerCase(), isNot(contains('token')));
      expect(out, contains('Yıllık izin'));
    });

    test('truncates to max 500 characters', () {
      final long = 'a' * 600;
      final out = StaffLeaveNoteSanitizer.sanitize(long);
      expect(out, isNotNull);
      expect(out!.length, 500);
    });

    test('preserves normal Turkish note', () {
      const input = 'Cumartesi pazarı tatil, acil durumda arayın.';
      expect(StaffLeaveNoteSanitizer.sanitize(input), input);
    });

    test('empty returns null', () {
      expect(StaffLeaveNoteSanitizer.sanitize('   '), isNull);
      expect(StaffLeaveNoteSanitizer.sanitize(null), isNull);
    });
  });
}
