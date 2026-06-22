/// Stok listesi — form/hareket sonrası yenileme işareti.
abstract final class InventoryListRefresh {
  static int _version = 0;

  static int get version => _version;

  static void markStale() => _version++;

  static bool isStale(int lastSeenVersion) => version != lastSeenVersion;
}
