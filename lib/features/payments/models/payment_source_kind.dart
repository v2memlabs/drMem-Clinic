enum PaymentSourceKind {
  manual,
  materialCharge,
}

String paymentSourceKindLabel(PaymentSourceKind kind) {
  switch (kind) {
    case PaymentSourceKind.manual:
      return 'Manuel';
    case PaymentSourceKind.materialCharge:
      return 'Malzeme şarjı';
  }
}
