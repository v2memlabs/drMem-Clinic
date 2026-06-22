import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_lookup_data_source.dart';

void main() {
  setUp(() {
    AppBackendConfig.activeBackend = DataBackend.mock;
    AppBackendConfig.requestedBackend = DataBackend.mock;
  });

  test('findById delegates to sync mock when remote unavailable', () async {
    const id = 'a1';
    final sync = AppointmentLookupDataSource.findByIdSync(id);
    final async = await AppointmentLookupDataSource.findById(id);
    expect(async, sync);
  });

  test('findById returns null for empty id', () async {
    expect(await AppointmentLookupDataSource.findById(''), isNull);
  });
}
