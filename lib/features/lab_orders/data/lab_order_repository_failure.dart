enum LabOrderRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class LabOrderRepositoryException implements Exception {
  final LabOrderRepositoryFailure reason;

  const LabOrderRepositoryException(this.reason);

  @override
  String toString() => 'LabOrderRepositoryException($reason)';
}
