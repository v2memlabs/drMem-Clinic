import '../models/consent_record.dart';

class ConsentListLoadResult {
  final List<ConsentRecord> records;
  final String? errorMessage;

  const ConsentListLoadResult._({required this.records, this.errorMessage});

  factory ConsentListLoadResult.success(List<ConsentRecord> records) {
    return ConsentListLoadResult._(records: records);
  }

  factory ConsentListLoadResult.failure(String message) {
    return ConsentListLoadResult._(
      records: const [],
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
