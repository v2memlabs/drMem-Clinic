enum ClinicalReportRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class ClinicalReportRepositoryException implements Exception {
  final ClinicalReportRepositoryFailure reason;

  const ClinicalReportRepositoryException(this.reason);

  @override
  String toString() => 'ClinicalReportRepositoryException($reason)';
}
