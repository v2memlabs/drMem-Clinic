import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import '../clinical_encounter/data/clinical_role_summary_ui_states.dart';
import '../patient_files/data/patient_file_metadata_list_data_source.dart';
import '../patient_files/data/patient_file_metadata_list_load_result.dart';
import '../patient_files/data/patient_file_metadata_list_user_messages.dart';
import '../patient_files/presentation/patient_file_metadata_list_content.dart';

class FileListScreen extends StatefulWidget {
  final String? patientId;
  const FileListScreen({super.key, this.patientId});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  String _search = '';
  late Future<PatientFileMetadataListLoadResult> _loadFuture;
  PatientFileMetadataListLoadResult? _cachedResult;
  bool _activatedOnce = false;

  bool get _hasPatientScope =>
      widget.patientId != null && widget.patientId!.trim().isNotEmpty;

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
    _reload();
  }

  void _reload() {
    setState(() {
      _cachedResult = null;
      _loadFuture = PatientFileMetadataListDataSource.load(
        patientId: widget.patientId,
        search: _search,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _hasPatientScope ? 'Hasta Dosyaları' : 'Dosyalar';

    return AppShell(
      title: title,
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: title,
              icon: Icons.folder_outlined,
              leadingBack: _hasPatientScope,
              fallbackRoute: '/files',
            ),
            FilterBar(
              searchHint: 'Dosya adı veya tür ara',
              onSearchChanged: (v) {
                _search = v;
                _reload();
              },
              collapsible: true,
              trailing: FilledButton.icon(
                onPressed: () {
                  final q = _hasPatientScope
                      ? '?patientId=${widget.patientId!.trim()}'
                      : '';
                  context.push('/files/upload$q');
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Yeni Dosya'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<PatientFileMetadataListLoadResult>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  final waiting =
                      snapshot.connectionState == ConnectionState.waiting;
                  final result = snapshot.data;

                  if (result != null &&
                      !result.hasError &&
                      !result.isNotConfigured) {
                    _cachedResult = result;
                  }

                  return ClinicalRoleSummaryUiStates.listBodyWithRefresh(
                    showRefreshBar: waiting && _cachedResult != null,
                    child: PatientFileMetadataListContent(
                      isLoading: waiting && _cachedResult == null,
                      result: result ?? _cachedResult,
                      onRetry: _reload,
                      emptyTitle: _hasPatientScope
                          ? PatientFileMetadataListUserMessages.emptyForPatient
                          : PatientFileMetadataListUserMessages.emptyForTenant,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
