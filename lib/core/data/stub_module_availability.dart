import 'backend_config.dart';

/// Mock veya hazır remote oturum — stub modül UI/data gate ortak kuralı.
abstract final class StubModuleAvailability {
  static bool isOperational({required bool remoteReady}) =>
      AppBackendConfig.isMock || remoteReady;
}
