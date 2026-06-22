import '../models/prescription.dart';
import 'prescription_list_load_result.dart';
import 'prescription_repository_failure.dart';
import 'prescription_repository_provider.dart';
import 'prescription_user_messages.dart';

abstract final class PrescriptionListDataSource {
  static Future<PrescriptionListLoadResult> load({
    String? patientId,
    String? query,
    PrescriptionStatus? statusFilter,
  }) async {
    try {
      final items = await PrescriptionRepositoryProvider.asyncRepository
          .getFiltered(
        patientId: patientId,
        query: query,
        statusFilter: statusFilter,
      );
      return PrescriptionListLoadResult.success(items);
    } on PrescriptionRepositoryException catch (e) {
      return PrescriptionListLoadResult.failure(
        PrescriptionUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PrescriptionListLoadResult.failure(
        PrescriptionUserMessages.genericLoadFailure,
      );
    }
  }
}
