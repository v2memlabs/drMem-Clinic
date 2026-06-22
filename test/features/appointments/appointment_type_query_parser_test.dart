import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_type_query_parser.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';

void main() {
  test('fizikTedavi enum name parses', () {
    expect(
      AppointmentTypeQueryParser.fromQuery('fizikTedavi'),
      AppointmentType.fizikTedavi,
    );
  });

  test('physiotherapy DB alias parses', () {
    expect(
      AppointmentTypeQueryParser.fromQuery('physiotherapy'),
      AppointmentType.fizikTedavi,
    );
  });

  test('unknown type returns null', () {
    expect(AppointmentTypeQueryParser.fromQuery('unknown_type'), isNull);
    expect(AppointmentTypeQueryParser.fromQuery(''), isNull);
    expect(AppointmentTypeQueryParser.fromQuery(null), isNull);
  });
}
