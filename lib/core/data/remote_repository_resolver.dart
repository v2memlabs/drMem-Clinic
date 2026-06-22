import 'backend_config.dart';

/// Tri-state repository çözümü: mock / remote / unavailable.
///
/// Supabase modunda gate başarısızsa mock adapter dönülmez.
abstract final class RemoteRepositoryResolver {
  static T resolve<T>({
    required bool remoteReady,
    required T Function() mockFactory,
    required T Function() remoteFactory,
    required T Function() unavailableFactory,
  }) {
    if (AppBackendConfig.isMock) {
      return mockFactory();
    }
    if (remoteReady) {
      return remoteFactory();
    }
    return unavailableFactory();
  }
}
