enum LabOrderTemplateRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class LabOrderTemplateRepositoryException implements Exception {
  final LabOrderTemplateRepositoryFailure reason;

  const LabOrderTemplateRepositoryException(this.reason);

  @override
  String toString() => 'LabOrderTemplateRepositoryException($reason)';
}
