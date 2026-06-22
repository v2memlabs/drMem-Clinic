enum PaymentRehabBillingMode {
  tekSeans,
  paket,
}

String paymentRehabBillingModeLabel(PaymentRehabBillingMode mode) {
  switch (mode) {
    case PaymentRehabBillingMode.tekSeans:
      return 'Tek seans';
    case PaymentRehabBillingMode.paket:
      return 'Paket';
  }
}
