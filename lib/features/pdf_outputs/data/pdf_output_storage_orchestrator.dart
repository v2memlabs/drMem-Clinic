import 'dart:typed_data';

import '../../../core/auth/auth_session.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import '../../../core/session/active_tenant_context_sync.dart';
import '../../patient_files/data/patient_file_storage_id.dart';
import '../../patient_files/data/patient_file_storage_path_builder.dart';
import '../../patient_files/data/patient_file_storage_repository.dart';
import '../../patient_files/data/patient_file_storage_repository_provider.dart';
import '../models/pdf_output.dart';
import 'pdf_output_bytes_builder.dart';
import 'pdf_output_repository.dart';
import 'supabase_pdf_output_repository.dart';

/// PDF kaydet: mock'ta [PdfOutputRepository.add]; Supabase'te upload + persist.
abstract final class PdfOutputStorageOrchestrator {
  static Future<PdfOutput> saveGeneratedPdf({
    required PdfOutput draft,
    Uint8List? pdfBytes,
  }) async {
    if (!AuthSession.canEditPdfOutputs) {
      throw const PdfOutputStorageException('Bu işlem için yetkiniz yok.');
    }

    if (!_usesRemotePdfStorage()) {
      if (AppBackendConfig.isSupabase) {
        throw const PdfOutputStorageException(
          'PDF kayıt altyapısı henüz kullanıma hazır değil.',
        );
      }
      return _saveMock(draft, pdfBytes);
    }

    return _saveSupabase(draft, pdfBytes);
  }

  /// Mevcut storage kaydının PDF içeriğini günceller.
  static Future<void> replaceStoredPdfBytes({
    required PdfOutput output,
    required Uint8List pdfBytes,
  }) async {
    if (!AuthSession.canEditPdfOutputs) {
      throw const PdfOutputStorageException('Bu işlem için yetkiniz yok.');
    }
    if (pdfBytes.isEmpty) {
      throw const PdfOutputStorageException('PDF içeriği boş.');
    }

    final bucket = output.storageBucket?.trim();
    final path = output.storagePath?.trim();
    if (bucket == null ||
        bucket.isEmpty ||
        path == null ||
        path.isEmpty) {
      throw const PdfOutputStorageException('PDF depolama yolu bulunamadı.');
    }

    final storage = PatientFileStorageRepositoryProvider.repository;
    try {
      await ActiveTenantContextSync.ensureSyncedBeforeWrite();
      await storage.upload(
        bucket: bucket,
        path: path,
        bytes: pdfBytes,
        mimeType: 'application/pdf',
        upsert: true,
      );
    } on ActiveTenantContextSyncException {
      throw const PdfOutputStorageException(
        'Klinik oturumu senkronize edilemedi. Lütfen tekrar giriş yapın.',
      );
    } on PatientFileStorageException {
      throw const PdfOutputStorageException('PDF güvenli alana kaydedilemedi.');
    }
  }

  /// Supabase oturumu + tenant bağlamı ile güvenli PDF storage hazır mı?
  static bool get isRemoteStorageReady => _usesRemotePdfStorage();

  static bool _usesRemotePdfStorage() {
    return !AppBackendConfig.isMock &&
        SupabaseEnvConfig.isSupabaseConfigured &&
        SupabaseClientInitializer.isInitialized &&
        AuthSession.isLoggedIn &&
        SessionReadiness.isReady &&
        ActiveTenantContextStore.current != null;
  }

