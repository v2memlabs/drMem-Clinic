import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_route_permissions.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/tenant/tenant_financial_feature_gate.dart';
import 'package:v2mem_clinic/features/settings/demo_usage_settings_content.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_financial_feature_settings.dart';
import 'package:v2mem_clinic/features/settings/settings_categories.dart';
import 'package:v2mem_clinic/features/settings/settings_hub_screen.dart';
import 'package:v2mem_clinic/features/settings/settings_product_labels.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    TenantFinancialFeatureGate.reset();
  });

  AppUser user(String role) => AppUser(
        id: 'u-$role',
        username: role,
        displayName: 'Test User',
        role: role,
      );

  group('SettingsProductLabels', () {
    test('doctor role shows Doktor not Admin', () {
      expect(SettingsProductLabels.roleLabel(AppRoles.doctor), 'Doktor');
      expect(SettingsProductLabels.roleLabel(AppRoles.doctor), isNot(contains('Admin')));
    });

    test('assistant role shows Asistan not Sekreter', () {
      expect(SettingsProductLabels.roleLabel(AppRoles.assistant), 'Asistan');
      expect(SettingsProductLabels.roleLabel(AppRoles.assistant), isNot(contains('Sekreter')));
    });

    test('membership status labels', () {
      expect(SettingsProductLabels.membershipStatusLabel('active'), 'Aktif');
      expect(SettingsProductLabels.membershipStatusLabel('invited'), 'Davetli');
      expect(SettingsProductLabels.membershipStatusLabel('disabled'), 'Pasif');
    });
  });

  group('SettingsCategories visibility', () {
    test('doctor sees 9 categories including users-roles and clinic-finance', () {
      AuthSession.setUser(user(AppRoles.doctor));
      TenantFinancialFeatureGate.apply(TenantFinancialFeatureSettings.defaults);
      final visible = SettingsCategories.visibleForCurrentUser();
      expect(visible.length, 9);
      expect(visible.any((c) => c.id == 'clinic-workflow'), isFalse);
      expect(
        visible.any((c) => c.id == 'users-roles'),
        isTrue,
      );
      expect(
        visible.any((c) => c.id == 'clinic-finance'),
        isTrue,
      );
    });

    test('doctor does not see clinic-finance when payment records disabled', () {
      AuthSession.setUser(user(AppRoles.doctor));
      TenantFinancialFeatureGate.apply(
        TenantFinancialFeatureSettings.defaults.copyWithFlag(
          TenantFinancialFeatureKey.paymentRecords,
          false,
        ),
      );
      final visible = SettingsCategories.visibleForCurrentUser();
      expect(visible.length, 8);
      expect(visible.any((c) => c.id == 'clinic-finance'), isFalse);
    });

    test('assistant sees profile, display-region and password only', () {
      AuthSession.setUser(user(AppRoles.assistant));
      final visible = SettingsCategories.visibleForCurrentUser();
      expect(visible.length, 3);
      expect(visible.map((c) => c.id).toList(), [
        'profile',
        'display-region',
        'system-security',
      ]);
      expect(visible.singleWhere((c) => c.id == 'system-security').title,
          'Şifre İşlemleri');
      expect(visible.any((c) => c.id == 'users-roles'), isFalse);
      expect(visible.any((c) => c.id == 'clinic'), isFalse);
      expect(visible.any((c) => c.id == 'patient-settings'), isFalse);
      expect(visible.any((c) => c.id == 'demo-usage'), isFalse);
      expect(visible.any((c) => c.id == 'subscription'), isFalse);
    });

    test('nurse and physiotherapist see same limited settings as assistant', () {
      for (final role in [AppRoles.nurse, AppRoles.physiotherapist]) {
        AuthSession.setUser(user(role));
        final visible = SettingsCategories.visibleForCurrentUser();
        expect(visible.length, 3, reason: role);
        expect(
          visible.any((c) => c.id == 'system-security' && c.title == 'Şifre İşlemleri'),
          isTrue,
          reason: role,
        );
      }
    });
  });

  group('AuthRoutePermissions settings paths', () {
    test('doctor can access users-roles', () {
      AuthSession.setUser(user(AppRoles.doctor));
      expect(AuthRoutePermissions.canAccessPath('/settings/users-roles'), isTrue);
    });

    test('assistant cannot access users-roles', () {
      AuthSession.setUser(user(AppRoles.assistant));
      expect(AuthRoutePermissions.canAccessPath('/settings/users-roles'), isFalse);
    });

    test('physiotherapist cannot access users-roles', () {
      AuthSession.setUser(user(AppRoles.physiotherapist));
      expect(AuthRoutePermissions.canAccessPath('/settings/users-roles'), isFalse);
    });

    test('nurse cannot access users-roles', () {
      AuthSession.setUser(user(AppRoles.nurse));
      expect(AuthRoutePermissions.canAccessPath('/settings/users-roles'), isFalse);
    });

    test('clinical non-doctor staff cannot access doctor-only settings paths', () {
      for (final role in [
        AppRoles.assistant,
        AppRoles.nurse,
        AppRoles.physiotherapist,
      ]) {
        AuthSession.setUser(user(role));
        expect(
          AuthRoutePermissions.canAccessPath('/settings/clinic'),
          isFalse,
          reason: role,
        );
        expect(
          AuthRoutePermissions.canAccessPath('/settings/patient-settings'),
          isFalse,
          reason: role,
        );
        expect(
          AuthRoutePermissions.canAccessPath('/settings/demo-usage'),
          isFalse,
          reason: role,
        );
        expect(
          AuthRoutePermissions.canAccessPath('/settings/subscription'),
          isFalse,
          reason: role,
        );
        expect(
          AuthRoutePermissions.canAccessPath('/settings/system-security'),
          isTrue,
          reason: role,
        );
      }
    });
  });

  group('SettingsHubScreen', () {
    testWidgets('shows settings hub without clinic-workflow for doctor', (tester) async {
      AuthSession.setUser(user(AppRoles.doctor));

      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsHubScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profil Bilgileri'), findsOneWidget);
      expect(find.text('Kullanıcılar ve Roller'), findsOneWidget);
      expect(find.text('Demo / Kullanım Durumu'), findsOneWidget);
      expect(find.text('SaaS / Abonelik'), findsOneWidget);
      expect(find.text('Klinik İşleyiş'), findsNothing);
    });
  });

  group('DemoUsageSettingsContent', () {
    testWidgets('does not show technical id labels', (tester) async {
      AuthSession.setUser(user(AppRoles.doctor));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DemoUsageSettingsContent(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('tenant_id'), findsNothing);
      expect(find.textContaining('auth_user_id'), findsNothing);
      expect(find.textContaining('profile_id'), findsNothing);
      expect(find.textContaining('anon'), findsNothing);
      expect(find.text('Backend'), findsOneWidget);
      expect(find.text('Aktif rol'), findsOneWidget);
    });
  });
}
