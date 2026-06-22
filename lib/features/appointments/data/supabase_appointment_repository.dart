import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/active_tenant_context_sync.dart';
import '../models/appointment.dart';
import 'appointment_datetime_helper.dart';
import 'appointment_remote_mapper.dart';
import 'appointment_repository_error_mapper.dart';
import 'appointment_repository_failure.dart';
import 'appointment_search_helper.dart';
import 'async_appointment_repository_contract.dart';

/// Supabase `appointments` remote CRUD — [AsyncAppointmentRepositoryContract].
///
/// UI/provider'a bağlı değil; yalnızca hazır implementasyon.
class SupabaseAppointmentRepository
    implements AsyncAppointmentRepositoryContract {
  SupabaseAppointmentRepository(this._client);

  factory SupabaseAppointmentRepository.fromSupabase() {
    return SupabaseAppointmentRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  static const String _table = 'appointments';

  static const String _selectColumns =
      'id, tenant_id, patient_id, appointment_at, status, appointment_type, '
      'notes, created_by, assigned_doctor_profile_id, '
      'assigned_physiotherapist_profile_id, created_at, updated_at, deleted_at, '
      'patients(first_name, last_name, file_number)';

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const AppointmentRepositoryException(
        AppointmentRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const AppointmentRepositoryException(
        AppointmentRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  String? _currentProfileId() {
    final id = ActiveTenantContextStore.current?.profile.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeAppointmentsQuery(
    String tenantId,
  ) {
    return _client
        .from(_table)
        .select(_selectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ActiveTenantContextSyncException {
      throw const AppointmentRepositoryException(
        AppointmentRepositoryFailure.noActiveTenant,
      );
    } catch (e) {
      throw AppointmentRepositoryErrorMapper.toException(e);
    }
  }

  Future<void> _syncTenantForWrite() async {
    try {
      await ActiveTenantContextSync.ensureSyncedBeforeWrite();
    } on ActiveTenantContextSyncException {
      throw const AppointmentRepositoryException(
        AppointmentRepositoryFailure.noActiveTenant,
      );
    }
  }

  List<Appointment> _mapRows(List<dynamic> rows) {
    return rows
        .map((e) => AppointmentRemoteMapper.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Appointment>> _fetchOrdered(
    String tenantId,
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>>,
    ) build,
  ) async {
    final query = build(_activeAppointmentsQuery(tenantId));
    final rows = await query.order('appointment_at', ascending: true);
    return _mapRows(rows);
  }

  @override
  Future<List<Appointment>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<Appointment>> getByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return const [];

    return _guard(() async {
      final tenantId = _requireTenantId();
      final pid = patientId.trim();
      return _fetchOrdered(tenantId, (q) => q.eq('patient_id', pid));
    });
  }

  @override
  Future<Appointment?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _activeAppointmentsQuery(tenantId)
          .eq('id', id.trim())
          .maybeSingle();
      if (row == null) return null;
      return AppointmentRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<Appointment>> getToday() async {
    return getForCalendarDay(AppointmentDateTimeHelper.istanbulCalendarToday());
  }

  @override
  Future<List<Appointment>> getForCalendarDay(DateTime day) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final calendarDay = DateTime(day.year, day.month, day.day);
      final startUtc =
          AppointmentDateTimeHelper.istanbulDayStartUtc(calendarDay);
      final endUtc =
          AppointmentDateTimeHelper.istanbulDayEndExclusiveUtc(calendarDay);
      return _fetchOrdered(
        tenantId,
        (q) => q
            .gte('appointment_at', startUtc.toIso8601String())
            .lt('appointment_at', endUtc.toIso8601String()),
      );
    });
  }

  @override
  Future<List<Appointment>> getThisWeek() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final range = AppointmentDateTimeHelper.localWeekRangeUtc();
      return _fetchOrdered(
        tenantId,
        (q) => q
            .gte('appointment_at', range.startUtc.toIso8601String())
            .lt('appointment_at', range.endExclusiveUtc.toIso8601String()),
      );
    });
  }

  @override
  Future<List<Appointment>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getAll();

    // Remote v1: reason DB'de yok; hasta adı embed filter karmaşık — MVP client-side.
    final all = await getAll();
    return AppointmentSearchHelper.filter(all, trimmed);
  }

  @override
  Future<int> countToday() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final range = AppointmentDateTimeHelper.istanbulTodayRangeUtc();
      final result = await _client
          .from(_table)
          .select('id')
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .gte('appointment_at', range.startUtc.toIso8601String())
          .lt('appointment_at', range.endExclusiveUtc.toIso8601String())
          .count(CountOption.exact);
      return result.count;
    });
  }

  @override
  Future<Appointment> add(Appointment appointment) async {
    return _guard(() async {
      await _syncTenantForWrite();
      final tenantId = _requireTenantId();
      final profileId = _currentProfileId();
      if (profileId == null || profileId.isEmpty) {
        throw const AppointmentRepositoryException(
          AppointmentRepositoryFailure.noActiveTenant,
        );
      }
      _assertValidDateTime(appointment.appointmentDateTime);

      final role = ActiveTenantContextStore.current?.membership.role;
      var doctorId = appointment.assignedDoctorProfileId?.trim();
      var physioId = appointment.assignedPhysiotherapistProfileId?.trim();

      if (role == AppRoles.doctor) {
        doctorId = profileId;
      } else if (role == AppRoles.physiotherapist) {
        physioId = profileId;
      } else if (doctorId == null || doctorId.isEmpty) {
        throw const AppointmentRepositoryException(
          AppointmentRepositoryFailure.forbidden,
        );
      }

      final payload = Appointment(
        id: appointment.id,
        patientId: appointment.patientId,
        patientName: appointment.patientName,
        patientFileNumber: appointment.patientFileNumber,
        appointmentDateTime: appointment.appointmentDateTime,
        durationMinutes: appointment.durationMinutes,
        type: appointment.type,
        status: appointment.status,
        reason: appointment.reason,
        controlDate: appointment.controlDate,
        notes: appointment.notes,
        assignedDoctorProfileId: doctorId,
        assignedDoctorName: appointment.assignedDoctorName,
        assignedPhysiotherapistProfileId: physioId,
        createdByProfileId: profileId,
      );

      final insertRow = AppointmentRemoteMapper.toInsertRow(
        payload,
        tenantId: tenantId,
        createdByProfileId: profileId,
      );

      final row = await _client
          .from(_table)
          .insert(insertRow)
          .select(_selectColumns)
          .single();

      return AppointmentRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<Appointment> update(Appointment appointment) async {
    return _guard(() async {
      await _syncTenantForWrite();
      final tenantId = _requireTenantId();
      _assertValidDateTime(appointment.appointmentDateTime);

      final updateRow = AppointmentRemoteMapper.toUpdateRow(appointment);

      final row = await _client
          .from(_table)
          .update(updateRow)
          .eq('id', appointment.id)
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select(_selectColumns)
          .maybeSingle();

      if (row == null) {
        throw const AppointmentRepositoryException(
          AppointmentRepositoryFailure.notFound,
        );
      }

      return AppointmentRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<Appointment> cancel(String id) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final patch = AppointmentRemoteMapper.toCancelRow();

      final row = await _client
          .from(_table)
          .update(patch)
          .eq('id', id.trim())
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select(_selectColumns)
          .maybeSingle();

      if (row == null) {
        throw const AppointmentRepositoryException(
          AppointmentRepositoryFailure.notFound,
        );
      }

      return AppointmentRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<void> archiveAppointment(String id) async {
    await _guard(() async {
      final tenantId = _requireTenantId();
      final patch = AppointmentRemoteMapper.toArchiveRow();

      final row = await _client
          .from(_table)
          .update(patch)
          .eq('id', id.trim())
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select('id')
          .maybeSingle();

      if (row == null) {
        throw const AppointmentRepositoryException(
          AppointmentRepositoryFailure.notFound,
        );
      }
    });
  }

  void _assertValidDateTime(DateTime dateTime) {
    if (dateTime.year < 1900 || dateTime.year > 2100) {
      throw const AppointmentRepositoryException(
        AppointmentRepositoryFailure.invalidDateTime,
      );
    }
  }
}
