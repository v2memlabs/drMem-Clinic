/// Tedavi planı yaklaşımı — `clinical_data.plan.treatmentApproach` JSONB.
enum ClinicalTreatmentApproach {
  conservative,
  surgical,
  combined,
  observation;

  String get label {
    switch (this) {
      case ClinicalTreatmentApproach.conservative:
        return 'Konservatif';
      case ClinicalTreatmentApproach.surgical:
        return 'Cerrahi';
      case ClinicalTreatmentApproach.combined:
        return 'Kombine';
      case ClinicalTreatmentApproach.observation:
        return 'İzlem';
    }
  }

  static ClinicalTreatmentApproach? fromDb(String? value) {
    final v = value?.trim().toLowerCase();
    if (v == null || v.isEmpty) return null;
    for (final item in ClinicalTreatmentApproach.values) {
      if (item.name == v) return item;
    }
    return null;
  }

  static String? toDb(ClinicalTreatmentApproach? value) => value?.name;
}
