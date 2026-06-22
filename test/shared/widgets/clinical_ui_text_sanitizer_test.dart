import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_state_message.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_ui_text_sanitizer.dart';

void main() {
  test('ClinicalNotice and ClinicalStateMessage use aligned forbidden tokens', () {
    expect(
      ClinicalUiTextSanitizer.forbiddenUiTokens,
      containsAll(<String>[
        'internal_doctor_note',
        'clinical_data',
        'storage_path',
        'storage_bucket',
        'auth_user_id',
        'signed_url',
        'tenant_id',
        'internalDoctorNote',
        'PostgREST',
        'PostgrestException',
        'AuthException',
        'StorageException',
      ]),
    );
  });

  test('sanitizer strips forbidden tokens', () {
    expect(
      ClinicalUiTextSanitizer.sanitize('JWT tenant_id storage_path storage_bucket'),
      '—',
    );
    expect(
      ClinicalUiTextSanitizer.containsForbiddenToken('PostgREST AuthException fail'),
      isTrue,
    );
    expect(
      ClinicalUiTextSanitizer.containsForbiddenToken('PostgrestException: denied'),
      isTrue,
    );
  });

  test('safeErrorDescription never returns raw exception text', () {
    expect(
      ClinicalStateMessage.safeErrorDescription('SocketException: host'),
      ClinicalStateMessage.genericLoadFailure,
    );
    expect(
      ClinicalStateMessage.safeErrorDescription('internal_doctor_note leak'),
      ClinicalStateMessage.genericLoadFailure,
    );
    expect(
      ClinicalStateMessage.safeErrorDescription('auth_user_id=abc'),
      ClinicalStateMessage.genericLoadFailure,
    );
  });

  test('normal Turkish text is not broken', () {
    const safe = 'Hasta listesi yüklenemedi.';
    expect(ClinicalUiTextSanitizer.containsForbiddenToken(safe), isFalse);
    expect(ClinicalStateMessage.safeErrorDescription(safe), safe);
    expect(ClinicalUiTextSanitizer.sanitize(safe), safe);
  });
}
