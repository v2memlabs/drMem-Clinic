import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import '../timeline/data/timeline_event_display.dart';
import '../timeline/data/timeline_event_navigation.dart';
import '../timeline/data/timeline_list_data_source.dart';
import '../timeline/data/timeline_list_load_result.dart';
import '../timeline/data/timeline_list_user_messages.dart';
import '../timeline/models/timeline_event.dart';
import '../timeline/models/timeline_event_enums.dart' as remote;
import '../timeline/presentation/patient_timeline_list_content.dart';

class PatientTimelineScreen extends StatefulWidget {
  final String? patientId;

  const PatientTimelineScreen({super.key, this.patientId});

  @override
  State<PatientTimelineScreen> createState() => _PatientTimelineScreenState();
}

class _PatientTimelineScreenState extends State<PatientTimelineScreen> {
  String search = '';
  remote.TimelineEventType? typeFilter;

  bool _loading = false;
  TimelineListLoadResult? _result;
  int _loadGeneration = 0;
  String? _loadedPatientId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PatientTimelineScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientId != widget.patientId) {
      search = '';
      typeFilter = null;
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final pid = widget.patientId?.trim() ?? '';

    setState(() {
      _loading = true;
      _result = null;
      _loadedPatientId = null;
    });

    final result = await TimelineListDataSource.load(patientId: pid);

    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _loading = false;
      _result = result;
      _loadedPatientId = pid.isEmpty ? null : pid;
    });
  }

  List<TimelineEvent> get filtered {
    if (_loading || _result == null) return const [];
    final pid = widget.patientId?.trim() ?? '';
    if (pid.isEmpty || _loadedPatientId != pid) return const [];

    final events = _result!.events;
    final q = search.toLowerCase();
    return events.where((e) {
      if (typeFilter != null && e.eventType != typeFilter) return false;
      if (q.isEmpty) return true;
      if (e.title.toLowerCase().contains(q)) return true;
      final sub = e.subtitle?.toLowerCase() ?? '';
      if (sub.contains(q)) return true;
      if (TimelineEventDisplay.eventTypeLabel(e.eventType)
          .toLowerCase()
          .contains(q)) {
        return true;
      }
      final actor = e.actorDisplayName?.toLowerCase() ?? '';
      if (actor.contains(q)) return true;
      return false;
    }).toList();
  }

  void _onEventTap(BuildContext context, TimelineEvent event) {
    final route = TimelineEventNavigation.routeFor(event);
    if (route != null && route.isNotEmpty) {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pid = widget.patientId?.trim() ?? '';
    final hasPatient = pid.isNotEmpty;
    final baseEvents =
        (!_loading && _loadedPatientId == pid) ? (_result?.events ?? const []) : const [];
    final emptyTitle = baseEvents.isNotEmpty && filtered.isEmpty
        ? TimelineListUserMessages.filterNoMatch
        : null;
    final emptyDescription = emptyTitle != null
        ? TimelineListUserMessages.filterNoMatchDescription
        : null;

    return AppShell(
      title: 'Hasta Zaman Çizelgesi',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Hasta Zaman Çizelgesi',
              icon: Icons.timeline_outlined,
              leadingBack: true,
              fallbackRoute: hasPatient ? '/patients/$pid' : '/patients',
            ),
            if (hasPatient && !_loading) ...[
              FilterBar(
                searchHint: 'Başlık, alt başlık veya olay tipine göre ara',
                onSearchChanged: (v) => setState(() => search = v),
                filters: [
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<remote.TimelineEventType?>(
                      value: typeFilter,
                      decoration: const InputDecoration(
                        labelText: 'Olay tipi',
                        isDense: true,
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tüm olay tipleri'),
                        ),
                        ...remote.TimelineEventType.values
                            .where((t) => t != remote.TimelineEventType.other)
                            .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              TimelineEventDisplay.eventTypeLabel(t),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => typeFilter = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: PatientTimelineListContent(
                isLoading: _loading,
                result: _result,
                events: filtered,
                emptyTitle: emptyTitle,
                emptyDescription: emptyDescription,
                onRetry: _load,
                onEventTap: (e) => _onEventTap(context, e),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
