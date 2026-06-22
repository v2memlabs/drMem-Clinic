enum PrescriptionRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class PrescriptionRepositoryException implements Exception {
  final PrescriptionRepositoryFailure reason;

  const PrescriptionRepositoryException(this.reason);

  @override
  String toString() => 'PrescriptionRepositoryException($reason)';
}
