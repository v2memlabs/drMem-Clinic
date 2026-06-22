import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../core/theme/app_spacing.dart';

/// Dijital imza pad — PNG döndürür.
Future<Uint8List?> showConsentSignaturePadSheet(BuildContext context) {
  return showModalBottomSheet<Uint8List>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const _ConsentSignaturePadSheet(),
  );
}

class _ConsentSignaturePadSheet extends StatefulWidget {
  const _ConsentSignaturePadSheet();

  @override
  State<_ConsentSignaturePadSheet> createState() =>
      _ConsentSignaturePadSheetState();
}

class _ConsentSignaturePadSheetState extends State<_ConsentSignaturePadSheet> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 2.5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen imza alanını doldurun.')),
      );
      return;
    }

    final bytes = await _controller.toPngBytes();
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İmza kaydedilemedi. Tekrar deneyin.')),
      );
      return;
    }
    Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hasta / Yasal Temsilci İmzası',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Parmağınız veya kalemle imza alanını doldurun. Onayladığınızda '
            'imza PDF evrakına işlenir ve onam "Alındı" olarak kaydedilir.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _controller.clear(),
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Temizle'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Vazgeç'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: _confirm,
                child: const Text('İmzayı Onayla'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
