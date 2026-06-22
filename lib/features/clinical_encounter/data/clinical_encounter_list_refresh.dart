/// Muayene listesi / hasta detay önizlemesi — form sonrası yenileme işareti.
abstract final class ClinicalEncounterListRefresh {
  static int _version = 0;

  static int get version => _version;

  static void markStale() => _version++;

  static bool isStale(int lastSeenVersion) => version != lastSeenVersion;
}
