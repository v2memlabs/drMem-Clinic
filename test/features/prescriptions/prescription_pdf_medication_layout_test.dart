import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:v2mem_clinic/features/prescriptions/models/prescription.dart';
import 'package:v2mem_clinic/features/prescriptions/services/prescription_pdf_medication_layout.dart';

void main() {
  test('prescription medication section builds widgets for usage format', () {
    const med = PrescriptionMedication(
      name: 'Parasetamol',
      dose: '',
      frequency: 'Günde 3 kez',
      duration: '7 gün',
      boxCount: 1,
    );

    final widgets = buildPrescriptionMedicationSection(
      const [med],
      pw.Font.helvetica(),
      pw.Font.helveticaBold(),
    );

    expect(widgets.length, greaterThan(1));
  });
}
