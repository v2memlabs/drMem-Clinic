import 'package:flutter/material.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/clinical_snack_bar.dart';
import '../data/consent_completion_rules.dart';
import '../data/consent_signature_finalize_service.dart';
import '../models/consent_record.dart';
import 'consent_signature_pad_sheet.dart';
import 'consent_signed_document_picker.dart';

/// Pad veya ıslak imza kanıtı — onam "Alındı" akışı.
class ConsentSignatureActionsPanel extends StatefulWidget {
  final ConsentRecord consent;
  final VoidCallback? onSigned;

  const ConsentSignatureActionsPanel({
    super.key,
    required this.consent,
    this.onSigned,
  });

  @override
  State<ConsentSignatureActionsPanel> createState() =>
      _ConsentSignatureActionsPanelState();
}

class _ConsentSignatureActionsPanelState
    extends State<ConsentSignatureActionsPanel> {
  bool _busy = false;

  bool get _canSign =>
      AuthSession.canEditConsents &&
      widget.consent.documentFileName != null &&
      widget.consent.documentFileName!.trim().isNotEmpty &&
      ConsentCompletionRules.needsSignature(widget.consent);

  Future<void> _withBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signWithPad() async {
    final png = await showConsentSignaturePadSheet(context);
    if (png == null || !mounted) return;

    await _withBusy(() async {
      final result = await ConsentSignatureFinalizeService.finalizeWithPadSignature(
        consent: widget.consent,
        signaturePng: png,
      );
      if (!mounted) return;
      if (result.success) {
        showClinicalSnackBar(context, 'Onam imzalandı ve "Alındı" olarak kaydedildi.');
        widget.onSigned?.call();
      } else {
        showClinicalSnackBar(
          context,
          result.errorMessage ?? 'İmza kaydedilemedi.',
          isError: true,
        );
      }
    });
  }

  Future<void> _signWithUpload() async {
    final pick = await ConsentSignedDocumentPicker.pick(context);
    if (pick == null || !mounted) return;

    await _withBusy(() async {
      final result =
          await ConsentSignatureFinalizeService.finalizeWithWetUpload(
        consent: widget.consent,
        fileBytes: pick.bytes,
        mimeType: pick.mimeType,
        originalFileName: pick.fileName,
      );
      if (!mounted) return;
      if (result.success) {
        showClinicalSnackBar(
          context,
          'Islak imza yüklendi; onam "Alındı" olarak kaydedildi.',
        );
        widget.onSigned?.call();
      } else {
        showClinicalSnackBar(
          context,
          result.errorMessage ?? 'Islak imza kaydedilemedi.',
          isError: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_canSign) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'İmza gerekli',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Onam "Alındı" sayılması için dijital imza pad\'i veya '
                'ıslak imzalı evrak yüklemesi zorunludur.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _signWithPad,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.draw_outlined),
                    label: const Text('Pad ile imzala'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _signWithUpload,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Islak imza yükle'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
