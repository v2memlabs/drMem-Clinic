import '../models/physiotherapy_session_note.dart';

class PhysiotherapySessionDetailLoadResult {
  final PhysiotherapySessionNote? session;
  final String? errorMessage;

  const PhysiotherapySessionDetailLoadResult._({
    this.session,
    this.errorMessage,
  });

  factory PhysiotherapySessionDetailLoadResult.success(
    PhysiotherapySessionNote session,
  ) {
    return PhysiotherapySessionDetailLoadResult._(session: session);
  }

  factory PhysiotherapySessionDetailLoadResult.notFound() {
    return const PhysiotherapySessionDetailLoadResult._();
  }

  factory PhysiotherapySessionDetailLoadResult.failure(String message) {
    return PhysiotherapySessionDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
