/// Dashboard quick action — sidebar ile bilinçli örtüşen rotalar.
///
/// Whitelist dışındaki sidebar route'ları dashboard quick action'da
/// tekrarlanmamalı (modül launcher hissini önlemek için).
abstract final class DashboardIntentionalQuickRoutes {
  static const doctor = <String>[
    '/pdf-outputs',
  ];

  static const assistant = <String>[
    '/consents',
    '/payments',
    '/files/upload',
  ];

  static const createRoutes = <String>[
    '/clinical-records/new',
    '/appointments/new',
  ];

  static bool isIntentionalOverlap(String route) {
    return doctor.contains(route) ||
        assistant.contains(route) ||
        createRoutes.contains(route);
  }
}
