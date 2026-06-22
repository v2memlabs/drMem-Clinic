import '../../../core/data/stub_module_availability.dart';
import 'settings_image_storage_repository_provider.dart';

/// Ayarlar görsel storage — mock veya hazır remote oturum.
abstract final class SettingsImageStorageAvailability {
  static bool get isOperational => StubModuleAvailability.isOperational(
        remoteReady: SettingsImageStorageRepositoryProvider.usesRemoteStorage,
      );
}
