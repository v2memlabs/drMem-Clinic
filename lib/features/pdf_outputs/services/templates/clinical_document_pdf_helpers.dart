import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../pdf_letterhead_config.dart';

final PdfColor clinicalDocAccentTeal = PdfColor.fromInt(0xFF00838F);
final PdfColor clinicalDocAccentNavy = PdfColor.fromInt(0xFF1565C0);
final PdfColor clinicalDocMutedGray = PdfColor.fromInt(0xFF616161);

/// [pw.MultiPage] içerik alanı yatay kenar boşluğu — tam genişlik çerçeve için.
const double clinicalDocContentHorizontalMargin = 48;

pw.Widget buildClinicalDocHeader(
  PdfLetterheadConfig letterhead,
  pw.Font boldFont,
  pw.Font baseFont,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Text(
        letterhead.clinicName,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 13,
          color: clinicalDocAccentNavy,
        ),
      ),
      if (letterhead.specialty.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Text(
          letterhead.specialty,
          style: pw.TextStyle(
            font: baseFont,
            fontSize: 9,
            color: clinicalDocMutedGray,
          ),
        ),
      ],
      pw.SizedBox(height: 6),
      pw.Container(height: 1.5, color: clinicalDocAccentTeal),
      pw.SizedBox(height: 5),
    ],
  );
}

pw.Widget buildClinicalDocFooter(
  pw.Context context,
  String footerNotice,
  pw.Font baseFont,
) {
  return pw.Column(
    children: [
      pw.Divider(color: clinicalDocMutedGray, height: 0.5),
      pw.SizedBox(height: 4),
      pw.Text(
        footerNotice,
        style: pw.TextStyle(
          font: baseFont,
          fontSize: 7,
          color: clinicalDocMutedGray,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Center(
        child: pw.Text(
          'Sayfa ${context.pageNumber} / ${context.pagesCount}',
          style: pw.TextStyle(
            font: baseFont,
            fontSize: 7,
            color: clinicalDocMutedGray,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    ],
  );
}

pw.Widget clinicalDocSectionTitle(String title, pw.Font boldFont) {
  return pw.Center(
    child: pw.Text(
      title,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(font: boldFont, fontSize: 11),
    ),
  );
}

/// Bölüm başlığı altı çerçevesi — sayfa içerik alanının tam genişliğine yayılır.
pw.Widget clinicalDocEdgeToEdgeFrame({
  required List<pw.Widget> children,
  double horizontalBleed = clinicalDocContentHorizontalMargin,
  pw.EdgeInsetsGeometry padding = const pw.EdgeInsets.all(8),
  pw.EdgeInsetsGeometry? margin,
}) {
  return pw.Container(
    width: double.infinity,
    margin: margin ??
        pw.EdgeInsets.fromLTRB(-horizontalBleed, 0, -horizontalBleed, 0),
    padding: padding,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: clinicalDocMutedGray, width: 0.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    ),
  );
}

pw.Widget clinicalDocLabelValue(
  String label,
  String value,
  pw.Font baseFont,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(font: baseFont, fontSize: 10),
          ),
          pw.TextSpan(
            text: value.trim().isEmpty ? 'Belirtilmedi' : value.trim(),
            style: pw.TextStyle(font: baseFont, fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

String formatClinicalDocDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}
