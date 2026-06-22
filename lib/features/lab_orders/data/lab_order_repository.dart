import '../models/lab_order.dart';
import '../models/lab_test_catalog.dart';
import 'mock_lab_orders.dart';

class LabOrderRepository {
  LabOrderRepository._();

  static final LabOrderRepository instance = LabOrderRepository._();

  List<LabOrder> getAll() => List.unmodifiable(mockLabOrders);

  LabOrder? getById(String id) {
    for (final item in mockLabOrders) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<LabOrder> getFiltered({
    String? patientId,
    String? query,
    LabOrderStatus? statusFilter,
  }) {
    var list = patientId != null && patientId.isNotEmpty
        ? mockLabOrders.where((o) => o.patientId == patientId).toList()
        : getAll();

    if (statusFilter != null) {
      list = list.where((o) => o.status == statusFilter).toList();
    }

    final q = (query ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((o) => matchesQuery(o, q)).toList();
    }

    return list;
  }

  static bool matchesQuery(LabOrder o, String q) {
    final protocol = o.displayProtocolNumber?.toLowerCase() ?? '';
    if (protocol.isNotEmpty && protocol.contains(q)) return true;
    if (o.patientName.toLowerCase().contains(q)) return true;
    if (o.diagnosis.toLowerCase().contains(q)) return true;
    if ((o.templateName ?? '').toLowerCase().contains(q)) return true;
    for (final test in o.selectedTests) {
      if (labTestCodeLabel(test).toLowerCase().contains(q)) return true;
    }
    return false;
  }

  void add(LabOrder order) => mockLabOrders.insert(0, order);

  void update(LabOrder order) {
    final index = mockLabOrders.indexWhere((o) => o.id == order.id);
    if (index >= 0) mockLabOrders[index] = order;
  }

  bool delete(String id) {
    final index = mockLabOrders.indexWhere((o) => o.id == id);
    if (index < 0) return false;
    mockLabOrders.removeAt(index);
    return true;
  }
}
