abstract final class PrescriptionListRefresh {
  static int _version = 0;

  static int get version => _version;

  static void markStale() => _version++;

  static bool isStale(int lastSeen) => lastSeen != _version;
}
