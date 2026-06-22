import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_membership_error_mapper.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_membership_failure.dart';

void main() {
  group('TenantMembershipErrorMapper', () {
    test('maps self_update_blocked', () {
      expect(
        TenantMembershipErrorMapper.mapPostgrest(
          PostgrestException(message: 'self_update_blocked'),
        ),
        TenantMembershipFailure.selfUpdateBlocked,
      );
      expect(
        TenantMembershipErrorMapper.messageFor(
          TenantMembershipFailure.selfUpdateBlocked,
        ),
        'Kendi rolünüzü bu ekrandan değiştiremezsiniz.',
      );
    });

    test('maps last_admin_blocked', () {
      expect(
        TenantMembershipErrorMapper.mapPostgrest(
          PostgrestException(message: 'last_admin_blocked'),
        ),
        TenantMembershipFailure.lastAdminBlocked,
      );
      expect(
        TenantMembershipErrorMapper.messageFor(
          TenantMembershipFailure.lastAdminBlocked,
        ),
        contains('Son aktif doktor/admin'),
      );
    });

    test('maps forbidden', () {
      expect(
        TenantMembershipErrorMapper.mapPostgrest(
          PostgrestException(message: 'permission denied', code: '42501'),
        ),
        TenantMembershipFailure.forbidden,
      );
      expect(
        TenantMembershipErrorMapper.messageFor(
          TenantMembershipFailure.forbidden,
        ),
        'Bu işlem için yetkiniz yok.',
      );
    });

    test('maps invitation_acceptance_required', () {
      expect(
        TenantMembershipErrorMapper.mapPostgrest(
          PostgrestException(message: 'invitation_acceptance_required'),
        ),
        TenantMembershipFailure.invitationAcceptanceRequired,
      );
    });
  });
}
