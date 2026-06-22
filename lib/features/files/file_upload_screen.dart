import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/data/remote_list_refresh_coordinator.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/page_header.dart';
import '../patient_files/data/patient_file_upload_orchestrator.dart';
import '../patients/widgets/patient_selector_field.dart';

class FileUploadScreen extends StatefulWidget {
  final String? patientId;

  const FileUploadScreen({super.key, this.patientId});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  String? _patientId;
  String? _pickedFileName;
  Uint8List? _pickedBytes;
  String? _pickedMime;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _patientId = widget.patientId?.trim().isNotEmpty == true
        ? widget.patientId!.trim()
        : null;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya okunamadı. Lütfen tekrar deneyin.')),
      );
      return;
    }

    setState(() {
      _pickedBytes = bytes;
      _pickedFileName = file.name;
      _pickedMime = _mimeFromName(file.name);
    });
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  Future<void> _upload() async {
    final pid = _patientId?.trim();
    if (pid == null || pid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hasta seçin.')),
      );
      return;
    }

    final bytes = _pickedBytes;
    final name = _pickedFileName;
    final mime = _pickedMime;
    if (bytes == null || name == null || mime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir dosya seçin.')),
      );
      return;
    }

    if (!AuthSession.canEditFiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu işlem için yetkiniz yok.')),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      await PatientFileUploadOrchestrator.uploadPatientFile(
        patientId: pid,
        bytes: bytes,
        mimeType: mime,
        originalFileName: name,
      );
      RemoteListRefreshCoordinator.markAllStale();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya güvenli alana yüklendi.')),
      );
      context.pop();
    } on PatientFileUploadException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dosya yüklenemedi. Lütfen tekrar deneyin.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya yüklenemedi. Lütfen tekrar deneyin.')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AuthSession.canEditFiles;

    return AppShell(
      title: 'Dosya Yükle',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Dosya Yükle',
              leadingBack: true,
              fallbackRoute: '/files',
            ),
            PatientSelectorField(
              selectedPatientId: _patientId,
              enabled: canEdit && !_uploading,
              isDense: true,
              onChanged: canEdit && !_uploading
                  ? (v) => setState(() => _patientId = v)
                  : null,
              onPatientSelected: (_) {},
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: canEdit && !_uploading ? _pickFile : null,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _pickedFileName == null
                    ? 'Dosya seç (PDF öncelikli)'
                    : _pickedFileName!,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: canEdit && !_uploading ? _upload : null,
              child: _uploading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text('Dosya yükleniyor…'),
                      ],
                    )
                  : const Text('Yükle'),
            ),
          ],
        ),
      ),
    );
  }
}
