import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/lab_orders/models/lab_order_catalog_settings.dart';
import 'package:v2mem_clinic/features/lab_orders/models/lab_test_catalog.dart';

void main() {
  test('catalog settings round-trip json', () {
    final settings = LabOrderCatalogSettings(
      enabledDigerTests: {LabTestCode.vitaminD, LabTestCode.tiroidFonksiyon},
      customTests: const [
        LabCustomTestEntry(id: 'c1', label: 'PTH'),
      ],
    );

    final restored = LabOrderCatalogSettings.fromJson(settings.toJson());
    expect(restored.enabledDigerTests, settings.enabledDigerTests);
    expect(restored.customTests.first.label, 'PTH');
  });

  test('defaults include all diger built-in tests', () {
    expect(
      LabOrderCatalogSettings.defaults.enabledDigerTests,
      containsAll(labDefaultDigerTestCodes),
    );
  });
}
