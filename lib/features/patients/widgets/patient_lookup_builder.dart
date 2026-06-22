import 'package:flutter/material.dart';

import '../data/patient_lookup_data_source.dart';
import '../models/patient.dart';

/// [PatientLookupDataSource.findById] sonucunu [builder] ile sunar.
///
/// Yükleme sırasında `patient` null gelir; satır/detay ekranları denormalize
/// alanlarla çalışmaya devam eder.
class PatientLookupBuilder extends StatelessWidget {
  final String patientId;
  final Widget Function(BuildContext context, Patient? patient) builder;

  const PatientLookupBuilder({
    super.key,
    required this.patientId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Patient?>(
      future: PatientLookupDataSource.findById(patientId),
      builder: (context, snapshot) => builder(context, snapshot.data),
    );
  }
}
