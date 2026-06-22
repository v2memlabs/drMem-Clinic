enum AuditLogRepositoryFailure {
  notConfigured,
  noActiveTenant,
  forbidden,
  notFound,
  network,
  invalidRow,
  unknown,
}

class AuditLogRepositoryException implements Exception {
  const AuditLogRepositoryException(this.reason, {this.cause});

  final AuditLogRepositoryFailure reason;
  final Object? cause;

  @override
  String toString() => 'AuditLogRepositoryException($reason)';
}
