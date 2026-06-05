import 'package:sri_sai_ro_water/data/models/dispatch_collection_status.dart';
import 'package:sri_sai_ro_water/data/models/dispatch_payment_mode.dart';
import 'package:sri_sai_ro_water/data/models/order_line_item.dart';
import 'package:sri_sai_ro_water/data/models/order_source.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/data/models/walk_in_contact.dart';

class CustomerOrder {
  CustomerOrder({
    required this.id,
    required this.customerId,
    required this.normalQty,
    required this.coolQty,
    required this.status,
    this.shopId,
    this.placedByAppUserId,
    this.customerNote,
    this.adminResponse,
    DateTime? createdAt,
    this.respondedAt,
    this.driverAcceptedAt,
    this.deliveryStartedAt,
    this.fulfilledAt,
    this.fulfilledBy,
    this.adminDispatchNote,
    this.source = OrderSource.customerApp,
    this.paymentMode = DispatchPaymentMode.billLater,
    this.walkInContact,
    this.collectionStatus,
    this.collectedAmount,
    this.collectionMethod,
    this.collectionRecordedBy,
    this.instantOutcome,
    List<OrderLineItem> lineItems = const [],
  })  : lineItems = List.unmodifiable(lineItems),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String customerId;
  final String? shopId;
  final String? placedByAppUserId;
  int normalQty;
  int coolQty;
  OrderStatus status;
  String? customerNote;
  String? adminResponse;
  final DateTime createdAt;
  DateTime? respondedAt;
  DateTime? driverAcceptedAt;
  DateTime? deliveryStartedAt;
  DateTime? fulfilledAt;
  String? fulfilledBy;
  String? adminDispatchNote;
  final OrderSource source;
  final DispatchPaymentMode paymentMode;
  final WalkInContact? walkInContact;
  DispatchCollectionStatus? collectionStatus;
  double? collectedAmount;
  String? collectionMethod;
  String? collectionRecordedBy;
  String? instantOutcome;
  final List<OrderLineItem> lineItems;

  int get totalCans => normalQty + coolQty;

  bool get isPhoneDispatch => source == OrderSource.phoneCall;

  bool get isInstantNoStock =>
      instantOutcome == 'noStock' ||
      (isPhoneDispatch &&
          status == OrderStatus.rejected &&
          (adminResponse?.toLowerCase().contains('no stock') ?? false));

  bool get isPaymentPending =>
      isDelivered && collectionStatus == DispatchCollectionStatus.pending;

  String get collectionSummary {
    final status = collectionStatus;
    if (status == null) return '';
    if (status == DispatchCollectionStatus.collected &&
        collectedAmount != null &&
        collectedAmount! > 0) {
      final method = collectionMethod == 'upi' ? 'UPI' : 'Cash';
      return '${status.shortLabel} · $method';
    }
    return status.label;
  }

  bool get isOpenForDriver =>
      status == OrderStatus.accepted && fulfilledAt == null;

  bool get isCancelled => status == OrderStatus.cancelled;

  bool get isDelivered => fulfilledAt != null;

  bool get isActiveDispatch =>
      status == OrderStatus.accepted && fulfilledAt == null && !isCancelled;

  String get dispatchTrackerLabel {
    if (isInstantNoStock) return 'No stock';
    if (isCancelled) return 'Cancelled';
    if (isDelivered) {
      if (isPaymentPending) return 'Delivered · pay pending';
      if (collectionStatus == DispatchCollectionStatus.collected) {
        return 'Delivered · paid';
      }
      return 'Delivered';
    }
    if (status == OrderStatus.accepted) return 'Out for delivery';
    return status.label;
  }

  String get fulfilledByLabel => switch (fulfilledBy) {
        'driver' => 'Driver confirmed',
        'admin' => 'Admin confirmed',
        _ => '',
      };

  String get cansSummary {
    final parts = <String>[];
    if (normalQty > 0) parts.add('$normalQty Normal');
    if (coolQty > 0) parts.add('$coolQty Cool');
    return parts.isEmpty ? 'No cans' : parts.join(' · ');
  }

  String get itemsSummary {
    if (lineItems.isNotEmpty) {
      return lineItems
          .where((l) => l.quantity > 0)
          .map((l) => '${l.quantity} ${l.label}')
          .join(' · ');
    }
    return cansSummary;
  }

  bool get isPending => status == OrderStatus.pending;

  bool get canCustomerEdit =>
      status == OrderStatus.pending && source == OrderSource.customerApp;

  bool get canCustomerCancel =>
      status == OrderStatus.pending && source == OrderSource.customerApp;

  bool get isDriverAssigned => driverAcceptedAt != null;

  bool get isOutForDelivery => deliveryStartedAt != null;

  static int _sumCans(List<OrderLineItem> items, bool normal) {
    return items
        .where((l) => normal ? l.isNormalCan : l.isCoolCan)
        .fold(0, (s, l) => s + l.quantity);
  }

  static CustomerOrder withLineItems({
    required String id,
    required String customerId,
    required OrderStatus status,
    required List<OrderLineItem> lineItems,
    String? shopId,
    String? placedByAppUserId,
    String? customerNote,
    String? adminResponse,
    DateTime? createdAt,
    DateTime? respondedAt,
    DateTime? driverAcceptedAt,
    DateTime? deliveryStartedAt,
    DateTime? fulfilledAt,
    String? fulfilledBy,
    String? adminDispatchNote,
    OrderSource source = OrderSource.customerApp,
    DispatchPaymentMode paymentMode = DispatchPaymentMode.billLater,
    WalkInContact? walkInContact,
    DispatchCollectionStatus? collectionStatus,
    double? collectedAmount,
    String? collectionMethod,
    String? collectionRecordedBy,
    String? instantOutcome,
  }) {
    return CustomerOrder(
      id: id,
      customerId: customerId,
      normalQty: _sumCans(lineItems, true),
      coolQty: _sumCans(lineItems, false),
      status: status,
      shopId: shopId,
      placedByAppUserId: placedByAppUserId,
      customerNote: customerNote,
      adminResponse: adminResponse,
      createdAt: createdAt,
      respondedAt: respondedAt,
      driverAcceptedAt: driverAcceptedAt,
      deliveryStartedAt: deliveryStartedAt,
      fulfilledAt: fulfilledAt,
      fulfilledBy: fulfilledBy,
      adminDispatchNote: adminDispatchNote,
      source: source,
      paymentMode: paymentMode,
      walkInContact: walkInContact,
      collectionStatus: collectionStatus,
      collectedAmount: collectedAmount,
      collectionMethod: collectionMethod,
      collectionRecordedBy: collectionRecordedBy,
      instantOutcome: instantOutcome,
      lineItems: lineItems,
    );
  }
}
