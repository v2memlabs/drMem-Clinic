import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../pdf_outputs/services/pdf_letterhead_config.dart';
import '../data/clinical_report_document_date_resolver.dart';
import '../data/clinical_report_istirahat_body_template.dart';
import '../models/clinical_report.dart';
import 'clinical_report_pdf_layout.dart';

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

Future<Uint8List> buildClinicalReportPdf({
  required ClinicalReport report,
  required PdfLetterheadConfig letterhead,
  String? patientIdentityNumber,
  String? clinicalEncounterProtocolNumber,
  DateTime? encounterDate,
}) async {
  final baseFont = await _regularFont();
  final boldFont = await _boldFont();
  final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);
  final doc = pw.Document(theme: theme);
  final footerNotice = PdfLetterheadConfig.defaultFooterNotice;
  final title = clinicalReportTypeLabel(report.reportType);
  final logo = await loadClinicalReportLogo(letterhead);

  final protocolNumber = clinicalEncounterProtocolNumber?.trim().isNotEmpty == true
      ? clinicalEncounterProtocolNumber!.trim()
      : report.displayProtocolNumber;

  final documentDateLabel = ClinicalReportDocumentDateResolver.resolveLabel(
    report: report,
    generatedAt: letterhead.generatedAt,
    encounterDate: encounterDate,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 40, 48, 56),
      header: (context) =>
          buildClinicalReportLetterhead(letterhead, logo, boldFont, baseFont),
      footer: (context) => buildClinicalReportFooter(
        context,
        footerNotice,
        baseFont,
        letterhead: letterhead,
      ),
      build: (context) => [
        pw.SizedBox(height: 8),
        buildClinicalReportCenteredTitle(title, boldFont),
        pw.SizedBox(height: 16),
        buildClinicalReportPatientBlock(
          patientName: report.patientName,
          identityNumber: patientIdentityNumber,
          documentDateLabel: documentDateLabel,
          protocolNumber: protocolNumber,
          reportNumber: report.displayReportNumber,
          baseFont: baseFont,
          boldFont: boldFont,
        ),
        pw.SizedBox(height: 12),
        buildClinicalReportInlineDiagnosis(report.diagnosis, baseFont),
        pw.SizedBox(height: clinicalReportPdfDiagnosisBlankGap),
        ..._typeSpecificRows(report, boldFont, baseFont),
        buildClinicalReportBodySection(
          report.bodyText,
          baseFont,
          trailingLine: _istirahatReturnToWorkLine(report),
        ),
        buildClinicalReportSignatureBlock(baseFont),
      ],
    ),
  );

  return doc.save();
}

String? _istirahatReturnToWorkLine(ClinicalReport report) {
  if (report.reportType != ClinicalReportType.istirahat) return null;
  final endDate = report.endDate;
  if (endDate == null) return null;
  return ClinicalReportIstirahatBodyTemplate.returnToWorkDateLabel(endDate);
}

List<pw.Widget> _typeSpecificRows(
  ClinicalReport report,
  pw.Font boldFont,
  pw.Font baseFont,
) {
  switch (report.reportType) {
    case ClinicalReportType.istirahat:
    case ClinicalReportType.durumBildirir:
    case ClinicalReportType.ucabilir:
    case ClinicalReportType.cihazKullanim:
      return [];
    case ClinicalReportType.diger:
      return [];
  }
}
