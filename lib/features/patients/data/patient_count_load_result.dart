/// Ayarlar demo kartı — hasta sayısı yükleme sonucu.
class PatientCountLoadResult {
  final int? count;
  final String? errorMessage;

  const PatientCountLoadResult._({
    this.count,
    this.errorMessage,
  });

  factory PatientCountLoadResult.success(int count) {
    return PatientCountLoadResult._(count: count);
  }

  factory PatientCountLoadResult.failure(String message) {
    return PatientCountLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
