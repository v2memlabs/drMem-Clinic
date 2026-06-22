import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_view_launcher.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';

void main() {
  test('view exception maps safe user messages', () {
    const notStored = PdfOutputViewException(PdfOutputViewFailureReason.notStored);
    expect(notStored.userMessage, 'PDF henüz depolanmamış.');

    const signed = PdfOutputViewException(
      PdfOutputViewFailureReason.signedUrlFailed,
    );
    expect(
      signed.userMessage,
      'PDF bağlantısı oluşturulamadı. Lütfen tekrar deneyin.',
    );

    const launch = PdfOutputViewException(PdfOutputViewFailureReason.launchFailed);
    expect(
      launch.userMessage,
      'PDF bağlantısı oluşturuldu ancak cihazda açılamadı.',
    );
  });

  test('openStoredPdf throws notStored when path missing', () async {
    final output = PdfOutput(
      id: 'pdf-1',
      patientId: 'p1',
      patientName: 'Hasta',
      createdAt: DateTime(2026, 6, 1),
      documentType: DocumentType.muayeneOzeti,
      title: 'Test',
      contentSummary: 'Özet',
      warningNote: 'Not',
      createdBy: 'Dr',
      status: PdfStatus.taslak,
    );

    expect(
      () => PdfOutputViewLauncher.openStoredPdf(output),
      throwsA(
        isA<PdfOutputViewException>().having(
          (e) => e.reason,
          'reason',
          PdfOutputViewFailureReason.notStored,
        ),
      ),
    );
  });
}
