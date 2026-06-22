import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_bytes_builder.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (
      call,
    ) async {
      return '.';
    });
  });

  test('patient-only draft produces non-empty snapshot bytes', () async {
    final draft = PdfOutput(
      id: 'pdf-test-patient',
      patientId: 'p1',
      patientName: 'Ayşe Yılmaz',
      createdAt: DateTime(2026, 6, 1),
      documentType: DocumentType.hastaBilgilendirmeFormu,
      title: 'Hasta Bilgilendirme',
      contentSummary: 'Genel bilgilendirme metni.',
      warningNote: 'Uyarı notu.',
      createdBy: 'Dr. Test',
      status: PdfStatus.taslak,
    );

    final bytes = await PdfOutputBytesBuilder.buildForSave(draft: draft);

    expect(bytes, isNotNull);
    expect(bytes!.isNotEmpty, isTrue);
    expect(bytes.first, 0x25); // %
    expect(bytes[1], 0x50); // P
    expect(bytes[2], 0x44); // D
    expect(bytes[3], 0x46); // F
  });
}
