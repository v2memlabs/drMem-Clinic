import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../patient_display_helpers.dart';

/// Yatay Türkçe harf indeksi — tıklanınca soyad filtresi.
class PatientAlphabetIndexBar extends StatelessWidget {
  final String? selectedLetter;
  final Set<String> enabledLetters;
  final ValueChanged<String?> onLetterSelected;

  const PatientAlphabetIndexBar({
    super.key,
    required this.selectedLetter,
    required this.enabledLetters,
    required this.onLetterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          _LetterChip(
            label: 'Tümü',
            selected: selectedLetter == null,
            enabled: true,
            onTap: () => onLetterSelected(null),
          ),
          const SizedBox(width: AppSpacing.xxs),
          for (final letter in PatientDisplayHelpers.turkishIndexLetters) ...[
            _LetterChip(
              label: letter,
              selected: selectedLetter == letter,
              enabled: enabledLetters.contains(letter),
              onTap: enabledLetters.contains(letter)
                  ? () => onLetterSelected(
                        selectedLetter == letter ? null : letter,
                      )
                  : null,
            ),
            const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}

class _LetterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _LetterChip({
    required this.label,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.35)
        : selected
            ? Colors.white
            : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryDeepTeal
                : AppColors.backgroundSoft,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? AppColors.primaryDeepTeal
                  : AppColors.borderSoft,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
