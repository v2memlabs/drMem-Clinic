import '../models/sent_message.dart';
import 'async_sent_message_repository_contract.dart';
import 'sent_message_repository_failure.dart';

class SupabaseAsyncSentMessageRepositoryStub
    implements AsyncSentMessageRepositoryContract {
  const SupabaseAsyncSentMessageRepositoryStub();

  static const _error = SentMessageRepositoryException(
    SentMessageRepositoryFailure.notConfigured,
  );

  @override
  Future<SentMessage> create(
    SentMessage message, {
    String? templateId,
    String? patientEmail,
    String? fullContent,
  }) async =>
      throw _error;

  @override
  Future<List<SentMessage>> getAll() async => throw _error;

  @override
  Future<SentMessage?> getById(String id) async => throw _error;

  @override
  Future<List<SentMessage>> getByPatientId(String patientId) async =>
      throw _error;

  @override
  Future<List<SentMessage>> getFiltered({
    String? patientId,
    String? query,
    String? channelFilter,
    String? statusFilter,
    String? categoryFilter,
    SendStatus? statusEnumFilter,
  }) async =>
      throw _error;
}
