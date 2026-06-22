import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_reports/models/clinical_report.dart';

void main() {
  test('tek hekim raporu label matches docx title', () {
    expect(
      clinicalReportTypeLabel(ClinicalReportType.diger),
      'Tek Hekim Raporu',
    );
  });
}
