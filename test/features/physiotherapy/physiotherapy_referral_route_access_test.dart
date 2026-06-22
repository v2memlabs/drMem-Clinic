import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/auth/auth_route_permissions.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  test('doctor can access referral list and create', () {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Dr',
        role: AppRoles.doctor,
      ),
    );

    expect(
      AuthRoutePermissions.canAccessPath('/physiotherapy/referrals'),
      isTrue,
    );
    expect(
      AuthRoutePermissions.canAccessPath('/physiotherapy/referrals/new'),
      isTrue,
    );
  });

  test('physiotherapist can access referral list but not create', () {
    AuthSession.setUser(
      AppUser(
        id: 'ph1',
        username: 'physio',
        displayName: 'Fizyo',
        role: AppRoles.physiotherapist,
      ),
    );

    expect(
      AuthRoutePermissions.canAccessPath('/physiotherapy/referrals'),
      isTrue,
    );
    expect(
      AuthRoutePermissions.canAccessPath('/physiotherapy/referrals/new'),
      isFalse,
    );
  });

  test('assistant and nurse cannot access referrals', () {
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

    AuthSession.setUser(
      AppUser(
        id: 'n1',
        username: 'nurse',
        displayName: 'Hemşire',
        role: AppRoles.nurse,
      ),
    );
    expect(
      AuthRoutePermissions.canAccessPath('/physiotherapy/referrals'),
      isFalse,
    );
  });
}
