import 'package:sri_sai_ro_water/core/services/push_notification_service.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/delivery_line_item.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';

class DeliveryValidationException implements Exception {
  DeliveryValidationException(this.message);
  final String message;
}

/// Validates, saves delivery, notifies admin + customer (in-app + device banner).
class DeliveryRecordingService {
  DeliveryRecordingService({
    required WaterPlantRepository plant,
    required NotificationRepository notifications,
    required PushNotificationService push,
    required AuthRepository auth,
  }) : _plant = plant,
       _notifications = notifications,
       _push = push,
       _auth = auth;

  final WaterPlantRepository _plant;
  final NotificationRepository _notifications;
  final PushNotificationService _push;
  final AuthRepository _auth;

  static const int maxCansPerDelivery = 50;

  Future<Delivery> recordCansDelivery({
    required String customerId,
    required int normalQty,
    required int coolQty,
    DateTime? date,
    int emptyNormalReturned = 0,
    int emptyCoolReturned = 0,
    List<BottleDeliveryInput> extraBottles = const [],
    String? driverNote,
    bool driverMode = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw DeliveryValidationException('You must be signed in');
    }

    if (driverMode && !user.isDriver) {
      throw DeliveryValidationException(
        'Only drivers can use field delivery mode',
      );
    }

    final customer = _plant.customerById(customerId);
    if (customer == null) {
      throw DeliveryValidationException('Customer not found');
    }
    if (driverMode && customer.isInstantDispatch) {
      throw DeliveryValidationException(
        'Use the quick delivery screen to complete this job',
      );
    }

    final extraQty = extraBottles.fold<int>(0, (sum, b) => sum + b.quantity);
    final totalCans = normalQty + coolQty + extraQty;
    if (totalCans <= 0) {
      throw DeliveryValidationException('Enter at least 1 item delivered');
    }
    if (normalQty + coolQty > maxCansPerDelivery) {
      throw DeliveryValidationException(
        'Maximum $maxCansPerDelivery cans per trip',
      );
    }

    if (normalQty < 0 || coolQty < 0) {
      throw DeliveryValidationException('Invalid quantity');
    }
    if (emptyNormalReturned < 0 || emptyCoolReturned < 0) {
      throw DeliveryValidationException('Invalid empty return quantity');
    }

    final staffId = user.isDriver ? user.driverId : user.id;
    if (user.isDriver && (staffId == null || staffId.isEmpty)) {
      throw DeliveryValidationException('Driver profile not linked');
    }

    final today = DateTime.now();
    final deliveryDate = driverMode
        ? DateTime(today.year, today.month, today.day, today.hour, today.minute)
        : today;

    final driverName = user.isDriver
        ? (_plant.driverById(user.driverId)?.name ?? user.ownerName)
        : user.ownerName;

    final delivery = await _plant.addDeliveryToCurrentShop(
      customerId: customerId,
      date: date ?? deliveryDate,
      normalQty: normalQty,
      coolQty: coolQty,
      emptyNormalReturned: emptyNormalReturned,
      emptyCoolReturned: emptyCoolReturned,
      bottles: extraBottles,
      driverId: staffId,
      driverName: driverName,
      customer: customer,
    );

    _notifications.recordDelivery(
      delivery: delivery,
      customer: customer,
      driverName: driverName,
      driverId: staffId,
    );

    _push.showDeliveryRecordedSafe(
      title: 'Delivery saved · ${customer.name}',
      body: '${delivery.cansSummary} — admin & customer notified',
      payload: delivery.id,
    );

    // Second banner simulates customer device (demo).
    _push.showDeliveryRecordedSafe(
      title: 'Water delivered',
      body: '${delivery.cansSummary} recorded for ${customer.name}',
      payload: 'customer:${customer.id}',
    );

    return delivery;
  }
}
