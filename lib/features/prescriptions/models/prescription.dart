class PrescriptionMedication {
  final String name;
  final String dose;
  final String frequency;
  final String duration;
  final String? notes;
  /// PDF D…B satırı için kutu sayısı (e-reçete entegrasyonu öncesi manuel).
  final int? boxCount;

  const PrescriptionMedication({
    required this.name,
    required this.dose,
    required this.frequency,
    required this.duration,
    this.notes,
    this.boxCount,
  });

  PrescriptionMedication copyWith({
    String? name,
    String? dose,
    String? frequency,
    String? duration,
    String? notes,
    int? boxCount,
  }) {
    return PrescriptionMedication(
      name: name ?? this.name,
      dose: dose ?? this.dose,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      boxCount: boxCount ?? this.boxCount,
    );
  }
}

enum PrescriptionStatus { taslak, hazirlandi, hastayaVerildi, iptal }

class Prescription {
  final String id;
  final String patientId;
  final String patientName;
  final String? clinicalEncounterId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final PrescriptionStatus status;
  final String diagnosis;
  final List<PrescriptionMedication> medications;
  final String? additionalNotes;

  const Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.clinicalEncounterId,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    required this.status,
    required this.diagnosis,
    required this.medications,
    this.additionalNotes,
  });

  Prescription copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? clinicalEncounterId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    PrescriptionStatus? status,
    String? diagnosis,
    List<PrescriptionMedication>? medications,
    String? additionalNotes,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      clinicalEncounterId: clinicalEncounterId ?? this.clinicalEncounterId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      diagnosis: diagnosis ?? this.diagnosis,
      medications: medications ?? this.medications,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }
}

String prescriptionStatusLabel(PrescriptionStatus status) {
  switch (status) {
    case PrescriptionStatus.taslak:
      return 'Taslak';
    case PrescriptionStatus.hazirlandi:
      return 'Hazırlandı';
    case PrescriptionStatus.hastayaVerildi:
      return 'Hastaya Verildi';
    case PrescriptionStatus.iptal:
      return 'İptal';
  }
}
