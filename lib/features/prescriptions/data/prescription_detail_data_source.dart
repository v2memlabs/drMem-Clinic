import '../models/prescription.dart';
import 'prescription_repository_failure.dart';
import 'prescription_repository_provider.dart';
import 'prescription_user_messages.dart';

class PrescriptionDetailLoadResult {
  final Prescription? prescription;
  final String? errorMessage;

  const PrescriptionDetailLoadResult._({
    this.prescription,
    this.errorMessage,
  });

  factory PrescriptionDetailLoadResult.success(Prescription prescription) {
    return PrescriptionDetailLoadResult._(prescription: prescription);
  }

  factory PrescriptionDetailLoadResult.failure(String message) {
    return PrescriptionDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class PrescriptionDetailDataSource {
  static Future<PrescriptionDetailLoadResult> load(String id) async {
    try {
      final prescription =
          await PrescriptionRepositoryProvider.asyncRepository.getById(id);
      if (prescription == null) {
        return PrescriptionDetailLoadResult.failure(
          PrescriptionUserMessages.notFound,
        );
      }
      return PrescriptionDetailLoadResult.success(prescription);
    } on PrescriptionRepositoryException catch (e) {
      return PrescriptionDetailLoadResult.failure(
        PrescriptionUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PrescriptionDetailLoadResult.failure(
        PrescriptionUserMessages.genericLoadFailure,
      );
    }
  }
}
