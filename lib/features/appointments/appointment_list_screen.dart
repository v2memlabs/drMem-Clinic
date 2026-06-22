import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/repository_registry.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/clinical_status_legend.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import 'data/appointment_availability_data_source.dart';
import 'data/appointment_calendar_helper.dart';
import 'data/appointment_schedule_bootstrap.dart';
import 'data/appointment_date_query_parser.dart';
import 'data/appointment_calendar_load_result.dart';
import 'data/appointment_list_data_source.dart';
import 'data/appointment_list_filters.dart';
import 'data/appointment_list_refresh.dart';
import 'data/appointment_list_state_messages.dart';
import 'data/appointment_list_user_messages.dart';
import 'models/appointment.dart';
import 'models/appointment_slot.dart';
import 'widgets/appointment_clinical_list_row.dart';
import 'widgets/appointment_day_summary_bar.dart';
import 'widgets/appointment_list_legend.dart';
import 'widgets/appointment_week_strip.dart';

class AppointmentListScreen extends StatefulWidget {
  final String? patientId;

  const AppointmentListScreen({super.key, this.patientId});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  String _search = '';
  AppointmentStatus? _statusFilter;
  late DateTime _selectedDay;
  late DateTime _visibleWeekStart;
  Timer? _searchDebounce;
  AppointmentCalendarLoadResult? _cachedResult;
  AppointmentAvailabilityResult? _cachedSlots;
  DateTime? _cachedSlotsDay;
  bool _calendarLoading = false;
  bool _slotsLoading = false;
  bool _activatedOnce = false;
  int _lastRefreshVersion = 0;
  int _calendarLoadSeq = 0;
  int _slotsLoadSeq = 0;

  static const Duration _remoteSearchDebounce = Duration(milliseconds: 350);

  bool get _usesRemote => RepositoryRegistry.usesRemoteAppointments;

  bool get _hasPatientFilter =>
      widget.patientId != null && widget.patientId!.isNotEmpty;

  int get _appointmentActiveFilterCount => _statusFilter != null ? 1 : 0;

  @override
  void initState() {
    super.initState();
    _selectedDay = AppointmentCalendarHelper.istanbulToday();
    _visibleWeekStart = AppointmentCalendarHelper.mondayWeekStart(_selectedDay);
    unawaited(_bootstrapAndReload());
  }

  Future<void> _bootstrapAndReload() async {
    final initial = await AppointmentScheduleBootstrap.resolveInitialDay();
    if (!mounted) return;
    setState(() {
      _selectedDay = initial;
      _visibleWeekStart = AppointmentCalendarHelper.mondayWeekStart(initial);
    });
    _reload(invalidateCache: true);
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    if (AppointmentListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _reload({bool invalidateCache = false}) {
    _lastRefreshVersion = AppointmentListRefresh.version;
    setState(() {
      if (invalidateCache) {
        _cachedResult = null;
        _cachedSlots = null;
        _cachedSlotsDay = null;
      }
    });
    unawaited(_loadCalendar());
    unawaited(_loadSlots());
  }

  Future<void> _loadCalendar() async {
    final seq = ++_calendarLoadSeq;
    final selectedDay = AppointmentCalendarHelper.normalize(_selectedDay);
    final weekStart = AppointmentCalendarHelper.mondayWeekStart(_visibleWeekStart);
    final search = _search;

    if (mounted) {
      setState(() => _calendarLoading = true);
    }

    AppointmentCalendarLoadResult result;
    try {
      result = await AppointmentListDataSource.loadCalendarView(
        selectedDay: selectedDay,
        weekStart: weekStart,
        patientId: widget.patientId,
        search: search,
      );
    } catch (_) {
      result = AppointmentCalendarLoadResult.failure(
        AppointmentListUserMessages.genericLoadFailure,
      );
    }

    if (!mounted || seq != _calendarLoadSeq) return;
    if (!AppointmentCalendarHelper.isSameDay(selectedDay, _selectedDay)) return;
    if (search != _search) return;
    if (!AppointmentCalendarHelper.isSameDay(
      weekStart,
      AppointmentCalendarHelper.mondayWeekStart(_visibleWeekStart),
    )) {
      return;
    }

    setState(() {
      _cachedResult = result;
      _calendarLoading = false;
    });
  }

  Future<void> _loadSlots() async {
    if (_search.trim().isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _cachedSlots = null;
        _cachedSlotsDay = null;
        _slotsLoading = false;
      });
      return;
    }

    final seq = ++_slotsLoadSeq;
    final selectedDay = AppointmentCalendarHelper.normalize(_selectedDay);

    if (mounted) {
      setState(() {
        _slotsLoading = true;
        _cachedSlots = null;
        _cachedSlotsDay = null;
      });
    }

    AppointmentAvailabilityResult? result;
    try {
      result = await AppointmentAvailabilityDataSource.loadSlotsForDay(
        day: selectedDay,
      );
    } catch (_) {
      result = null;
    }

    if (!mounted || seq != _slotsLoadSeq) return;
    if (!AppointmentCalendarHelper.isSameDay(selectedDay, _selectedDay)) return;

    setState(() {
      _cachedSlots = result;
      _cachedSlotsDay = selectedDay;
      _slotsLoading = false;
    });
  }

  bool get _slotsReadyForSelectedDay {
    if (_cachedSlotsDay == null) return false;
    return AppointmentCalendarHelper.isSameDay(_cachedSlotsDay!, _selectedDay);
  }

  AppointmentAvailabilityResult? get _slotsForSelectedDay {
    if (!_slotsReadyForSelectedDay) return null;
    return _cachedSlots;
  }

