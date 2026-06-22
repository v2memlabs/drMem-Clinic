import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Debug build — `flutter run` ile staging config (dart-define olmadan).
///
/// Release/profile build'de kullanılmaz; production CI `--dart-define` ile beslenir.
abstract final class DebugEnvAssetLoader {
  static const String stagingAssetPath = 'assets/config/staging.json';

  static Future<Map<String, dynamic>?> loadStagingConfig() async {
    if (!kDebugMode) return null;
    try {
      final raw = await rootBundle.loadString(stagingAssetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded;
    } catch (_) {
      return null;
    }
  }
}
