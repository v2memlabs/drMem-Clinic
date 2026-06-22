import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_reports/data/clinical_report_durum_bildirir_body_template.dart';
import 'package:v2mem_clinic/features/clinical_reports/models/clinical_report.dart';

void main() {
  test('durum bildirir body template composes docx sentence', () {
    final text = ClinicalReportDurumBildirirBodyTemplate.compose(
      diagnosis: 'Sol omuz ağrısı',
      treatmentApproach: ClinicalReportTreatmentApproach.konservatif,
      duration: '2 hafta',
      recommendation: 'ağır aktiviteden kaçınması',
      suitability: ClinicalReportStatusSuitability.uygun,
      supplementaryNotes: 'Fizik tedavi programına devam edecektir.',
    );

    expect(
      text,
      contains(
        'Yukarıda kimliği belirtilen hastamız Sol omuz ağrısı tanısıyla '
        'konservatif tedaviyle takip edilmektedir.',
      ),
    );
    expect(
      text,
      contains(
        'Hastanın 2 hafta süreyle ağır aktiviteden kaçınması uygundur.',
      ),
    );
    expect(text, contains(ClinicalReportDurumBildirirBodyTemplate.legalNotice));
    expect(text, contains('Fizik tedavi programına devam edecektir.'));
  });
}
