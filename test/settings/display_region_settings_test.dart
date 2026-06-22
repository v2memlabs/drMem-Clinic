import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/settings/app_settings.dart';
import 'package:v2mem_clinic/core/settings/app_settings_controller.dart';
import 'package:v2mem_clinic/features/settings/data/profile_settings_repository_provider.dart';
import 'package:v2mem_clinic/features/lab_orders/models/lab_order_catalog_settings.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_settings_repository.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_settings_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/display_region_settings_screen.dart';
import 'package:v2mem_clinic/features/settings/models/patient_registration_settings.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_financial_feature_settings.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_preferences.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_role_access_settings.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_security_settings.dart';
import 'package:v2mem_clinic/features/settings/models/user_display_preferences.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _FakeTenantPrefsRepository implements TenantSettingsRepository {
  TenantPreferences preferences = TenantPreferences.defaults;
  PatientRegistrationSettings patientRegistrationSettings =
      const PatientRegistrationSettings();
  TenantSecuritySettings securitySettings = TenantSecuritySettings.defaults;

  @override
  Future<TenantBasicInfo> loadBasicInfo() async =>
      const TenantBasicInfo(name: 'Klinik');

  @override
  Future<void> updateBasicInfo({
    required String name,
    required String specialty,
    required String timezone,
    required TenantContactInfo contact,
  }) async {}

  @override
  Future<TenantPreferences> loadPreferences() async => preferences;

  @override
  Future<void> updatePreferences(TenantPreferences preferences) async {
    if (!AuthSession.canEditClinicProfile) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Bu işlem için yetkiniz yok.',
      );
    }
    this.preferences = preferences;
  }

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
  ) async {
    if (!AuthSession.canEditClinicProfile) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Bu işlem için yetkiniz yok.',
      );
    }
    patientRegistrationSettings = settings;
  }

  @override
  Future<TenantSecuritySettings> loadSecuritySettings() async {
    return securitySettings;
  }

  @override
  Future<void> updateSecuritySettings(TenantSecuritySettings settings) async {
    if (!AuthSession.canEditClinicProfile) {
      throw const TenantSettingsRepositoryException(
        TenantSettingsFailure.forbidden,
        'Bu işlem için yetkiniz yok.',
      );
    }
    securitySettings = settings;
  }

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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TenantSettingsRepositoryProvider.testOverride = null;
    ProfileSettingsRepositoryProvider.testOverride = null;
    AuthSession.clear();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/settings/display-region',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/settings/display-region',
          builder: (context, state) => const DisplayRegionSettingsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  testWidgets('doctor sees personal and clinic sections with save', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'p1',
        username: 'd@test.local',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );
    TenantSettingsRepositoryProvider.testOverride = _FakeTenantPrefsRepository();

    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpScreen(tester);

    expect(find.text('Kişisel görünüm'), findsOneWidget);
    expect(find.text('Klinik bölge ayarları'), findsOneWidget);
    expect(find.text('Kaydet'), findsOneWidget);
    expect(find.text(DateTimeFormatKind.longTurkish.label), findsOneWidget);
  });

  testWidgets('assistant can save personal display preferences', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'p2',
        username: 'a@test.local',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );
    TenantSettingsRepositoryProvider.testOverride = _FakeTenantPrefsRepository();

    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpScreen(tester);

    expect(find.text('Kaydet'), findsOneWidget);
    expect(
      find.textContaining('yalnızca doktor hesabı tarafından değiştirilebilir'),
      findsOneWidget,
    );
    expect(
      find.text('Görünüm tercihlerini yalnızca doktor hesabı değiştirebilir.'),
      findsNothing,
    );

    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(
      appSettingsController.settings.themeMode,
      AppThemeModeKind.dark,
    );
  });

  test('applyUserDisplayPreferences updates controller format', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await appSettingsController.applyUserDisplayPreferences(
      const UserDisplayPreferences(
        dateTimeFormat: DateTimeFormatKind.iso,
        timeFormat: TimeFormatKind.hour12,
        themeMode: AppThemeModeKind.dark,
        languageCode: 'en',
      ),
    );
    expect(
      appSettingsController.settings.dateTimeFormat,
      DateTimeFormatKind.iso,
    );
    expect(appSettingsController.settings.timeFormat, TimeFormatKind.hour12);
    expect(appSettingsController.settings.themeMode, AppThemeModeKind.dark);
    expect(appSettingsController.settings.languageCode, 'en');
  });
}
