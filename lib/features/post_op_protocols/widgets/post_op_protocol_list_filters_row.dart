import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../models/post_op_protocol.dart';

/// Post-op listesi — muayene kayıtları ile aynı filtre satırı düzeni.
class PostOpProtocolListFiltersRow extends StatelessWidget {
  final PostOpPhase? phaseFilter;
  final PostOpProtocolStatus? statusFilter;
  final ValueChanged<PostOpPhase?> onPhaseChanged;
  final ValueChanged<PostOpProtocolStatus?> onStatusChanged;

  const PostOpProtocolListFiltersRow({
    super.key,
    required this.phaseFilter,
    required this.statusFilter,
    required this.onPhaseChanged,
    required this.onStatusChanged,
  });

  static const double _narrowBreakpoint = 600;
  static const double _filterMinWidth = 160;
  static const double _filterMaxWidth = 240;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _narrowBreakpoint;
        final fieldWidth = narrow ? constraints.maxWidth : _filterMaxWidth;

        Widget field(Widget dropdown) {
          if (narrow) {
            return SizedBox(width: double.infinity, child: dropdown);
          }
          return ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: _filterMinWidth,
              maxWidth: fieldWidth,
            ),
            child: dropdown,
          );
        }

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            field(
              _dropdown<PostOpPhase?>(
                fieldKey: ValueKey('phase-${phaseFilter?.name ?? 'all'}'),
                label: 'Faz',
                value: phaseFilter,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Tüm fazlar'),
                  ),
                  ...PostOpPhase.values.map(
                    (ph) => DropdownMenuItem(
                      value: ph,
                      child: Text(
                        postOpPhaseLabel(ph),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: onPhaseChanged,
              ),
            ),
            field(
              _dropdown<PostOpProtocolStatus?>(
                fieldKey: ValueKey('status-${statusFilter?.name ?? 'all'}'),
                label: 'Durum',
                value: statusFilter,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Tüm durumlar'),
                  ),
                  ...PostOpProtocolStatus.values.map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        postOpProtocolStatusLabel(s),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: onStatusChanged,
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _dropdown<T>({
    required Key fieldKey,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      key: fieldKey,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
