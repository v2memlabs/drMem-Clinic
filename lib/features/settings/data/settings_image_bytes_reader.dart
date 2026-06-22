import 'dart:typed_data';

import 'settings_image_bytes_reader_stub.dart'
    if (dart.library.io) 'settings_image_bytes_reader_io.dart' as impl;

abstract final class SettingsImageBytesReader {
  static Future<Uint8List?> fromPath(String? path) =>
      impl.readSettingsImageBytesFromPath(path);
}
