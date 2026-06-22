enum ExercisePlanRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class ExercisePlanRepositoryException implements Exception {
  final ExercisePlanRepositoryFailure reason;

  const ExercisePlanRepositoryException(this.reason);

  @override
  String toString() => 'ExercisePlanRepositoryException($reason)';
}
