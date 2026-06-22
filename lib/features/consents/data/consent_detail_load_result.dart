import '../models/consent_record.dart';

class ConsentDetailLoadResult {
  final ConsentRecord? record;
  final String? errorMessage;
  final bool notFound;

  const ConsentDetailLoadResult._({
    this.record,
    this.errorMessage,
    this.notFound = false,
  });

  factory ConsentDetailLoadResult.success(ConsentRecord record) {
    return ConsentDetailLoadResult._(record: record);
  }

  factory ConsentDetailLoadResult.notFound() {
    return const ConsentDetailLoadResult._(notFound: true);
  }

  factory ConsentDetailLoadResult.failure(String message) {
    return ConsentDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
