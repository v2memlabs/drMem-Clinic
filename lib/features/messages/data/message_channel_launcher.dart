import 'package:url_launcher/url_launcher.dart';

import '../models/message_template.dart';

enum MessageChannelLaunchFailure {
  unsupportedChannel,
  missingPhone,
  invalidPhone,
  missingEmail,
  invalidEmail,
  launchFailed,
}

extension MessageChannelLaunchFailureMessages on MessageChannelLaunchFailure {
  String get userMessage => switch (this) {
        MessageChannelLaunchFailure.unsupportedChannel =>
          'Bu kanal şu an desteklenmiyor.',
        MessageChannelLaunchFailure.missingPhone =>
          'Telefon numarası gerekli.',
        MessageChannelLaunchFailure.invalidPhone =>
          'Geçerli bir telefon numarası girin.',
        MessageChannelLaunchFailure.missingEmail =>
          'E-posta adresi gerekli.',
        MessageChannelLaunchFailure.invalidEmail =>
          'Geçerli bir e-posta adresi girin.',
        MessageChannelLaunchFailure.launchFailed =>
          'Mesaj uygulaması açılamadı. Cihazınızda ilgili uygulama yüklü mü kontrol edin.',
      };
}

abstract final class MessageChannelLauncher {
  static Channel? channelFromLabel(String label) {
    final trimmed = label.trim();
    for (final channel in Channel.values) {
      if (messageChannelLabel(channel) == trimmed) return channel;
    }
    return null;
  }

  static String? validateRecipient({
    required String channelLabel,
    required String phone,
    required String email,
  }) {
    final channel = channelFromLabel(channelLabel);
    if (channel == null) {
      return MessageChannelLaunchFailure.unsupportedChannel.userMessage;
    }

    switch (channel) {
      case Channel.whatsapp:
      case Channel.sms:
        final normalized = normalizePhoneDigits(phone);
        if (phone.trim().isEmpty) {
          return MessageChannelLaunchFailure.missingPhone.userMessage;
        }
        if (normalized == null) {
          return MessageChannelLaunchFailure.invalidPhone.userMessage;
        }
        return null;
      case Channel.email:
        final trimmed = email.trim();
        if (trimmed.isEmpty) {
          return MessageChannelLaunchFailure.missingEmail.userMessage;
        }
        if (!_isValidEmail(trimmed)) {
          return MessageChannelLaunchFailure.invalidEmail.userMessage;
        }
        return null;
    }
  }

  /// TR ve uluslararası numaraları wa.me / sms URI'leri için rakam dizisine çevirir.
  static String? normalizePhoneDigits(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    var digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length == 11) {
      digits = '90${digits.substring(1)}';
    } else if (digits.length == 10 && digits.startsWith('5')) {
      digits = '90$digits';
    }

    if (digits.length < 10 || digits.length > 15) return null;
    return digits;
  }

  static Uri? buildLaunchUri({
    required String channelLabel,
    required String phone,
    required String email,
    required String body,
    String? subject,
  }) {
    final channel = channelFromLabel(channelLabel);
    if (channel == null) return null;

    final encodedBody = Uri.encodeComponent(body.trim());

    switch (channel) {
      case Channel.whatsapp:
        final digits = normalizePhoneDigits(phone);
        if (digits == null || encodedBody.isEmpty) return null;
        return Uri.parse('https://wa.me/$digits?text=$encodedBody');
      case Channel.sms:
        final digits = normalizePhoneDigits(phone);
        if (digits == null || encodedBody.isEmpty) return null;
        return Uri(scheme: 'sms', path: '+$digits', query: 'body=$encodedBody');
      case Channel.email:
        final trimmedEmail = email.trim();
        if (!_isValidEmail(trimmedEmail) || encodedBody.isEmpty) return null;
        final resolvedSubject = Uri.encodeComponent(
          (subject?.trim().isNotEmpty == true ? subject!.trim() : 'Klinik Mesajı'),
        );
        return Uri(
          scheme: 'mailto',
          path: trimmedEmail,
          query: 'subject=$resolvedSubject&body=$encodedBody',
        );
    }
  }

  static Future<bool> launch({
    required String channelLabel,
    required String phone,
    required String email,
    required String body,
    String? subject,
  }) async {
    final uri = buildLaunchUri(
      channelLabel: channelLabel,
      phone: phone,
      email: email,
      body: body,
      subject: subject,
    );
    if (uri == null) return false;

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
}
