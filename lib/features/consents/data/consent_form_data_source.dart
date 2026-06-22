import '../../../core/data/repository_registry.dart';
import '../models/consent_record.dart';
import 'consent_list_user_messages.dart';
import 'consent_repository_failure.dart';

class ConsentFormSaveResult {
  final ConsentRecord? record;
  final String? errorMessage;

  const ConsentFormSaveResult._({this.record, this.errorMessage});

  factory ConsentFormSaveResult.success(ConsentRecord record) {
    return ConsentFormSaveResult._(record: record);
  }

  factory ConsentFormSaveResult.failure(String message) {
    return ConsentFormSaveResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class ConsentFormDataSource {
  static Future<ConsentFormSaveResult> add(ConsentRecord record) async {
    try {
      final saved = await RepositoryRegistry.consentsAsync.add(record);
      return ConsentFormSaveResult.success(saved);
    } on ConsentRepositoryException catch (e) {
      return ConsentFormSaveResult.failure(
        ConsentListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return ConsentFormSaveResult.failure(
        ConsentListUserMessages.genericLoadFailure,
      );
    }
  }
}
