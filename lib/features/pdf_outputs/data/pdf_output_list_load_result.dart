import '../models/pdf_output.dart';

/// PDF çıktı listesi yükleme sonucu.
class PdfOutputListLoadResult {
  final List<PdfOutput> outputs;
  final String? errorMessage;

  const PdfOutputListLoadResult._({
    required this.outputs,
    this.errorMessage,
  });

  factory PdfOutputListLoadResult.success(List<PdfOutput> outputs) {
    return PdfOutputListLoadResult._(outputs: outputs);
  }

  factory PdfOutputListLoadResult.failure(String message) {
    return PdfOutputListLoadResult._(
      outputs: const [],
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
