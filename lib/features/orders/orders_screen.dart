import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/services/order_workflow_service.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/orders/widgets/orders_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _search = TextEditingController();
  String _query = '';
  OrderListFilter _filter = OrderListFilter.pending;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CustomerOrder> _filtered(WaterPlantRepository repo) {
    var list = repo.ordersNewestFirst();
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      final qDigits = q.replaceAll(RegExp(r'\D'), '');
      list = list.where((o) {
        final c = repo.customerById(o.customerId);
        final shopName = o.shopId == null
            ? ''
            : repo.shopById(o.shopId!)?.name.toLowerCase() ?? '';
        final phone = c?.phone.replaceAll(RegExp(r'\D'), '') ?? '';
        return (c?.name.toLowerCase().contains(q) ?? false) ||
            (qDigits.isNotEmpty && phone.contains(qDigits)) ||
            shopName.contains(q) ||
            o.cansSummary.toLowerCase().contains(q);
      }).toList();
    }
    if (_filter == OrderListFilter.all) return list;
    return list
        .where(
          (o) => switch (_filter) {
            OrderListFilter.pending => o.status == OrderStatus.pending,
            OrderListFilter.accepted => o.status == OrderStatus.accepted,
            OrderListFilter.rejected => o.status == OrderStatus.rejected,
            OrderListFilter.all => true,
          },
        )
        .toList();
  }

  void _openOrder(
    BuildContext context,
    WaterPlantRepository repo,
    CustomerOrder order,
  ) {
    final customer = repo.customerById(order.customerId);
    if (customer == null) return;
    final shopName = order.shopId == null
        ? 'Your water plant'
        : repo.shopById(order.shopId!)?.name ?? 'Your water plant';

    showOrderRespondSheet(
      context: context,
      order: order,
      customerName: customer.name,
      customerPhone: customer.phone,
      shopName: shopName,
      isMonthlyCustomer: customer.isMonthlyContract,
      onAccept: () {
        context.read<OrderWorkflowService>().acceptOrder(orderId: order.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request accepted. Driver notified to deliver to ${customer.name}',
              style: GoogleFonts.poppins(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onReject: (reason) {
        context.read<OrderWorkflowService>().rejectOrder(
          orderId: order.id,
          reason: reason,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request declined', style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final orders = _filtered(repo);
        final pendingCount = repo.pendingOrderCount;

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: CustomersScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomersHeader(
                  title: 'Customer requests',
                  showAddButton: false,
                  onAdd: () {},
                  onMenu: () => context.go(AppRoutes.more),
                ),
                CustomersSearchRow(
                  controller: _search,
                  hintText: 'Search requests, customer, plant...',
                  onChanged: (v) => setState(() => _query = v),
                ),
                CustomersListPanel(
                  child: Column(
                    children: [
                      OrdersFilterChips(
                        selected: _filter,
                        pendingCount: pendingCount,
                        onSelected: (f) => setState(() => _filter = f),
                      ),
                      Expanded(
                        child: orders.isEmpty
                            ? _EmptyOrders(
                                filter: _filter,
                                isSearch: _query.isNotEmpty,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  16,
                                ),
                                itemCount: orders.length,
                                itemBuilder: (_, i) {
                                  final order = orders[i];
                                  final customer = repo.customerById(
                                    order.customerId,
                                  );
                                  final shopName = order.shopId == null
                                      ? 'Your water plant'
                                      : repo.shopById(order.shopId!)?.name ??
                                            'Your water plant';
                                  final idx = customer == null
                                      ? 0
                                      : repo.customers.indexWhere(
                                          (c) => c.id == customer.id,
                                        );
                                  return OrderListCard(
                                    order: order,
                                    customerName: customer?.name ?? 'Unknown',
                                    customerPhone: customer?.phone ?? '',
                                    shopName: shopName,
                                    isMonthlyCustomer:
                                        customer?.isMonthlyContract ?? false,
                                    initials: customer?.initials ?? '?',
                                    colorIndex: idx >= 0 ? idx : 0,
                                    onTap: () =>
                                        _openOrder(context, repo, order),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.filter, required this.isSearch});

  final OrderListFilter filter;
  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    final message = isSearch
        ? 'No requests match your search'
        : switch (filter) {
            OrderListFilter.pending => 'No new requests',
            OrderListFilter.accepted => 'No accepted requests',
            OrderListFilter.rejected => 'No declined requests',
            OrderListFilter.all => 'No requests yet',
          };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: CustomersColors.labelGrey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: CustomersColors.labelGrey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Customer app requests will appear here',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: CustomersColors.labelGrey,
            ),
          ),
        ],
      ),
    );
  }
}
