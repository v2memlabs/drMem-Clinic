import '../../../core/data/stub_module_availability.dart';
import 'timeline_repository_provider.dart';

/// Hasta timeline — mock veya hazır remote oturum.
abstract final class TimelineModuleAvailability {
  static bool get isOperational => StubModuleAvailability.isOperational(
        remoteReady: TimelineRepositoryProvider.usesRemotePatientTimeline,
      );
}
