/// FTR yönlendirme repository hata sınıflandırması.
enum PhysiotherapyReferralRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class PhysiotherapyReferralRepositoryException implements Exception {
  final PhysiotherapyReferralRepositoryFailure reason;

  const PhysiotherapyReferralRepositoryException(this.reason);

  @override
  String toString() => 'PhysiotherapyReferralRepositoryException($reason)';
}
