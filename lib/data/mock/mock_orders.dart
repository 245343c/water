import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';

List<CustomerOrder> seedOrders({required DateTime now}) => [
  CustomerOrder(
    id: 'ord-1',
    customerId: 'c3',
    normalQty: 2,
    coolQty: 2,
    status: OrderStatus.accepted,
    customerNote: 'Deliver before 12 noon',
    createdAt: now.subtract(const Duration(hours: 3)),
  ),
  CustomerOrder(
    id: 'ord-2',
    customerId: 'c5',
    normalQty: 1,
    coolQty: 1,
    status: OrderStatus.pending,
    customerNote: 'First order this week',
    createdAt: now.subtract(const Duration(hours: 1)),
  ),
  CustomerOrder(
    id: 'ord-3',
    customerId: 'c6',
    normalQty: 4,
    coolQty: 0,
    status: OrderStatus.accepted,
    createdAt: now.subtract(const Duration(minutes: 45)),
  ),
  CustomerOrder(
    id: 'ord-4',
    customerId: 'c7',
    normalQty: 6,
    coolQty: 2,
    status: OrderStatus.accepted,
    customerNote: 'Shop opens 8 AM',
    createdAt: now.subtract(const Duration(minutes: 20)),
  ),
];
