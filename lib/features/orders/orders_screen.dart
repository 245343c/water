import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/services/order_workflow_service.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/orders/widgets/admin_dispatch_manage_sheet.dart';
import 'package:sri_sai_ro_water/features/orders/widgets/create_dispatch_sheet.dart';
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
  OrderListFilter _filter = OrderListFilter.outForDelivery;

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
        final walkIn = o.walkInContact;
        final displayName = c?.name ?? walkIn?.name ?? '';
        final displayPhone = c?.phone ?? walkIn?.phone ?? '';
        final shopName = o.shopId == null
            ? ''
            : repo.shopById(o.shopId!)?.name.toLowerCase() ?? '';
        final phone = displayPhone.replaceAll(RegExp(r'\D'), '');
        return displayName.toLowerCase().contains(q) ||
            (qDigits.isNotEmpty && phone.contains(qDigits)) ||
            shopName.contains(q) ||
            o.itemsSummary.toLowerCase().contains(q);
      }).toList();
    }
    if (_filter == OrderListFilter.all) return list;
    return list.where((o) => switch (_filter) {
          OrderListFilter.pending => o.status == OrderStatus.pending,
          OrderListFilter.walkIn => o.isPhoneDispatch,
          OrderListFilter.outForDelivery => o.isActiveDispatch,
          OrderListFilter.delivered => o.isDelivered,
          OrderListFilter.all => true,
        }).toList();
  }

  void _openOrder(
    BuildContext context,
    WaterPlantRepository repo,
    CustomerOrder order,
  ) {
    final customer = repo.customerById(order.customerId);
    final walkIn = order.walkInContact;
    final customerName = customer?.name ?? walkIn?.name ?? 'Unknown';
    final customerPhone = customer?.phone ?? walkIn?.phone ?? '';
    final customerAddress = customer?.address ?? walkIn?.address ?? '';
    if (customer == null && walkIn == null) return;

    final shopName = order.shopId == null
        ? 'Your water plant'
        : repo.shopById(order.shopId!)?.name ?? 'Your water plant';

    if (order.isPhoneDispatch) {
      showAdminDispatchManageSheet(
        context: context,
        order: order,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        shopName: shopName,
      );
      return;
    }

    if (!order.isPending) {
      showDispatchDetailSheet(
        context: context,
        order: order,
        customerName: customerName,
        customerPhone: customerPhone,
        shopName: shopName,
        isMonthlyCustomer: customer?.isMonthlyContract ?? false,
      );
      return;
    }

    showOrderRespondSheet(
      context: context,
      order: order,
      customerName: customerName,
      customerPhone: customerPhone,
      shopName: shopName,
      isMonthlyCustomer: customer?.isMonthlyContract ?? false,
      onAccept: () async {
        await context.read<OrderWorkflowService>().acceptOrder(
          orderId: order.id,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request accepted. Driver notified to deliver to $customerName',
              style: GoogleFonts.poppins(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onReject: (reason) async {
        await context.read<OrderWorkflowService>().rejectOrder(
          orderId: order.id,
          reason: reason,
        );
        if (!context.mounted) return;
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
                  title: 'Dispatch',
                  showAddButton: true,
                  onAdd: () async {
                    final saved = await showCreateDispatchSheet(context);
                    if (!context.mounted || saved != true) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Walk-in dispatch sent to driver',
                          style: GoogleFonts.poppins(),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onMenu: () => context.go(AppRoutes.more),
                ),
                CustomersSearchRow(
                  controller: _search,
                  hintText: 'Search dispatch, customer, phone...',
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
                                  final walkIn = order.walkInContact;
                                  final customerName =
                                      customer?.name ?? walkIn?.name ?? 'Unknown';
                                  final customerPhone =
                                      customer?.phone ?? walkIn?.phone ?? '';
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
                                    customerName: customerName,
                                    customerPhone: customerPhone,
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
            OrderListFilter.pending => 'No new app requests',
            OrderListFilter.walkIn => 'No walk-in dispatches yet',
            OrderListFilter.outForDelivery => 'Nothing out for delivery',
            OrderListFilter.delivered => 'No completed dispatches',
            OrderListFilter.all => 'No dispatches yet',
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
            'Tap + when someone calls for water today',
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
