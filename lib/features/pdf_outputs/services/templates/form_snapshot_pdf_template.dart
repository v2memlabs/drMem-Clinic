import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/pdf_output.dart';
import '../pdf_letterhead_config.dart';

final PdfColor _accentTeal = PdfColor.fromInt(0xFF00838F);
final PdfColor _accentNavy = PdfColor.fromInt(0xFF1565C0);
final PdfColor _mutedGray = PdfColor.fromInt(0xFF616161);

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

/// Form alanlarından minimal PDF (kaynak repo lookup yok).
Future<Uint8List> buildFormSnapshotPdf({
  required PdfOutput output,
  required PdfLetterheadConfig letterhead,
  String? patientFileNumber,
}) async {
  final baseFont = await _regularFont();
  final boldFont = await _boldFont();
  final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);

  final doc = pw.Document(theme: theme);
  final footerNotice = output.warningNote.trim().isNotEmpty
      ? output.warningNote.trim()
      : PdfLetterheadConfig.defaultFooterNotice;

  final title = output.title.trim().isEmpty ? 'Klinik Belge' : output.title.trim();
  final patientName =
      output.patientName.trim().isEmpty ? 'Hasta' : output.patientName.trim();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 40, 48, 56),
      header: (context) => _buildHeader(letterhead, boldFont, baseFont),
      footer: (context) => _buildFooter(context, letterhead, footerNotice, baseFont),
      build: (context) => [
        pw.SizedBox(height: 6),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: _accentNavy,
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Belge tipi: ${documentTypeLabel(output.documentType)}',
          style: pw.TextStyle(font: baseFont, fontSize: 10),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Hasta Bilgileri', style: pw.TextStyle(font: boldFont, fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text('Hasta: $patientName', style: pw.TextStyle(font: baseFont, fontSize: 10)),
        if (patientFileNumber != null && patientFileNumber.trim().isNotEmpty)
          pw.Text(
            'Dosya No: ${patientFileNumber.trim()}',
            style: pw.TextStyle(font: baseFont, fontSize: 10),
          ),
        pw.Text(
          'Belge tarihi: ${_formatDate(letterhead.generatedAt)}',
          style: pw.TextStyle(font: baseFont, fontSize: 10),
        ),
        if (output.relatedDiagnosis != null &&
            output.relatedDiagnosis!.trim().isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text('İlgili Tanı', style: pw.TextStyle(font: boldFont, fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text(
            output.relatedDiagnosis!.trim(),
            style: pw.TextStyle(font: baseFont, fontSize: 10),
          ),
        ],
        if (output.relatedTreatmentPlan != null &&
            output.relatedTreatmentPlan!.trim().isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text('İlgili Plan', style: pw.TextStyle(font: boldFont, fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text(
            output.relatedTreatmentPlan!.trim(),
            style: pw.TextStyle(font: baseFont, fontSize: 10),
          ),
        ],
        pw.SizedBox(height: 12),
        pw.Text('İçerik Özeti', style: pw.TextStyle(font: boldFont, fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text(
          output.contentSummary.trim().isEmpty
              ? 'Belirtilmedi'
              : output.contentSummary.trim(),
          style: pw.TextStyle(font: baseFont, fontSize: 10),
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _buildHeader(
  PdfLetterheadConfig letterhead,
  pw.Font boldFont,
  pw.Font baseFont,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Text(
        letterhead.clinicName,
        style: pw.TextStyle(font: boldFont, fontSize: 13, color: _accentNavy),
      ),
      if (letterhead.specialty.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Text(
          letterhead.specialty,
          style: pw.TextStyle(font: baseFont, fontSize: 9, color: _mutedGray),
        ),
      ],
      pw.SizedBox(height: 6),
      pw.Container(height: 1.5, color: _accentTeal),
      pw.SizedBox(height: 5),
    ],
  );
}

pw.Widget _buildFooter(
  pw.Context context,
  PdfLetterheadConfig letterhead,
  String footerNotice,
  pw.Font baseFont,
) {
  return pw.Column(
    children: [
      pw.Divider(color: _mutedGray, height: 0.5),
      pw.SizedBox(height: 4),
      pw.Text(
        footerNotice,
        style: pw.TextStyle(font: baseFont, fontSize: 7, color: _mutedGray),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Sayfa ${context.pageNumber} / ${context.pagesCount}',
        style: pw.TextStyle(font: baseFont, fontSize: 7, color: _mutedGray),
      ),
    ],
  );
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}
