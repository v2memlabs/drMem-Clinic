import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/data/backend_config.dart';
import '../../patient_files/data/patient_file_storage_path_builder.dart';
import '../../patient_files/data/patient_file_storage_repository.dart';
import '../../patient_files/data/patient_file_storage_repository_provider.dart';
import '../models/pdf_output.dart';
import 'pdf_output_bytes_builder.dart';

enum PdfOutputViewFailureReason {
  notStored,
  signedUrlFailed,
  launchFailed,
}

/// PDF açma hatası — UI için güvenli kullanıcı mesajı.
class PdfOutputViewException implements Exception {
  const PdfOutputViewException(this.reason, {this.debugMessage});

  final PdfOutputViewFailureReason reason;
  final String? debugMessage;

  String get userMessage => switch (reason) {
        PdfOutputViewFailureReason.notStored => 'PDF henüz depolanmamış.',
        PdfOutputViewFailureReason.signedUrlFailed =>
          'PDF bağlantısı oluşturulamadı. Lütfen tekrar deneyin.',
        PdfOutputViewFailureReason.launchFailed =>
          'PDF bağlantısı oluşturuldu ancak cihazda açılamadı.',
      };
}

abstract final class PdfOutputViewLauncher {
  static Future<void> openStoredPdf(PdfOutput output) async {
    final location = _resolveStorageLocation(output);
    if (location == null) {
      throw const PdfOutputViewException(PdfOutputViewFailureReason.notStored);
    }

    if (!AppBackendConfig.isMock &&
        PatientFileStorageRepositoryProvider.usesRemoteStorage &&
        !AuthSession.canViewPdfOutputs) {
      throw const PdfOutputViewException(
        PdfOutputViewFailureReason.signedUrlFailed,
        debugMessage: 'view_pdf_outputs denied',
      );
    }

    final useLocalBytes =
        AppBackendConfig.isMock ||
        !PatientFileStorageRepositoryProvider.usesRemoteStorage ||
        kIsWeb;

    if (useLocalBytes) {
      await _openFromStorageBytes(
        bucket: location.bucket,
        path: location.path,
        output: output,
      );
      return;
    }

    try {
      await _openViaSignedUrl(
        bucket: location.bucket,
        path: location.path,
      );
    } on PdfOutputViewException catch (e) {
      if (e.reason == PdfOutputViewFailureReason.launchFailed) {
        await _openFromStorageBytes(
          bucket: location.bucket,
          path: location.path,
          output: output,
        );
        return;
      }
      rethrow;
    } on PatientFileStorageException catch (e) {
      if (kDebugMode) {
        debugPrint('PdfOutputViewLauncher signed URL: ${e.message}');
      }
      await _openFromStorageBytes(
        bucket: location.bucket,
        path: location.path,
        output: output,
      );
    }
  }

  static ({String bucket, String path})? _resolveStorageLocation(
    PdfOutput output,
  ) {
    final path = output.storagePath?.trim();
    if (path == null || path.isEmpty) return null;

    final bucket = output.storageBucket?.trim();
    return (
      bucket: bucket == null || bucket.isEmpty
          ? PatientFileStoragePathBuilder.defaultBucket
          : bucket,
      path: path,
    );
  }

  static Future<void> _openViaSignedUrl({
    required String bucket,
    required String path,
  }) async {
    final url = await PatientFileStorageRepositoryProvider.repository
        .createSignedUrl(bucket: bucket, path: path);

    if (url.startsWith('drmem-mock://')) {
      throw const PdfOutputViewException(
        PdfOutputViewFailureReason.signedUrlFailed,
        debugMessage: 'mock signed url',
      );
    }

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw const PdfOutputViewException(PdfOutputViewFailureReason.launchFailed);
    }
  }

  static Future<void> _openFromStorageBytes({
    required String bucket,
    required String path,
    required PdfOutput output,
  }) async {
    try {
      final bytes = await PatientFileStorageRepositoryProvider.repository.download(
        bucket: bucket,
        path: path,
      );
      await _showPdf(bytes, output.title);
      return;
    } on PatientFileStorageException catch (e) {
      if (kDebugMode) {
        debugPrint('PdfOutputViewLauncher download: ${e.message}');
      }
    }

    await _openRegeneratedSnapshot(output);
  }

  static Future<void> _openRegeneratedSnapshot(PdfOutput output) async {
    final bytes = await PdfOutputBytesBuilder.buildForSave(draft: output);
    if (bytes == null || bytes.isEmpty) {
      throw const PdfOutputViewException(
        PdfOutputViewFailureReason.signedUrlFailed,
        debugMessage: 'regenerate failed',
      );
    }
    await _showPdf(bytes, output.title);
  }

  static Future<void> _showPdf(Uint8List bytes, String title) async {
    final safeName = title.trim().isEmpty ? 'belge.pdf' : '${title.trim()}.pdf';
    await Printing.layoutPdf(
      name: safeName,
      onLayout: (_) async => bytes,
    );
  }
}
