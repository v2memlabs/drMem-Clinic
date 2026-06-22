import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/payment_staff_notification.dart';
import 'async_payment_staff_notification_repository_contract.dart';

class SupabasePaymentStaffNotificationRepository
    implements AsyncPaymentStaffNotificationRepositoryContract {
  SupabasePaymentStaffNotificationRepository(this._client);

  factory SupabasePaymentStaffNotificationRepository.fromSupabase() {
    return SupabasePaymentStaffNotificationRepository(Supabase.instance.client);
  }

  static const String table = 'payment_staff_notifications';

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw StateError('Supabase yapılandırması hazır değil.');
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw StateError('Aktif klinik bulunamadı.');
    }
    return tenantId;
  }

  PaymentStaffNotification _mapRow(Map<String, dynamic> row) {
    final paymentId = row['payment_id'];
    return PaymentStaffNotification(
      id: row['id'].toString(),
      paymentId: paymentId == null ? '' : paymentId.toString(),
      patientId: row['patient_id'].toString(),
      patientName: row['patient_name']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      body: row['body']?.toString() ?? '',
      createdByRole: row['created_by_role']?.toString() ?? '',
      createdByDisplay: row['created_by_display']?.toString() ?? '',
      createdAt: DateTime.parse(row['created_at'].toString()),
      readAt: row['read_at'] == null
          ? null
          : DateTime.tryParse(row['read_at'].toString()),
      readByDisplay: row['read_by_display']?.toString(),
    );
  }

  @override
  Future<void> add(PaymentStaffNotification notification) async {
    final tenantId = _requireTenantId();
    final paymentId = notification.paymentId.trim();
    final payload = {
      'tenant_id': tenantId,
      if (paymentId.isNotEmpty) 'payment_id': paymentId,
      'patient_id': notification.patientId,
      'title': notification.title,
      'body': notification.body,
      'created_by_role': notification.createdByRole,
      'created_by_display': notification.createdByDisplay,
      'created_at': notification.createdAt.toUtc().toIso8601String(),
    };
    await _client.from(table).insert(payload);
  }

  @override
  Future<List<PaymentStaffNotification>> listUnread() async {
    final tenantId = _requireTenantId();
    final rows = await _client
        .from(table)
        .select(
          'id, payment_id, patient_id, title, body, created_by_role, '
          'created_by_display, read_at, read_by_display, created_at, '
          'patients(first_name, last_name)',
        )
        .eq('tenant_id', tenantId)
        .isFilter('read_at', null)
        .order('created_at', ascending: false);

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final patient = map['patients'];
      if (patient is Map) {
        final first = patient['first_name']?.toString().trim() ?? '';
        final last = patient['last_name']?.toString().trim() ?? '';
        map['patient_name'] = '$first $last'.trim();
      }
      return _mapRow(map);
    }).toList();
  }

  @override
  Future<void> markRead(
    String id, {
    required String readBy,
    required DateTime at,
  }) async {
    final tenantId = _requireTenantId();
    await _client
        .from(table)
        .update({
          'read_at': at.toUtc().toIso8601String(),
          'read_by_display': readBy,
        })
        .eq('tenant_id', tenantId)
        .eq('id', id.trim());
  }

  @override
  Future<void> markAllRead({
    required String readBy,
    required DateTime at,
  }) async {
    final tenantId = _requireTenantId();
    await _client
        .from(table)
        .update({
          'read_at': at.toUtc().toIso8601String(),
          'read_by_display': readBy,
        })
        .eq('tenant_id', tenantId)
        .isFilter('read_at', null);
  }
}
