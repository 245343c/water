import 'package:sri_sai_ro_water/core/services/push_notification_service.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';

/// Admin accept/reject → driver notification pipeline.
class OrderWorkflowService {
  OrderWorkflowService({
    required WaterPlantRepository plant,
    required NotificationRepository notifications,
    required PushNotificationService push,
  })  : _plant = plant,
        _notifications = notifications,
        _push = push;

  final WaterPlantRepository _plant;
  final NotificationRepository _notifications;
  final PushNotificationService _push;

  CustomerOrder? acceptOrder({
    required String orderId,
    String adminResponse = 'Order confirmed — driver will deliver',
  }) {
    _plant.respondToOrder(orderId, OrderStatus.accepted, adminResponse: adminResponse);
    final order = _plant.orderById(orderId);
    if (order == null) return null;

    final customer = _plant.customerById(order.customerId);
    if (customer == null) return order;

    _notifications.notifyDriverOrderAccepted(order: order, customerName: customer.name);
    _notifications.notifyAdminOrderAccepted(order: order, customerName: customer.name);

    _push.showDeliveryRecordedSafe(
      title: 'New delivery task',
      body: '${customer.name}: ${order.cansSummary} — go deliver',
      payload: 'order:${order.id}',
    );

    return order;
  }

  void rejectOrder({required String orderId, required String reason}) {
    _plant.respondToOrder(orderId, OrderStatus.rejected, adminResponse: reason);
  }
}
