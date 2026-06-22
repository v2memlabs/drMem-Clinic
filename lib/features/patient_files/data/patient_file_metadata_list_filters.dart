import '../models/patient_file_metadata.dart';
import 'patient_file_metadata_display.dart';

/// İstemci tarafı arama — yalnızca güvenli görünür alanlar.
abstract final class PatientFileMetadataListFilters {
  static List<PatientFileMetadata> applySearch(
    List<PatientFileMetadata> files,
    String search,
  ) {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return files;

    return files.where((f) {
      if (f.displayName.toLowerCase().contains(q)) return true;
      final orig = f.originalFileName?.toLowerCase();
      if (orig != null && orig.contains(q)) return true;
      if (PatientFileMetadataDisplay.fileKindLabel(f.fileKind)
          .toLowerCase()
          .contains(q)) {
        return true;
      }
      if (PatientFileMetadataDisplay.clinicalContextLabel(f.clinicalContext)
          .toLowerCase()
          .contains(q)) {
        return true;
      }
      return false;
    }).toList();
  }
}
