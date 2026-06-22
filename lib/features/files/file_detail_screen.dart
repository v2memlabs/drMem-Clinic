import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../features/patients/widgets/patient_lookup_builder.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_stacked_sections.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../patient_files/data/patient_file_metadata_detail_data_source.dart';
import '../patient_files/data/patient_file_metadata_display.dart';
import '../patient_files/data/patient_file_view_launcher.dart';
import '../patient_files/models/patient_file_metadata.dart';

class FileDetailScreen extends StatefulWidget {
  final String id;
  const FileDetailScreen({super.key, required this.id});

  @override
  State<FileDetailScreen> createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends State<FileDetailScreen> {
  late Future<PatientFileMetadataDetailLoadResult> _loadFuture;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = PatientFileMetadataDetailDataSource.load(widget.id);
  }

  Future<void> _openFile(PatientFileMetadata file) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await PatientFileViewLauncher.openPatientFile(file.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya açılamadı. Lütfen tekrar deneyin.')),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PatientFileMetadataDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppShell(
            title: 'Dosya',
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final result = snapshot.data;
        final file = result?.file;
        if (snapshot.hasError || result == null || result.hasError || file == null) {
          return AppShell(
            title: 'Dosya',
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: 'Dosya bulunamadı',
              description: ClinicalStateMessage.safeErrorDescription(
                result?.errorMessage ?? 'Kayıt yüklenemedi.',
              ),
              onRetry: () {
                setState(() {
                  _loadFuture =
                      PatientFileMetadataDetailDataSource.load(widget.id);
                });
              },
            ),
          );
        }

        return PatientLookupBuilder(
          patientId: file.patientId,
          builder: (context, patient) {
            final fileNo = patient?.fileNumber ?? '';
            return _buildBody(context, file, fileNo);
          },
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    PatientFileMetadata file,
    String fileNo,
  ) {
    final uploadedStr = PatientFileMetadataDisplay.formatDateTime(file.createdAt);
    final uploadedBy =
        file.metadata['uploaded_by_display']?.toString().trim() ?? '';
    final description =
        file.metadata['description']?.toString().trim() ?? '';

    return AppShell(
      title: 'Dosya',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Dosya',
              icon: Icons.folder_outlined,
              leadingBack: true,
              fallbackRoute: '/files',
            ),
            DetailHeaderCard(
              title: file.displayName,
              subtitle: PatientFileMetadataDisplay.subtitleFor(file),
            ),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'Hasta ve Dosya Bilgisi',
                  rows: [
                    InfoSectionRow(
                      'Hasta dosya no',
                      fileNo.isEmpty ? kDisplayUnspecified : fileNo,
                    ),
                    InfoSectionRow(
                      'Dosya adı',
                      displayField(file.displayName),
                      emphasize: true,
                    ),
                    InfoSectionRow(
                      'Dosya türü',
                      PatientFileMetadataDisplay.fileKindLabel(file.fileKind),
                    ),
                    InfoSectionRow(
                      'Durum',
                      PatientFileMetadataDisplay.statusLabel(file.status),
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'Yükleme / Kaynak Bilgisi',
                  rows: [
                    if (uploadedBy.isNotEmpty)
                      InfoSectionRow('Yükleyen', uploadedBy),
                    InfoSectionRow('Yükleme tarihi', uploadedStr),
                    if (description.isNotEmpty)
                      InfoSectionRow('Açıklama', description),
                    if (file.mimeType?.trim().isNotEmpty == true)
                      InfoSectionRow('MIME', file.mimeType!.trim()),
                  ],
                ),
              ],
            ),
            DetailActionsPanel(
              title: 'İşlemler',
              topSpacing: 0,
              actions: [
                DetailAction(
                  label: _opening ? 'Açılıyor…' : 'Dosyayı Aç',
                  filled: true,
                  icon: Icons.open_in_new_outlined,
                  onPressed: _opening ? null : () => _openFile(file),
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
