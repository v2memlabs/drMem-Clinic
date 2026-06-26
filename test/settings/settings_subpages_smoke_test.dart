import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/lab_orders/models/lab_order_catalog_settings.dart';
import 'package:v2mem_clinic/features/patient_tags/data/mock_patient_tag_repository.dart';
import 'package:v2mem_clinic/features/patient_tags/data/patient_tag_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/clinic_finance_statistics_screen.dart';
import 'package:v2mem_clinic/features/settings/clinic_settings_screen.dart';
import 'package:v2mem_clinic/features/settings/data/profile_settings_repository.dart';
import 'package:v2mem_clinic/features/settings/data/profile_settings_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_settings_repository.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_settings_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/demo_usage_settings_screen.dart';
import 'package:v2mem_clinic/features/settings/models/my_profile_settings.dart';
import 'package:v2mem_clinic/features/settings/models/patient_registration_settings.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_financial_feature_settings.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_preferences.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_role_access_settings.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_security_settings.dart';
import 'package:v2mem_clinic/features/settings/models/user_display_preferences.dart';
import 'package:v2mem_clinic/features/settings/patient_settings_screen.dart';
import 'package:v2mem_clinic/features/settings/profile_settings_screen.dart';
import 'package:v2mem_clinic/features/settings/system_security_settings_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _FakeTenantSettingsRepository implements TenantSettingsRepository {
  TenantBasicInfo info = const TenantBasicInfo(name: 'Test Klinik');
  PatientRegistrationSettings patientRegistrationSettings =
      const PatientRegistrationSettings();
  TenantSecuritySettings securitySettings = TenantSecuritySettings.defaults;

  @override
  Future<TenantBasicInfo> loadBasicInfo() async => info;

  @override
  Future<void> updateBasicInfo({
    required String name,
    required String specialty,
    required String timezone,
    required TenantContactInfo contact,
  }) async {}

  @override
  Future<TenantPreferences> loadPreferences() async =>
      TenantPreferences.defaults;

  @override
  Future<void> updatePreferences(TenantPreferences preferences) async {}

  @override
  Future<void> updateBrandingPaths({
    String? logoStoragePath,
    String? bannerStoragePath,
  }) async {}

  @override
  Future<PatientRegistrationSettings> loadPatientRegistrationSettings() async {
    return patientRegistrationSettings;
  }

  @override
  Future<void> updatePatientRegistrationSettings(
    PatientRegistrationSettings settings,
  ) async {}

  @override
  Future<TenantSecuritySettings> loadSecuritySettings() async {
    return securitySettings;
  }

  @override
  Future<void> updateSecuritySettings(TenantSecuritySettings settings) async {}

  @override
  Future<TenantFinancialFeatureSettings> loadFinancialFeatureSettings() async {
    return TenantFinancialFeatureSettings.defaults;
  }

  @override
  Future<TenantRoleAccessSettings> loadRoleAccessSettings() async {
    return TenantRoleAccessSettings.empty();
  }

  @override
  Future<LabOrderCatalogSettings> loadLabOrderCatalogSettings() async {
    return LabOrderCatalogSettings.defaults;
  }

  @override
  Future<void> updateLabOrderCatalogSettings(
    LabOrderCatalogSettings settings,
  ) async {}
}

class _FakeProfileSettingsRepository implements ProfileSettingsRepository {
  @override
  Future<String> loadMyDisplayName() async => 'Dr. Test';

  @override
  Future<void> updateMyDisplayName(String displayName) async {}

  @override
  Future<MyProfileSettings> loadMyProfile() async {
    return const MyProfileSettings(
      displayName: 'Dr. Test',
      firstName: 'Test',
      lastName: 'Doktor',
      title: 'Ortopedi',
      phone: '555',
      email: 'doctor@test.local',
    );
  }

  @override
  Future<void> updateMyProfile(MyProfileSettings profile) async {}

  @override
  Future<void> updateAvatarStoragePath(String storagePath) async {}

  @override
  Future<UserDisplayPreferences?> loadMyDisplayPreferences() async => null;

  @override
  Future<void> updateMyDisplayPreferences(
    UserDisplayPreferences preferences,
  ) async {}
}

