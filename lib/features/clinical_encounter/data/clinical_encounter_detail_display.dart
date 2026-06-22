import '../../../core/auth/auth_session.dart';
import '../models/clinical_encounter.dart';

/// Muayene detay — görünürlük ve özel not etiketleri.
///
/// [internalDoctorNote] yalnızca doctor full path; `clinical_data` içinde yok.
abstract final class ClinicalEncounterDetailDisplay {
  static const String privateNoteSectionTitle = 'Özel Not';

  static bool get showInternalDoctorNoteSection =>
      AuthSession.canViewFullClinicalEncounter;

  static String internalNoteSectionTitle({required bool usesRemote}) =>
      privateNoteSectionTitle;

  static List<InfoSectionRowSpec> internalNoteRows(
    ClinicalEncounter encounter, {
    required bool usesRemote,
  }) {
    if (!showInternalDoctorNoteSection) return const [];

    return [
      InfoSectionRowSpec(
        label: privateNoteSectionTitle,
        value: _displayInternalNote(encounter.internalDoctorNote),
        emphasize: encounter.internalDoctorNote.trim().isNotEmpty,
      ),
    ];
  }

  static String _displayInternalNote(String note) {
    final trimmed = note.trim();
    return trimmed.isEmpty ? 'Özel not girilmemiş.' : trimmed;
  }
}

/// Detay ekranı satır tanımı.
class InfoSectionRowSpec {
  final String label;
  final String value;
  final bool emphasize;

  const InfoSectionRowSpec({
    required this.label,
    required this.value,
    this.emphasize = false,
  });
}
