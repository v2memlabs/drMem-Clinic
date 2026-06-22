import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../data/settings_image_source_picker.dart';
import '../data/mock_settings_image_storage_repository.dart';
import '../data/settings_image_storage_availability.dart';
import '../data/settings_image_storage_path_builder.dart';
import '../data/settings_image_storage_user_messages.dart';
import '../data/settings_image_upload_service.dart';
import '../settings_widgets.dart';

class SettingsImagePickerTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final double height;
  final SettingsImageKind kind;
  final String? storagePath;
  final bool enabled;
  final ValueChanged<String>? onUploaded;

  const SettingsImagePickerTile({
    super.key,
    required this.label,
    required this.kind,
    this.icon = Icons.image_outlined,
    this.height = 96,
    this.storagePath,
    this.enabled = true,
    this.onUploaded,
  });

  bool get _offerCamera => kind == SettingsImageKind.profileAvatar;

  @override
  State<SettingsImagePickerTile> createState() => _SettingsImagePickerTileState();
}

class _SettingsImagePickerTileState extends State<SettingsImagePickerTile> {
  String? _previewUrl;
  Uint8List? _localPreviewBytes;
  bool _loadingPreview = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _resolvePreview();
  }

  @override
  void didUpdateWidget(SettingsImagePickerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath) {
      _resolvePreview();
    }
  }

  Future<void> _resolvePreview() async {
    final path = widget.storagePath?.trim();
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      setState(() {
        _previewUrl = null;
        _localPreviewBytes = null;
        _loadingPreview = false;
      });
      return;
    }

    setState(() => _loadingPreview = true);

    final bytes = await SettingsImageUploadService.loadPreviewBytes(path);
    final url = bytes == null
        ? await SettingsImageUploadService.signedPreviewUrl(path)
        : null;

    if (!mounted) return;
    setState(() {
      _localPreviewBytes = bytes ??
          (url != null ? MockSettingsImageStorageRepository.bytesForMockUrl(url) : null);
      _previewUrl = url;
      _loadingPreview = false;
    });
  }

  Future<void> _pickAndUpload() async {
    if (!widget.enabled || _uploading) return;
    if (!SettingsImageStorageAvailability.isOperational) return;

    final picked = await SettingsImageSourcePicker.pick(
      context: context,
      offerCamera: widget._offerCamera,
    );
    if (picked == null) return;

    setState(() {
      _uploading = true;
      _localPreviewBytes = picked.bytes;
    });

    try {
      final path = await SettingsImageUploadService.upload(
        kind: widget.kind,
        bytes: picked.bytes,
        mimeType: picked.mimeType,
        originalFileName: picked.fileName,
      );
      if (!mounted) return;
      widget.onUploaded?.call(path);
      await _resolvePreview();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.label} yüklendi.')),
      );
    } on SettingsImageUploadException catch (e) {
      if (!mounted) return;
      setState(() => _localPreviewBytes = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _localPreviewBytes = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yükleme başarısız. Lütfen tekrar deneyin.')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _buildImageContent() {
    if (_loadingPreview || _uploading) {
      return const Center(child: CircularProgressIndicator());
    }

    final local = _localPreviewBytes;
    if (local != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          local,
          fit: BoxFit.cover,
          width: double.infinity,
          height: widget.height,
        ),
      );
    }

    final url = _previewUrl;
    if (url != null && !url.startsWith('drmem-mock://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: widget.height,
          errorBuilder: (_, __, ___) => _placeholderContent(),
        ),
      );
    }

    return _placeholderContent();
  }

  Widget _placeholderContent() {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: muted, size: 32),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storageReady = SettingsImageStorageAvailability.isOperational;
    final canUpload = widget.enabled && storageReady;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.35),
            ),
            child: _buildImageContent(),
          ),
        ),
        if (!storageReady) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            SettingsImageStorageUserMessages.notConfiguredDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        if (canUpload) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: Icon(
                widget._offerCamera ? Icons.add_a_photo_outlined : Icons.upload_outlined,
                size: 18,
              ),
              label: Text(
                widget.storagePath?.trim().isNotEmpty == true
                    ? 'Değiştir'
                    : 'Yükle',
              ),
            ),
          ),
        ],
      ],
    );
  }
}
