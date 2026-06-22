import '../../../core/data/repository_registry.dart';
import '../models/patient_file_metadata.dart';
import 'patient_file_metadata_list_filters.dart';
import 'patient_file_metadata_list_load_result.dart';
import 'patient_file_metadata_list_user_messages.dart';
import 'patient_file_metadata_module_availability.dart';
import 'patient_file_metadata_repository_failure.dart';

/// Hasta dosya metadata listesi — [RepositoryRegistry.patientFileMetadata].
abstract final class PatientFileMetadataListDataSource {
  static Future<PatientFileMetadataListLoadResult> load({
    String? patientId,
    String search = '',
  }) async {
    if (!PatientFileMetadataModuleAvailability.isOperational) {
      return PatientFileMetadataListLoadResult.notConfigured();
    }

    try {
      final repo = RepositoryRegistry.patientFileMetadata;
      var list = await repo.listTenantFiles(
        patientId: patientId?.trim().isNotEmpty == true
            ? patientId!.trim()
            : null,
      );
      list = PatientFileMetadataListFilters.applySearch(list, search);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return PatientFileMetadataListLoadResult.success(list);
    } on PatientFileMetadataRepositoryException catch (e) {
      if (e.reason == PatientFileMetadataRepositoryFailure.notConfigured) {
        return PatientFileMetadataListLoadResult.notConfigured();
      }
      return PatientFileMetadataListLoadResult.failure(
        PatientFileMetadataListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PatientFileMetadataListLoadResult.failure(
        PatientFileMetadataListUserMessages.errorDescription,
      );
    }
  }
}
