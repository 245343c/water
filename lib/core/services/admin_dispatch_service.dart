import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/order_line_item.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';

/// Admin creates and manages instant / walk-in deliveries.
class AdminDispatchService {
  AdminDispatchService({
    required WaterPlantRepository plant,
    required NotificationRepository notifications,
  })  : _plant = plant,
        _notifications = notifications;

  final WaterPlantRepository _plant;
  final NotificationRepository _notifications;

  Future<CustomerOrder> createInstantDelivery({
    required String callerName,
    required String callerPhone,
    required String callerAddress,
    String callerPlace = '',
    required List<OrderLineItem> lineItems,
    String? note,
    required bool sendToDriver,
  }) async {
    final order = await _plant.placeWalkInDispatch(
      callerName: callerName,
      callerPhone: callerPhone,
      callerAddress: callerAddress,
      callerPlace: callerPlace,
      lineItems: lineItems,
      note: note,
      sendToDriver: sendToDriver,
    );
    final name = order.walkInContact?.name ?? callerName.trim();
    if (sendToDriver) {
      _notifications.notifyDriverOrderAccepted(
        order: order,
        customerName: name,
      );
      _notifications.notifyAdminOrderAccepted(
        order: order,
        customerName: name,
      );
    } else {
      _notifications.notifyAdminInstantNoStock(
        order: order,
        customerName: name,
      );
    }
    return order;
  }

  Future<void> markDeliveredByAdmin({
    required String orderId,
    required List<Map<String, dynamic>> lines,
    required int emptyNormalReturned,
    required int emptyCoolReturned,
    required String collectionStatus,
    double collectedAmount = 0,
    String collectionMethod = 'cash',
  }) async {
    await _plant.fulfillInstantDispatchInFirestore(
      orderId: orderId,
      date: DateTime.now(),
      lines: lines,
      emptyNormalReturned: emptyNormalReturned,
      emptyCoolReturned: emptyCoolReturned,
      collectionStatus: collectionStatus,
      collectedAmount: collectedAmount,
      collectionMethod: collectionMethod,
      driverName: 'Admin',
    );
  }

  Future<Delivery> fulfillInstantDispatchByAdmin({
    required String orderId,
    required List<Map<String, dynamic>> lines,
    required int emptyNormalReturned,
    required int emptyCoolReturned,
    required String collectionStatus,
    double collectedAmount = 0,
    String collectionMethod = 'cash',
  }) {
    return _plant.fulfillInstantDispatchInFirestore(
      orderId: orderId,
      date: DateTime.now(),
      lines: lines,
      emptyNormalReturned: emptyNormalReturned,
      emptyCoolReturned: emptyCoolReturned,
      collectionStatus: collectionStatus,
      collectedAmount: collectedAmount,
      collectionMethod: collectionMethod,
      driverName: 'Admin',
    );
  }

  Future<void> updateCollectionByAdmin({
    required String orderId,
    required String collectionStatus,
    double collectedAmount = 0,
    String collectionMethod = 'cash',
  }) async {
    await _plant.updateWalkInDispatchInFirestore(
      orderId: orderId,
      action: 'updateCollection',
      collectionStatus: collectionStatus,
      collectedAmount: collectedAmount,
      collectionMethod: collectionMethod,
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
