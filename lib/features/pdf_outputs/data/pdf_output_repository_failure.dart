/// Remote PDF çıktı repository hata nedenleri (UI'ya teknik detay sızdırılmaz).
enum PdfOutputRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  network,
  notConfigured,
  invalidRow,
  unknown,
}

class PdfOutputRepositoryException implements Exception {
  final PdfOutputRepositoryFailure reason;
  final Object? cause;

  const PdfOutputRepositoryException(this.reason, {this.cause});

  @override
  String toString() => 'PdfOutputRepositoryException($reason)';
}
