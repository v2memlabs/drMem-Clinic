import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../pdf_outputs/services/clinical_document_pdf_layout.dart';
import '../../pdf_outputs/services/pdf_letterhead_config.dart';
import '../../pdf_outputs/services/templates/clinical_document_pdf_helpers.dart';
import '../models/radiology_order.dart';

pw.Font? _cachedRegularFont;
pw.Font? _cachedBoldFont;

Future<pw.Font> _regularFont() async {
  _cachedRegularFont ??= pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
  );
  return _cachedRegularFont!;
}

Future<pw.Font> _boldFont() async {
  _cachedBoldFont ??= pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
  );
  return _cachedBoldFont!;
}

pw.Widget _diagnosisAndPriorityRow(
  RadiologyOrder order,
  pw.Font baseFont,
  pw.Font boldFont,
) {
  final diagnosis =
      order.diagnosis.trim().isEmpty ? 'Belirtilmedi' : order.diagnosis.trim();
  final priority = radiologyPriorityLabel(order.priority);
  final labelStyle = pw.TextStyle(
    font: boldFont,
    fontSize: 10,
  );
  final valueStyle = pw.TextStyle(font: baseFont, fontSize: 10);

  return pw.Wrap(
    spacing: 16,
    runSpacing: 4,
    children: [
      pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: 'Ön Tanı / Tanı: ', style: labelStyle),
            pw.TextSpan(text: diagnosis, style: valueStyle),
          ],
        ),
      ),
      pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: 'Öncelik: ', style: labelStyle),
            pw.TextSpan(text: priority, style: valueStyle),
          ],
        ),
      ),
    ],
  );
}

List<pw.Widget> _lineDetailRows(RadiologyOrderLine line, pw.Font baseFont) {
  final isXRay = line.modality == RadiologyModality.xRay;
  return [
    clinicalDocLabelValue('Taraf', radiologySideLabel(line.side), baseFont),
    clinicalDocLabelValue(
      isXRay ? 'İstenen grafi' : 'Bölge',
      line.bodyRegion,
      baseFont,
    ),
    clinicalDocLabelValue(
      isXRay ? 'Klinik bilgi' : 'Klinik endikasyon',
      line.clinicalIndication,
      baseFont,
    ),
    if (!isXRay &&
        (line.modality == RadiologyModality.mri ||
            line.modality == RadiologyModality.bt))
      clinicalDocLabelValue(
        'Kontrast',
        line.withContrast ? 'Evet' : 'Hayır',
        baseFont,
      ),
    if (line.notes != null && line.notes!.trim().isNotEmpty)
      clinicalDocLabelValue('Not', line.notes!, baseFont),
  ];
}

Future<Uint8List> buildRadiologyOrderPdf({
  required RadiologyOrder order,
  required PdfLetterheadConfig letterhead,
  String? patientIdentityNumber,
  String? clinicalEncounterProtocolNumber,
}) async {
  final baseFont = await _regularFont();
  final boldFont = await _boldFont();
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
  );
  final logo = await loadClinicalDocumentLogo(letterhead);

  final protocolNumber = clinicalEncounterProtocolNumber?.trim().isNotEmpty == true
      ? clinicalEncounterProtocolNumber!.trim()
      : order.displayProtocolNumber;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 40, 48, 56),
      header: (context) =>
          buildClinicalDocumentLetterhead(letterhead, logo, boldFont, baseFont),
      footer: (context) => buildClinicalDocumentFooter(
        context,
        PdfLetterheadConfig.defaultFooterNotice,
        baseFont,
        letterhead: letterhead,
      ),
      build: (context) => [
        pw.SizedBox(height: 8),
        buildClinicalDocumentCenteredTitle('Radyoloji İstem Formu', boldFont),
        pw.SizedBox(height: 16),
        buildClinicalDocumentPatientBlock(
          patientName: order.patientName,
          identityNumber: patientIdentityNumber,
          documentDateLabel: formatClinicalDocDate(order.createdAt),
          protocolNumber: protocolNumber,
          baseFont: baseFont,
          boldFont: boldFont,
        ),
        pw.SizedBox(height: 12),
        _diagnosisAndPriorityRow(order, baseFont, boldFont),
        pw.SizedBox(height: 12),
        clinicalDocSectionTitle('İstenen Görüntülemeler', boldFont),
        pw.SizedBox(height: 6),
        clinicalDocEdgeToEdgeFrame(
          children: [
            for (var i = 0; i < order.lines.length; i++) ...[
              if (i > 0) pw.SizedBox(height: 8),
              pw.Text(
                radiologyModalityLabel(order.lines[i].modality),
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
              ..._lineDetailRows(order.lines[i], baseFont),
            ],
          ],
        ),
        if (order.additionalNotes != null &&
            order.additionalNotes!.trim().isNotEmpty) ...[
          pw.SizedBox(height: 8),
          clinicalDocSectionTitle('Ek Notlar', boldFont),
          pw.Text(
            order.additionalNotes!.trim(),
            style: pw.TextStyle(font: baseFont, fontSize: 10),
          ),
        ],
        buildClinicalDocumentSignatureBlock(baseFont),
      ],
    ),
  );

  return doc.save();
}
