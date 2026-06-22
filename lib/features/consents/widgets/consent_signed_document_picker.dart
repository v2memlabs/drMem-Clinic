import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../settings/data/settings_image_bytes_reader.dart';
import '../../settings/data/settings_image_storage_path_builder.dart';

class ConsentSignedDocumentPick {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  const ConsentSignedDocumentPick({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  bool get isPdf => mimeType.toLowerCase() == 'application/pdf';
}

enum _MobilePickSource {
  camera,
  gallery,
  files,
}

/// Islak imzalı evrak — kamera, galeri veya dosya (PDF/görüntü).
abstract final class ConsentSignedDocumentPicker {
  static final ImagePicker _imagePicker = ImagePicker();

  static bool get supportsCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<ConsentSignedDocumentPick?> pick(BuildContext context) async {
    if (supportsCamera) {
      final source = await _pickMobileSource(context);
      if (source == null) return null;
      return switch (source) {
        _MobilePickSource.camera => _fromImagePicker(ImageSource.camera),
        _MobilePickSource.gallery => _fromImagePicker(ImageSource.gallery),
        _MobilePickSource.files => _fromFilePicker(),
      };
    }
    return _fromFilePicker();
  }

  static Future<_MobilePickSource?> _pickMobileSource(BuildContext context) {
    return showModalBottomSheet<_MobilePickSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera ile çek'),
              onTap: () => Navigator.pop(ctx, _MobilePickSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              onTap: () => Navigator.pop(ctx, _MobilePickSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Dosya seç (PDF veya görüntü)'),
              onTap: () => Navigator.pop(ctx, _MobilePickSource.files),
            ),
          ],
        ),
      ),
    );
  }

  static Future<ConsentSignedDocumentPick?> _fromImagePicker(
    ImageSource source,
  ) async {
    final file = await _imagePicker.pickImage(
      source: source,
      maxWidth: 4096,
      maxHeight: 4096,
      imageQuality: 92,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;

    final name = file.name.trim().isNotEmpty ? file.name.trim() : 'imzali.jpg';
    return ConsentSignedDocumentPick(
      bytes: bytes,
      fileName: name,
      mimeType: SettingsImageStoragePathBuilder.mimeFromFileName(name),
    );
  }

  static Future<ConsentSignedDocumentPick?> _fromFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
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

    final name = file.name.trim().isNotEmpty ? file.name.trim() : 'imzali.pdf';
    final mime = _mimeFromFileName(name);
    return ConsentSignedDocumentPick(
      bytes: bytes,
      fileName: name,
      mimeType: mime,
    );
  }

  static String _mimeFromFileName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return SettingsImageStoragePathBuilder.mimeFromFileName(name);
  }
}
