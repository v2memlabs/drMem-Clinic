import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class MessagePreviewDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String channel,
    required String phone,
    required String email,
    required String content,
    required bool confirmSend,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _MessagePreviewDialogBody(
        channel: channel,
        phone: phone,
        email: email,
        content: content,
        confirmSend: confirmSend,
      ),
    );
  }
}

class _MessagePreviewDialogBody extends StatelessWidget {
  final String channel;
  final String phone;
  final String email;
  final String content;
  final bool confirmSend;

  const _MessagePreviewDialogBody({
    required this.channel,
    required this.phone,
    required this.email,
    required this.content,
    required this.confirmSend,
  });

  String get _recipientLabel {
    if (channel == 'E-posta') {
      return email.trim().isEmpty ? '—' : email.trim();
    }
    return phone.trim().isEmpty ? '—' : phone.trim();
  }

  void _copyContent(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mesaj içeriği panoya kopyalandı.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(confirmSend ? 'Gönderimi Onayla' : 'Mesaj Önizleme'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PreviewRow(label: 'Kanal', value: channel),
            _PreviewRow(label: 'Alıcı', value: _recipientLabel),
            const SizedBox(height: 12),
            Text(
              'İçerik',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(content),
            ),
            if (confirmSend) ...[
              const SizedBox(height: 12),
              Text(
                'Onayladığınızda ilgili uygulama (WhatsApp, SMS veya e-posta) açılacak ve gönderim kaydı oluşturulacaktır.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Kapat'),
        ),
        OutlinedButton(
          onPressed: () => _copyContent(context),
          child: const Text('Kopyala'),
        ),
        if (confirmSend)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kanalda Aç ve Kaydet'),
          ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
