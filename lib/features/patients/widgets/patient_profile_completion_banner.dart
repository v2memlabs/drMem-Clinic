import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../data/patient_profile_completion.dart';
import '../models/patient.dart';
import '../../../shared/widgets/clinical_notice.dart';
import '../../../shared/widgets/clinical_notice_tone.dart';

/// Hasta detay — eksik profil bilgisi banner'ı.
class PatientProfileCompletionBanner extends StatelessWidget {
  final Patient patient;
  final VoidCallback? onComplete;

  const PatientProfileCompletionBanner({
    super.key,
    required this.patient,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final status = PatientProfileCompletion.evaluate(patient);
    if (status.isComplete) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClinicalNotice(
        tone: ClinicalNoticeTone.info,
        title: 'Profil bilgileri eksik',
        message:
            'Bu hasta hızlı oluşturulmuş olabilir. Klinik kayıtların daha sağlıklı tutulması için eksik bilgileri tamamlayın.',
        dense: true,
        children: [
          if (status.missingLabels.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ...status.missingLabels.map(
              (label) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        )),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (status.hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  've diğer bilgiler',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
          ],
          if (onComplete == null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Eksik bilgileri yetkili personel hasta formundan tamamlayabilir.',
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
          ],
        ],
        actions: onComplete == null
            ? const []
            : [
                ClinicalNoticeAction(
                  label: 'Profili tamamla',
                  onPressed: onComplete!,
                  key: const Key(
                    'patient_profile_completion_complete_button',
                  ),
                ),
              ],
      ),
    );
  }
}
