import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Muayene formu — kompakt yatay bölüm indeksi.
class ClinicalEncounterFormSectionIndex extends StatelessWidget {
  final List<({String id, String label, bool isFilled})> sections;
  final String? activeSectionId;
  final ValueChanged<String> onSectionSelected;

  const ClinicalEncounterFormSectionIndex({
    super.key,
    required this.sections,
    required this.activeSectionId,
    required this.onSectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SingleChildScrollView(
        key: const Key('clinical_encounter_section_index'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final section in sections) ...[
              _SectionChip(
                key: Key('clinical_encounter_section_chip_${section.id}'),
                label: section.label,
                isActive: activeSectionId == section.id,
                isFilled: section.isFilled,
                onTap: () => onSectionSelected(section.id),
                outline: outline,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isFilled;
  final VoidCallback onTap;
  final Color outline;

  const _SectionChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.isFilled,
    required this.onTap,
    required this.outline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isActive ? theme.colorScheme.primary : outline;
    final borderWidth = isActive ? 1.5 : 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border(
              bottom: BorderSide(color: borderColor, width: borderWidth),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFilled) ...[
                Icon(
                  Icons.check,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
