/// Personel izin notu — yasak teknik/klinik terimleri ayıklar.
abstract final class StaffLeaveNoteSanitizer {
  static const int maxLength = 500;

  static const Set<String> _forbiddenTerms = {
    'internaldoctornote',
    'internal_doctor_note',
    'clinical_data',
    'rawclinicaldata',
    'filecontent',
    'pdfcontent',
    'pdf_content',
    'signedurl',
    'signed_url',
    'publicurl',
    'public_url',
    'storagepath',
    'storage_path',
    'servicerole',
    'service_role',
    'secret',
    'token',
  };

  static String? sanitize(String? input) {
    if (input == null) return null;
    var text = input.trim();
    if (text.isEmpty) return null;

    for (final term in _forbiddenTerms) {
      text = _removeTermCaseInsensitive(text, term);
    }

    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return null;
    if (text.length > maxLength) {
      text = text.substring(0, maxLength);
    }
    return text;
  }

  static String _removeTermCaseInsensitive(String text, String term) {
    final pattern = RegExp(term, caseSensitive: false);
    return text.replaceAll(pattern, '');
  }
}
