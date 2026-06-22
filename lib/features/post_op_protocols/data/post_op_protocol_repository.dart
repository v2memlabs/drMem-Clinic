import '../models/post_op_protocol.dart';
import 'mock_post_op_protocols.dart';

class PostOpProtocolRepository {
  PostOpProtocolRepository._();

  static final PostOpProtocolRepository instance = PostOpProtocolRepository._();

  List<PostOpProtocol> getAll() => List.unmodifiable(mockPostOpProtocols);

  PostOpProtocol? getById(String id) {
    for (final protocol in mockPostOpProtocols) {
      if (protocol.id == id) return protocol;
    }
    return null;
  }

  List<PostOpProtocol> getByPatientId(String patientId) =>
      mockPostOpProtocols.where((p) => p.patientId == patientId).toList();

  List<PostOpProtocol> getBySurgeryNoteId(String surgeryNoteId) =>
      mockPostOpProtocols
          .where((p) => p.surgeryNoteId == surgeryNoteId)
          .toList();

  List<PostOpProtocol> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return mockPostOpProtocols.where((p) => matchesQuery(p, q)).toList();
  }

  List<PostOpProtocol> getFiltered({
    String? patientId,
    String? surgeryNoteId,
    String? query,
    PostOpPhase? phaseFilter,
    PostOpProtocolStatus? statusFilter,
  }) {
    Iterable<PostOpProtocol> list = mockPostOpProtocols;

    if (patientId != null && patientId.isNotEmpty) {
      list = list.where((p) => p.patientId == patientId);
    }
    if (surgeryNoteId != null && surgeryNoteId.isNotEmpty) {
      list = list.where((p) => p.surgeryNoteId == surgeryNoteId);
    }
    if (phaseFilter != null) {
      list = list.where((p) => p.phase == phaseFilter);
    }
    if (statusFilter != null) {
      list = list.where((p) => p.status == statusFilter);
    }

    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((p) => matchesQuery(p, q));
    }

    return List<PostOpProtocol>.from(list);
  }

  void add(PostOpProtocol protocol) => mockPostOpProtocols.insert(0, protocol);

  static bool matchesQuery(PostOpProtocol p, String q) {
    if (p.patientName.toLowerCase().contains(q)) return true;
    if (p.protocolTitle.toLowerCase().contains(q)) return true;
    if (p.diagnosisOrProcedureSummary.toLowerCase().contains(q)) return true;
    if (postOpPhaseLabel(p.phase).toLowerCase().contains(q)) return true;
    if (p.phase.name.toLowerCase().contains(q)) return true;
    if (postOpProtocolStatusLabel(p.status).toLowerCase().contains(q)) {
      return true;
    }
    if (p.status.name.toLowerCase().contains(q)) return true;
    if (p.weightBearingStatus.toLowerCase().contains(q)) return true;
    if (p.createdBy.toLowerCase().contains(q)) return true;
    if (p.notes.toLowerCase().contains(q)) return true;
    if (p.controlDate != null) {
      final dateStr = p.controlDate!.toLocal().toString().split(' ').first;
      if (dateStr.contains(q)) return true;
    }
    return false;
  }
}
