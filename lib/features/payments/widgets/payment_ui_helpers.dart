import 'package:flutter/material.dart';
import '../models/payment_record.dart';

String formatPaymentAmount(double amount) => '${amount.toStringAsFixed(2)} TL';

String paymentServiceTypeLabel(ServiceType type) {
  switch (type) {
    case ServiceType.muayene:
      return 'Muayene';
    case ServiceType.kontrol:
      return 'Kontrol';
    case ServiceType.enjeksiyon_girisim:
      return 'Enjeksiyon / Girişim';
    case ServiceType.ameliyat_girisim_notu:
      return 'Ameliyat / Girişim Notu';
    case ServiceType.fizyoterapi_seansi:
      return 'Fizyoterapi Seansı';
    case ServiceType.rehabilitasyon:
      return 'Rehabilitasyon';
    case ServiceType.rapor_belge:
      return 'Rapor / Belge';
    case ServiceType.diger:
      return 'Diğer';
  }
}

String paymentMethodLabel(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.nakit:
      return 'Nakit';
    case PaymentMethod.kredi_karti:
      return 'Kredi Kartı';
    case PaymentMethod.havale_eft:
      return 'Havale / EFT';
    case PaymentMethod.karma:
      return 'Karma';
    case PaymentMethod.belirtilmedi:
      return 'Belirtilmedi';
  }
}

String paymentStatusLabel(PaymentStatus status) => _statusLabel(status);

String paymentInvoiceStatusLabel(InvoiceStatus status) => _invoiceLabel(status);

class PaymentStatusChip extends StatelessWidget {
  final PaymentStatus status;

  const PaymentStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = _paymentStatusColors(status, Theme.of(context).colorScheme);
    return _softChip(
      context,
      label: _statusLabel(status),
      background: colors.background,
      foreground: colors.foreground,
    );
  }
}

class InvoiceStatusChip extends StatelessWidget {
  final InvoiceStatus status;

  const InvoiceStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _softChip(
      context,
      label: _invoiceLabel(status),
      background: scheme.surfaceContainerHighest,
      foreground: scheme.onSurfaceVariant,
    );
  }
}

class _ChipColors {
  final Color background;
  final Color foreground;

  const _ChipColors(this.background, this.foreground);
}

_ChipColors _paymentStatusColors(PaymentStatus status, ColorScheme scheme) {
  switch (status) {
    case PaymentStatus.odendi:
      return const _ChipColors(Color(0xFFD7F0E3), Color(0xFF1B5E3A));
    case PaymentStatus.kismi_odendi:
      return const _ChipColors(Color(0xFFFFE8CC), Color(0xFF8A4B00));
    case PaymentStatus.bekliyor:
      return _ChipColors(scheme.primaryContainer, scheme.onPrimaryContainer);
    case PaymentStatus.iptal:
      return _ChipColors(scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
    case PaymentStatus.iade:
      return _ChipColors(scheme.errorContainer, scheme.onErrorContainer);
  }
}

String _statusLabel(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.odendi:
      return 'Ödendi';
    case PaymentStatus.kismi_odendi:
      return 'Kısmi Ödendi';
    case PaymentStatus.bekliyor:
      return 'Bekliyor';
    case PaymentStatus.iptal:
      return 'İptal';
    case PaymentStatus.iade:
      return 'İade';
  }
}

String _invoiceLabel(InvoiceStatus status) {
  switch (status) {
    case InvoiceStatus.kesildi:
      return 'Fatura Kesildi';
    case InvoiceStatus.bekliyor:
      return 'Fatura Bekliyor';
    case InvoiceStatus.gerekmiyor:
      return 'Fatura Gerekmiyor';
    case InvoiceStatus.belirtilmedi:
      return 'Belirtilmedi';
  }
}

Widget _softChip(
  BuildContext context, {
  required String label,
  required Color background,
  required Color foreground,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

Widget paymentSectionTitle(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
    ),
  );
}

Widget paymentDetailSection(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      paymentSectionTitle(context, title),
      Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ],
  );
}

Widget paymentDetailRow(BuildContext context, String label, String value) {
  final muted = Theme.of(context).colorScheme.onSurfaceVariant;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
