/// Onam şablon listesi — form/create sonrası yenileme işareti.
abstract final class ConsentTemplateListRefresh {
  static int _version = 0;

  static int get version => _version;

  static void markStale() => _version++;

  static bool isStale(int lastSeenVersion) => version != lastSeenVersion;
}
