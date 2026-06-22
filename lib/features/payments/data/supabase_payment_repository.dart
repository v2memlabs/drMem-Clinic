import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/payment_outstanding_patient_alert.dart';
import '../models/payment_record.dart';
import '../models/payment_statistics_snapshot.dart';
import 'async_payment_repository_contract.dart';
import 'payment_list_filters.dart';
import 'payment_remote_mapper.dart';
import 'payment_repository_error_mapper.dart';
import 'payment_repository_failure.dart';

/// Supabase `payments` — doctor_admin / assistant_secretary RLS.
class SupabasePaymentRepository implements AsyncPaymentRepositoryContract {
  SupabasePaymentRepository(this._client);

  factory SupabasePaymentRepository.fromSupabase() {
    return SupabasePaymentRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const PaymentRepositoryException(
        PaymentRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PaymentRepositoryException(
        PaymentRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  String? _createdByProfileId() {
    final id = ActiveTenantContextStore.current?.profile.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PaymentRepositoryException {
      rethrow;
    } catch (e) {
      throw PaymentRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(PaymentRemoteMapper.table)
        .select(PaymentRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<PaymentRecord> _mapRows(List<dynamic> rows) {
    return rows
        .map(
          (e) => PaymentRemoteMapper.fromRow(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<List<PaymentRecord>> _fetchOrdered(
    String tenantId,
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>>,
    ) build,
  ) async {
    final query = build(_activeQuery(tenantId));
    final rows = await query.order('transaction_date', ascending: false);
    return _mapRows(rows);
  }

  @override
  Future<List<PaymentRecord>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<PaymentRecord>> getByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return const [];

    return _guard(() async {
      final tenantId = _requireTenantId();
      final pid = patientId.trim();
      return _fetchOrdered(tenantId, (q) => q.eq('patient_id', pid));
    });
  }

  @override
  Future<PaymentRecord?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _activeQuery(tenantId)
          .eq('id', id.trim())
          .maybeSingle();
      if (row == null) return null;
      return PaymentRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<PaymentRecord>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return getAll();

    final all = await getAll();
    final lower = q.toLowerCase();
    return all.where((p) => PaymentListFilters.matchesQuery(p, lower)).toList();
  }

  @override
  Future<List<PaymentRecord>> listFiltered({
    String? patientId,
    String query = '',
    ServiceType? serviceTypeFilter,
    PaymentStatus? paymentStatusFilter,
    PaymentMethod? paymentMethodFilter,
    bool operationalScope = true,
  }) async {
    return _guard(() async {
      _requireTenantId();
      final rows = await _client.rpc(
        'list_payments_filtered_v1',
        params: {
          'p_patient_id': patientId?.trim().isEmpty == true
              ? null
              : patientId?.trim(),
          'p_query': query.trim().isEmpty ? null : query.trim(),
          'p_service_type': serviceTypeFilter?.name,
          'p_payment_status': paymentStatusFilter?.name,
          'p_payment_method': paymentMethodFilter?.name,
          'p_operational_scope': operationalScope,
        },
      );
      return _mapRows(rows as List<dynamic>);
    });
  }

  @override
  Future<PaymentStatisticsSnapshot> loadStatistics({
    required PaymentStatisticsScope scope,
    required int year,
    int? month,
  }) async {
    return _guard(() async {
      _requireTenantId();
      final row = await _client.rpc(
        'get_payment_statistics_v1',
        params: {
          'p_scope': scope.name,
          'p_year': year,
          'p_month': month,
        },
      ).single();
      return _statisticsFromRow(
        Map<String, dynamic>.from(row as Map),
        scope: scope,
        year: year,
        month: month,
      );
    });
  }

  @override
  Future<List<PaymentOutstandingPatientAlert>> loadOutstandingAlerts() async {
    return _guard(() async {
      _requireTenantId();
      final rows = await _client.rpc('list_payment_outstanding_alerts_v1');
      return (rows as List<dynamic>)
          .map(
            (row) => _outstandingAlertFromRow(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    });
  }

  @override
  Future<PaymentRecord> add(PaymentRecord payment) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = PaymentRemoteMapper.toInsertRow(
        tenantId: tenantId,
        payment: payment,
        createdByProfileId: _createdByProfileId(),
      );

      final inserted = await _client
          .from(PaymentRemoteMapper.table)
          .insert(row)
          .select(PaymentRemoteMapper.listSelectColumns)
          .single();

      return PaymentRemoteMapper.fromRow(Map<String, dynamic>.from(inserted));
    });
  }

  @override
  Future<PaymentRecord> update(PaymentRecord payment) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = PaymentRemoteMapper.toUpdateRow(payment);

      final updated = await _client
          .from(PaymentRemoteMapper.table)
          .update(row)
          .eq('tenant_id', tenantId)
          .eq('id', payment.id.trim())
          .isFilter('deleted_at', null)
          .select(PaymentRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const PaymentRepositoryException(
          PaymentRepositoryFailure.notFound,
        );
      }
      return PaymentRemoteMapper.fromRow(Map<String, dynamic>.from(updated));
    });
  }

  @override
  Future<PaymentRecord?> getByClinicalEncounterId(String encounterId) async {
    final eid = encounterId.trim();
    if (eid.isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _activeQuery(tenantId)
          .eq('clinical_encounter_id', eid)
          .maybeSingle();
      if (row == null) return null;
      return PaymentRemoteMapper.fromRow(row);
    });
  }

  PaymentStatisticsSnapshot _statisticsFromRow(
    Map<String, dynamic> row, {
    required PaymentStatisticsScope scope,
    required int year,
    int? month,
  }) {
    return PaymentStatisticsSnapshot(
      scope: scope,
      year: year,
      month: scope == PaymentStatisticsScope.month ? month : null,
      periodLabel:
          row['period_label']?.toString() ?? _periodLabel(scope, year, month),
      totalAccrual: _numToDouble(row['total_accrual']),
      totalCollected: _numToDouble(row['total_collected']),
      openBalanceAllTime: _numToDouble(row['open_balance_all_time']),
      paymentCount: _numToInt(row['payment_count']),
      patientCount: _numToInt(row['patient_count']),
      outstandingPatientCount: _numToInt(row['outstanding_patient_count']),
      collectedByService: _serviceBreakdown(row['collected_by_service']),
    );
  }

  PaymentOutstandingPatientAlert _outstandingAlertFromRow(
    Map<String, dynamic> row,
  ) {
    return PaymentOutstandingPatientAlert(
      patientId: row['patient_id']?.toString() ?? '',
      patientName: row['patient_name']?.toString() ?? 'Hasta',
      totalRemaining: _numToDouble(row['total_remaining']),
      openRecordCount: _numToInt(row['open_record_count']),
      oldestUnpaidDate:
          DateTime.tryParse(row['oldest_unpaid_date']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Map<ServiceType, double> _serviceBreakdown(Object? raw) {
    if (raw is! Map) return const {};
    final result = <ServiceType, double>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      ServiceType? service;
      for (final value in ServiceType.values) {
        if (value.name == key) {
          service = value;
          break;
        }
      }
      if (service != null) {
        result[service] = _numToDouble(entry.value);
      }
    }
    return result;
  }

  double _numToDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _numToInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _periodLabel(PaymentStatisticsScope scope, int year, int? month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    if (scope == PaymentStatisticsScope.year) return '$year';
    if (month == null || month < 1 || month > 12) return '$year';
    return '${months[month - 1]} $year';
  }
}
