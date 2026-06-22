import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_date_query_parser.dart';

void main() {
  group('AppointmentDateQueryParser', () {
    test('toQuery formats yyyy-MM-dd', () {
      expect(
        AppointmentDateQueryParser.toQuery(DateTime(2026, 6, 7)),
        '2026-06-07',
      );
    });

    test('fromQuery parses valid date', () {
      final parsed = AppointmentDateQueryParser.fromQuery('2026-06-07');
      expect(parsed, DateTime(2026, 6, 7));
    });

    test('fromQuery rejects invalid values', () {
      expect(AppointmentDateQueryParser.fromQuery(null), isNull);
      expect(AppointmentDateQueryParser.fromQuery(''), isNull);
      expect(AppointmentDateQueryParser.fromQuery('07-06-2026'), isNull);
      expect(AppointmentDateQueryParser.fromQuery('2026-02-31'), isNull);
    });

    test('roundtrip preserves calendar day', () {
      final day = DateTime(2026, 12, 1);
      final query = AppointmentDateQueryParser.toQuery(day);
      expect(AppointmentDateQueryParser.fromQuery(query), day);
    });
  });
}
