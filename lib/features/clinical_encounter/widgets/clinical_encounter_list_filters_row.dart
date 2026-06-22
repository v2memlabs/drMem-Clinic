import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../data/clinical_encounter_list_filter_labels.dart';
import '../models/clinical_encounter.dart';

/// Muayene listesi — responsive filtre satırı (overflow-safe).
class ClinicalEncounterListFiltersRow extends StatelessWidget {
  final ClinicalVisitType? visitFilter;
  final ClinicalEncounterStatus? statusFilter;
  final ClinicalBodyRegion? regionFilter;
  final ValueChanged<ClinicalVisitType?> onVisitChanged;
  final ValueChanged<ClinicalEncounterStatus?> onStatusChanged;
  final ValueChanged<ClinicalBodyRegion?> onRegionChanged;
  final bool showRegionFilter;

  const ClinicalEncounterListFiltersRow({
    super.key,
    required this.visitFilter,
    required this.statusFilter,
    required this.regionFilter,
    required this.onVisitChanged,
    required this.onStatusChanged,
    required this.onRegionChanged,
    this.showRegionFilter = true,
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
              _dropdown<ClinicalVisitType?>(
                label: 'Başvuru tipi',
                value: visitFilter,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tümü')),
                  ...ClinicalVisitType.values.map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: _filterText(
                        ClinicalEncounterListFilterLabels.visitType(v),
                      ),
                    ),
                  ),
                ],
                onChanged: onVisitChanged,
              ),
            ),
            field(
              _dropdown<ClinicalEncounterStatus?>(
                label: 'Durum',
                value: statusFilter,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tümü')),
                  ...ClinicalEncounterStatus.values.map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: _filterText(
                        ClinicalEncounterListFilterLabels.status(s),
                      ),
                    ),
                  ),
                ],
                onChanged: onStatusChanged,
              ),
            ),
            if (showRegionFilter)
              field(
                _dropdown<ClinicalBodyRegion?>(
                  label: 'Bölge',
                  value: regionFilter,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tümü')),
                    ...ClinicalBodyRegion.values.map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: _filterText(r.label),
                      ),
                    ),
                  ],
                  onChanged: onRegionChanged,
                ),
              ),
          ],
        );
      },
    );
  }

  static Widget _filterText(String label) {
    return Text(
      label,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  static Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return DropdownButtonFormField<T>(
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
