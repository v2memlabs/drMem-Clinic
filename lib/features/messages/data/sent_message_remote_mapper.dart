import '../models/message_template.dart';
import '../models/sent_message.dart';
import 'sent_message_repository_failure.dart';

abstract final class SentMessageRemoteMapper {
  static const table = 'sent_messages';

  static const listSelectColumns =
      'id, tenant_id, patient_id, patient_phone, patient_email, channel, '
      'category, template_id, template_title, status, content, content_preview, '
      'related_module, notes, sent_by, sent_by_display, sent_at, created_at, '
      'patients(first_name, last_name)';

  static SentMessage fromRow(Map<String, dynamic> row) {
    final categoryDb = _optionalString(row['category']) ?? '';
    return SentMessage(
      id: _requireString(row, 'id'),
      patientId: _requireString(row, 'patient_id'),
      patientName: _embeddedPatientFullName(row['patients']) ?? 'Hasta',
      patientPhone: _optionalString(row['patient_phone']) ?? '',
      channel: _channelLabelFromDb(row['channel']),
      category: categoryDb.isEmpty
          ? ''
          : _categoryLabelFromDb(categoryDb),
      templateTitle: _optionalString(row['template_title']) ?? '',
      sentAt: _requireDateTime(row['sent_at']),
      sentBy: _optionalString(row['sent_by_display']) ?? '',
      status: _enumFromDb(SendStatus.values, row['status']),
      contentPreview: _optionalString(row['content_preview']) ?? '',
      relatedModule: _optionalString(row['related_module']) ?? '',
      notes: _optionalString(row['notes']) ?? '',
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required SentMessage message,
    String? templateId,
    String? sentByProfileId,
    String? sentByDisplay,
    String? patientEmail,
    String? content,
  }) {
    final channelName = _channelNameFromLabel(message.channel);
    final categoryName = _categoryNameFromLabel(message.category);
    final fullContent = content ?? message.contentPreview;

    return {
      'tenant_id': tenantId,
      'patient_id': message.patientId.trim(),
      'patient_phone': message.patientPhone.trim(),
      if (patientEmail?.trim().isNotEmpty == true)
        'patient_email': patientEmail!.trim(),
      'channel': channelName,
      'category': categoryName ?? '',
      if (templateId?.trim().isNotEmpty == true) 'template_id': templateId!.trim(),
      'template_title': message.templateTitle.trim(),
      'status': message.status.name,
      'content': fullContent,
      'content_preview': message.contentPreview.trim(),
      'related_module': message.relatedModule.trim(),
      'notes': message.notes.trim(),
      if (sentByProfileId != null) 'sent_by': sentByProfileId,
      'sent_by_display': sentByDisplay?.trim().isNotEmpty == true
          ? sentByDisplay!.trim()
          : message.sentBy.trim(),
      'sent_at': message.sentAt.toUtc().toIso8601String(),
    };
  }

  static String _channelLabelFromDb(Object? raw) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) {
      throw const SentMessageRepositoryException(
        SentMessageRepositoryFailure.invalidRow,
      );
    }
    for (final channel in Channel.values) {
      if (channel.name == name) return messageChannelLabel(channel);
    }
    throw const SentMessageRepositoryException(
      SentMessageRepositoryFailure.invalidRow,
    );
  }

  static String _categoryLabelFromDb(String dbName) {
    for (final category in Category.values) {
      if (category.name == dbName) return messageCategoryLabel(category);
    }
    return dbName;
  }

  static String _channelNameFromLabel(String label) {
    final trimmed = label.trim();
    for (final channel in Channel.values) {
      if (messageChannelLabel(channel) == trimmed) return channel.name;
    }
    final lower = trimmed.toLowerCase();
    for (final channel in Channel.values) {
      if (channel.name == lower) return channel.name;
    }
    throw const SentMessageRepositoryException(
      SentMessageRepositoryFailure.invalidRow,
    );
  }

  static String? _categoryNameFromLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return null;
    for (final category in Category.values) {
      if (messageCategoryLabel(category) == trimmed) return category.name;
    }
    for (final category in Category.values) {
      if (category.name == trimmed.toLowerCase()) return category.name;
    }
    return null;
  }

  static String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw const SentMessageRepositoryException(
        SentMessageRepositoryFailure.invalidRow,
      );
    }
    return value;
  }

  static String? _optionalString(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static DateTime _requireDateTime(Object? raw) {
    if (raw is DateTime) return raw;
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) {
      throw const SentMessageRepositoryException(
        SentMessageRepositoryFailure.invalidRow,
      );
    }
    return parsed;
  }

  static String? _embeddedPatientFullName(dynamic value) {
    if (value is Map) {
      final first = value['first_name']?.toString().trim() ?? '';
      final last = value['last_name']?.toString().trim() ?? '';
      final name = '$first $last'.trim();
      return name.isEmpty ? null : name;
    }
    return null;
  }

  static T _enumFromDb<T extends Enum>(List<T> values, Object? raw) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) {
      throw const SentMessageRepositoryException(
        SentMessageRepositoryFailure.invalidRow,
      );
    }
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw const SentMessageRepositoryException(
      SentMessageRepositoryFailure.invalidRow,
    );
  }
}
