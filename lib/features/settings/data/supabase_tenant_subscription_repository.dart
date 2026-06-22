import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/repository_registry.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import '../models/tenant_subscription_summary.dart';
import 'tenant_membership_repository_provider.dart';
import 'tenant_subscription_mapper.dart';
import 'tenant_subscription_repository.dart';

class SupabaseTenantSubscriptionRepository
    implements TenantSubscriptionRepository {
  SupabaseTenantSubscriptionRepository(this._client);

  factory SupabaseTenantSubscriptionRepository.fromSupabase() {
    return SupabaseTenantSubscriptionRepository(Supabase.instance.client);
  }

  static const String subscriptionsTable = 'subscriptions';
  static const String usageLimitsTable = 'usage_limits';
  static const String membershipsTable = 'memberships';

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const TenantSubscriptionRepositoryException(
        TenantSubscriptionFailure.notConfigured,
        'Uzak veritabanı yapılandırılmadı.',
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty || !SessionReadiness.isReady) {
      throw const TenantSubscriptionRepositoryException(
        TenantSubscriptionFailure.noActiveTenant,
        'Aktif klinik bulunamadı.',
      );
    }
    return tenantId;
  }

  @override
  Future<TenantSubscriptionSummary> loadSummary() async {
    final tenantId = _requireTenantId();

    try {
      final subscriptionRaw = await _client
          .from(subscriptionsTable)
          .select(
            'plan_key, status, current_period_start, current_period_end',
          )
          .maybeSingle();

      final limitsRaw = await _client.from(usageLimitsTable).select();

      final membershipsRaw = await _client
          .from(membershipsTable)
          .select('status')
          .eq('tenant_id', tenantId)
          .eq('status', 'active');

      final patientCount = await RepositoryRegistry.patientsAsync.count();

      final subscriptionRow = subscriptionRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(subscriptionRaw)
          : null;

      final limitRows = (limitsRaw as List)
          .whereType<Map<String, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList();

      var seatUsed = (membershipsRaw as List).length;
      if (AuthSession.canEditClinicProfile) {
        try {
          final members =
              await TenantMembershipRepositoryProvider.repository
                  .listCurrentTenantMembers();
          seatUsed = members
              .where((m) => m.status == 'active' || m.status == 'invited')
              .length;
        } catch (_) {
          // RLS ile görünen aktif üye sayısı kullanılır.
        }
      }

      return TenantSubscriptionMapper.fromParts(
        subscriptionRow: subscriptionRow,
        usageLimitRows: limitRows,
        seatUsed: seatUsed,
        patientCount: patientCount,
        fromRemoteRecord: subscriptionRow != null,
      );
    } on TenantSubscriptionRepositoryException {
      rethrow;
    } on PostgrestException {
      throw const TenantSubscriptionRepositoryException(
        TenantSubscriptionFailure.unknown,
        'Abonelik bilgileri yüklenemedi.',
      );
    } catch (_) {
      throw const TenantSubscriptionRepositoryException(
        TenantSubscriptionFailure.unknown,
        'Abonelik bilgileri yüklenemedi.',
      );
    }
  }
}
