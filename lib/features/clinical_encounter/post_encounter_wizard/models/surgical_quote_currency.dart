enum SurgicalQuoteCurrency {
  try_,
  usd,
  eur,
  stg,
}

extension SurgicalQuoteCurrencyLabels on SurgicalQuoteCurrency {
  String get label {
    switch (this) {
      case SurgicalQuoteCurrency.try_:
        return 'TL';
      case SurgicalQuoteCurrency.usd:
        return 'USD';
      case SurgicalQuoteCurrency.eur:
        return 'EUR';
      case SurgicalQuoteCurrency.stg:
        return 'STG';
    }
  }

  String get notificationLabel => label;
}
