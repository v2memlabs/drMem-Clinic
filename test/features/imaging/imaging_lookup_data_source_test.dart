import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/imaging/data/imaging_lookup_data_source.dart';

void main() {
  setUp(() {
    AppBackendConfig.activeBackend = DataBackend.mock;
    AppBackendConfig.requestedBackend = DataBackend.mock;
  });

  test('findById returns note in mock mode', () async {
    final note = await ImagingLookupDataSource.findById('i1');
    expect(note, isNotNull);
    expect(note!.id, 'i1');
  });

  test('findById returns null for empty id', () async {
    expect(await ImagingLookupDataSource.findById(''), isNull);
  });
}
