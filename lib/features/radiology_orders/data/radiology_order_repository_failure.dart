enum RadiologyOrderRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class RadiologyOrderRepositoryException implements Exception {
  final RadiologyOrderRepositoryFailure reason;

  const RadiologyOrderRepositoryException(this.reason);

  @override
  String toString() => 'RadiologyOrderRepositoryException($reason)';
}
