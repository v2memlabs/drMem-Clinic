import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../data/timeline_list_load_result.dart';
import '../data/timeline_list_user_messages.dart';
import '../models/timeline_event.dart';
import 'remote_timeline_event_card.dart';
import 'timeline_list_ui_states.dart';

/// Hasta timeline gövdesi — loading / empty / error / notConfigured / liste.
class PatientTimelineListContent extends StatelessWidget {
  final bool isLoading;
  final TimelineListLoadResult? result;
  final List<TimelineEvent> events;
  final String? emptyTitle;
  final String? emptyDescription;
  final VoidCallback? onRetry;
  final void Function(TimelineEvent event)? onEventTap;

  const PatientTimelineListContent({
    super.key,
    required this.isLoading,
    required this.result,
    this.events = const [],
    this.emptyTitle,
    this.emptyDescription,
    this.onRetry,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return TimelineListUiStates.listLoading(
        message: TimelineListUserMessages.loading,
      );
    }

    final active = result;
    if (active == null) {
      return TimelineListUiStates.listLoading(
        message: TimelineListUserMessages.loading,
      );
    }

    if (active.requiresPatientContext) {
      return TimelineListUiStates.listEmpty(
        icon: Icons.person_search_outlined,
        title: TimelineListUserMessages.requiresPatientContext,
        description: TimelineListUserMessages.requiresPatientContextDescription,
      );
    }

    if (active.isNotConfigured) {
      return TimelineListUiStates.listNotConfigured(
        icon: Icons.timeline_outlined,
        title: TimelineListUserMessages.notConfigured,
        description: TimelineListUserMessages.notConfiguredDescription,
      );
    }

    if (active.isSessionRequired) {
      return TimelineListUiStates.listEmpty(
        icon: Icons.apartment_outlined,
        title: TimelineListUserMessages.sessionRequired,
        description: TimelineListUserMessages.sessionRequiredDescription,
      );
    }

    if (active.hasError) {
      final presentation = active.errorPresentation!;
      return TimelineListUiStates.listError(
        title: presentation.title,
        description: presentation.description.isNotEmpty
            ? presentation.description
            : TimelineListUserMessages.genericErrorDescription,
        onRetry: onRetry,
        showRetry: presentation.showRetry,
      );
    }

    if (events.isEmpty) {
      final isFilterEmpty = emptyTitle == TimelineListUserMessages.filterNoMatch;
      return TimelineListUiStates.listEmpty(
        icon: Icons.timeline_outlined,
        title: emptyTitle ?? TimelineListUserMessages.emptyForPatient,
        description: emptyDescription ??
            (isFilterEmpty
                ? TimelineListUserMessages.filterNoMatchDescription
                : TimelineListUserMessages.emptyForPatientDescription),
      );
    }

    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final event = events[i];
        return RemoteTimelineEventCard(
          event: event,
          onTap: onEventTap != null ? () => onEventTap!(event) : null,
        );
      },
    );
  }
}
