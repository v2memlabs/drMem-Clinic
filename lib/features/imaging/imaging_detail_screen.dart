import '../../../shared/widgets/clinical_stacked_sections.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/patients/widgets/patient_lookup_builder.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/detail_action_labels.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/imaging_detail_data_source.dart';
import 'data/imaging_repository.dart';
import 'models/imaging_note.dart';

class ImagingDetailScreen extends StatefulWidget {
  final String id;
  final bool isAssistant;
  const ImagingDetailScreen({super.key, required this.id, this.isAssistant = false});

  @override
  State<ImagingDetailScreen> createState() => _ImagingDetailScreenState();
}

class _ImagingDetailScreenState extends State<ImagingDetailScreen> {
  late Future<ImagingDetailLoadResult> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = ImagingDetailDataSource.load(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImagingDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppShell(
            title: 'Görüntüleme Notu',
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final result = snapshot.data;
        final note = result?.note;
        if (snapshot.hasError || result == null || result.hasError || note == null) {
          return AppShell(
            title: 'Görüntüleme Notu',
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: 'Görüntüleme notu bulunamadı',
              description: ClinicalStateMessage.safeErrorDescription(
                result?.errorMessage ?? 'Kayıt yüklenemedi.',
              ),
              onRetry: () {
                setState(() {
                  _loadFuture = ImagingDetailDataSource.load(widget.id);
                });
              },
            ),
          );
        }

        final dateStr = _formatDate(note.imagingDate);
        final headerTitle = '${ImagingRepository.typeLabel(note.imagingType)} — '
            '${ImagingRepository.regionLabel(note.bodyRegion)}';

        return PatientLookupBuilder(
          patientId: note.patientId,
          builder: (context, patient) {
            final fileNo = patient?.fileNumber ?? '';
            return _buildImagingDetailBody(
              context,
              note,
              dateStr,
              headerTitle,
              fileNo,
            );
          },
        );
      },
    );
  }

  Widget _buildImagingDetailBody(
    BuildContext context,
    ImagingNote note,
    String dateStr,
    String headerTitle,
    String fileNo,
  ) {
    return AppShell(
      title: 'Görüntüleme Notu',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Görüntüleme Notu',
              icon: Icons.image_search_outlined,
              leadingBack: true,
              fallbackRoute: '/imaging',
            ),
            DetailHeaderCard(
              title: note.patientName,
              subtitle: headerTitle,
            ),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'Hasta ve Görüntüleme Bilgisi',
                  rows: [
                    InfoSectionRow('Hasta', note.patientName, emphasize: true),
                    InfoSectionRow(
                      'Hasta dosya no',
                      fileNo.isEmpty ? kDisplayUnspecified : fileNo,
                    ),
                    InfoSectionRow('Görüntüleme tarihi', dateStr),
                    InfoSectionRow(
                      'İlgili muayene tarihi',
                      note.relatedVisitDate == null ||
                              note.relatedVisitDate!.trim().isEmpty
                          ? kDisplayUnspecified
                          : note.relatedVisitDate!.trim(),
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'Görüntüleme Detayı',
                  rows: [
                    InfoSectionRow(
                      'Görüntüleme tipi',
                      ImagingRepository.typeLabel(note.imagingType),
                    ),
                    InfoSectionRow(
                      'Bölge',
                      ImagingRepository.regionLabel(note.bodyRegion),
                    ),
                    InfoSectionRow('Taraf', imagingSideLabel(note.side)),
                    InfoSectionRow(
                      'Görüntüleme merkezi',
                      displayField(note.imagingCenter),
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'Bulgular / Rapor Özeti',
                  rows: [
                    InfoSectionRow(
                      'Rapor özeti',
                      displayField(note.reportSummary),
                      emphasize: true,
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'Klinik Değerlendirme',
                  rows: [
                    InfoSectionRow(
                      'Doktor yorumu',
                      displayField(note.doctorComment),
                    ),
                    InfoSectionRow(
                      'Önceki görüntüleme ile karşılaştırma',
                      displayField(note.comparisonWithPrevious),
                    ),
                    InfoSectionRow(
                      'İlgili tanı / muayene',
                      displayField(note.relatedDiagnosis),
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'Ek Notlar',
                  rows: [
                    InfoSectionRow(
                      'Ekli dosya',
                      note.attachedFileName == null ||
                              note.attachedFileName!.trim().isEmpty
                          ? kDisplayUnspecified
                          : note.attachedFileName!.trim(),
                    ),
                    InfoSectionRow(
                      'Kayıt oluşturma',
                      _formatDateTime(note.createdAt),
                    ),
                  ],
                ),
              ],
            ),
            if (AuthSession.canEditPdfOutputs)
              DetailActionsPanel(
                title: 'İşlemler',
                topSpacing: 0,
                actions: [
                  DetailAction(
                    label: DetailActionLabels.pdfPrepare,
                    filled: true,
                    onPressed: () => context.push(
                      '/pdf-outputs/new?patientId=${note.patientId}&source=imaging_note&id=${note.id}',
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '${_formatDate(local)} $time';
}
