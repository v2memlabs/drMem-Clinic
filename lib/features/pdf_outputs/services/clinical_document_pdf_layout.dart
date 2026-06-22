import 'package:pdf/widgets.dart' as pw;

import 'pdf_letterhead_config.dart';
import 'pdf_letterhead_logo_loader.dart';
import 'templates/clinical_document_pdf_helpers.dart';

const double _headerLogoMaxSize = 88;
const double _pdfLineHeight = 12;

/// İmza bloğu öncesi boşluk (7 satır).
const int clinicalDocumentPdfSignatureBlankLineCount = 7;
const double clinicalDocumentPdfSignatureBlankGap =
    _pdfLineHeight * clinicalDocumentPdfSignatureBlankLineCount;

Future<pw.ImageProvider?> loadClinicalDocumentLogo(
  PdfLetterheadConfig letterhead,
) =>
    loadPdfLetterheadLogo(letterhead);

pw.Widget buildClinicalDocumentLetterhead(
  PdfLetterheadConfig letterhead,
  pw.ImageProvider? logo,
  pw.Font boldFont,
  pw.Font baseFont,
) {
  final mutedStyle = pw.TextStyle(
    font: baseFont,
    fontSize: 8,
    color: clinicalDocMutedGray,
  );
  final contactLine = _formatLetterheadContactLine(letterhead);

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                if (contactLine.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(contactLine, style: mutedStyle),
                ],
              ],
            ),
          ),
          if (logo != null) ...[
            pw.SizedBox(width: 16),
            pw.SizedBox(
              width: _headerLogoMaxSize,
              height: _headerLogoMaxSize,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          ],
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Container(height: 1.5, color: clinicalDocAccentTeal),
      pw.SizedBox(height: 5),
    ],
  );
}

pw.Widget buildClinicalDocumentCenteredTitle(String title, pw.Font boldFont) {
  return pw.Center(
    child: pw.Text(
      title,
      style: pw.TextStyle(
        font: boldFont,
        fontSize: 18,
        color: clinicalDocAccentNavy,
      ),
      textAlign: pw.TextAlign.center,
    ),
  );
}

pw.Widget buildClinicalDocumentPatientBlock({
  required String patientName,
  required String documentDateLabel,
  required pw.Font baseFont,
  required pw.Font boldFont,
  String? identityNumber,
  String? protocolNumber,
  String? documentNumber,
  String documentNumberLabel = 'Belge No',
  String? eReceteNumber,
}) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        flex: 11,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _patientField('Hasta Adı Soyadı', patientName, baseFont, boldFont),
            if (identityNumber != null && identityNumber.trim().isNotEmpty)
              _patientField(
                'TC. Kimlik No',
                identityNumber.trim(),
                baseFont,
                boldFont,
              ),
            if (eReceteNumber != null)
              _patientField(
                'e-reçete No',
                eReceteNumber.trim().isEmpty ? '—' : eReceteNumber.trim(),
                baseFont,
                boldFont,
              ),
          ],
        ),
      ),
      pw.Expanded(
        flex: 9,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _patientField(
              'Tarih',
              documentDateLabel,
              baseFont,
              boldFont,
              alignRight: true,
            ),
            if (protocolNumber != null && protocolNumber.trim().isNotEmpty)
              _patientField(
                'Protokol No',
                protocolNumber.trim(),
                baseFont,
                boldFont,
                alignRight: true,
              ),
            if (documentNumber != null && documentNumber.trim().isNotEmpty)
              _patientField(
                documentNumberLabel,
                documentNumber.trim(),
                baseFont,
                boldFont,
                alignRight: true,
              ),
          ],
        ),
      ),
    ],
  );
}

pw.Widget buildClinicalDocumentInlineDiagnosis(
  String diagnosis,
  pw.Font baseFont, {
  String label = 'Tanı',
}) {
  final value = diagnosis.trim().isEmpty ? 'Belirtilmedi' : diagnosis.trim();
  return pw.RichText(
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: '$label: ',
          style: pw.TextStyle(
            font: baseFont,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.TextSpan(
          text: value,
          style: pw.TextStyle(font: baseFont, fontSize: 10),
        ),
      ],
    ),
  );
}

pw.Widget buildClinicalDocumentSignatureBlock(pw.Font baseFont) {
  return pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Padding(
      padding: const pw.EdgeInsets.only(
        top: clinicalDocumentPdfSignatureBlankGap,
        right: 8,
      ),
      child: pw.Text(
        'Hekim İmza - Kaşe',
        style: pw.TextStyle(font: baseFont, fontSize: 10),
      ),
    ),
  );
}

pw.Widget buildClinicalDocumentFooter(
  pw.Context context,
  String footerNotice,
  pw.Font baseFont, {
  required PdfLetterheadConfig letterhead,
}) {
  final contactLine = _formatBottomContactLine(letterhead);
  final mutedStyle = pw.TextStyle(
    font: baseFont,
    fontSize: 7,
    color: clinicalDocMutedGray,
  );

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Divider(color: clinicalDocMutedGray, height: 0.5),
      pw.SizedBox(height: 4),
      pw.Center(
        child: pw.Text(
          footerNotice,
          style: mutedStyle,
          textAlign: pw.TextAlign.center,
        ),
      ),
      if (contactLine.isNotEmpty) ...[
        pw.SizedBox(height: 4),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            contactLine,
            style: pw.TextStyle(
              font: baseFont,
              fontSize: 8,
              color: clinicalDocMutedGray,
            ),
            textAlign: pw.TextAlign.right,
            maxLines: 1,
          ),
        ),
      ],
      pw.SizedBox(height: 3),
      pw.Center(
        child: pw.Text(
          'Sayfa ${context.pageNumber} / ${context.pagesCount}',
          style: mutedStyle,
          textAlign: pw.TextAlign.center,
        ),
      ),
    ],
  );
}

pw.Widget _patientField(
  String label,
  String value,
  pw.Font baseFont,
  pw.Font boldFont, {
  bool alignRight = false,
}) {
  final display = value.trim().isEmpty ? 'Belirtilmedi' : value.trim();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.RichText(
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(font: boldFont, fontSize: 10),
          ),
          pw.TextSpan(
            text: display,
            style: pw.TextStyle(font: baseFont, fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

String _formatLetterheadContactLine(PdfLetterheadConfig letterhead) {
  final parts = <String>[];
  if (letterhead.address.trim().isNotEmpty) {
    parts.add(letterhead.address.trim());
  }
  if (letterhead.phone.trim().isNotEmpty) {
    parts.add('Tel: ${letterhead.phone.trim()}');
  }
  return parts.join(' · ');
}

String _formatBottomContactLine(PdfLetterheadConfig letterhead) {
  final parts = <String>[];
  if (letterhead.email.trim().isNotEmpty) {
    parts.add(letterhead.email.trim());
  }
  if (letterhead.website.trim().isNotEmpty) {
    parts.add(letterhead.website.trim());
  }
  return parts.join(' · ');
}
