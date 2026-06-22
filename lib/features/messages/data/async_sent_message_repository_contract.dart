import '../models/sent_message.dart';

abstract interface class AsyncSentMessageRepositoryContract {
  Future<List<SentMessage>> getAll();

  Future<List<SentMessage>> getByPatientId(String patientId);

  Future<SentMessage?> getById(String id);

  Future<List<SentMessage>> getFiltered({
    String? patientId,
    String? query,
    String? channelFilter,
    String? statusFilter,
    String? categoryFilter,
    SendStatus? statusEnumFilter,
  });

  Future<SentMessage> create(
    SentMessage message, {
    String? templateId,
    String? patientEmail,
    String? fullContent,
  });
}
