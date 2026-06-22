import '../models/lab_order_catalog_settings.dart';

/// Oturum kapsamında tenant laboratuvar katalog ayarları.
abstract final class LabOrderCatalogGate {
  static LabOrderCatalogSettings _settings = LabOrderCatalogSettings.defaults;

  static LabOrderCatalogSettings get current => _settings;

  static void apply(LabOrderCatalogSettings settings) {
    _settings = settings;
  }

  static void reset() {
    _settings = LabOrderCatalogSettings.defaults;
  }
}