  static Future<PdfOutput> _saveMock(
    PdfOutput draft,
    Uint8List? pdfBytes,
  ) async {
    final id = draft.id.trim().isNotEmpty
        ? draft.id
        : 'pdf${DateTime.now().millisecondsSinceEpoch}';

    if (pdfBytes != null && pdfBytes.isNotEmpty) {
      final tenantId =
          ActiveTenantContextStore.current?.tenantId ?? 'mock-tenant';
      final path = PatientFileStoragePathBuilder.generatedPdfPath(
        tenantId: tenantId,
        patientId: draft.patientId,
        fileId: id,
      );
      await PatientFileStorageRepositoryProvider.repository.upload(
        bucket: PatientFileStoragePathBuilder.defaultBucket,
        path: path,
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );
    }

    final record = PdfOutput(
      id: id,
      patientId: draft.patientId,
      patientName: draft.patientName,
      createdAt: draft.createdAt,
      documentType: draft.documentType,
      title: draft.title,
      relatedDiagnosis: draft.relatedDiagnosis,
      relatedTreatmentPlan: draft.relatedTreatmentPlan,
      contentSummary: draft.contentSummary,
      warningNote: draft.warningNote,
      createdBy: draft.createdBy,
      status: draft.status,
      sourceModule: draft.sourceModule,
      sourceRecordId: draft.sourceRecordId,
      storagePath: pdfBytes != null
          ? PatientFileStoragePathBuilder.generatedPdfPath(
              tenantId: ActiveTenantContextStore.current?.tenantId ?? 'mock-tenant',
              patientId: draft.patientId,
              fileId: id,
            )
          : null,
      storageBucket: pdfBytes != null
          ? PatientFileStoragePathBuilder.defaultBucket
          : null,
    );

    PdfOutputRepository.instance.add(record);
    return record;
  }

  static Future<PdfOutput> _saveSupabase(
    PdfOutput draft,
    Uint8List? pdfBytes,
  ) async {
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PdfOutputStorageException('Aktif klinik bulunamadı.');
    }

    var bytes = pdfBytes;
    if (bytes == null || bytes.isEmpty) {
      bytes = await PdfOutputBytesBuilder.buildForSave(draft: draft);
    }

    if (bytes == null || bytes.isEmpty) {
      throw const PdfOutputStorageException(
        PdfOutputStorageException.contentCouldNotBeCreatedMessage,
      );
    }

    final pdfOutputId = generatePatientFileStorageId();
    final storagePath = PatientFileStoragePathBuilder.generatedPdfPath(
      tenantId: tenantId,
      patientId: draft.patientId,
      fileId: pdfOutputId,
    );
    const bucket = PatientFileStoragePathBuilder.defaultBucket;
    final storage = PatientFileStorageRepositoryProvider.repository;

    try {
      await ActiveTenantContextSync.ensureSyncedBeforeWrite();
      await storage.upload(
        bucket: bucket,
        path: storagePath,
        bytes: bytes,
        mimeType: 'application/pdf',
      );
    } on ActiveTenantContextSyncException {
      throw const PdfOutputStorageException(
        'Klinik oturumu senkronize edilemedi. Lütfen tekrar giriş yapın.',
      );
    } on PatientFileStorageException {
      throw const PdfOutputStorageException('PDF güvenli alana kaydedilemedi.');
    }

    try {
      await SupabasePdfOutputRepository.fromSupabase().insertWithStorage(
        pdfOutputId: pdfOutputId,
        storagePath: storagePath,
        output: draft,
        fileSizeBytes: bytes.length,
      );
    } catch (_) {
      await storage.remove(bucket: bucket, path: storagePath);
      throw const PdfOutputStorageException('PDF kaydı oluşturulamadı.');
    }

    return PdfOutput(
      id: pdfOutputId,
      patientId: draft.patientId,
      patientName: draft.patientName,
      createdAt: draft.createdAt,
      documentType: draft.documentType,
      title: draft.title,
      relatedDiagnosis: draft.relatedDiagnosis,
      relatedTreatmentPlan: draft.relatedTreatmentPlan,
      contentSummary: draft.contentSummary,
      warningNote: draft.warningNote,
      createdBy: draft.createdBy,
      status: draft.status,
      sourceModule: draft.sourceModule,
      sourceRecordId: draft.sourceRecordId,
      storagePath: storagePath,
      storageBucket: bucket,
    );
  }
}

class PdfOutputStorageException implements Exception {
  const PdfOutputStorageException(this.message);

  static const String contentCouldNotBeCreatedMessage =
      'Belge içeriği oluşturulamadı. Lütfen belge bilgilerini kontrol edin.';

  final String message;

  @override
  String toString() => message;
}
