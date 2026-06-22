import '../models/sent_message.dart';
import 'async_sent_message_repository_contract.dart';
import 'message_repository.dart';

class MockAsyncSentMessageRepositoryAdapter
    implements AsyncSentMessageRepositoryContract {
  MessageRepository get _sync => MessageRepository.instance;

  @override
  Future<SentMessage> create(
    SentMessage message, {
    String? templateId,
    String? patientEmail,
    String? fullContent,
  }) async {
    _sync.addSentMessage(message);
    return message;
  }

  @override
  Future<List<SentMessage>> getAll() async => _sync.getSentMessages();

  @override
  Future<SentMessage?> getById(String id) async => _sync.getSentMessageById(id);

  @override
  Future<List<SentMessage>> getByPatientId(String patientId) async =>
      _sync.getSentMessagesByPatientId(patientId);

  @override
  Future<List<SentMessage>> getFiltered({
    String? patientId,
    String? query,
    String? channelFilter,
    String? statusFilter,
    String? categoryFilter,
    SendStatus? statusEnumFilter,
  }) async {
    return _sync.getFilteredSentMessages(
      patientId: patientId,
      query: query,
      channelFilter: channelFilter,
      statusFilter: statusFilter,
      categoryFilter: categoryFilter,
      statusEnumFilter: statusEnumFilter,
    );
  }
}
