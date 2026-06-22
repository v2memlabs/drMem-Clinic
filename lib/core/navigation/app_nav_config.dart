import 'package:flutter/material.dart';
import '../auth/auth_session.dart';
import '../../features/clinical_encounter/data/clinical_summary_module_availability.dart';

class AppNavItem {
  final String label;
  final IconData icon;
  final String route;
  final bool Function() visible;

  const AppNavItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.visible,
  });
}

class AppNavSection {
  final String title;
  final List<AppNavItem> items;

  /// Grup başlığı gösterilmez; öğeler doğrudan listelenir.
  final bool hideTitle;

  /// Üstte ince ayırıcı (sidebar).
  final bool dividerBefore;

  const AppNavSection({
    this.title = '',
    required this.items,
    this.hideTitle = false,
    this.dividerBefore = false,
  });

  /// Daraltma durumu anahtarı — başlıksız bölümlerde ilk route.
  String get expansionKey =>
      hideTitle && items.isNotEmpty ? items.first.route : title;
}

AppNavItem? buildAppNavDashboardItem() {
  if (AuthSession.canAccessDoctorDashboard) {
    return AppNavItem(
      label: 'Ana Ekran',
      icon: Icons.dashboard,
      route: '/doctor',
      visible: _alwaysVisible,
    );
  }
  if (AuthSession.canAccessAssistantDashboard) {
    return AppNavItem(
      label: 'Ana Ekran',
      icon: Icons.dashboard,
      route: '/assistant',
      visible: _alwaysVisible,
    );
  }
  if (AuthSession.canAccessPhysioDashboard) {
    return AppNavItem(
      label: 'Ana Ekran',
      icon: Icons.dashboard,
      route: '/physio',
      visible: _alwaysVisible,
    );
  }
  if (AuthSession.canAccessNurseDashboard) {
    return AppNavItem(
      label: 'Ana Ekran',
      icon: Icons.dashboard,
      route: '/nurse',
      visible: _alwaysVisible,
    );
  }
  return null;
}

bool _alwaysVisible() => true;

List<AppNavSection> buildAppNavSections() {
  if (AuthSession.canAccessDoctorDashboard) {
    return _filterSections(_doctorSections());
  }
  if (AuthSession.canAccessAssistantDashboard) {
    return _filterSections(_assistantSections());
  }
  if (AuthSession.canAccessPhysioDashboard) {
    return _filterSections(_physioSections());
  }
  if (AuthSession.canAccessNurseDashboard) {
    return _filterSections(_nurseSections());
  }
  return [];
}

/// Görünür menü route'ları (test / smoke).
List<String> visibleNavRoutes() {
  final routes = <String>[];
  final dashboard = buildAppNavDashboardItem();
  if (dashboard != null && dashboard.visible()) {
    routes.add(dashboard.route);
  }
  for (final section in buildAppNavSections()) {
    for (final item in section.items) {
      if (item.visible()) routes.add(item.route);
    }
  }
  return routes;
}

List<AppNavSection> _filterSections(List<AppNavSection> sections) {
  return sections
      .map((section) {
        final visibleItems = section.items.where((item) => item.visible()).toList();
        if (visibleItems.isEmpty) return null;
        return AppNavSection(
          title: section.title,
          items: visibleItems,
          hideTitle: section.hideTitle,
          dividerBefore: section.dividerBefore,
        );
      })
      .whereType<AppNavSection>()
      .toList();
}

List<AppNavItem> _klinikNavItems() => [
      AppNavItem(
        label: 'İzin Talebi',
        icon: Icons.event_busy_outlined,
        route: '/staff-leave-requests',
        visible: () => AuthSession.canRequestStaffLeave,
      ),
      AppNavItem(
        label: 'Ödeme / Tahsilat',
        icon: Icons.payments,
        route: '/payments',
        visible: () => AuthSession.canViewPayments,
      ),
      AppNavItem(
        label: 'Stok / Sarf',
        icon: Icons.inventory_2,
        route: '/inventory',
        visible: () => AuthSession.canViewInventory,
      ),
      AppNavItem(
        label: 'Klinik İşleyiş',
        icon: Icons.schedule_outlined,
        route: '/clinic-workflow',
        visible: () => AuthSession.canViewSettings,
      ),
      AppNavItem(
        label: 'Personel İzinleri',
        icon: Icons.beach_access_outlined,
        route: '/staff-leaves',
        visible: () => AuthSession.canViewSettings,
      ),
    ];

List<AppNavItem> _yonlendirmeIstemNavItems({bool includeFtr = false}) => [
      if (includeFtr)
        AppNavItem(
          label: 'FTR Yönlendirme',
          icon: Icons.person_search,
          route: '/physiotherapy/referrals',
          visible: () => AuthSession.canViewPhysiotherapy,
        ),
      AppNavItem(
        label: 'Radyoloji İstemleri',
        icon: Icons.radar_outlined,
        route: '/radiology-orders',
        visible: () => AuthSession.canViewRadiologyOrders,
      ),
      AppNavItem(
        label: 'Laboratuvar İstemleri',
        icon: Icons.biotech_outlined,
        route: '/lab-orders',
        visible: () => AuthSession.canViewLabOrders,
      ),
    ];

