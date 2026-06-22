import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/invitation_deep_link.dart';

void main() {
  const validId = 'a1b2c3d4-e5f6-4789-a012-3456789abcde';

  test('parseMembershipId reads accept path query', () {
    expect(
      InvitationDeepLink.parseMembershipId(
        '/invite/accept?membership_id=$validId',
      ),
      validId,
    );
  });

  test('normalizeMembershipId rejects invalid values', () {
    expect(InvitationDeepLink.normalizeMembershipId('not-a-uuid'), isNull);
    expect(InvitationDeepLink.normalizeMembershipId(''), isNull);
  });

  test('buildAcceptLocation encodes membership id', () {
    expect(
      InvitationDeepLink.buildAcceptLocation(validId),
      '/invite/accept?membership_id=$validId',
    );
  });

  test('isAcceptPath matches only accept route', () {
    expect(InvitationDeepLink.isAcceptPath('/invite/accept?membership_id=$validId'), isTrue);
    expect(InvitationDeepLink.isAcceptPath('/login'), isFalse);
  });
}
