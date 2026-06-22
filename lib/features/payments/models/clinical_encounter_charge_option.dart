/// Malzeme şarjı — muayene seçimi (klinik detay içermez).
class ClinicalEncounterChargeOption {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime encounterDate;
  final String? protocolNumber;

  const ClinicalEncounterChargeOption({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.encounterDate,
    this.protocolNumber,
  });

  String get displayLabel {
    final date = encounterDate.toLocal();
    final dateText =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    final protocol = protocolNumber?.trim();
    if (protocol != null && protocol.isNotEmpty) {
      return '$patientName · $dateText · $protocol';
    }
    return '$patientName · $dateText';
  }
}