List<AppNavSection> _yonlendirmeIstemSection({bool includeFtr = false}) {
  final items = _yonlendirmeIstemNavItems(includeFtr: includeFtr)
      .where((item) => item.visible())
      .toList();
  if (items.isEmpty) return const <AppNavSection>[];
  return [
    AppNavSection(
      title: 'Yönlendirme / İstem',
      dividerBefore: true,
      items: items,
    ),
  ];
}

List<AppNavItem> _belgelerNavItems({required bool doctorDocuments}) => [
      if (doctorDocuments)
        AppNavItem(
          label: 'Reçeteler',
          icon: Icons.medication_outlined,
          route: '/prescriptions',
          visible: () => AuthSession.canViewPrescriptions,
        ),
      if (doctorDocuments)
        AppNavItem(
          label: 'Raporlar',
          icon: Icons.description_outlined,
          route: '/clinical-reports',
          visible: () => AuthSession.canViewClinicalReports,
        ),
      AppNavItem(
        label: 'Dosyalar',
        icon: Icons.folder,
        route: '/files',
        visible: () => AuthSession.canViewFiles,
      ),
      AppNavItem(
        label: 'KVKK / Onam',
        icon: Icons.shield,
        route: '/consents',
        visible: () => AuthSession.canViewConsents,
      ),
      if (doctorDocuments)
        AppNavItem(
          label: 'PDF Çıktıları',
          icon: Icons.picture_as_pdf_outlined,
          route: '/pdf-outputs',
          visible: () => AuthSession.canViewPdfOutputs,
        ),
    ];

List<AppNavSection> _doctorSections() {
  return [
    AppNavSection(
      hideTitle: true,
      items: [
        AppNavItem(
          label: 'Hastalar',
          icon: Icons.people,
          route: '/patients',
          visible: () => AuthSession.canViewPatients,
        ),
        AppNavItem(
          label: 'Randevular',
          icon: Icons.calendar_today,
          route: '/appointments',
          visible: () => AuthSession.canViewAppointments,
        ),
        AppNavItem(
          label: 'Muayene',
          icon: Icons.medical_information,
          route: '/clinical-records',
          visible: () => AuthSession.canViewClinicalEncounters,
        ),
        AppNavItem(
          label: 'Ameliyat / İşlem',
          icon: Icons.medical_services_outlined,
          route: '/surgery-notes',
          visible: () => AuthSession.canViewSurgeryNotes,
        ),
        AppNavItem(
          label: 'Post-op Takip',
          icon: Icons.assignment_turned_in_outlined,
          route: '/post-op-protocols',
          visible: () => AuthSession.canViewPostOpProtocols,
        ),
      ],
    ),
    ..._yonlendirmeIstemSection(includeFtr: true),
    AppNavSection(
      title: 'Klinik',
      dividerBefore: true,
      items: _klinikNavItems(),
    ),
    AppNavSection(
      title: 'Belgeler',
      items: _belgelerNavItems(doctorDocuments: true),
    ),
    AppNavSection(
      title: 'Sistem',
      items: [
        AppNavItem(
          label: 'Denetim Kayıtları',
          icon: Icons.history,
          route: '/audit-logs',
          visible: () => AuthSession.canViewAuditLogs,
        ),
        AppNavItem(
          label: 'Ayarlar',
          icon: Icons.settings,
          route: '/settings',
          visible: () => AuthSession.isLoggedIn,
        ),
      ],
    ),
  ];
}

List<AppNavSection> _assistantSections() {
  return [
    AppNavSection(
      hideTitle: true,
      items: [
        AppNavItem(
          label: 'Hastalar',
          icon: Icons.people,
          route: '/patients',
          visible: () => AuthSession.canViewPatients,
        ),
        AppNavItem(
          label: 'Randevular',
          icon: Icons.calendar_today,
          route: '/appointments',
          visible: () => AuthSession.canViewAppointments,
        ),
        AppNavItem(
          label: 'Ön tanı/Tanı özeti',
          icon: Icons.healing,
          route: '/clinical-records/diagnosis-summary',
          visible: () =>
              AuthSession.canViewClinicalDiagnosisSummary &&
              ClinicalSummaryModuleAvailability.assistantOperational,
        ),
      ],
    ),
    ..._yonlendirmeIstemSection(),
    AppNavSection(
      title: 'Klinik',
      dividerBefore: true,
      items: _klinikNavItems(),
    ),
    AppNavSection(
      title: 'Belgeler',
      items: _belgelerNavItems(doctorDocuments: false),
    ),
    AppNavSection(
      hideTitle: true,
      dividerBefore: true,
      items: [
        AppNavItem(
          label: 'Ayarlar',
          icon: Icons.settings,
          route: '/settings',
          visible: () => AuthSession.isLoggedIn,
        ),
      ],
    ),
  ];
}

