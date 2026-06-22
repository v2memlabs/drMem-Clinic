enum SentMessageRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class SentMessageRepositoryException implements Exception {
  final SentMessageRepositoryFailure reason;

  const SentMessageRepositoryException(this.reason);

  @override
  String toString() => 'SentMessageRepositoryException($reason)';
}
