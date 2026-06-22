import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/patient_tag.dart';
import 'patient_tag_mapper.dart';
import 'patient_tag_repository_contract.dart';

class SupabasePatientTagRepository implements PatientTagRepositoryContract {
  SupabasePatientTagRepository(this._client);

  factory SupabasePatientTagRepository.fromSupabase() {
    return SupabasePatientTagRepository(Supabase.instance.client);
  }

  static const String tagsTable = 'patient_tags';
  static const String assignmentsTable = 'patient_tag_assignments';

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const PatientTagRepositoryException(
        PatientTagRepositoryFailure.notConfigured,
        'Uzak veritabanı yapılandırılmadı.',
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PatientTagRepositoryException(
        PatientTagRepositoryFailure.notConfigured,
        'Aktif klinik bulunamadı.',
      );
    }
    return tenantId;
  }

  PatientTagRepositoryException _mapError(Object error, String fallback) {
    if (error is PatientTagRepositoryException) return error;
    if (error is PostgrestException) {
      final code = error.code ?? '';
      if (code == '42501' || code == 'PGRST301') {
        return const PatientTagRepositoryException(
          PatientTagRepositoryFailure.forbidden,
          'Bu işlem için yetkiniz yok.',
        );
      }
      if (code == '23505') {
        return const PatientTagRepositoryException(
          PatientTagRepositoryFailure.duplicateName,
          'Bu isimde aktif bir etiket zaten var.',
        );
      }
    }
    return PatientTagRepositoryException(
      PatientTagRepositoryFailure.unknown,
      fallback,
    );
  }

  @override
  Future<List<PatientTag>> listAll() async {
    _requireTenantId();
    try {
      final rows = await _client
          .from(tagsTable)
          .select()
          .order('name', ascending: true);
      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(PatientTagMapper.fromRow)
          .toList();
    } catch (e) {
      throw _mapError(e, 'Etiketler yüklenemedi.');
    }
  }

  @override
  Future<List<PatientTag>> listActive() async {
    final all = await listAll();
    return all.where((t) => t.isActive).toList();
  }

  @override
  Future<PatientTag?> getById(String id) async {
    _requireTenantId();
    try {
      final row = await _client.from(tagsTable).select().eq('id', id).maybeSingle();
      if (row == null) return null;
      return PatientTagMapper.fromRow(Map<String, dynamic>.from(row));
    } catch (e) {
      throw _mapError(e, 'Etiket yüklenemedi.');
    }
  }

  @override
  Future<List<PatientTag>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    _requireTenantId();
    try {
      final rows = await _client.from(tagsTable).select().inFilter('id', ids);
      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(PatientTagMapper.fromRow)
          .toList();
    } catch (e) {
      throw _mapError(e, 'Etiketler yüklenemedi.');
    }
  }

  @override
  Future<bool> existsByName(String name) async {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final all = await listActive();
    return all.any((t) => t.name.trim().toLowerCase() == normalized);
  }

  @override
  Future<int> countPatientsWithTag(String tagId) async {
    _requireTenantId();
    try {
      final rows = await _client
          .from(assignmentsTable)
          .select('patient_id')
          .eq('tag_id', tagId);
      return (rows as List).length;
    } catch (e) {
      throw _mapError(e, 'Etiket kullanımı yüklenemedi.');
    }
  }

  @override
  Future<PatientTag> create({
    required String name,
    required PatientTagColor color,
    String? description,
  }) async {
    final tenantId = _requireTenantId();
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 32) {
      throw const PatientTagRepositoryException(
        PatientTagRepositoryFailure.validation,
        'Etiket adı 1–32 karakter olmalıdır.',
      );
    }
    if (await existsByName(trimmed)) {
      throw const PatientTagRepositoryException(
        PatientTagRepositoryFailure.duplicateName,
        'Bu isimde aktif bir etiket zaten var.',
      );
    }

    try {
      final row = await _client
          .from(tagsTable)
          .insert(
            PatientTagMapper.toInsertRow(
              tenantId: tenantId,
              name: trimmed,
              color: color,
              description: description ?? '',
            ),
          )
          .select()
          .single();
      return PatientTagMapper.fromRow(Map<String, dynamic>.from(row));
    } catch (e) {
      throw _mapError(e, 'Etiket oluşturulamadı.');
    }
  }

  @override
  Future<void> assignToPatient({
    required String patientId,
    required String tagId,
  }) async {
    final tenantId = _requireTenantId();
    final existing = await getTagIdsForPatient(patientId);
    if (existing.contains(tagId)) return;

    try {
      await _client.from(assignmentsTable).insert({
        'tenant_id': tenantId,
        'patient_id': patientId,
        'tag_id': tagId,
      });
    } catch (e) {
      throw _mapError(e, 'Etiket atanamadı.');
    }
  }

  @override
  Future<void> removeFromPatient({
    required String patientId,
    required String tagId,
  }) async {
    _requireTenantId();
    try {
      await _client
          .from(assignmentsTable)
          .delete()
          .eq('patient_id', patientId)
          .eq('tag_id', tagId);
    } catch (e) {
      throw _mapError(e, 'Etiket kaldırılamadı.');
    }
  }

  @override
  Future<List<String>> getTagIdsForPatient(String patientId) async {
    final map = await getTagIdsByPatientIds([patientId]);
    return map[patientId] ?? const [];
  }

  @override
  Future<Map<String, List<String>>> getTagIdsByPatientIds(
    List<String> patientIds,
  ) async {
    if (patientIds.isEmpty) return {};
    _requireTenantId();
    try {
      final rows = await _client
          .from(assignmentsTable)
          .select('patient_id, tag_id')
          .inFilter('patient_id', patientIds);
      final result = <String, List<String>>{};
      for (final raw in rows as List) {
        if (raw is! Map<String, dynamic>) continue;
        final patientId = raw['patient_id']?.toString();
        final tagId = raw['tag_id']?.toString();
        if (patientId == null || tagId == null) continue;
        result.putIfAbsent(patientId, () => []).add(tagId);
      }
      return result;
    } catch (e) {
      throw _mapError(e, 'Hasta etiketleri yüklenemedi.');
    }
  }
}
