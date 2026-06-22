import 'package:flutter/material.dart';

import '../../../shared/widgets/clinical_list_status_tones.dart';
import '../../../shared/widgets/data_list_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/patient_file_metadata_display.dart';
import '../data/patient_file_signed_url_service.dart';
import '../data/patient_file_view_launcher.dart';
import '../models/patient_file_metadata.dart';
import '../models/patient_file_metadata_enums.dart';

class PatientFileClinicalListRow extends StatefulWidget {
  final PatientFileMetadata file;
  final bool showPreviewHintOnTap;

  const PatientFileClinicalListRow({
    super.key,
    required this.file,
    required this.showPreviewHintOnTap,
  });

  @override
  State<PatientFileClinicalListRow> createState() =>
      _PatientFileClinicalListRowState();
}

class _PatientFileClinicalListRowState extends State<PatientFileClinicalListRow> {
  bool _opening = false;

  Future<void> _openFile() async {
    if (_opening || !widget.showPreviewHintOnTap) return;
    setState(() => _opening = true);
    try {
      await PatientFileViewLauncher.openPatientFile(widget.file.id);
    } on PatientFileSignedUrlException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dosya açılamadı. Lütfen tekrar deneyin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dosya açılırken bir sorun oluştu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final showSemantic = file.status == PatientFileStatus.archived ||
        file.status == PatientFileStatus.deleted;
    StatusChipTone? tone;
    if (showSemantic) {
      tone = file.status == PatientFileStatus.deleted
          ? StatusChipTone.danger
          : StatusChipTone.warning;
    }
    final marker = showSemantic && tone != null
        ? ClinicalListStatusTones.markerColorForTone(tone)
        : null;

    final metaLines = PatientFileMetadataDisplay.listMetaLinesFor(file);
    final neutralChip = PatientFileMetadataDisplay.listNeutralChipLabel(file);

    return DataListCard(
      title: file.displayName,
      subtitle: PatientFileMetadataDisplay.subtitleFor(file),
      metaLine: metaLines.isNotEmpty ? metaLines.first : null,
      contextLine: metaLines.length > 1 ? metaLines.sublist(1).join(' • ') : null,
      chips: neutralChip != null ? [neutralChip] : const [],
      accentRailColor: marker,
      semanticChipLabel: showSemantic
          ? PatientFileMetadataDisplay.statusLabel(file.status)
          : null,
      semanticChipTone: tone,
      trailing: _opening
          ? 'Açılıyor…'
          : PatientFileMetadataDisplay.formatDateTime(file.createdAt),
      onTap: widget.showPreviewHintOnTap ? _openFile : null,
    );
  }
}
