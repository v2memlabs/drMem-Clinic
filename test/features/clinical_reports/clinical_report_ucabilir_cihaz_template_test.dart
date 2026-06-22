import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_reports/data/clinical_report_cihaz_body_template.dart';
import 'package:v2mem_clinic/features/clinical_reports/data/clinical_report_ucabilir_body_template.dart';
import 'package:v2mem_clinic/features/clinical_reports/models/clinical_report.dart';

void main() {
  test('ucabilir body template — uçabilir kararı', () {
    final text = ClinicalReportUcabilirBodyTemplate.compose(
      diagnosis: 'Sol omuz impingement sendromu',
      treatmentApproach: ClinicalReportTreatmentApproach.konservatif,
      flightDecision: ClinicalReportFlightDecision.ucabilir,
    );
    expect(text, contains('uçakla seyahat etmesinde sakınca yoktur.'));
  });

  test('ucabilir body template — koşullu uçuş', () {
    final text = ClinicalReportUcabilirBodyTemplate.compose(
      diagnosis: 'Diz protezi',
      treatmentApproach: ClinicalReportTreatmentApproach.cerrahi,
      flightDecision: ClinicalReportFlightDecision.kosullu,
      flightConditions: 'Uzun mesafe uçuşlarda mobilizasyon önerilir.',
    );
    expect(text, contains('aşağıda belirtilen koşullar sağlandığında'));
    expect(
      text,
      contains(ClinicalReportUcabilirBodyTemplate.flightConditionsHeading),
    );
    expect(text, contains('Uzun mesafe uçuşlarda mobilizasyon önerilir.'));
  });

  test('cihaz body template composes docx sentence', () {
    final text = ClinicalReportCihazBodyTemplate.compose(
      diagnosis: 'Sağ diz medial menisküs yırtığı',
      treatmentApproach: ClinicalReportTreatmentApproach.konservatif,
      deviceUsageDuration: '4 hafta',
      deviceName: 'dizlik',
      deviceUsageNotes: 'Yürürken sürekli kullanılmalıdır',
      weightBearing: ClinicalReportWeightBearing.kismi,
    );
    expect(
      text,
      contains(
        'hastaya 4 hafta süreyle dizlik kullanımı önerilmiştir.',
      ),
    );
    expect(
      text,
      contains(ClinicalReportCihazBodyTemplate.usageInstructionHeading),
    );
    expect(text, contains('Yürürken sürekli kullanılmalıdır'));
    expect(text, contains('Kısmi yük bindirme'));
  });
}