void main() {
  tearDown(() {
    AuthSession.clear();
    TenantSettingsRepositoryProvider.testOverride = null;
    ProfileSettingsRepositoryProvider.testOverride = null;
    PatientTagRepositoryProvider.testOverride = null;
  });

  AppUser doctor() => AppUser(
        id: 'u-doctor',
        username: 'doctor',
        displayName: 'Dr. Test',
        role: AppRoles.doctor,
      );

  AppUser assistant() => AppUser(
        id: 'u-assistant',
        username: 'assistant',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      );

  Future<void> pumpRoute(
    WidgetTester tester, {
    required String path,
    required Widget screen,
    required AppUser user,
  }) async {
    AuthSession.setUser(user);
    TenantSettingsRepositoryProvider.testOverride =
        _FakeTenantSettingsRepository();
    ProfileSettingsRepositoryProvider.testOverride =
        _FakeProfileSettingsRepository();
    PatientTagRepositoryProvider.testOverride = const MockPatientTagRepository();

    final router = GoRouter(
      initialLocation: path,
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: path,
          builder: (context, state) => screen,
        ),
        GoRoute(
          path: '/lab-order-templates/catalog-settings',
          builder: (context, state) =>
              const Scaffold(body: Text('Lab katalog ayarları')),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('Settings subpage smoke', () {
    testWidgets('profile settings loads for staff', (tester) async {
      await pumpRoute(
        tester,
        path: '/settings/profile',
        screen: const ProfileSettingsScreen(),
        user: assistant(),
      );

      expect(find.text('Profil Bilgileri'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
      expect(find.text('doctor@test.local'), findsOneWidget);
    });

    testWidgets('clinic settings loads for doctor', (tester) async {
      await pumpRoute(
        tester,
        path: '/settings/clinic',
        screen: const ClinicSettingsScreen(),
        user: doctor(),
      );

      expect(find.text('Klinik Bilgileri'), findsOneWidget);
      expect(find.text('Test Klinik'), findsWidgets);
      expect(find.text('PDF üst bilgi önizleme'), findsOneWidget);
    });

    testWidgets('patient settings loads with lab catalog link', (tester) async {
      await pumpRoute(
        tester,
        path: '/settings/patient-settings',
        screen: const PatientSettingsScreen(),
        user: doctor(),
      );

      expect(find.text('Hasta Ayarları'), findsOneWidget);
      expect(find.text('Hasta etiketleri'), findsOneWidget);
      expect(find.text('Lab istem kataloğu'), findsOneWidget);
    });

    testWidgets('system security shows full page for doctor', (tester) async {
      await pumpRoute(
        tester,
        path: '/settings/system-security',
        screen: const SystemSecuritySettingsScreen(),
        user: doctor(),
      );

      expect(find.text('Sistem ve Güvenlik'), findsOneWidget);
      expect(find.text('KVKK'), findsOneWidget);
      expect(find.text('Oturum güvenliği'), findsOneWidget);
    });

    testWidgets('system security shows password-only page for assistant', (
      tester,
    ) async {
      await pumpRoute(
        tester,
        path: '/settings/system-security',
        screen: const SystemSecuritySettingsScreen(),
        user: assistant(),
      );

      expect(find.text('Şifre İşlemleri'), findsOneWidget);
      expect(find.text('Hesap güvenliği'), findsOneWidget);
      expect(find.text('KVKK'), findsNothing);
    });

    testWidgets('demo usage settings loads for doctor', (tester) async {
      await pumpRoute(
        tester,
        path: '/settings/demo-usage',
        screen: const DemoUsageSettingsScreen(),
        user: doctor(),
      );

      expect(find.text('Demo / Kullanım Durumu'), findsOneWidget);
      expect(find.text('Backend'), findsOneWidget);
      expect(find.text('Aktif rol'), findsOneWidget);
    });

    testWidgets('clinic finance statistics loads for doctor', (tester) async {
      await pumpRoute(
        tester,
        path: '/settings/clinic-finance',
        screen: const ClinicFinanceStatisticsScreen(),
        user: doctor(),
      );

      expect(find.text('Finansal İstatistikler'), findsOneWidget);
      expect(find.text('Aylık'), findsOneWidget);
      expect(find.text('Yıllık'), findsOneWidget);
    });
  });
}
