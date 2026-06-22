import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Islak imza taraması (görüntü) → tek sayfalık PDF.
abstract final class ConsentSignedImageToPdf {
  static Future<Uint8List> convert(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      throw ArgumentError('Görüntü boş olamaz.');
    }

    final doc = pw.Document();
    final image = pw.MemoryImage(imageBytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );
    return doc.save();
  }
}
