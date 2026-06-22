import 'lab_test_catalog.dart';

class LabCustomTestEntry {
  final String id;
  final String label;

  const LabCustomTestEntry({
    required this.id,
    required this.label,
  });

  LabCustomTestEntry copyWith({String? id, String? label}) {
    return LabCustomTestEntry(
      id: id ?? this.id,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label};

  static LabCustomTestEntry fromJson(Map<String, dynamic> json) {
    return LabCustomTestEntry(
      id: json['id'] is String ? json['id'] as String : '',
      label: json['label'] is String ? json['label'] as String : '',
    );
  }
}

/// Tenant «Diğer» test listesi — doktor tarafından düzenlenir.
class LabOrderCatalogSettings {
  final Set<LabTestCode> enabledDigerTests;
  final List<LabCustomTestEntry> customTests;

  const LabOrderCatalogSettings({
    required this.enabledDigerTests,
    this.customTests = const [],
  });

  static final LabOrderCatalogSettings defaults = LabOrderCatalogSettings(
    enabledDigerTests: Set<LabTestCode>.from(labDefaultDigerTestCodes),
  );

  List<LabTestCode> get visibleDigerBuiltInTests {
    return labDefaultDigerTestCodes
        .where((code) => enabledDigerTests.contains(code))
        .toList();
  }

  String? labelForCustomTest(String id) {
    for (final entry in customTests) {
      if (entry.id == id) return entry.label.trim();
    }
    return null;
  }

  LabOrderCatalogSettings copyWith({
    Set<LabTestCode>? enabledDigerTests,
    List<LabCustomTestEntry>? customTests,
  }) {
    return LabOrderCatalogSettings(
      enabledDigerTests: enabledDigerTests ?? this.enabledDigerTests,
      customTests: customTests ?? this.customTests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled_diger_tests':
          enabledDigerTests.map((c) => c.name).toList(growable: false),
      'custom_tests': customTests.map((e) => e.toJson()).toList(),
    };
  }

  static LabOrderCatalogSettings fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return defaults;

    final enabledRaw = json['enabled_diger_tests'];
    final enabled = <LabTestCode>{};
    if (enabledRaw is List) {
      for (final item in enabledRaw) {
        if (item is! String) continue;
        for (final code in LabTestCode.values) {
          if (code.name == item) enabled.add(code);
        }
      }
    }
    if (enabled.isEmpty) {
      enabled.addAll(labDefaultDigerTestCodes);
    }

    final customRaw = json['custom_tests'];
    final custom = <LabCustomTestEntry>[];
    if (customRaw is List) {
      for (final item in customRaw) {
        if (item is Map<String, dynamic>) {
          final entry = LabCustomTestEntry.fromJson(item);
          if (entry.id.trim().isNotEmpty && entry.label.trim().isNotEmpty) {
            custom.add(entry);
          }
        }
      }
    }

    return LabOrderCatalogSettings(
      enabledDigerTests: enabled,
      customTests: custom,
    );
  }
}
