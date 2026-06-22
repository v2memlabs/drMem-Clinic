import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'settings_image_bytes_reader.dart';
import 'settings_image_storage_path_builder.dart';

class SettingsPickedImage {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  const SettingsPickedImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });
}

enum _MobileImageSource {
  camera,
  gallery,
  files,
}

/// Ayarlar görselleri — galeri, kamera (mobil) veya dosya seçici.
abstract final class SettingsImageSourcePicker {
  static final ImagePicker _imagePicker = ImagePicker();

  static bool get supportsCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<SettingsPickedImage?> pick({
    required BuildContext context,
    bool offerCamera = false,
  }) async {
    if (offerCamera && supportsCamera) {
      final source = await _pickMobileSource(context);
      if (source == null) return null;
      return switch (source) {
        _MobileImageSource.camera => _fromImagePicker(ImageSource.camera),
        _MobileImageSource.gallery => _fromImagePicker(ImageSource.gallery),
        _MobileImageSource.files => _fromFilePicker(),
      };
    }
    return _fromFilePicker();
  }

  static Future<_MobileImageSource?> _pickMobileSource(
    BuildContext context,
  ) {
    return showModalBottomSheet<_MobileImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              onTap: () => Navigator.pop(ctx, _MobileImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera ile çek'),
              onTap: () => Navigator.pop(ctx, _MobileImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Dosya seç'),
              onTap: () => Navigator.pop(ctx, _MobileImageSource.files),
            ),
          ],
        ),
      ),
    );
  }

  static Future<SettingsPickedImage?> _fromImagePicker(ImageSource source) async {
    final file = await _imagePicker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;

    final name = file.name.trim().isNotEmpty ? file.name.trim() : 'photo.jpg';
    return SettingsPickedImage(
      bytes: bytes,
      fileName: name,
      mimeType: SettingsImageStoragePathBuilder.mimeFromFileName(name),
    );
  }

  static Future<SettingsPickedImage?> _fromFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    var bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      bytes = await SettingsImageBytesReader.fromPath(file.path);
    }
    if (bytes == null || bytes.isEmpty) return null;

    final name = file.name.trim().isNotEmpty ? file.name.trim() : 'image.jpg';
    return SettingsPickedImage(
      bytes: bytes,
      fileName: name,
      mimeType: SettingsImageStoragePathBuilder.mimeFromFileName(name),
    );
  }
}
