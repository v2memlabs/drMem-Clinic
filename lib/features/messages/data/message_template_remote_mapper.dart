import '../models/message_template.dart';
import 'message_template_repository_failure.dart';

abstract final class MessageTemplateRemoteMapper {
  static const table = 'message_templates';

  static const listSelectColumns =
      'id, tenant_id, title, channel, category, content, is_active, '
      'created_by, created_by_display, created_at, updated_at';

  static MessageTemplate fromRow(Map<String, dynamic> row) {
    return MessageTemplate(
      id: _requireString(row, 'id'),
      title: _requireString(row, 'title'),
      channel: _enumFromDb(Channel.values, row['channel']),
      category: _enumFromDb(Category.values, row['category']),
      content: _optionalString(row['content']) ?? '',
      createdBy: _optionalString(row['created_by_display']) ?? '',
      isActive: row['is_active'] == true,
    );
  }

  static String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw const MessageTemplateRepositoryException(
        MessageTemplateRepositoryFailure.invalidRow,
      );
    }
    return value;
  }

  static String? _optionalString(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required MessageTemplate template,
    String? createdByProfileId,
    String? createdByDisplay,
  }) {
    return {
      'tenant_id': tenantId,
      'title': template.title.trim(),
      'channel': template.channel.name,
      'category': template.category.name,
      'content': template.content.trim(),
      'is_active': template.isActive,
      if (createdByProfileId != null) 'created_by': createdByProfileId,
      if (createdByDisplay?.trim().isNotEmpty == true)
        'created_by_display': createdByDisplay!.trim(),
    };
  }

  static Map<String, dynamic> toUpdateRow(MessageTemplate template) {
    return {
      'title': template.title.trim(),
      'channel': template.channel.name,
      'category': template.category.name,
      'content': template.content.trim(),
      'is_active': template.isActive,
    };
  }

  static T _enumFromDb<T extends Enum>(List<T> values, Object? raw) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) {
      throw const MessageTemplateRepositoryException(
        MessageTemplateRepositoryFailure.invalidRow,
      );
    }
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw const MessageTemplateRepositoryException(
      MessageTemplateRepositoryFailure.invalidRow,
    );
  }
}
