enum ConsentRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class ConsentRepositoryException implements Exception {
  final ConsentRepositoryFailure reason;

  const ConsentRepositoryException(this.reason);

  @override
  String toString() => 'ConsentRepositoryException($reason)';
}
