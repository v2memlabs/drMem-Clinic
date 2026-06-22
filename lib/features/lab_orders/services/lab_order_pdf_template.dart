import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../pdf_outputs/services/clinical_document_pdf_layout.dart';
import '../../pdf_outputs/services/pdf_letterhead_config.dart';
import '../../pdf_outputs/services/templates/clinical_document_pdf_helpers.dart';
import '../data/lab_order_catalog_gate.dart';
import '../data/lab_test_selection.dart';
import '../models/lab_order.dart';
import '../models/lab_test_catalog.dart';

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

Future<Uint8List> buildLabOrderPdf({
  required LabOrder order,
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
  final catalog = LabOrderCatalogGate.current;

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
        buildClinicalDocumentCenteredTitle('Laboratuvar İstem Formu', boldFont),
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
        buildClinicalDocumentInlineDiagnosis(
          order.diagnosis,
          baseFont,
          label: 'Ön Tanı / Tanı',
        ),
        pw.SizedBox(height: 8),
        clinicalDocLabelValue(
          'İstem sebebi',
          labOrderReasonLabel(order.orderReason),
          baseFont,
        ),
        if (order.infectionContext != InfectionContext.yok) ...[
          clinicalDocLabelValue(
            'Enfeksiyon klinik',
            infectionContextLabel(order.infectionContext),
            baseFont,
          ),
          if (order.infectionNotes != null &&
              order.infectionNotes!.trim().isNotEmpty)
            clinicalDocLabelValue(
              'Enfeksiyon notu',
              order.infectionNotes!,
              baseFont,
            ),
        ],
        pw.SizedBox(height: 12),
        ...LabTestGroup.values.expand((group) {
          final tests = LabTestSelection.codesForPdfGroup(
            group,
            order.selectedTests,
          );
          final customLabels = group == LabTestGroup.diger
              ? order.selectedCustomTestIds
                  .map(catalog.labelForCustomTest)
                  .whereType<String>()
                  .where((l) => l.isNotEmpty)
                  .toList()
              : <String>[];

          if (tests.isEmpty && customLabels.isEmpty) {
            return <pw.Widget>[];
          }

          return [
            clinicalDocSectionTitle(labTestGroupLabel(group), boldFont),
            pw.SizedBox(height: 4),
            ...tests.map(
              (t) => pw.Bullet(
                text: labTestCodeLabel(t),
                style: pw.TextStyle(font: baseFont, fontSize: 10),
              ),
            ),
            ...customLabels.map(
              (label) => pw.Bullet(
                text: label,
                style: pw.TextStyle(font: baseFont, fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 8),
          ];
        }),
        if (order.preoperativeNotes != null &&
            order.preoperativeNotes!.trim().isNotEmpty)
          clinicalDocLabelValue(
            'Preoperatif not',
            order.preoperativeNotes!,
            baseFont,
          ),
        if (order.ekgNotes != null && order.ekgNotes!.trim().isNotEmpty)
          clinicalDocLabelValue('EKG notu', order.ekgNotes!, baseFont),
        if (order.additionalNotes != null &&
            order.additionalNotes!.trim().isNotEmpty)
          clinicalDocLabelValue('Ek not', order.additionalNotes!, baseFont),
        buildClinicalDocumentSignatureBlock(baseFont),
      ],
    ),
  );

  return doc.save();
}
