/// Oturum içi dashboard uyarıları — tıklanan / okunan bildirimler.
abstract final class DashboardNotificationDismissals {
  static final Set<String> _dismissedEntryIds = {};

  static bool isActive(String entryId) =>
      entryId.isNotEmpty && !_dismissedEntryIds.contains(entryId);

  static void dismiss(String entryId) {
    if (entryId.isEmpty) return;
    _dismissedEntryIds.add(entryId);
  }

  static void dismissAll(Iterable<String> entryIds) {
    for (final id in entryIds) {
      dismiss(id);
    }
  }

  static void reset() => _dismissedEntryIds.clear();
}
