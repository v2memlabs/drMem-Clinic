/// Tanı özeti listesi / hasta detay asistan özet — stale işaretleme.
abstract final class AssistantClinicalSummaryListRefresh {
  static int _version = 0;

  static int get version => _version;

  static void markStale() => _version++;

  static bool isStale(int lastSeenVersion) => lastSeenVersion != _version;
}
