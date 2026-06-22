import '../../../shared/widgets/clinical_stacked_sections.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../core/data/repository_registry.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/patients/widgets/patient_lookup_builder.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/pdf_output_detail_data_source.dart';
import 'data/pdf_output_list_refresh.dart';
import 'data/pdf_output_source_record_lookup_data_source.dart';
import 'models/pdf_output.dart';
import 'data/pdf_output_view_launcher.dart';
import 'services/pdf_generator_service.dart';

class PdfOutputDetailScreen extends StatefulWidget {
  final String id;
  const PdfOutputDetailScreen({super.key, required this.id});

  @override
  State<PdfOutputDetailScreen> createState() => _PdfOutputDetailScreenState();
}

class _PdfOutputDetailScreenState extends State<PdfOutputDetailScreen> {
  late Future<PdfOutput?> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = PdfOutputListRefresh.version;
  String? _sourceRecordLabel;
  bool _sourceRecordResolved = false;
  String? _sourceRecordLoadKey;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    if (PdfOutputListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefreshVersion = PdfOutputListRefresh.version;
    _sourceRecordLabel = null;
    _sourceRecordResolved = false;
    _sourceRecordLoadKey = null;
    setState(() {
      _loadFuture = PdfOutputDetailDataSource.loadById(widget.id);
    });
  }

  void _loadSourceRecordLabelIfNeeded(PdfOutput p) {
    final module = p.sourceModule?.trim() ?? '';
    final id = p.sourceRecordId?.trim() ?? '';
    if (module.isEmpty || id.isEmpty) {
      _sourceRecordResolved = true;
      return;
    }

    final loadKey = '$module|$id';
    if (_sourceRecordLoadKey == loadKey) return;

    _sourceRecordLoadKey = loadKey;
    _sourceRecordResolved = false;

    PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel(
      sourceModule: module,
      sourceRecordId: id,
    ).then((label) {
      if (!mounted || _sourceRecordLoadKey != loadKey) return;
      setState(() {
        _sourceRecordResolved = true;
        _sourceRecordLabel = label ?? _sourceRecordNotFoundLabel(module);
      });
    });
  }

