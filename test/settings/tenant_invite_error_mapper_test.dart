import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_invite_error_mapper.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_invite_failure.dart';

void main() {
  test('maps auth_user_exists to clear user message', () {
    final failure =
        TenantInviteErrorMapper.fromFunctionError('auth_user_exists');
    expect(failure, TenantInviteFailure.authUserExists);
    expect(
      TenantInviteErrorMapper.messageFor(failure),
      contains('zaten bir hesap'),
    );
  });

  test('maps self_invite_blocked to clear user message', () {
    final failure =
        TenantInviteErrorMapper.fromFunctionError('self_invite_blocked');
    expect(failure, TenantInviteFailure.selfInviteBlocked);
    expect(
      TenantInviteErrorMapper.messageFor(failure),
      contains('Kendi e-posta'),
    );
  });

  test('maps invite_rate_limited from auth rate limit code', () {
    final failure =
        TenantInviteErrorMapper.fromFunctionError('invite_rate_limited');
    expect(failure, TenantInviteFailure.inviteRateLimited);
  });

  test('maps auth_email_rate_limited from Supabase mail quota', () {
    final failure =
        TenantInviteErrorMapper.fromFunctionError('auth_email_rate_limited');
    expect(failure, TenantInviteFailure.authEmailRateLimited);
    expect(
      TenantInviteErrorMapper.messageFor(failure),
      contains('saatlik'),
    );
  });
}
