import '../models/physiotherapy_session_note.dart';

class PhysiotherapySessionListLoadResult {
  final List<PhysiotherapySessionNote>? items;
  final String? errorMessage;

  const PhysiotherapySessionListLoadResult._({this.items, this.errorMessage});

  factory PhysiotherapySessionListLoadResult.success(
    List<PhysiotherapySessionNote> items,
  ) {
    return PhysiotherapySessionListLoadResult._(items: items);
  }

  factory PhysiotherapySessionListLoadResult.failure(String message) {
    return PhysiotherapySessionListLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
