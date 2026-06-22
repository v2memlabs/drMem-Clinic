import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Responsive filtre satırı — Post-op / muayene listesi ile aynı düzen.
class ListFiltersRow extends StatelessWidget {
  final List<Widget> fields;

  const ListFiltersRow({super.key, required this.fields});

  static const double narrowBreakpoint = 600;
  static const double filterMinWidth = 160;
  static const double filterMaxWidth = 240;

  static Widget dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < narrowBreakpoint;
        final fieldWidth = narrow ? constraints.maxWidth : filterMaxWidth;

        Widget wrapField(Widget dropdown) {
          if (narrow) {
            return SizedBox(width: double.infinity, child: dropdown);
          }
          return ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: filterMinWidth,
              maxWidth: fieldWidth,
            ),
            child: dropdown,
          );
        }

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: fields.map(wrapField).toList(),
        );
      },
    );
  }
}
