import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Release/production path must not depend on debug staging asset fallback.
void main() {
  test('DebugEnvAssetLoader skips staging asset outside debug mode', () {
    const loaderPath = 'lib/core/config/debug_env_asset_loader.dart';
    final content = File(loaderPath).readAsStringSync();
    expect(
      content.contains('if (!kDebugMode) return null'),
      isTrue,
      reason: '$loaderPath must guard staging.json with kDebugMode',
    );
  });

  test('needsDebugAssetFallback requires mock backend and empty supabase config',
      () {
    const bootstrapPath = 'lib/core/config/env_runtime_overrides.dart';
    final content = File(bootstrapPath).readAsStringSync();
    expect(
      content.contains('!SupabaseEnvConfig.isSupabaseConfigured'),
      isTrue,
    );
    expect(
      content.contains('AppBackendConfig.activeBackend == DataBackend.mock'),
      isTrue,
    );
  });

  test('AppBackendConfig respects compile-time DATA_BACKEND over runtime map',
      () {
    const backendPath = 'lib/core/data/backend_config.dart';
    final content = File(backendPath).readAsStringSync();
    expect(
      content.contains("String.fromEnvironment('DATA_BACKEND')"),
      isTrue,
      reason: 'Production CI must inject DATA_BACKEND via --dart-define',
    );
    expect(
      content.contains('applyRuntimeBackendOverride'),
      isTrue,
      reason: 'Debug asset override must not win when dart-define is set',
    );
  });

  test('staging.json is not referenced outside debug loader', () {
    const allowedPaths = {
      'lib/core/config/debug_env_asset_loader.dart',
      'pubspec.yaml',
    };
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowedPaths.contains(normalized)) continue;

      final content = entity.readAsStringSync();
      if (content.contains('assets/config/staging.json') ||
          content.contains('staging.json')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'staging.json must only load via DebugEnvAssetLoader: $violations',
    );
  });
}
