import 'package:flutter/material.dart';
import '../models/patient_tag.dart';

class PatientTagChip extends StatelessWidget {
  final PatientTag tag;
  final VoidCallback? onRemove;

  const PatientTagChip({
    super.key,
    required this.tag,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = _chipColors(tag.color, scheme);

    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: EdgeInsets.only(
          left: 10,
          right: onRemove != null ? 2 : 10,
          top: 4,
          bottom: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                tag.name,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRemove != null)
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: colors.foreground.withValues(alpha: 0.85),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChipColors {
  final Color background;
  final Color foreground;

  const _ChipColors(this.background, this.foreground);
}

_ChipColors _chipColors(PatientTagColor color, ColorScheme scheme) {
  switch (color) {
    case PatientTagColor.blue:
      return _ChipColors(scheme.primaryContainer, scheme.onPrimaryContainer);
    case PatientTagColor.green:
      return _ChipColors(const Color(0xFFD7F0E3), const Color(0xFF1B5E3A));
    case PatientTagColor.orange:
      return _ChipColors(const Color(0xFFFFE8CC), const Color(0xFF8A4B00));
    case PatientTagColor.red:
      return _ChipColors(scheme.errorContainer, scheme.onErrorContainer);
    case PatientTagColor.purple:
      return _ChipColors(const Color(0xFFEDE4F7), const Color(0xFF4A2C6E));
    case PatientTagColor.gray:
      return _ChipColors(scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
    case PatientTagColor.teal:
      return _ChipColors(const Color(0xFFD5F0EE), const Color(0xFF0F5C55));
  }
}
