import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import 'clinic_finance_statistics_screen.dart';

/// Ayarlar hub kategori tanımı.
class SettingsCategoryDef {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String routePath;
  final bool Function() isVisible;

  const SettingsCategoryDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.routePath,
    required this.isVisible,
  });
}

abstract final class SettingsCategories {
  static const String hubPath = '/settings';

  static List<SettingsCategoryDef> visibleForCurrentUser() =>
      buildAll().where((c) => c.isVisible()).toList(growable: false);

  static List<SettingsCategoryDef> buildAll() => [
        SettingsCategoryDef(
          id: 'profile',
          title: 'Profil Bilgileri',
          description: 'Fotoğraf, iletişim ve rol bilgileriniz',
          icon: Icons.person_outline,
          routePath: '/settings/profile',
          isVisible: () => AuthSession.canViewSettings,
        ),
        SettingsCategoryDef(
          id: 'clinic',
          title: 'Klinik Bilgileri',
          description: 'Klinik adı, logo ve iletişim bilgileri',
          icon: Icons.local_hospital_outlined,
          routePath: '/settings/clinic',
          isVisible: () => AuthSession.canViewDoctorOnlySettings,
        ),
        SettingsCategoryDef(
          id: 'display-region',
          title: 'Görünüm ve Bölge',
          description: 'Kişisel tema/dil ve klinik bölge tercihleri',
          icon: Icons.tune_outlined,
          routePath: '/settings/display-region',
          isVisible: () => AuthSession.canViewSettings,
        ),
        SettingsCategoryDef(
          id: 'patient-settings',
          title: 'Hasta Ayarları',
          description: 'Etiketler, dosya no ve kimlik tipleri',
          icon: Icons.badge_outlined,
          routePath: '/settings/patient-settings',
          isVisible: () => AuthSession.canViewDoctorOnlySettings,
        ),
        SettingsCategoryDef(
          id: 'users-roles',
          title: 'Kullanıcılar ve Roller',
          description: 'Klinik kullanıcıları ve rol atamaları',
          icon: Icons.group_outlined,
          routePath: '/settings/users-roles',
          isVisible: () => AuthSession.canEditClinicProfile,
        ),
        SettingsCategoryDef(
          id: 'system-security',
          title: AuthSession.canViewDoctorOnlySettings
              ? 'Sistem ve Güvenlik'
              : 'Şifre İşlemleri',
          description: AuthSession.canViewDoctorOnlySettings
              ? 'KVKK, oturum güvenliği ve uygulama bilgisi'
              : 'Şifre değiştirme ve sıfırlama',
          icon: AuthSession.canViewDoctorOnlySettings
              ? Icons.shield_outlined
              : Icons.lock_outline,
          routePath: '/settings/system-security',
          isVisible: () => AuthSession.canViewSettings,
        ),
        SettingsCategoryDef(
          id: 'clinic-finance',
          title: 'Finansal İstatistikler',
          description: 'Aylık/yıllık ciro, tahsilat ve hasta özetleri',
          icon: Icons.insights_outlined,
          routePath: '/settings/clinic-finance',
          isVisible: clinicFinanceStatisticsVisible,
        ),
        SettingsCategoryDef(
          id: 'demo-usage',
          title: 'Demo / Kullanım Durumu',
          description: 'Demo modu, backend ve kullanım özeti',
          icon: Icons.science_outlined,
          routePath: '/settings/demo-usage',
          isVisible: () => AuthSession.canViewDoctorOnlySettings,
        ),
        SettingsCategoryDef(
          id: 'subscription',
          title: 'SaaS / Abonelik',
          description: 'Plan durumu, koltuk ve kullanım özeti',
          icon: Icons.workspace_premium_outlined,
          routePath: '/settings/subscription',
          isVisible: () => AuthSession.canViewDoctorOnlySettings,
        ),
      ];
}
