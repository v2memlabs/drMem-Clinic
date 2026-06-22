import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// İmplant / materyal — satır satır eklenebilir alanlar.
class SurgeryImplantMaterialFields extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAddRow;
  final ValueChanged<int> onRemoveRow;

  const SurgeryImplantMaterialFields({
    super.key,
    required this.controllers,
    required this.onAddRow,
    required this.onRemoveRow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < controllers.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers[i],
                  decoration: InputDecoration(
                    labelText: 'İmplant / materyal ${i + 1}',
                    isDense: true,
                  ),
                ),
              ),
              if (controllers.length > 1)
                IconButton(
                  tooltip: 'Satırı kaldır',
                  onPressed: () => onRemoveRow(i),
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAddRow,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Satır ekle',
              style: theme.textTheme.labelLarge,
            ),
          ),
        ),
      ],
    );
  }
}
