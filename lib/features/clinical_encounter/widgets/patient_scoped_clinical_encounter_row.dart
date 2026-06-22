import 'package:flutter/material.dart';

import '../../../shared/widgets/clinical_list_row.dart';
import '../../../shared/widgets/clinical_list_status_tones.dart';
import '../data/clinical_encounter_patient_scoped_display.dart';
import '../models/clinical_encounter.dart';

/// Hasta detayı gömülü muayene satırı — hasta adı/demografi/chip yok.
class PatientScopedClinicalEncounterRow extends StatelessWidget {
  final ClinicalEncounter encounter;
  final bool usesRemote;
  final VoidCallback onTap;

  const PatientScopedClinicalEncounterRow({
    super.key,
    required this.encounter,
    required this.usesRemote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusTone =
        ClinicalListStatusTones.clinicalEncounterStatus(encounter.status);
    final marker = ClinicalListStatusTones.markerColorForTone(statusTone);

    final subtitle =
        ClinicalEncounterPatientScopedDisplay.diagnosisSubtitle(encounter);

    return ClinicalListRow(
      title: ClinicalEncounterPatientScopedDisplay.titleLine(encounter),
      subtitle: subtitle,
      metaLines: ClinicalEncounterPatientScopedDisplay.metaLines(
        encounter,
        usesRemote: usesRemote,
      ),
      showSemanticStatusChip: false,
      tags: const [],
      statusMarkerColor: marker,
      trailing: ClinicalEncounterPatientScopedDisplay.statusTrailing(encounter),
      compact: true,
      onTap: onTap,
    );
  }
}
