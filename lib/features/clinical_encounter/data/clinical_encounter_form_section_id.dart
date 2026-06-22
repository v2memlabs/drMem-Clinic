/// Muayene formu bölüm kimlikleri — section index ve scroll hedefi.
abstract final class ClinicalEncounterFormSectionId {
  static const String identity = 'identity';
  static const String complaint = 'complaint';
  static const String examination = 'examination';
  static const String imaging = 'imaging';
  static const String diagnosis = 'diagnosis';
  static const String treatment = 'treatment';
  static const String followUp = 'follow_up';
  static const String privateNote = 'private_note';

  static const List<({String id, String label})> clinicalSections = [
    (id: complaint, label: 'Şikayet / Hikaye'),
    (id: examination, label: 'Muayene'),
    (id: imaging, label: 'Görüntüleme'),
    (id: diagnosis, label: 'Ön tanı/Tanı'),
    (id: treatment, label: 'Tedavi Planı'),
    (id: followUp, label: 'Fizyoterapi / Egzersiz / Kontrol'),
    (id: privateNote, label: 'Özel Not'),
  ];
}
