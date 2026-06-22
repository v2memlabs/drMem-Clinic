import '../models/prescription.dart';
import 'prescription_list_refresh.dart';
import 'prescription_repository_failure.dart';
import 'prescription_repository_provider.dart';
import 'prescription_user_messages.dart';

abstract final class PrescriptionFormDataSource {
  static Future<Prescription> create(Prescription draft) async {
    try {
      final saved =
          await PrescriptionRepositoryProvider.asyncRepository.create(draft);
      PrescriptionListRefresh.markStale();
      return saved;
    } on PrescriptionRepositoryException catch (e) {
      throw PrescriptionFormException(
        PrescriptionUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const PrescriptionFormException(
        PrescriptionUserMessages.genericSaveFailure,
      );
    }
  }

  static Future<Prescription> update(Prescription record) async {
    try {
      final saved =
          await PrescriptionRepositoryProvider.asyncRepository.update(record);
      PrescriptionListRefresh.markStale();
      return saved;
    } on PrescriptionRepositoryException catch (e) {
      throw PrescriptionFormException(
        PrescriptionUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const PrescriptionFormException(
        PrescriptionUserMessages.genericSaveFailure,
      );
    }
  }

  static Future<Prescription?> loadForEdit(String id) async {
    try {
      return await PrescriptionRepositoryProvider.asyncRepository.getById(id);
    } catch (_) {
      return null;
    }
  }
}

class PrescriptionFormException implements Exception {
  final String message;

  const PrescriptionFormException(this.message);

  @override
  String toString() => message;
}