  String _sourceRecordNotFoundLabel(String module) {
    if (module == pdfSourceModulePhysiotherapyReferral) {
      return 'Yönlendirme kaydı bulunamadı';
    }
    return 'Kaynak kaydı bulunamadı';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PdfOutput?>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppShell(
            title: 'PDF Çıktısı',
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final p = snapshot.data;
        if (p == null) {
          return AppShell(
            title: 'PDF Çıktısı',
            child: Center(
              child: ClinicalStateMessage.empty(
                icon: Icons.error_outline,
                title: 'PDF çıktı kaydı bulunamadı',
              ),
            ),
          );
        }

        return _buildLoaded(context, p);
      },
    );
  }

  Widget _buildLoaded(BuildContext context, PdfOutput p) {
    _loadSourceRecordLabelIfNeeded(p);

    return PatientLookupBuilder(
      patientId: p.patientId,
      builder: (context, patient) {
        final fileNo = patient?.fileNumber ?? '';
        return _buildPdfOutputBody(context, p, fileNo);
      },
    );
  }

  Widget _buildPdfOutputBody(BuildContext context, PdfOutput p, String fileNo) {
    final createdStr = _formatDate(p.createdAt);
    final canPreview = PdfGeneratorService.instance.canGenerateFromPdfOutput(p);
    final hasStoredPdf =
        p.storagePath != null && p.storagePath!.trim().isNotEmpty;

    return AppShell(
      title: 'PDF Çıktısı',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'PDF Çıktısı',
              icon: Icons.picture_as_pdf_outlined,
              leadingBack: true,
              fallbackRoute: '/pdf-outputs',
            ),
                DetailHeaderCard(
                  title: p.title,
                  subtitle: documentTypeLabel(p.documentType),
                ),
                InfoSectionCard(
                  title: 'Belge Bilgisi',
                  rows: [
                    InfoSectionRow(
                      'Belge başlığı',
                      displayField(p.title),
                      emphasize: true,
                    ),
                    InfoSectionRow(
                      'Belge tipi',
                      documentTypeLabel(p.documentType),
                    ),
                    InfoSectionRow('Oluşturan', displayField(p.createdBy)),
                    InfoSectionRow('Oluşturulma tarihi', createdStr),
                    InfoSectionRow('Belge durumu', pdfStatusLabel(p.status)),
                    InfoSectionRow(
                      'İçerik özeti',
                      displayField(p.contentSummary),
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'Hasta / Kaynak Bilgisi',
                  rows: [
                    InfoSectionRow('Hasta', p.patientName, emphasize: true),
                    InfoSectionRow(
                      'Hasta dosya no',
                      fileNo.isEmpty ? kDisplayUnspecified : fileNo,
                    ),
                    if (_hasSourceLink(p)) ...[
                      InfoSectionRow(
                        'Kaynak modül',
                        pdfSourceModuleLabel(p.sourceModule),
                      ),
                      InfoSectionRow(
                        'Kaynak kayıt',
                        _sourceRecordDisplay(p),
                      ),
                    ],
                  ],
                ),
            if (_hasSourceLink(p)) ..._sourceNavigationActions(context, p),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'Durum',
                  rows: [
                    InfoSectionRow('Belge durumu', pdfStatusLabel(p.status)),
                    InfoSectionRow(
                      'Paylaşım durumu',
                      _sharingStatusLabel(p.status),
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'İlgili Klinik Kayıt',
                  rows: [
                    InfoSectionRow(
                      'İlgili tanı',
                      p.relatedDiagnosis == null || p.relatedDiagnosis!.trim().isEmpty
                          ? kDisplayUnspecified
                          : p.relatedDiagnosis!.trim(),
                    ),
                    InfoSectionRow(
                      'İlgili tedavi planı',
                      p.relatedTreatmentPlan == null ||
                              p.relatedTreatmentPlan!.trim().isEmpty
                          ? kDisplayUnspecified
                          : p.relatedTreatmentPlan!.trim(),
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'Hasta Bilgilendirme Notu',
                  rows: [
                    InfoSectionRow(
                      'Uyarı / not',
                      displayField(p.warningNote),
                    ),
                  ],
                ),
              ],
            ),
            DetailActionsPanel(
              title: 'İşlemler',
              topSpacing: 0,
              actions: [
                DetailAction(
                  label: 'PDF Aç',
                  filled: true,
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: hasStoredPdf
                      ? () => _onOpenStoredPdf(context, p)
                      : null,
                ),
                DetailAction(
                  label: 'PDF Önizle',
                  icon: Icons.visibility_outlined,
                  onPressed:
                      canPreview ? () => _onPreviewPdf(context, p) : null,
                ),
                const DetailAction(label: 'Yazdır', comingSoon: true),
                const DetailAction(label: 'Hastaya Verildi', comingSoon: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _sourceRecordDisplay(PdfOutput p) {
    final id = p.sourceRecordId?.trim() ?? '';
    if (id.isEmpty) return kDisplayUnspecified;
    if (!_sourceRecordResolved) return kDisplayUnspecified;
    return _sourceRecordLabel ?? 'Kaynak kaydı bulunamadı';
  }
}

Future<void> _onOpenStoredPdf(BuildContext context, PdfOutput output) async {
  try {
    await PdfOutputViewLauncher.openStoredPdf(output);
  } on PdfOutputViewException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.userMessage)),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF açılırken bir sorun oluştu.')),
    );
  }
}

Future<void> _onPreviewPdf(BuildContext context, PdfOutput output) async {
  final generator = PdfGeneratorService.instance;
  if (!generator.canGenerateFromPdfOutput(output)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'PDF önizleme yalnızca Muayene Özeti ve muayene kaynağı için kullanılabilir.',
        ),
      ),
    );
    return;
  }

  final recordId = output.sourceRecordId!.trim();
  try {
    final encounter =
        await RepositoryRegistry.clinicalEncountersAsync.getById(recordId);
    if (encounter == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF oluşturulamadı. Lütfen tekrar deneyin.'),
        ),
      );
      return;
    }

    final result = await generator.generateClinicalEncounterSummary(
      encounter: encounter,
      createdBy: output.createdBy,
      warningNote: output.warningNote,
    );

    if (!context.mounted) return;

    await Printing.layoutPdf(
      name: result.fileName,
      onLayout: (_) async => result.bytes,
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF oluşturulamadı. Lütfen tekrar deneyin.'),
      ),
    );
  }
}

String _sharingStatusLabel(PdfStatus status) {
  switch (status) {
    case PdfStatus.hastayaVerildi:
      return 'Hastaya verildi';
    case PdfStatus.gonderildi:
      return 'Gönderildi';
    case PdfStatus.hazirlandi:
      return 'Hazırlandı — paylaşım bekliyor';
    case PdfStatus.taslak:
      return 'Taslak — henüz paylaşılmadı';
    case PdfStatus.iptal:
      return 'İptal edildi';
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}

bool _hasSourceLink(PdfOutput p) {
  final module = p.sourceModule?.trim() ?? '';
  final record = p.sourceRecordId?.trim() ?? '';
  return module.isNotEmpty || record.isNotEmpty;
}

List<Widget> _sourceNavigationActions(BuildContext context, PdfOutput p) {
  final id = p.sourceRecordId?.trim() ?? '';
  if (id.isEmpty) return [];

  String? route;
  String? label;

  switch (p.sourceModule) {
    case pdfSourceModuleClinicalEncounter:
      route = '/clinical-records/$id';
      label = 'Kaynak muayene kaydına git';
    case pdfSourceModulePostOpProtocol:
      route = '/post-op-protocols/$id';
      label = 'Kaynak post-op protokolüne git';
    case pdfSourceModuleExercisePlan:
      route = '/exercise-plans/$id';
      label = 'Kaynak egzersiz programına git';
    case pdfSourceModuleSurgeryNote:
      route = '/surgery-notes/$id';
      label = 'Kaynak ameliyat notuna git';
    case pdfSourceModuleImagingNote:
      route = '/imaging/$id';
      label = 'Kaynak görüntüleme notuna git';
    case pdfSourceModulePhysiotherapyReferral:
      route = '/physiotherapy/referrals/$id';
      label = 'Kaynak fizyoterapi yönlendirmesine git';
  }

  if (route == null || label == null) return [];

  return [
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => context.push(route!),
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(label!),
      ),
    ),
    const SizedBox(height: AppSpacing.sm),
  ];
}
