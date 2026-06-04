import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/order_line_item.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';

/// Admin creates and manages walk-in dispatches.
class AdminDispatchService {
  AdminDispatchService({
    required WaterPlantRepository plant,
    required NotificationRepository notifications,
  })  : _plant = plant,
        _notifications = notifications;

  final WaterPlantRepository _plant;
  final NotificationRepository _notifications;

  Future<CustomerOrder> createWalkInDispatch({
    required String callerName,
    required String callerPhone,
    required String callerAddress,
    String callerPlace = '',
    required List<OrderLineItem> lineItems,
    String? note,
  }) async {
    final order = await _plant.placeWalkInDispatch(
      callerName: callerName,
      callerPhone: callerPhone,
      callerAddress: callerAddress,
      callerPlace: callerPlace,
      lineItems: lineItems,
      note: note,
    );
    final name = order.walkInContact?.name ?? callerName.trim();
    _notifications.notifyDriverOrderAccepted(
      order: order,
      customerName: name,
    );
    _notifications.notifyAdminOrderAccepted(
      order: order,
      customerName: name,
    );
    return order;
  }

  Future<void> markDeliveredByAdmin(String orderId) async {
    await _plant.updateWalkInDispatchInFirestore(
      orderId: orderId,
      action: 'markDelivered',
    );
  }

  Future<void> cancelWalkInDispatch(String orderId) async {
    await _plant.updateWalkInDispatchInFirestore(
      orderId: orderId,
      action: 'cancel',
    );
  }

  Future<void> saveAdminNote({
    required String orderId,
    required String note,
  }) async {
    await _plant.updateWalkInDispatchInFirestore(
      orderId: orderId,
      action: 'updateNote',
      adminNote: note,
    );
  }
}
