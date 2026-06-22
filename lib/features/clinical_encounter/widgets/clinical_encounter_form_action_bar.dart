import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Muayene formu — altta sabit kaydet / vazgeç çubuğu.
class ClinicalEncounterFormActionBar extends StatelessWidget {
  final bool isEditMode;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const ClinicalEncounterFormActionBar({
    super.key,
    required this.isEditMode,
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  String get _saveLabel =>
      isEditMode ? 'Değişiklikleri Kaydet' : 'Muayene Kaydet';

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(top: BorderSide(color: AppColors.borderSoft)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                OutlinedButton(
                  key: const Key('clinical_encounter_form_cancel'),
                  onPressed: saving ? null : onCancel,
                  child: const Text('Vazgeç'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    key: const Key('clinical_encounter_form_save'),
                    onPressed: saving ? null : onSave,
                    child: saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(_saveLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
