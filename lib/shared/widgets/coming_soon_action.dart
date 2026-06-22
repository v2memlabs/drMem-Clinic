import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Pasif / sonraki faz aksiyonları için kısa tooltip.
const String kComingSoonTooltip = 'Sonraki sürümde aktif olacak';

/// Küçük “Yakında” etiketi — detay, form ve dashboard.
class ComingSoonBadge extends StatelessWidget {
  final String label;

  const ComingSoonBadge({super.key, this.label = 'Yakında'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}

/// Devre dışı, “Yakında” etiketli outline buton.
class ComingSoonOutlinedButton extends StatelessWidget {
  final String label;

  const ComingSoonOutlinedButton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: kComingSoonTooltip,
      child: OutlinedButton(
        onPressed: null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 6),
            const ComingSoonBadge(),
          ],
        ),
      ),
    );
  }
}
