import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/pending_invitation_store.dart';

void main() {
  tearDown(PendingInvitationStore.clearSilently);

  test('stores and clears membership id', () {
    PendingInvitationStore.setMembershipId('a1b2c3d4-e5f6-4789-a012-3456789abcde');
    expect(PendingInvitationStore.membershipId, isNotNull);
    PendingInvitationStore.clear();
    expect(PendingInvitationStore.membershipId, isNull);
  });
}
