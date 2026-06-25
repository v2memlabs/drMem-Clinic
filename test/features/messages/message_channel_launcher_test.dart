import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/messages/data/message_channel_launcher.dart';

void main() {
  group('MessageChannelLauncher', () {
    test('normalizePhoneDigits handles TR formats', () {
      expect(
        MessageChannelLauncher.normalizePhoneDigits('0555 123 45 67'),
        '905551234567',
      );
      expect(
        MessageChannelLauncher.normalizePhoneDigits('+90 555 123 45 67'),
        '905551234567',
      );
      expect(
        MessageChannelLauncher.normalizePhoneDigits('5551234567'),
        '905551234567',
      );
      expect(
        MessageChannelLauncher.normalizePhoneDigits('0090 555 123 45 67'),
        '905551234567',
      );
    });

    test('normalizePhoneDigits rejects invalid input', () {
      expect(MessageChannelLauncher.normalizePhoneDigits(''), isNull);
      expect(MessageChannelLauncher.normalizePhoneDigits('abc'), isNull);
      expect(MessageChannelLauncher.normalizePhoneDigits('123'), isNull);
    });

    test('validateRecipient enforces channel-specific contact fields', () {
      expect(
        MessageChannelLauncher.validateRecipient(
          channelLabel: 'WhatsApp',
          phone: '',
          email: '',
        ),
        isNotNull,
      );
      expect(
        MessageChannelLauncher.validateRecipient(
          channelLabel: 'WhatsApp',
          phone: '0555 123 45 67',
          email: '',
        ),
        isNull,
      );
      expect(
        MessageChannelLauncher.validateRecipient(
          channelLabel: 'E-posta',
          phone: '',
          email: '',
        ),
        isNotNull,
      );
      expect(
        MessageChannelLauncher.validateRecipient(
          channelLabel: 'E-posta',
          phone: '',
          email: 'hasta@ornek.com',
        ),
        isNull,
      );
    });

    test('buildLaunchUri builds WhatsApp link', () {
      final uri = MessageChannelLauncher.buildLaunchUri(
        channelLabel: 'WhatsApp',
        phone: '0555 123 45 67',
        email: '',
        body: 'Merhaba Ayşe',
      );

      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/905551234567');
      expect(uri.queryParameters['text'], 'Merhaba Ayşe');
    });

    test('buildLaunchUri builds SMS link', () {
      final uri = MessageChannelLauncher.buildLaunchUri(
        channelLabel: 'SMS',
        phone: '0555 123 45 67',
        email: '',
        body: 'Kontrol randevunuz',
      );

      expect(uri, isNotNull);
      expect(uri!.scheme, 'sms');
      expect(uri.path, '+905551234567');
      expect(uri.queryParameters['body'], 'Kontrol randevunuz');
    });

    test('buildLaunchUri builds mailto link', () {
      final uri = MessageChannelLauncher.buildLaunchUri(
        channelLabel: 'E-posta',
        phone: '',
        email: 'hasta@ornek.com',
        body: 'Bilgilendirme mesajı',
        subject: 'Randevu Hatırlatma',
      );

      expect(uri, isNotNull);
      expect(uri!.scheme, 'mailto');
      expect(uri.path, 'hasta@ornek.com');
      expect(uri.queryParameters['subject'], 'Randevu Hatırlatma');
      expect(uri.queryParameters['body'], 'Bilgilendirme mesajı');
    });
  });
}
