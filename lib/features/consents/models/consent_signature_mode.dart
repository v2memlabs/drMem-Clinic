enum ConsentSignatureMode {
  pending,
  pad,
  wetUpload,
}

String consentSignatureModeLabel(ConsentSignatureMode mode) {
  switch (mode) {
    case ConsentSignatureMode.pending:
      return 'İmza bekleniyor';
    case ConsentSignatureMode.pad:
      return 'Pad imzası';
    case ConsentSignatureMode.wetUpload:
      return 'Islak imza yüklendi';
  }
}

ConsentSignatureMode consentSignatureModeFromDb(String? raw) {
  switch (raw?.trim()) {
    case 'pad':
      return ConsentSignatureMode.pad;
    case 'wet_upload':
      return ConsentSignatureMode.wetUpload;
    default:
      return ConsentSignatureMode.pending;
  }
}

String consentSignatureModeToDb(ConsentSignatureMode mode) {
  switch (mode) {
    case ConsentSignatureMode.pending:
      return 'pending';
    case ConsentSignatureMode.pad:
      return 'pad';
    case ConsentSignatureMode.wetUpload:
      return 'wet_upload';
  }
}
