import '../models/radiology_order.dart';
import 'mock_radiology_orders.dart';

class RadiologyOrderRepository {
  RadiologyOrderRepository._();

  static final RadiologyOrderRepository instance = RadiologyOrderRepository._();

  List<RadiologyOrder> getAll() => List.unmodifiable(mockRadiologyOrders);

  RadiologyOrder? getById(String id) {
    for (final item in mockRadiologyOrders) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<RadiologyOrder> getByPatientId(String patientId) =>
      mockRadiologyOrders.where((o) => o.patientId == patientId).toList();

  List<RadiologyOrder> getFiltered({
    String? patientId,
    String? query,
    RadiologyOrderStatus? statusFilter,
  }) {
    var list = patientId != null && patientId.isNotEmpty
        ? mockRadiologyOrders.where((o) => o.patientId == patientId).toList()
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

  static bool matchesQuery(RadiologyOrder o, String q) {
    final protocol = o.displayProtocolNumber?.toLowerCase() ?? '';
    if (protocol.isNotEmpty && protocol.contains(q)) return true;
    if (o.patientName.toLowerCase().contains(q)) return true;
    if (o.diagnosis.toLowerCase().contains(q)) return true;
    if (o.createdBy.toLowerCase().contains(q)) return true;
    for (final line in o.lines) {
      if (radiologyModalityLabel(line.modality).toLowerCase().contains(q)) {
        return true;
      }
    }
    return false;
  }

  void add(RadiologyOrder order) => mockRadiologyOrders.insert(0, order);

  void update(RadiologyOrder order) {
    final index = mockRadiologyOrders.indexWhere((o) => o.id == order.id);
    if (index >= 0) mockRadiologyOrders[index] = order;
  }

  bool delete(String id) {
    final index = mockRadiologyOrders.indexWhere((o) => o.id == id);
    if (index < 0) return false;
    mockRadiologyOrders.removeAt(index);
    return true;
  }
}
