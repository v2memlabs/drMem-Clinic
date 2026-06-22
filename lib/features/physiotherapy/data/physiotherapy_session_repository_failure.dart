/// FTR seans notu repository hata sınıflandırması.
enum PhysiotherapySessionRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  validation,
  unknown,
}

class PhysiotherapySessionRepositoryException implements Exception {
  final PhysiotherapySessionRepositoryFailure reason;

  const PhysiotherapySessionRepositoryException(this.reason);

  @override
  String toString() => 'PhysiotherapySessionRepositoryException($reason)';
}
