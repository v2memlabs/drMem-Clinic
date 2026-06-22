import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readSettingsImageBytesFromPath(String? path) async {
  final trimmed = path?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  final file = File(trimmed);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}
