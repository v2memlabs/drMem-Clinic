import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../clinical_encounter/data/clinical_encounter_diagnosis_display.dart';
import '../../../clinical_encounter/models/clinical_encounter.dart';
import '../pdf_letterhead_config.dart';

/// Turkuaz / lacivert vurgu (sade klinik belge).
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

Future<Uint8List> buildClinicalEncounterSummaryPdf({
  required ClinicalEncounter encounter,
  required PdfLetterheadConfig letterhead,
  String? patientFileNumber,
  String? warningNote,
}) async {
  final baseFont = await _regularFont();
  final boldFont = await _boldFont();
  final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);

  pw.ImageProvider? logo;
  try {
    final logoData = await rootBundle.load(letterhead.logoAssetPath);
    logo = pw.MemoryImage(logoData.buffer.asUint8List());
  } catch (_) {
    logo = null;
  }

  final doc = pw.Document(theme: theme);
  final footerNotice = warningNote?.trim().isNotEmpty == true
      ? warningNote!.trim()
      : PdfLetterheadConfig.defaultFooterNotice;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 40, 48, 56),
      header: (context) => _buildHeader(letterhead, logo, boldFont, baseFont),
      footer: (context) => _buildFooter(
        context,
        letterhead,
        footerNotice,
        baseFont,
      ),
      build: (context) => [
        pw.SizedBox(height: 6),
        pw.Text(
          'Muayene Özeti',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _accentNavy),
        ),
        pw.SizedBox(height: 16),
        _sectionTitle('Hasta Bilgileri', boldFont),
        _labelValue('Hasta', encounter.patientName, baseFont),
        _labelValue(
          'Dosya No',
          _display(patientFileNumber),
          baseFont,
        ),
        _labelValue('Belge tarihi', _formatDate(letterhead.generatedAt), baseFont),
        pw.SizedBox(height: 12),
        _sectionTitle('Muayene Bilgileri', boldFont),
        if (encounter.hasProtocolNumber)
          _labelValue(
            'Protokol No',
            encounter.displayProtocolNumber,
            baseFont,
          ),
        _labelValue('Muayene tarihi', _formatDate(encounter.createdAt), baseFont),
        _labelValue('Başvuru tipi', encounter.visitType.label, baseFont),
        _labelValue(
          'Bölge / taraf',
          '${encounter.bodyRegion.label} / ${encounter.side.label}',
          baseFont,
        ),
        _labelValue('Durum', encounter.status.label, baseFont),
        if (encounter.doctorName.trim().isNotEmpty)
          _labelValue('Hekim', encounter.doctorName.trim(), baseFont),
        pw.SizedBox(height: 12),
        _sectionTitle(ClinicalEncounterDiagnosisDisplay.sectionTitle, boldFont),
        ...ClinicalEncounterDiagnosisDisplay.pdfRows(encounter).map(
          (row) => _labelValue(row.label, row.value, baseFont),
        ),
        pw.SizedBox(height: 12),
        _sectionTitle('Tedavi Planı', boldFont),
        _labelValue('Konservatif tedavi', _display(encounter.conservativeTreatment), baseFont),
        _labelValue(
          'Fizyoterapi yönlendirmesi',
          encounter.physiotherapyReferral ? 'Evet' : 'Hayır',
          baseFont,
        ),
        _labelValue(
          'Egzersiz önerisi',
          _display(encounter.exerciseRecommendation),
          baseFont,
        ),
        _labelValue(
          'Kontrol',
          encounter.controlDate != null
              ? _formatDate(encounter.controlDate!)
              : 'Belirtilmedi',
          baseFont,
        ),
        pw.SizedBox(height: 12),
        _sectionTitle('Klinik Değerlendirme', boldFont),
        _labelValue(
          'Klinik izlenim',
          _display(encounter.clinicalImpression),
          baseFont,
        ),
      ],
    ),
  );

  return doc.save();
}

/// Antet sağ logo — A4 içinde belirgin, oran korunur (önceki ~52 px → ~1.7×).
const double _headerLogoMaxSize = 88;

pw.Widget _buildHeader(
  PdfLetterheadConfig letterhead,
  pw.ImageProvider? logo,
  pw.Font boldFont,
  pw.Font baseFont,
) {
  final mutedStyle = pw.TextStyle(font: baseFont, fontSize: 8, color: _mutedGray);

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: logo != null
            ? pw.CrossAxisAlignment.center
            : pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                if (letterhead.address.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(letterhead.address, style: mutedStyle),
                ],
                if (letterhead.phone.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(letterhead.phone, style: mutedStyle),
                ],
                if (letterhead.email.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(letterhead.email, style: mutedStyle),
                ],
                if (letterhead.website.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(letterhead.website, style: mutedStyle),
                ],
              ],
            ),
          ),
          if (logo != null) ...[
            pw.SizedBox(width: 20),
            pw.SizedBox(
              width: _headerLogoMaxSize,
              height: _headerLogoMaxSize,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          ],
        ],
      ),
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
  final generatedLine = letterhead.generatedBy != null
      ? 'Üretim: ${_formatDateTime(letterhead.generatedAt)} • ${letterhead.generatedBy}'
      : 'Üretim: ${_formatDateTime(letterhead.generatedAt)}';

  return pw.Column(
    children: [
      pw.Divider(color: _mutedGray, height: 0.5),
      pw.SizedBox(height: 4),
      pw.Text(
        footerNotice,
        style: pw.TextStyle(font: baseFont, fontSize: 7, color: _mutedGray),
      ),
      if (generatedLine.isNotEmpty) ...[
        pw.SizedBox(height: 4),
        pw.Text(
          generatedLine,
          style: pw.TextStyle(font: baseFont, fontSize: 7, color: _mutedGray),
        ),
      ],
      pw.SizedBox(height: 3),
      pw.Center(
        child: pw.Text(
          'Sayfa ${context.pageNumber} / ${context.pagesCount}',
          style: pw.TextStyle(font: baseFont, fontSize: 7, color: _mutedGray),
          textAlign: pw.TextAlign.center,
        ),
      ),
    ],
  );
}

pw.Widget _sectionTitle(String title, pw.Font boldFont) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        font: boldFont,
        fontSize: 11,
        color: _accentTeal,
      ),
    ),
  );
}

pw.Widget _labelValue(String label, String value, pw.Font baseFont) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(font: baseFont, fontSize: 9, color: _mutedGray),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: baseFont, fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

String _display(String? value) {
  final t = value?.trim() ?? '';
  return t.isEmpty ? 'Belirtilmedi' : t;
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(local)} $h:$min';
}
