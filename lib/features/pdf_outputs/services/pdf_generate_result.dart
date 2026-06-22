import 'dart:typed_data';

/// Local PDF üretim çıktısı.
class PdfGenerateResult {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final DateTime generatedAt;

  const PdfGenerateResult({
    required this.bytes,
    required this.fileName,
    required this.generatedAt,
    this.mimeType = 'application/pdf',
  });
}
