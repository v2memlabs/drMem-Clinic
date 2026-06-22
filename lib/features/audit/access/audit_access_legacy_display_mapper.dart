import '../../../core/auth/auth_session.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../data/mock_audit_logs.dart';
import '../models/audit_log.dart';
import 'audit_access_event.dart';
import 'audit_access_event_type.dart';

/// Mock audit listesi UI — teknik/hassas detay göstermeden özet satır.
abstract final class AuditAccessLegacyDisplayMapper {
  static void appendLegacyMockLog(AuditAccessEvent event) {
    final user = AuthSession.currentUser;
    if (user == null) return;

    final tenantCtx = ActiveTenantContextStore.current;
    final description = _descriptionFor(event);

    mockAuditLogs.insert(
      0,
      AuditLog(
        id: 'access-${DateTime.now().microsecondsSinceEpoch}',
        createdAt: DateTime.now(),
        userId: user.id,
        userName: user.displayName,
        userRole: user.role,
        actionType: _actionTypeFor(event.eventType),
        module: _moduleTypeFor(event.eventScope),
        patientId: event.patientId,
        patientName: null,
        description: description,
        ipAddress: null,
        deviceInfo: 'mock',
      ),
    );
  }

  static String _descriptionFor(AuditAccessEvent event) {
    if (!event.success) {
      return 'Erişim denemesi başarısız (${event.eventType})';
    }
    switch (event.eventType) {
      case AuditAccessEventType.clinicalFullList:
        return 'Tam muayene listesi görüntülendi';
      case AuditAccessEventType.clinicalFullView:
        return 'Tam muayene kaydı görüntülendi';
      case AuditAccessEventType.clinicalInternalNoteView:
        return 'İç hekim notu alanı görüntülendi (içerik kaydedilmez)';
      case AuditAccessEventType.clinicalSummaryAssistantList:
        return 'Asistan klinik özet listesi görüntülendi';
      case AuditAccessEventType.clinicalSummaryAssistantView:
        return 'Asistan klinik özet detayı görüntülendi';
      case AuditAccessEventType.clinicalSummaryPhysiotherapistList:
        return 'FTR klinik özet listesi görüntülendi';
      case AuditAccessEventType.clinicalSummaryPhysiotherapistView:
        return 'FTR klinik özet detayı görüntülendi';
      case AuditAccessEventType.permissionDenied:
        return 'Yetkisiz erişim denemesi';
      default:
        return 'Erişim olayı: ${event.eventType}';
    }
  }

  static ActionType _actionTypeFor(String eventType) {
    if (eventType.contains('.list') || eventType.contains('.view')) {
      return ActionType.hastaDosyasiAcma;
    }
    if (eventType.contains('.create')) return ActionType.kayitOlusturma;
    if (eventType.contains('.update')) return ActionType.kayitGuncelleme;
    if (eventType == AuditAccessEventType.permissionDenied) {
      return ActionType.yetkiDegisikligi;
    }
    return ActionType.hastaDosyasiAcma;
  }

  static ModuleType _moduleTypeFor(String scope) {
    switch (scope) {
      case 'clinical_summary':
        return ModuleType.muayene;
      case 'security':
        return ModuleType.auth;
      case 'patient':
        return ModuleType.hasta;
      case 'appointment':
        return ModuleType.randevu;
      case 'pdf':
        return ModuleType.pdf;
      case 'consent':
        return ModuleType.kvkk;
      default:
        return ModuleType.muayene;
    }
  }
}
