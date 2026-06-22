import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Teknik ID — yalnız maintenance ekranlarında.
class MaintenanceCopyId extends StatelessWidget {
  final String label;
  final String value;

  const MaintenanceCopyId({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: SelectableText(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          tooltip: 'Kopyala',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Panoya kopyalandı')),
            );
          },
        ),
      ],
    );
  }
}
