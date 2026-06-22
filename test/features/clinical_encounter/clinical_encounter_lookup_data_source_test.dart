import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_lookup_data_source.dart';

void main() {
  setUp(() {
    AppBackendConfig.activeBackend = DataBackend.mock;
    AppBackendConfig.requestedBackend = DataBackend.mock;
  });

  test('findById delegates to sync mock when remote unavailable', () async {
    const id = 'ce1';
    final sync = ClinicalEncounterLookupDataSource.findByIdSync(id);
    final async = await ClinicalEncounterLookupDataSource.findById(id);
    expect(async, sync);
  });

  test('findById returns null for empty id', () async {
    expect(await ClinicalEncounterLookupDataSource.findById(''), isNull);
  });
}
