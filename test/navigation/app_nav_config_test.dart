import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/navigation/app_nav_config.dart';
import 'package:v2mem_clinic/features/settings/settings_product_labels.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  AppUser user(String role) => AppUser(
        id: 'u-$role',
        username: role,
        displayName: 'Test',
        role: role,
      );

  group('Doctor sidebar IA polish', () {
    setUp(() => AuthSession.setUser(user(AppRoles.doctor)));

    test('has Klinik and Belgeler sections', () {
      final titles = visibleNavSectionTitles();
      expect(titles, containsAll([
        'Yönlendirme / İstem',
        'Klinik',
        'Belgeler',
        'Sistem',
      ]));
      expect(titles, isNot(contains('Operasyon')));
    });

    test('core clinical labels and routes', () {
      final labels = visibleNavLabels();
      final routes = visibleNavRoutes();
      expect(labels, containsAll([
        'Hastalar',
        'Randevular',
        'Muayene',
        'Ameliyat / İşlem',
        'Post-op Takip',
      ]));
      expect(labels, isNot(contains('Muayene Kayıtları')));
      expect(routes, containsAll([
        '/patients',
        '/appointments',
        '/clinical-records',
        '/surgery-notes',
        '/post-op-protocols',
      ]));
    });

    test('single FTR referral entry without detail modules', () {
      final labels = visibleNavLabels();
      final routes = visibleNavRoutes();
      expect(labels, contains('FTR Yönlendirme'));
      expect(labels, isNot(contains('Fizyoterapi Seansları')));
      expect(labels, isNot(contains('Egzersiz Programları')));
      expect(routes, contains('/physiotherapy/referrals'));
      expect(routes, isNot(contains('/physiotherapy/sessions')));
      expect(routes, isNot(contains('/exercise-plans')));
      expect(routes, isNot(contains('/physiotherapy/clinical-summaries')));
    });

    test('excludes timeline, tags, alerts, archive', () {
      final routes = visibleNavRoutes();
      expect(routes, isNot(contains('/patient-timeline')));
      expect(routes, isNot(contains('/patient-tags')));
      expect(routes, isNot(contains('/patient-alerts')));
      expect(routes, isNot(contains('/anamnesis')));
      expect(routes, isNot(contains('/examinations')));
      expect(routes, isNot(contains('/diagnoses')));
      expect(routes, isNot(contains('/treatment-plans')));
      expect(routes, isNot(contains('/imaging')));
    });

    test('includes belgeler, klinik and system items', () {
      final labels = visibleNavLabels();
      final routes = visibleNavRoutes();
      expect(routes, contains('/doctor'));
      expect(routes, contains('/files'));
      expect(routes, contains('/audit-logs'));
      expect(routes, contains('/settings'));
      expect(routes, contains('/pdf-outputs'));
      expect(routes, contains('/clinic-workflow'));
      expect(routes, contains('/staff-leaves'));
      expect(labels, containsAll([
        'Ödeme / Tahsilat',
        'Stok / Sarf',
        'Klinik İşleyiş',
        'Personel İzinleri',
        'Reçeteler',
        'Raporlar',
        'KVKK / Onam',
        'PDF Çıktıları',
      ]));
    });
  });

  group('Assistant sidebar cleanup', () {
    setUp(() => AuthSession.setUser(user(AppRoles.assistant)));

    test('excludes timeline, tags, alerts, audit, full clinical', () {
      final routes = visibleNavRoutes();
      expect(routes, isNot(contains('/patient-timeline')));
      expect(routes, isNot(contains('/patient-tags')));
      expect(routes, isNot(contains('/patient-alerts')));
      expect(routes, isNot(contains('/audit-logs')));
      expect(routes, isNot(contains('/clinical-records')));
    });

    test('includes diagnosis summary and settings', () {
      final routes = visibleNavRoutes();
      expect(routes, contains('/clinical-records/diagnosis-summary'));
      expect(routes, contains('/settings'));
    });
  });

  group('Physio sidebar FTR detail', () {
    setUp(() => AuthSession.setUser(user(AppRoles.physiotherapist)));

    test('includes simplified FTR labels', () {
      final labels = visibleNavLabels();
      expect(labels, containsAll([
        'Yönlendirmeler',
        'Seanslar',
        'Egzersiz',
      ]));
    });

    test('excludes patient tags and full clinical encounter', () {
      final routes = visibleNavRoutes();
      expect(routes, isNot(contains('/patient-tags')));
      expect(routes, isNot(contains('/clinical-records')));
      expect(routes, contains('/physiotherapy/clinical-summaries'));
      expect(routes, contains('/physiotherapy/referrals'));
      expect(routes, contains('/physiotherapy/sessions'));
      expect(routes, contains('/exercise-plans'));
    });
  });

  group('Nurse sidebar', () {
    setUp(() => AuthSession.setUser(user(AppRoles.nurse)));

    test('excludes timeline, audit, files, full clinical', () {
      final routes = visibleNavRoutes();
      expect(routes, isNot(contains('/patient-timeline')));
      expect(routes, isNot(contains('/audit-logs')));
      expect(routes, isNot(contains('/files')));
      expect(routes, isNot(contains('/clinical-records')));
    });

    test('keeps inventory focus', () {
      final labels = visibleNavLabels();
      expect(labels, contains('Stok / Sarf'));
    });
  });

  group('Role product labels', () {
    test('doctor label is Doktor without Admin', () {
      final label = SettingsProductLabels.roleLabel(AppRoles.doctor);
      expect(label, 'Doktor');
      expect(label.toLowerCase(), isNot(contains('admin')));
    });
  });
}
