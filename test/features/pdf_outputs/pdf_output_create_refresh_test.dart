import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_list_refresh.dart';

void main() {
  group('PdfOutputListRefresh', () {
    test('markStale increments version', () {
      final seen = PdfOutputListRefresh.version;
      expect(PdfOutputListRefresh.isStale(seen), isFalse);
      PdfOutputListRefresh.markStale();
      expect(PdfOutputListRefresh.isStale(seen), isTrue);
    });
  });
}
