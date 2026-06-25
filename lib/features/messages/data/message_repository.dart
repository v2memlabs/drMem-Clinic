import '../models/message_template.dart';
import '../models/sent_message.dart';
import 'mock_message_templates.dart';
import 'mock_sent_messages.dart';

class MessageRepository {
  MessageRepository._();

  static final MessageRepository instance = MessageRepository._();

  // --- Şablonlar ---

  List<MessageTemplate> getTemplates() => List.unmodifiable(mockMessageTemplates);

  MessageTemplate? getTemplateById(String id) {
    for (final template in mockMessageTemplates) {
      if (template.id == id) return template;
    }
    return null;
  }

  List<MessageTemplate> searchTemplates(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getTemplates();
    return mockMessageTemplates.where((t) => templateMatchesQuery(t, q)).toList();
  }

  List<MessageTemplate> getFilteredTemplates({
    String? query,
    String? channelFilter,
    String? categoryFilter,
    Channel? channelEnumFilter,
    Category? categoryEnumFilter,
    bool activeOnly = false,
  }) {
    Iterable<MessageTemplate> list = mockMessageTemplates;

    if (activeOnly) {
      list = list.where((t) => t.isActive);
    }
    if (channelEnumFilter != null) {
      list = list.where((t) => t.channel == channelEnumFilter);
    } else if (channelFilter != null && channelFilter.isNotEmpty) {
      final cf = channelFilter.toLowerCase();
      list = list.where((t) => t.channelLabel.toLowerCase() == cf);
    }
    if (categoryEnumFilter != null) {
      list = list.where((t) => t.category == categoryEnumFilter);
    } else if (categoryFilter != null && categoryFilter.isNotEmpty) {
      final cat = categoryFilter.toLowerCase();
      list = list.where((t) => t.categoryLabel.toLowerCase().contains(cat));
    }

    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((t) => templateMatchesQuery(t, q));
    }

    return List<MessageTemplate>.from(list);
  }

  static bool templateMatchesQuery(MessageTemplate t, String q) {
    if (t.title.toLowerCase().contains(q)) return true;
    if (t.content.toLowerCase().contains(q)) return true;
    if (t.createdBy.toLowerCase().contains(q)) return true;
    if (t.channelLabel.toLowerCase().contains(q)) return true;
    if (t.categoryLabel.toLowerCase().contains(q)) return true;
    return false;
  }

  // --- Gönderim kayıtları ---

  List<SentMessage> getSentMessages() => List.unmodifiable(mockSentMessages);

  SentMessage? getSentMessageById(String id) {
    for (final message in mockSentMessages) {
      if (message.id == id) return message;
    }
    return null;
  }

  List<SentMessage> getSentMessagesByPatientId(String patientId) =>
      mockSentMessages.where((m) => m.patientId == patientId).toList();

  List<SentMessage> searchSentMessages(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getSentMessages();
    return mockSentMessages.where((m) => sentMessageMatchesQuery(m, q)).toList();
  }

  List<SentMessage> getFilteredSentMessages({
    String? patientId,
    String? query,
    String? channelFilter,
    String? statusFilter,
    String? categoryFilter,
    SendStatus? statusEnumFilter,
  }) {
    Iterable<SentMessage> list = mockSentMessages;

    if (patientId != null && patientId.isNotEmpty) {
      list = list.where((m) => m.patientId == patientId);
    }
    if (channelFilter != null && channelFilter.isNotEmpty) {
      final cf = channelFilter.toLowerCase();
      list = list.where((m) => m.channel.toLowerCase().contains(cf));
    }
    if (statusEnumFilter != null) {
      list = list.where((m) => m.status == statusEnumFilter);
    } else if (statusFilter != null && statusFilter.isNotEmpty) {
      final sf = statusFilter.toLowerCase();
      list = list.where((m) => m.status.name.toLowerCase().contains(sf));
    }
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      final cat = categoryFilter.toLowerCase();
      list = list.where((m) => m.category.toLowerCase().contains(cat));
    }

    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((m) => sentMessageMatchesQuery(m, q));
    }

    return List<SentMessage>.from(list);
  }

  static bool sentMessageMatchesQuery(SentMessage m, String q) {
    if (m.patientName.toLowerCase().contains(q)) return true;
    if (m.patientPhone.toLowerCase().contains(q)) return true;
    if (m.templateTitle.toLowerCase().contains(q)) return true;
    if (m.channel.toLowerCase().contains(q)) return true;
    if (m.category.toLowerCase().contains(q)) return true;
    if (m.contentPreview.toLowerCase().contains(q)) return true;
    if (m.sentBy.toLowerCase().contains(q)) return true;
    if (m.relatedModule.toLowerCase().contains(q)) return true;
    if (m.notes.toLowerCase().contains(q)) return true;
    return false;
  }

  void addSentMessage(SentMessage message) => mockSentMessages.insert(0, message);

  MessageTemplate createTemplate(MessageTemplate template) {
    final saved = MessageTemplate(
      id: 'tmpl-${DateTime.now().millisecondsSinceEpoch}',
      title: template.title,
      channel: template.channel,
      category: template.category,
      content: template.content,
      createdBy: template.createdBy.trim().isEmpty ? 'Kullanıcı' : template.createdBy,
      isActive: template.isActive,
    );
    mockMessageTemplates.insert(0, saved);
    return saved;
  }

  MessageTemplate updateTemplate(MessageTemplate template) {
    final index = mockMessageTemplates.indexWhere((t) => t.id == template.id);
    if (index < 0) {
      throw StateError('Message template not found');
    }
    mockMessageTemplates[index] = template;
    return template;
  }
}
