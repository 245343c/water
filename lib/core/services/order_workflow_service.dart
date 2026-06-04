import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';

/// Admin accept/reject -> driver notification pipeline.
class OrderWorkflowService {
  OrderWorkflowService({
    required WaterPlantRepository plant,
    required NotificationRepository notifications,
  })  : _plant = plant,
        _notifications = notifications;

  final WaterPlantRepository _plant;
  final NotificationRepository _notifications;

  Future<CustomerOrder?> acceptOrder({
    required String orderId,
    String adminResponse = 'Request confirmed. Driver will deliver soon.',
  }) async {
    final existing = _plant.orderById(orderId);
    if (existing == null || existing.status != OrderStatus.pending) {
      return existing;
    }
    await _plant.respondToOrderInFirestore(
      orderId,
      OrderStatus.accepted,
      adminResponse: adminResponse,
    );
    final order = _plant.orderById(orderId);
    if (order == null) return null;

    final customer = _plant.customerById(order.customerId);
    if (customer != null) {
      _notifications.notifyDriverOrderAccepted(
        order: order,
        customerName: customer.name,
      );
      _notifications.notifyAdminOrderAccepted(
        order: order,
        customerName: customer.name,
      );
    }

    return order;
  }

  Future<void> rejectOrder({required String orderId, required String reason}) async {
    final existing = _plant.orderById(orderId);
    if (existing == null || existing.status != OrderStatus.pending) return;
    await _plant.respondToOrderInFirestore(
      orderId,
      OrderStatus.rejected,
      adminResponse: reason,
    );
    final order = _plant.orderById(orderId);
    if (order == null) return;

  }
}
