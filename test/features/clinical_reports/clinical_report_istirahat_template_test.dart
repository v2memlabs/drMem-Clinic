import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_reports/data/clinical_report_istirahat_body_template.dart';
import 'package:v2mem_clinic/features/clinical_reports/data/clinical_report_number_helper.dart';
import 'package:v2mem_clinic/features/clinical_reports/models/clinical_report.dart';

void main() {
  test('istirahat body template composes sentence format C', () {
    final text = ClinicalReportIstirahatBodyTemplate.compose(
      diagnosis: 'Sağ diz medial menisküs yırtığı',
      treatmentApproach: ClinicalReportTreatmentApproach.konservatif,
      startDate: DateTime(2026, 6, 9),
      endDate: DateTime(2026, 6, 16),
      restDays: 7,
    );

    expect(
      text,
      contains(
        'Sağ diz medial menisküs yırtığı tanısıyla konservatif tedavi ile '
        'takip edilen hastanın 09.06.2026 – 16.06.2026 tarihleri arasında '
        '7 gün istirahati uygundur.',
      ),
    );
    expect(text, contains(ClinicalReportIstirahatBodyTemplate.defaultRestrictionNotes));
  });

  test('report number helper increments yearly sequence', () {
    final next = ClinicalReportNumberHelper.nextFromExisting(
      const ['R-2026-00001', 'R-2026-00008', 'R-2025-00099'],
      year: 2026,
    );
    expect(next, 'R-2026-00009');
  });

  test('rest days between dates is inclusive', () {
    final days = ClinicalReportIstirahatBodyTemplate.restDaysBetween(
      DateTime(2026, 6, 9),
      DateTime(2026, 6, 15),
    );
    expect(days, 7);
  });

  test('return to work date is day after rest end', () {
    final label = ClinicalReportIstirahatBodyTemplate.returnToWorkDateLabel(
      DateTime(2026, 6, 16),
    );
    expect(label, 'İşe başlama tarihi: 17.06.2026');
  });
}
