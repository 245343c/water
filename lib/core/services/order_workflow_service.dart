import 'package:sri_sai_ro_water/core/services/push_notification_service.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';

/// Admin accept/reject -> driver notification pipeline.
class OrderWorkflowService {
  OrderWorkflowService({
    required WaterPlantRepository plant,
    required NotificationRepository notifications,
    required PushNotificationService push,
  }) : _plant = plant,
       _notifications = notifications,
       _push = push;

  final WaterPlantRepository _plant;
  final NotificationRepository _notifications;
  final PushNotificationService _push;

  Future<CustomerOrder?> acceptOrder({
    required String orderId,
    String adminResponse = 'Request confirmed. Driver will deliver soon.',
  }) async {
    final existing = _plant.orderById(orderId);
    if (existing == null || existing.status != OrderStatus.pending) {
      return existing;
    }
    await _plant.respondToOrder(
      orderId,
      OrderStatus.accepted,
      adminResponse: adminResponse,
    );
    final order = _plant.orderById(orderId);
    if (order == null) return null;

    final customer = _plant.customerById(order.customerId);
    if (customer == null) return order;
    final shopName = order.shopId != null
        ? _plant.shopById(order.shopId!)?.name ?? 'Your water plant'
        : 'Your water plant';

    _notifications.notifyDriverOrderAccepted(
      order: order,
      customerName: customer.name,
    );
    _notifications.notifyAdminOrderAccepted(
      order: order,
      customerName: customer.name,
    );
    _notifications.notifyCustomerOrderAccepted(
      order: order,
      shopName: shopName,
    );

    _push.showDeliveryRecordedSafe(
      title: 'New delivery task',
      body: '${customer.name}: ${order.cansSummary} - go deliver',
      payload: 'order:${order.id}',
    );

    return order;
  }

  Future<void> rejectOrder({required String orderId, required String reason}) async {
    final existing = _plant.orderById(orderId);
    if (existing == null || existing.status != OrderStatus.pending) return;
    await _plant.respondToOrder(orderId, OrderStatus.rejected, adminResponse: reason);
    final order = _plant.orderById(orderId);
    if (order == null) return;

    final shopName = order.shopId != null
        ? _plant.shopById(order.shopId!)?.name ?? 'Your water plant'
        : 'Your water plant';
    _notifications.notifyCustomerOrderRejected(
      order: order,
      shopName: shopName,
      reason: reason,
    );

    _push.showDeliveryRecordedSafe(
      title: 'Request declined',
      body: '$shopName declined ${order.cansSummary}',
      payload: 'order:${order.id}',
    );
  }
}
