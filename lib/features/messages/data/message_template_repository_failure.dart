enum MessageTemplateRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class MessageTemplateRepositoryException implements Exception {
  final MessageTemplateRepositoryFailure reason;

  const MessageTemplateRepositoryException(this.reason);

  @override
  String toString() => 'MessageTemplateRepositoryException($reason)';
}
