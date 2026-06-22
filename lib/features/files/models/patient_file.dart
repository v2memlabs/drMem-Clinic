class PatientFile {
  final String id;
  final String patientId;
  final String patientName;
  final String fileName;
  final String fileType;
  final DateTime uploadedAt;
  final String uploadedBy;
  final String? description;

  PatientFile({required this.id, required this.patientId, required this.patientName, required this.fileName, required this.fileType, required this.uploadedAt, required this.uploadedBy, this.description});
}

String patientFileTypeLabel(String fileType) {
  final t = fileType.toLowerCase();
  if (t.contains('pdf')) return 'PDF';
  if (t.startsWith('image/')) return 'Görüntü';
  if (t.startsWith('video/')) return 'Video';
  if (t.contains('word') || t.contains('document')) return 'Word';
  return fileType;
}
