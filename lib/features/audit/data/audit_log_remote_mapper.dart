import '../access/audit_access_event_type.dart';
import '../models/audit_log.dart';

abstract final class AuditLogRemoteMapper {
  static const table = 'audit_logs';

  static const listSelectColumns =
      'id, tenant_id, actor_profile_id, action, module, record_id, '
      'patient_id, metadata, created_at, '
      'patients(full_name), profiles(display_name)';

  static AuditLog fromRow(Map<String, dynamic> row) {
    final metadata = _metadataMap(row['metadata']);
    final patient = _nestedMap(row['patients']);
    final profile = _nestedMap(row['profiles']);
    final action = (row['action'] as String? ?? '').trim();
    final module = (row['module'] as String? ?? '').trim();

    return AuditLog(
      id: row['id'].toString(),
      createdAt: DateTime.parse(row['created_at'] as String),
      userId: row['actor_profile_id']?.toString() ?? '',
      userName: _firstNonEmpty([
        profile?['display_name'] as String?,
        metadata['actor_display_name'] as String?,
      ], fallback: 'Belirtilmedi'),
      userRole: _firstNonEmpty([
        metadata['actor_role'] as String?,
        metadata['user_role'] as String?,
      ], fallback: 'Belirtilmedi'),
      actionType: mapActionType(action),
      module: mapModuleType(module),
      patientId: row['patient_id']?.toString(),
      patientName: _trimOrNull(patient?['full_name'] as String?),
      description: descriptionFor(action: action, metadata: metadata),
      ipAddress: _trimOrNull(metadata['ip_address'] as String?),
      deviceInfo: _trimOrNull(
        metadata['device_info'] as String? ?? metadata['source'] as String?,
      ),
    );
  }

  static String descriptionFor({
    required String action,
    required Map<String, dynamic> metadata,
  }) {
    final label = metadata['description'] as String?;
    if (label != null && label.trim().isNotEmpty) return label.trim();

    final success = metadata['success'];
    if (success == false) {
      final category = metadata['failure_category'] as String?;
      if (category != null && category.trim().isNotEmpty) {
        return 'Erişim denemesi başarısız ($category)';
      }
      return 'Erişim denemesi başarısız';
    }

    switch (action) {
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
        if (action.isEmpty) return 'İşlem kaydı';
        return action.replaceAll('.', ' • ');
    }
  }

  static ActionType mapActionType(String action) {
    if (action.contains('.create')) return ActionType.kayitOlusturma;
    if (action.contains('.update')) return ActionType.kayitGuncelleme;
    if (action.contains('.delete')) return ActionType.dosyaSilme;
    if (action == AuditAccessEventType.permissionDenied) {
      return ActionType.yetkiDegisikligi;
    }
    if (action.contains('login') || action.contains('auth')) {
      return ActionType.giris;
    }
    if (action.contains('payment')) return ActionType.odemeKaydi;
    if (action.contains('pdf')) return ActionType.pdfOlusturma;
    if (action.contains('message')) return ActionType.mesajGonderme;
    if (action.contains('.list') || action.contains('.view')) {
      return ActionType.hastaDosyasiAcma;
    }
    return ActionType.hastaDosyasiAcma;
  }

  static ModuleType mapModuleType(String module) {
    switch (module) {
      case 'clinical':
      case 'clinical_summary':
        return ModuleType.muayene;
      case 'security':
      case 'auth':
        return ModuleType.auth;
      case 'patient':
        return ModuleType.hasta;
      case 'appointment':
        return ModuleType.randevu;
      case 'pdf':
        return ModuleType.pdf;
      case 'consent':
        return ModuleType.kvkk;
      case 'payment':
        return ModuleType.odeme;
      case 'message':
      case 'messaging':
        return ModuleType.mesajlasma;
      case 'file':
      case 'files':
        return ModuleType.dosya;
      case 'imaging':
        return ModuleType.goruntuleme;
      default:
        return ModuleType.muayene;
    }
  }

  static Map<String, dynamic> _metadataMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  static Map<String, dynamic>? _nestedMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static String _firstNonEmpty(
    List<String?> values, {
    required String fallback,
  }) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return fallback;
  }
}
