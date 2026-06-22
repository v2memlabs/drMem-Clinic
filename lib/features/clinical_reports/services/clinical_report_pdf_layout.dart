import 'package:pdf/widgets.dart' as pw;

import '../../pdf_outputs/services/clinical_document_pdf_layout.dart';
import '../../pdf_outputs/services/pdf_letterhead_config.dart';
import '../models/clinical_report.dart';

const double _bodyParagraphIndent = 24;
const double _pdfBodyFontSize = 10;
const double _pdfLineHeight = 12;

/// Tanı ↔ İlgili Makama arasında 4 satır boşluk.
const int clinicalReportPdfDiagnosisBlankLineCount = 4;
const double clinicalReportPdfDiagnosisBlankGap =
    _pdfLineHeight * clinicalReportPdfDiagnosisBlankLineCount;

/// Rapor metni son satırı ↔ imza arasında 7 satır boşluk (4 + 3).
const int clinicalReportPdfBodyToSignatureBlankLineCount = 7;
const double clinicalReportPdfBodyToSignatureBlankGap =
    clinicalDocumentPdfSignatureBlankGap;

Future<pw.ImageProvider?> loadClinicalReportLogo(PdfLetterheadConfig letterhead) =>
    loadClinicalDocumentLogo(letterhead);

pw.Widget buildClinicalReportLetterhead(
  PdfLetterheadConfig letterhead,
  pw.ImageProvider? logo,
  pw.Font boldFont,
  pw.Font baseFont,
) =>
    buildClinicalDocumentLetterhead(letterhead, logo, boldFont, baseFont);

pw.Widget buildClinicalReportCenteredTitle(String title, pw.Font boldFont) =>
    buildClinicalDocumentCenteredTitle(title, boldFont);

pw.Widget buildClinicalReportPatientBlock({
  required String patientName,
  required String? identityNumber,
  required String documentDateLabel,
  required String? protocolNumber,
  required String? reportNumber,
  required pw.Font baseFont,
  required pw.Font boldFont,
}) =>
    buildClinicalDocumentPatientBlock(
      patientName: patientName,
      identityNumber: identityNumber,
      documentDateLabel: documentDateLabel,
      protocolNumber: protocolNumber,
      documentNumber: reportNumber,
      documentNumberLabel: 'Rapor No',
      baseFont: baseFont,
      boldFont: boldFont,
    );

pw.Widget buildClinicalReportInlineDiagnosis(String diagnosis, pw.Font baseFont) =>
    buildClinicalDocumentInlineDiagnosis(diagnosis, baseFont);

pw.Widget buildClinicalReportBodySection(
  String bodyText,
  pw.Font baseFont, {
  String? trailingLine,
}) {
  final content = bodyText.trim().isEmpty ? 'Belirtilmedi' : bodyText.trim();
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: _bodyParagraphIndent),
        child: pw.Text(
          clinicalReportPdfSalutation,
          style: pw.TextStyle(font: baseFont, fontSize: _pdfBodyFontSize),
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        content,
        style: pw.TextStyle(font: baseFont, fontSize: _pdfBodyFontSize),
      ),
      if (trailingLine != null && trailingLine.trim().isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.Text(
          trailingLine.trim(),
          style: pw.TextStyle(font: baseFont, fontSize: _pdfBodyFontSize),
        ),
      ],
    ],
  );
}

pw.Widget buildClinicalReportSignatureBlock(pw.Font baseFont) =>
    buildClinicalDocumentSignatureBlock(baseFont);

pw.Widget buildClinicalReportFooter(
  pw.Context context,
  String footerNotice,
  pw.Font baseFont, {
  required PdfLetterheadConfig letterhead,
}) =>
    buildClinicalDocumentFooter(
      context,
      footerNotice,
      baseFont,
      letterhead: letterhead,
    );
