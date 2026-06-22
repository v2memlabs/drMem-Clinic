enum SurgeryProcedureNoteRepositoryFailure {
  notConfigured,
  noActiveTenant,
  notFound,
  invalidRow,
  forbidden,
  network,
  unknown,
}

class SurgeryProcedureNoteRepositoryException implements Exception {
  final SurgeryProcedureNoteRepositoryFailure reason;

  const SurgeryProcedureNoteRepositoryException(this.reason);

  @override
  String toString() => 'SurgeryProcedureNoteRepositoryException($reason)';
}
