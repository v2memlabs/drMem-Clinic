import 'package:flutter/material.dart';

import '../../../core/constants/app_branding.dart';
import '../../../core/settings/app_settings_controller.dart';

/// Belge formunda salt-okunur antet önizlemesi (gerçek PDF render yok).
class PdfLetterheadPreviewCard extends StatelessWidget {
  const PdfLetterheadPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = appSettingsController.settings;
    final clinicName = settings.clinicName.trim().isNotEmpty
        ? settings.clinicName.trim()
        : AppBranding.clinicName;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final border = Theme.of(context).dividerColor;

    final contactParts = <String>[
      if (settings.specialty.trim().isNotEmpty) settings.specialty.trim(),
      if (settings.phone.trim().isNotEmpty) settings.phone.trim(),
      if (settings.email.trim().isNotEmpty) settings.email.trim(),
      if (settings.address.trim().isNotEmpty) settings.address.trim(),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Belge Anteti (Önizleme)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gerçek PDF üretimi sonraki fazda eklenecek. Antet bilgileri ayarlardan okunur.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    AppBranding.logoAsset,
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.medical_services_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppBranding.productName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          AppBranding.productTagline,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          clinicName,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (contactParts.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            contactParts.join(' • '),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
