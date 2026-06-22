import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../patients/models/patient.dart';
import '../../pdf_outputs/services/clinical_document_pdf_layout.dart';
import '../../pdf_outputs/services/pdf_generate_result.dart';
import '../../pdf_outputs/services/pdf_letterhead_config.dart';
import '../../pdf_outputs/services/templates/clinical_document_pdf_helpers.dart';
import '../models/consent_template.dart';

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

class ConsentDocumentPdfGenerator {
  const ConsentDocumentPdfGenerator._();

  static Future<PdfGenerateResult> generate({
    required ConsentTemplate template,
    required Patient patient,
    required String recordId,
    required String preparedBy,
    required DateTime preparedAt,
    String extraNotes = '',
    Uint8List? patientSignaturePng,
  }) async {
    final baseFont = await _regularFont();
    final boldFont = await _boldFont();
    final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);
    final letterhead = PdfLetterheadConfig.fromCurrentSettings(
      generatedBy: preparedBy,
    );
    final logo = await loadClinicalDocumentLogo(letterhead);
    final footerNotice =
        'Kişisel sağlık verisi içerir. Bu onam/aydınlatma evrakı hasta dosyası '
        'kapsamında saklanır; yetkisiz kişilerle paylaşılamaz.';

    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 40, 48, 56),
        header: (context) => buildClinicalDocumentLetterhead(
          letterhead,
          logo,
          boldFont,
          baseFont,
        ),
        footer: (context) => buildClinicalDocumentFooter(
          context,
          footerNotice,
          baseFont,
          letterhead: letterhead,
        ),
        build: (context) => [
          buildClinicalDocumentCenteredTitle(template.title, boldFont),
          pw.SizedBox(height: 12),
          buildClinicalDocumentPatientBlock(
            patientName: patient.fullName,
            identityNumber: patient.identityNumber,
            protocolNumber: patient.fileNumber,
            documentNumber: recordId,
            documentNumberLabel: 'Onam Kayıt No',
            documentDateLabel: formatClinicalDocDate(preparedAt),
            baseFont: baseFont,
            boldFont: boldFont,
          ),
          pw.SizedBox(height: 14),
          _section(
            title: 'Bilgilendirme ve Onam Metni',
            children: [
              _paragraph(_bodyForTemplate(template), baseFont),
              if (template.description.trim().isNotEmpty) ...[
                pw.SizedBox(height: 8),
                _paragraph(template.description.trim(), baseFont),
              ],
            ],
            boldFont: boldFont,
          ),
          pw.SizedBox(height: 10),
          _section(
            title: 'Beyan',
            children: [
              _bullet(
                'Belgeyi okudum veya tarafıma okunarak açıklandı.',
                baseFont,
              ),
              _bullet(
                'Sorularımı sorma ve yanıt alma fırsatım oldu.',
                baseFont,
              ),
              _bullet(
                'Belirtilen kapsamda bilgilendirildiğimi ve tercihimi özgür irademle beyan ederim.',
                baseFont,
              ),
            ],
            boldFont: boldFont,
          ),
          pw.SizedBox(height: 10),
          _section(
            title: 'Belge Bilgileri',
            children: [
              clinicalDocLabelValue('Kategori', template.category, baseFont),
              clinicalDocLabelValue('Şablon sürümü', template.version, baseFont),
              clinicalDocLabelValue(
                'Gerekli durum',
                template.requiredFor,
                baseFont,
              ),
              clinicalDocLabelValue('Hazırlayan', preparedBy, baseFont),
              if (extraNotes.trim().isNotEmpty)
                clinicalDocLabelValue('Ek not', extraNotes.trim(), baseFont),
            ],
            boldFont: boldFont,
          ),
          pw.SizedBox(height: 16),
          _signatureGrid(
            baseFont,
            boldFont,
            patientSignaturePng: patientSignaturePng,
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final fileName = _fileName(
      template: template,
      patient: patient,
      generatedAt: letterhead.generatedAt,
    );
    return PdfGenerateResult(
      bytes: bytes,
      fileName: fileName,
      generatedAt: letterhead.generatedAt,
    );
  }

  static pw.Widget _section({
    required String title,
    required List<pw.Widget> children,
    required pw.Font boldFont,
  }) {
    return clinicalDocEdgeToEdgeFrame(
      padding: const pw.EdgeInsets.all(10),
      children: [
        clinicalDocSectionTitle(title, boldFont),
        pw.SizedBox(height: 8),
        ...children,
      ],
    );
  }

  static pw.Widget _paragraph(String text, pw.Font baseFont) {
    return pw.Text(
      text.trim().isEmpty ? 'Belirtilmedi' : text.trim(),
      textAlign: pw.TextAlign.justify,
      style: pw.TextStyle(font: baseFont, fontSize: 10, lineSpacing: 2),
    );
  }

  static pw.Widget _bullet(String text, pw.Font baseFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ', style: pw.TextStyle(font: baseFont, fontSize: 10)),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(font: baseFont, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureGrid(
    pw.Font baseFont,
    pw.Font boldFont, {
    Uint8List? patientSignaturePng,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _signatureBox(
            'Hasta / Yasal Temsilci',
            baseFont,
            boldFont,
            signaturePng: patientSignaturePng,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _signatureBox('Hazırlayan / Tanık', baseFont, boldFont),
        ),
      ],
    );
  }

  static pw.Widget _signatureBox(
    String title,
    pw.Font baseFont,
    pw.Font boldFont, {
    Uint8List? signaturePng,
  }) {
    return pw.Container(
      height: 96,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: clinicalDocMutedGray, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 10)),
          if (signaturePng != null && signaturePng.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Expanded(
              child: pw.Image(
                pw.MemoryImage(signaturePng),
                fit: pw.BoxFit.contain,
                alignment: pw.Alignment.centerLeft,
              ),
            ),
          ] else ...[
            pw.Spacer(),
            pw.Text('Ad Soyad:', style: pw.TextStyle(font: baseFont, fontSize: 9)),
            pw.SizedBox(height: 10),
            pw.Text('İmza:', style: pw.TextStyle(font: baseFont, fontSize: 9)),
          ],
        ],
      ),
    );
  }

  static String _bodyForTemplate(ConsentTemplate template) {
    final preview = _cleanPreview(template.contentPreview);
    if (preview.isNotEmpty) return preview;

    switch (template.category) {
      case ConsentTemplateCategories.kvkkAydinlatma:
        return '6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında; '
            'kimlik, iletişim, sağlık ve klinik işlem verilerimin sağlık '
            'hizmetlerinin yürütülmesi, randevu ve hasta kayıt süreçlerinin '
            'işletilmesi, yasal yükümlülüklerin yerine getirilmesi ve hasta '
            'güvenliğinin sağlanması amaçlarıyla işlenebileceği hakkında '
            'bilgilendirildim. Kanunda tanımlanan başvuru ve itiraz haklarım '
            'tarafıma açıklandı.';
      case ConsentTemplateCategories.acikRiza:
        return 'Tarafıma açıklanan kapsam ve amaçlarla sınırlı olmak üzere, '
            'sağlık hizmeti sürecinde gerekli kişisel ve özel nitelikli '
            'verilerimin işlenmesine ilişkin tercihimi özgür irademle beyan ederim.';
      case ConsentTemplateCategories.ameliyatOnami:
        return 'Planlanan cerrahi girişimin amacı, uygulama yöntemi, anestezi '
            'seçenekleri, beklenen yararlar, sık görülebilecek riskler, '
            'alternatif tedavi yaklaşımları ve taburculuk sonrası takip '
            'gereksinimleri hakkında bilgilendirildim. Sorularım yanıtlandıktan '
            'sonra kararımı özgür irademle verdiğimi beyan ederim.';
      case ConsentTemplateCategories.girisimEnjeksiyon:
        return 'Planlanan enjeksiyon veya minimal invaziv girişimin türü, '
            'beklenen fayda, olası yan etkiler ve alternatif tedavi seçenekleri '
            'hakkında bilgilendirildim. İşleme onay verdiğimi beyan ederim.';
      case ConsentTemplateCategories.fotoVideo:
        return 'Tedavi takibi ve belgelenmesi amacıyla fotoğraf/video kaydı '
            'alınması ve yalnızca belirtilen amaçlarla kullanılması konusunda '
            'bilgilendirildim. Kimlik bilgilerimin korunacağı tarafıma açıklandı.';
      case ConsentTemplateCategories.fizyoterapistPaylasim:
        return 'Muayene, tanı özeti, tedavi planı ve gerekli klinik bilgilerimin '
            'fizyoterapi hizmetinin yürütülmesi amacıyla ilgili fizyoterapi '
            'ekibiyle paylaşılabileceği hakkında bilgilendirildim.';
      case ConsentTemplateCategories.whatsappSms:
      case ConsentTemplateCategories.email:
        return 'Randevu, bilgilendirme ve takip süreçleri için tarafımla seçilen '
            'iletişim kanalı üzerinden iletişim kurulabileceği hakkında '
            'bilgilendirildim ve tercihimi beyan ederim.';
      default:
        return _cleanPreview(template.contentPreview);
    }
  }

  static String _cleanPreview(String value) {
    return value
        .replaceAll(RegExp(r'\([^)]*[Pp]rototip[^)]*\)'), '')
        .trim();
  }

  static String _fileName({
    required ConsentTemplate template,
    required Patient patient,
    required DateTime generatedAt,
  }) {
    final datePart =
        '${generatedAt.year}${generatedAt.month.toString().padLeft(2, '0')}${generatedAt.day.toString().padLeft(2, '0')}';
    final patientPart = _safeFilePart(patient.fullName);
    final templatePart = _safeFilePart(template.title);
    final fileNo = _safeFilePart(patient.fileNumber);
    final prefix = fileNo.isEmpty ? '' : '${fileNo}_';
    return 'onam_${prefix}${patientPart}_${templatePart}_$datePart.pdf';
  }

  static String _safeFilePart(String value) {
    return value
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
