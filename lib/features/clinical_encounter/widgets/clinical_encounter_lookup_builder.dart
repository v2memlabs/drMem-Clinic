import 'package:flutter/material.dart';

import '../data/clinical_encounter_lookup_data_source.dart';
import '../models/clinical_encounter.dart';

/// [ClinicalEncounterLookupDataSource.findById] sonucunu [builder] ile sunar.
class ClinicalEncounterLookupBuilder extends StatelessWidget {
  final String? encounterId;
  final Widget Function(BuildContext context, ClinicalEncounter? encounter)
      builder;

  const ClinicalEncounterLookupBuilder({
    super.key,
    required this.encounterId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final id = encounterId?.trim() ?? '';
    if (id.isEmpty) {
      return builder(context, null);
    }

    return FutureBuilder<ClinicalEncounter?>(
      future: ClinicalEncounterLookupDataSource.findById(id),
      builder: (context, snapshot) => builder(context, snapshot.data),
    );
  }
}
