enum ImagingRepositoryFailure {
  notConfigured,
  noActiveTenant,
  notFound,
  invalidRow,
  forbidden,
  network,
  unknown,
}

class ImagingRepositoryException implements Exception {
  final ImagingRepositoryFailure reason;

  const ImagingRepositoryException(this.reason);

  @override
  String toString() => 'ImagingRepositoryException($reason)';
}
