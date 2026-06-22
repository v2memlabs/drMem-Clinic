import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../patient_files/data/patient_file_metadata_dto.dart';
import '../../patient_files/data/patient_file_metadata_mapper.dart';
import '../../patient_files/data/patient_file_metadata_parse_helpers.dart';
import '../../patient_files/models/patient_file_metadata.dart';
import '../models/pdf_output.dart';
import 'async_pdf_output_repository_contract.dart';
import 'pdf_output_remote_mapper.dart';
import 'pdf_output_repository_error_mapper.dart';
import 'pdf_output_repository_failure.dart';

/// Supabase `pdf_outputs` — doctor_admin RLS; storage path metadata.
class SupabasePdfOutputRepository implements AsyncPdfOutputRepositoryContract {
  SupabasePdfOutputRepository(this._client);

  factory SupabasePdfOutputRepository.fromSupabase() {
    return SupabasePdfOutputRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const PdfOutputRepositoryException(
        PdfOutputRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PdfOutputRepositoryException(
        PdfOutputRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PdfOutputRepositoryException {
      rethrow;
    } catch (e) {
      throw PdfOutputRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(PdfOutputRemoteMapper.table)
        .select(PdfOutputRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<PdfOutput> _mapRows(List<dynamic> rows) {
    return rows
        .map((e) => PdfOutputRemoteMapper.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PdfOutput>> _fetchOrdered(
    String tenantId,
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>>,
    ) build,
  ) async {
    final query = build(_activeQuery(tenantId));
    final rows = await query.order('created_at', ascending: false);
    return _mapRows(rows);
  }

  @override
  Future<List<PdfOutput>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<PdfOutput>> getByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return const [];

    return _guard(() async {
      final tenantId = _requireTenantId();
      final pid = patientId.trim();
      return _fetchOrdered(tenantId, (q) => q.eq('patient_id', pid));
    });
  }

  @override
  Future<PdfOutput?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _activeQuery(tenantId)
          .eq('id', id.trim())
          .maybeSingle();
      if (row == null) return null;
      return PdfOutputRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<PdfOutput>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return getAll();

    final all = await getAll();
    final lower = q.toLowerCase();
    return all.where((p) {
      if (p.patientName.toLowerCase().contains(lower)) return true;
      if (p.title.toLowerCase().contains(lower)) return true;
      if (documentTypeLabel(p.documentType).toLowerCase().contains(lower)) {
        return true;
      }
      if (pdfStatusLabel(p.status).toLowerCase().contains(lower)) return true;
      if (p.createdBy.toLowerCase().contains(lower)) return true;
      return false;
    }).toList();
  }

  Future<int> countToday() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final range = _istanbulTodayRangeUtc();
      final result = await _client
          .from(PdfOutputRemoteMapper.table)
          .select('id')
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .gte('created_at', range.startUtc.toIso8601String())
          .lt('created_at', range.endExclusiveUtc.toIso8601String())
          .count(CountOption.exact);
      return result.count;
    });
  }

  String? _createdByProfileId() {
    final id = ActiveTenantContextStore.current?.profile.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  ({DateTime startUtc, DateTime endExclusiveUtc}) _istanbulTodayRangeUtc() {
    const istanbulOffset = Duration(hours: 3);
    final istanbulNow = DateTime.now().toUtc().add(istanbulOffset);
    final istanbulStartAsUtc = DateTime.utc(
      istanbulNow.year,
      istanbulNow.month,
      istanbulNow.day,
    );
    final startUtc = istanbulStartAsUtc.subtract(istanbulOffset);
    return (
      startUtc: startUtc,
      endExclusiveUtc: startUtc.add(const Duration(days: 1)),
    );
  }

  Future<PatientFileMetadata> insertWithStorage({
    required String pdfOutputId,
    required String storagePath,
    required PdfOutput output,
    required int fileSizeBytes,
  }) async {
    final tenantId = _requireTenantId();
    final row = PdfOutputRemoteMapper.toInsertRow(
      tenantId: tenantId,
      patientId: output.patientId,
      pdfOutputId: pdfOutputId,
      storagePath: storagePath,
      output: output,
      fileSizeBytes: fileSizeBytes,
      createdByProfileId: _createdByProfileId(),
    );

    final inserted = await _client
        .from(PdfOutputRemoteMapper.table)
        .insert(row)
        .select(
          'id, tenant_id, patient_id, created_by, document_type, source_module, '
          'source_record_id, storage_bucket, storage_path, file_kind, clinical_context, '
          'encounter_id, display_name, original_file_name, mime_type, file_size_bytes, '
          'status, visibility_scope, metadata, created_at, updated_at, deleted_at',
        )
        .single();

    return PatientFileMetadataMapper.fromDto(
      PatientFileMetadataDto.fromPdfOutputsRow(
        Map<String, dynamic>.from(inserted),
      ),
    );
  }

  Future<StoredPdfOutputRecord?> getStoredRecord(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;

    final tenantId = _requireTenantId();
    final row = await _client
        .from(PdfOutputRemoteMapper.table)
        .select(
          'id, patient_id, storage_bucket, storage_path, display_name, document_type, '
          'status, metadata, created_at, source_module, source_record_id',
        )
        .eq('id', trimmed)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (row == null) return null;

    final map = Map<String, dynamic>.from(row);
    final storagePath =
        PatientFileMetadataParseHelpers.optionalString(map['storage_path']);
    if (storagePath == null || storagePath.isEmpty) return null;

    return StoredPdfOutputRecord(
      id: trimmed,
      patientId: map['patient_id']?.toString() ?? '',
      storageBucket: PatientFileMetadataParseHelpers.optionalString(
            map['storage_bucket'],
          ) ??
          'patient-files-private',
      storagePath: storagePath,
      displayName: PatientFileMetadataParseHelpers.optionalString(
            map['display_name'],
          ) ??
          'PDF',
    );
  }
}

class StoredPdfOutputRecord {
  final String id;
  final String patientId;
  final String storageBucket;
  final String storagePath;
  final String displayName;

  const StoredPdfOutputRecord({
    required this.id,
    required this.patientId,
    required this.storageBucket,
    required this.storagePath,
    required this.displayName,
  });
}