  bool get _showSlotsLoading =>
      _search.trim().isEmpty &&
      (_slotsLoading || !_slotsReadyForSelectedDay);

  void _onSearchChanged(String value) {
    _search = value;
    _searchDebounce?.cancel();

    if (_usesRemote) {
      _searchDebounce = Timer(_remoteSearchDebounce, () {
        if (mounted) _reload();
      });
      return;
    }

    _reload();
  }

  void _clearAppointmentFilters() {
    setState(() => _statusFilter = null);
  }

  void _onDaySelected(DateTime day) {
    final normalized = AppointmentCalendarHelper.normalize(day);
    if (AppointmentCalendarHelper.isSameDay(normalized, _selectedDay)) return;
    setState(() => _selectedDay = normalized);
    _reload(invalidateCache: true);
  }

  void _shiftWeek(int deltaWeeks) {
    setState(() {
      _visibleWeekStart = AppointmentCalendarHelper.mondayWeekStart(
        _visibleWeekStart.add(Duration(days: 7 * deltaWeeks)),
      );
      _selectedDay = AppointmentCalendarHelper.sameWeekdayInWeek(
        _visibleWeekStart,
        _selectedDay.weekday,
      );
      _cachedResult = null;
      _cachedSlots = null;
      _cachedSlotsDay = null;
    });
    _reload(invalidateCache: true);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (!mounted || picked == null) return;

    setState(() {
      _selectedDay = AppointmentCalendarHelper.normalize(picked);
      _visibleWeekStart =
          AppointmentCalendarHelper.mondayWeekStart(_selectedDay);
    });
    _reload(invalidateCache: true);
  }

  Future<void> _openAppointment(String id) async {
    await context.push('/appointments/$id');
    if (mounted && AppointmentListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  String _newAppointmentRoute() {
    final params = <String, String>{
      'date': AppointmentDateQueryParser.toQuery(_selectedDay),
    };
    if (_hasPatientFilter) {
      params['patientId'] = widget.patientId!;
    }
    return Uri(path: '/appointments/new', queryParameters: params).toString();
  }

  Future<void> _openNewAppointment() async {
    await context.push(_newAppointmentRoute());
    if (mounted && AppointmentListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  String get _searchHint => _usesRemote
      ? 'Hasta adı, not veya durum ara'
      : 'Hasta adı veya randevu nedeni ara';

  String get _screenTitle =>
      widget.patientId != null ? 'Hasta Randevuları' : 'Randevular';

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: _screenTitle,
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: _screenTitle,
              icon: Icons.event_outlined,
            ),
            AppointmentWeekStrip(
              weekStart: _visibleWeekStart,
              selectedDay: _selectedDay,
              appointmentCountsByDay: _cachedResult?.weekCounts ?? const {},
              onDaySelected: _onDaySelected,
              onPreviousWeek: () => _shiftWeek(-1),
              onNextWeek: () => _shiftWeek(1),
              onPickDate: _pickDate,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppointmentDaySummaryBar(
              selectedDay: _selectedDay,
              appointmentCount: _calendarLoading && _cachedResult == null
                  ? null
                  : _cachedResult?.appointments.length,
              availability: _slotsForSelectedDay,
              loadingAvailability: _showSlotsLoading,
            ),
            const SizedBox(height: AppSpacing.xs),
            FilterBar(
              searchHint: _searchHint,
              onSearchChanged: _onSearchChanged,
              flat: true,
              tightListSpacing: true,
              collapsible: true,
              activeFilterCount: _appointmentActiveFilterCount,
              onClearFilters: _appointmentActiveFilterCount > 0
                  ? _clearAppointmentFilters
                  : null,
              trailing: FilledButton.icon(
                onPressed: _openNewAppointment,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni Randevu'),
              ),
              filters: [
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<AppointmentStatus?>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tüm durumlar'),
                      ),
                      ...AppointmentStatus.values.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(appointmentStatusLabel(s)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v),
                  ),
                ),
              ],
            ),
            Expanded(child: _buildListBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody() {
    final active = _cachedResult;
    if (active == null) {
      return ClinicalStateMessage.loading(
        message: AppointmentListUserMessages.loading,
      );
    }

    if (active.hasError) {
      return _errorState(active.errorMessage);
    }

    final sourceList = active.appointments;
    final list = AppointmentListFilters.applyStatus(
      sourceList,
      _statusFilter,
    );

    if (list.isEmpty) {
      final emptyTitle = AppointmentListStateMessages.emptyTitle(
        search: _search,
        hasStatusFilter: _statusFilter != null,
        hasPatientFilter: _hasPatientFilter,
        emptySourceList: sourceList.isEmpty,
      );
      final emptyDescription = AppointmentListStateMessages.emptyDescription(
        search: _search,
        hasStatusFilter: _statusFilter != null,
        hasPatientFilter: _hasPatientFilter,
        emptySourceList: sourceList.isEmpty,
      );

      return Column(
        children: [
          if (_calendarLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ClinicalStateMessage.empty(
              icon: Icons.event_outlined,
              title: emptyTitle,
              description: emptyDescription,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (_calendarLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ClinicalSeparatedListBody(
            legend: ClinicalStatusLegend(
              items: AppointmentListLegend.items,
            ),
            children: [
              for (final a in list)
                AppointmentClinicalListRow(
                  appointment: a,
                  usesRemote: _usesRemote,
                  onTap: () => _openAppointment(a.id),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorState(String? message) {
    return ClinicalStateMessage.error(
      icon: Icons.error_outline,
      title: 'Liste yüklenemedi',
      description: ClinicalStateMessage.safeErrorDescription(message),
      onRetry: () => _reload(invalidateCache: true),
    );
  }
}