List<AppNavSection> _physioSections() {
  return [
    AppNavSection(
      hideTitle: true,
      items: [
        AppNavItem(
          label: 'Hastalar',
          icon: Icons.people,
          route: '/patients',
          visible: () => AuthSession.canViewPatients,
        ),
        AppNavItem(
          label: 'Randevular',
          icon: Icons.calendar_today,
          route: '/appointments',
          visible: () => AuthSession.canViewAppointments,
        ),
        AppNavItem(
          label: 'Klinik Özetler',
          icon: Icons.medical_information_outlined,
          route: '/physiotherapy/clinical-summaries',
          visible: () =>
              AuthSession.canViewClinicalSummary &&
              ClinicalSummaryModuleAvailability.physiotherapistOperational,
        ),
        AppNavItem(
          label: 'Yönlendirmeler',
          icon: Icons.person_search,
          route: '/physiotherapy/referrals',
          visible: () => AuthSession.canViewPhysiotherapy,
        ),
        AppNavItem(
          label: 'Seanslar',
          icon: Icons.note_alt,
          route: '/physiotherapy/sessions',
          visible: () => AuthSession.canViewPhysiotherapy,
        ),
        AppNavItem(
          label: 'Egzersiz',
          icon: Icons.fitness_center,
          route: '/exercise-plans',
          visible: () => AuthSession.canViewExercisePlans,
        ),
        AppNavItem(
          label: 'Post-op',
          icon: Icons.assignment_turned_in,
          route: '/post-op-protocols',
          visible: () => AuthSession.canViewPostOpProtocols,
        ),
      ],
    ),
    AppNavSection(
      hideTitle: true,
      dividerBefore: true,
      items: [
        AppNavItem(
          label: 'Ödeme / Tahsilat',
          icon: Icons.payments,
          route: '/payments',
          visible: () => AuthSession.canViewPayments,
        ),
        AppNavItem(
          label: 'İzin Talebi',
          icon: Icons.event_busy_outlined,
          route: '/staff-leave-requests',
          visible: () => AuthSession.canRequestStaffLeave,
        ),
        AppNavItem(
          label: 'Ayarlar',
          icon: Icons.settings,
          route: '/settings',
          visible: () => AuthSession.isLoggedIn,
        ),
      ],
    ),
  ];
}

List<AppNavSection> _nurseSections() {
  return [
    AppNavSection(
      hideTitle: true,
      items: [
        AppNavItem(
          label: 'Hastalar',
          icon: Icons.people,
          route: '/patients',
          visible: () => AuthSession.canViewPatients,
        ),
        AppNavItem(
          label: 'Randevular',
          icon: Icons.calendar_today,
          route: '/appointments',
          visible: () => AuthSession.canViewAppointments,
        ),
      ],
    ),
    ..._yonlendirmeIstemSection(),
    AppNavSection(
      title: 'Klinik',
      dividerBefore: true,
      items: _klinikNavItems(),
    ),
    AppNavSection(
      hideTitle: true,
      dividerBefore: true,
      items: [
        AppNavItem(
          label: 'Ayarlar',
          icon: Icons.settings,
          route: '/settings',
          visible: () => AuthSession.isLoggedIn,
        ),
      ],
    ),
  ];
}

/// Görünür bölüm başlıkları (test).
List<String> visibleNavSectionTitles() {
  return buildAppNavSections()
      .where((s) => !s.hideTitle && s.title.trim().isNotEmpty)
      .map((s) => s.title)
      .toList();
}

/// Görünür menü etiketleri (test).
List<String> visibleNavLabels() {
  final labels = <String>[];
  for (final section in buildAppNavSections()) {
    for (final item in section.items) {
      if (item.visible()) labels.add(item.label);
    }
  }
  return labels;
}

bool isNavSectionActive(String location, AppNavSection section) {
  return section.items.any((item) => isNavItemActive(location, item));
}

bool isNavItemActive(String location, AppNavItem item) {
  final currentPath = Uri.parse(location).path;
  final itemPath = Uri.parse(item.route).path;

  if (currentPath == itemPath) return true;

  if (itemPath == '/doctor' ||
      itemPath == '/assistant' ||
      itemPath == '/physio' ||
      itemPath == '/nurse') {
    return currentPath == itemPath;
  }

  if (currentPath.startsWith('$itemPath/')) return true;

  if (itemPath == '/messages/templates') {
    return currentPath.startsWith('/messages');
  }
  if (itemPath == '/messages/send') {
    return currentPath.startsWith('/messages/send') || currentPath.startsWith('/messages/sent');
  }
  if (itemPath == '/clinical-records/diagnosis-summary') {
    return currentPath.startsWith('/clinical-records/diagnosis-summary');
  }
  if (itemPath == '/clinical-records') {
    return currentPath.startsWith('/clinical-records') &&
        !currentPath.startsWith('/clinical-records/diagnosis-summary');
  }
  if (itemPath == '/clinic-workflow') {
    return currentPath == '/clinic-workflow' ||
        currentPath == '/settings/clinic-workflow';
  }
  if (itemPath == '/staff-leave-requests') {
    return currentPath == '/staff-leave-requests';
  }
  if (itemPath == '/staff-leaves') {
    return currentPath == '/staff-leaves' ||
        currentPath == '/settings/clinic-workflow/staff-leaves';
  }

  return false;
}
