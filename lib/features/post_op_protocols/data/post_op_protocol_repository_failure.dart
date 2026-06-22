enum PostOpProtocolRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class PostOpProtocolRepositoryException implements Exception {
  final PostOpProtocolRepositoryFailure reason;

  const PostOpProtocolRepositoryException(this.reason);

  @override
  String toString() => 'PostOpProtocolRepositoryException($reason)';
}
