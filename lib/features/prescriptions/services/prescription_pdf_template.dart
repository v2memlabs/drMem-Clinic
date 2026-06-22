import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../pdf_outputs/services/clinical_document_pdf_layout.dart';
import '../../pdf_outputs/services/pdf_letterhead_config.dart';
import '../../pdf_outputs/services/templates/clinical_document_pdf_helpers.dart';
import '../models/prescription.dart';
import 'prescription_pdf_medication_layout.dart';

pw.Font? _cachedRegularFont;
pw.Font? _cachedBoldFont;

Future<pw.Font> _regularFont() async {
  if (_cachedRegularFont != null) return _cachedRegularFont!;
  final data = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  _cachedRegularFont = pw.Font.ttf(data);
  return _cachedRegularFont!;
}

Future<pw.Font> _boldFont() async {
  if (_cachedBoldFont != null) return _cachedBoldFont!;
  final data = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
  _cachedBoldFont = pw.Font.ttf(data);
  return _cachedBoldFont!;
}

Future<Uint8List> buildPrescriptionPdf({
  required Prescription prescription,
  required PdfLetterheadConfig letterhead,
  String? patientIdentityNumber,
  String? clinicalEncounterProtocolNumber,
  String? eReceteNumber,
}) async {
  final baseFont = await _regularFont();
  final boldFont = await _boldFont();
  final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);
  final doc = pw.Document(theme: theme);
  final footerNotice = PdfLetterheadConfig.defaultFooterNotice;
  final logo = await loadClinicalDocumentLogo(letterhead);

  final protocolNumber = clinicalEncounterProtocolNumber?.trim().isNotEmpty == true
      ? clinicalEncounterProtocolNumber!.trim()
      : null;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 40, 48, 56),
      header: (context) =>
          buildClinicalDocumentLetterhead(letterhead, logo, boldFont, baseFont),
      footer: (context) => buildClinicalDocumentFooter(
        context,
        footerNotice,
        baseFont,
        letterhead: letterhead,
      ),
      build: (context) => [
        pw.SizedBox(height: 8),
        buildClinicalDocumentCenteredTitle('Reçete', boldFont),
        pw.SizedBox(height: 16),
        buildClinicalDocumentPatientBlock(
          patientName: prescription.patientName,
          identityNumber: patientIdentityNumber,
          documentDateLabel: formatClinicalDocDate(prescription.createdAt),
          protocolNumber: protocolNumber,
          eReceteNumber: eReceteNumber ?? '',
          baseFont: baseFont,
          boldFont: boldFont,
        ),
        pw.SizedBox(height: 12),
        buildClinicalDocumentInlineDiagnosis(prescription.diagnosis, baseFont),
        pw.SizedBox(height: 12),
        ...buildPrescriptionMedicationSection(
          prescription.medications,
          baseFont,
          boldFont,
        ),
        if (prescription.additionalNotes != null &&
            prescription.additionalNotes!.trim().isNotEmpty) ...[
          pw.SizedBox(height: 12),
          clinicalDocSectionTitle('Ek Notlar', boldFont),
          pw.SizedBox(height: 4),
          pw.Text(
            prescription.additionalNotes!.trim(),
            style: pw.TextStyle(font: baseFont, fontSize: 10),
          ),
        ],
        buildClinicalDocumentSignatureBlock(baseFont),
      ],
    ),
  );

  return doc.save();
}
