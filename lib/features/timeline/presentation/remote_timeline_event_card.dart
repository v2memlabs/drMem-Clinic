import 'package:flutter/material.dart';

import '../../../shared/widgets/data_list_card.dart';
import '../data/timeline_event_display.dart';
import '../models/timeline_event.dart';

/// Güvenli timeline satırı — yasak alanlar render edilmez.
class RemoteTimelineEventCard extends StatelessWidget {
  final TimelineEvent event;
  final VoidCallback? onTap;

  const RemoteTimelineEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final actor = event.actorDisplayName?.trim();
    final metaParts = <String>[
      TimelineEventDisplay.eventGroupLabel(event.eventGroup),
      if (actor != null && actor.isNotEmpty) actor,
    ];

    return DataListCard(
      title: event.title,
      subtitle: event.subtitle,
      metaLine: metaParts.join(' · '),
      chips: TimelineEventDisplay.chipsFor(event),
      trailing: TimelineEventDisplay.formatDateTime(event.occurredAt),
      onTap: onTap,
    );
  }
}
