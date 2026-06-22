import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/auth/auth_route_permissions.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  test('assistant cannot access referral routes', () {
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );
    expect(
      AuthRoutePermissions.canAccessPath('/physiotherapy/referrals'),
      isFalse,
    );
    expect(
      AuthRoutePermissions.canAccessPath('/appointments/new?patientId=p1&type=fizikTedavi'),
      isTrue,
    );
  });

  test('physiotherapist can access referral appointment create route', () {
    AuthSession.setUser(
      AppUser(
        id: 'ph1',
        username: 'physio',
        displayName: 'Fizyo',
        role: AppRoles.physiotherapist,
      ),
    );
    expect(
      AuthSession.canBookReferralAppointments,
      isTrue,
    );
    expect(
      AuthRoutePermissions.canAccessPath('/appointments/new'),
      isTrue,
    );
    expect(
      AuthRoutePermissions.canAccessPath('/physiotherapy/referrals/pending'),
      isTrue,
    );
  });
}
