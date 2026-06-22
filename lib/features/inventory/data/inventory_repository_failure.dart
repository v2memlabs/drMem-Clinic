enum InventoryRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class InventoryRepositoryException implements Exception {
  final InventoryRepositoryFailure reason;

  const InventoryRepositoryException(this.reason);

  @override
  String toString() => 'InventoryRepositoryException($reason)';
}
