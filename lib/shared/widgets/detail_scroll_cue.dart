import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Detay ekranında içeriğin devam ettiğini gösteren hafif ipucu.
///
/// Yeni detay ekranlarında kullanmayın; muayene/hasta/randevu detayında kaldırıldı.
/// Diğer detay ekranlarından kademeli temizlik backlog'ta.
@Deprecated('Prefer scrolling content without scroll cue; removal in progress.')
class DetailScrollCue extends StatelessWidget {
  const DetailScrollCue({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.textSecondary.withValues(alpha: 0.45),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            'Detaylar aşağıda',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.55),
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}
