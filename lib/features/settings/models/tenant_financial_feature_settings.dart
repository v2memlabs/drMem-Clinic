/// IT bakım konsolundan tenant bazında yönetilen finansal özellik bayrakları.
///
/// `tenants.settings_json.financial` altında saklanır; klinik kullanıcıları değiştiremez.
enum TenantFinancialFeatureKey {
  paymentRecords,
  encounterPaymentStep,
  surgicalQuotePricing,
  surgicalQuoteAlerts,
  assistantFinanceNotifications,
  materialCharges,
  rehabPackagePricing,
}

class TenantFinancialFeatureDefinition {
  final TenantFinancialFeatureKey key;
  final String label;
  final String description;

  const TenantFinancialFeatureDefinition({
    required this.key,
    required this.label,
    required this.description,
  });
}

abstract final class TenantFinancialFeatureCatalog {
  static const definitions = <TenantFinancialFeatureDefinition>[
    TenantFinancialFeatureDefinition(
      key: TenantFinancialFeatureKey.paymentRecords,
      label: 'Ödeme kayıtları',
      description:
          'Ödeme listesi, detay, yeni kayıt ve hasta zaman çizelgesindeki ödeme kayıtları.',
    ),
    TenantFinancialFeatureDefinition(
      key: TenantFinancialFeatureKey.encounterPaymentStep,
      label: 'Muayene sonrası ödeme adımı',
      description: 'Yeni muayene kaydı sonrası sihirbazdaki ödeme ekranı.',
    ),
    TenantFinancialFeatureDefinition(
      key: TenantFinancialFeatureKey.surgicalQuotePricing,
      label: 'Cerrahi teklif fiyatı',
      description:
          'Muayene sonrası cerrahi teklif tutarı girme ve verilen fiyatın kaydı.',
    ),
    TenantFinancialFeatureDefinition(
      key: TenantFinancialFeatureKey.surgicalQuoteAlerts,
      label: 'Cerrahi fiyat uyarıları',
      description:
          'Hasta detayı ve muayene formundaki cerrahi teklif banner\'ları.',
    ),
    TenantFinancialFeatureDefinition(
      key: TenantFinancialFeatureKey.assistantFinanceNotifications,
      label: 'Asistan finans bildirimleri',
      description:
          'Ödeme ve cerrahi teklif bildirimlerinin asistan ana ekranına düşmesi.',
    ),
    TenantFinancialFeatureDefinition(
      key: TenantFinancialFeatureKey.materialCharges,
      label: 'Malzeme şarjı',
      description: 'Hastaya malzeme şarjı ve muayene ödeme kaydına yansıtma.',
    ),
    TenantFinancialFeatureDefinition(
      key: TenantFinancialFeatureKey.rehabPackagePricing,
      label: 'Rehabilitasyon paket fiyatlandırma',
      description:
          'Ödeme formunda rehabilitasyon paket/seans tipi ve tutar alanları.',
    ),
  ];
}

class TenantFinancialFeatureSettings {
  final Map<TenantFinancialFeatureKey, bool> flags;

  const TenantFinancialFeatureSettings({required this.flags});

  static final TenantFinancialFeatureSettings defaults =
      TenantFinancialFeatureSettings(
    flags: {
      for (final def in TenantFinancialFeatureCatalog.definitions)
        def.key: true,
    },
  );

  bool isEnabled(TenantFinancialFeatureKey key) => flags[key] ?? true;

  TenantFinancialFeatureSettings copyWithFlag(
    TenantFinancialFeatureKey key,
    bool enabled,
  ) {
    final next = Map<TenantFinancialFeatureKey, bool>.from(flags);
    next[key] = enabled;
    return TenantFinancialFeatureSettings(flags: next);
  }

  Map<String, dynamic> toJson() {
    return {
      for (final def in TenantFinancialFeatureCatalog.definitions)
        _storageKey(def.key): flags[def.key] ?? true,
    };
  }

  static TenantFinancialFeatureSettings fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return defaults;
    final nested = json['financial'];
    final source = nested is Map<String, dynamic> ? nested : json;
    final next = <TenantFinancialFeatureKey, bool>{};
    for (final def in TenantFinancialFeatureCatalog.definitions) {
      final raw = source[_storageKey(def.key)];
      next[def.key] = raw is bool ? raw : true;
    }
    return TenantFinancialFeatureSettings(flags: next);
  }

  static String _storageKey(TenantFinancialFeatureKey key) {
    switch (key) {
      case TenantFinancialFeatureKey.paymentRecords:
        return 'payment_records';
      case TenantFinancialFeatureKey.encounterPaymentStep:
        return 'encounter_payment_step';
      case TenantFinancialFeatureKey.surgicalQuotePricing:
        return 'surgical_quote_pricing';
      case TenantFinancialFeatureKey.surgicalQuoteAlerts:
        return 'surgical_quote_alerts';
      case TenantFinancialFeatureKey.assistantFinanceNotifications:
        return 'assistant_finance_notifications';
      case TenantFinancialFeatureKey.materialCharges:
        return 'material_charges';
      case TenantFinancialFeatureKey.rehabPackagePricing:
        return 'rehab_package_pricing';
    }
  }
}
