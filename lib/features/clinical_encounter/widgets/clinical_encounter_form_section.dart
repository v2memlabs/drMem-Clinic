import 'package:flutter/material.dart';

import '../../../shared/widgets/form_section_card.dart';

/// Muayene form bölümü — [FormSectionCard] panel ile liste/detay referansı.
class ClinicalEncounterFormSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;
  final GlobalKey? sectionKey;
  final bool showFilledIndicator;

  const ClinicalEncounterFormSection({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.children,
    this.sectionKey,
    this.showFilledIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final card = FormSectionCard(
      panel: true,
      margin: EdgeInsets.zero,
      title: title,
      subtitle: subtitle,
      icon: icon,
      titleTrailing: showFilledIndicator
          ? Icon(
              Icons.check_circle_outline,
              size: 16,
              color: theme.colorScheme.primary,
            )
          : null,
      children: children,
    );

    if (sectionKey == null) return card;
    return KeyedSubtree(key: sectionKey, child: card);
  }
}
