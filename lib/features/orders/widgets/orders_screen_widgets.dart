import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/dispatch_collection_status.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

enum OrderListFilter {
  pending,
  walkIn,
  outForDelivery,
  payPending,
  delivered,
  all,
}

extension OrderListFilterX on OrderListFilter {
  String get label => switch (this) {
        OrderListFilter.pending => 'New requests',
        OrderListFilter.walkIn => 'Instant / phone',
        OrderListFilter.outForDelivery => 'Out for delivery',
        OrderListFilter.payPending => 'Pay pending',
        OrderListFilter.delivered => 'Completed',
        OrderListFilter.all => 'All orders',
      };

  String get shortLabel => switch (this) {
        OrderListFilter.pending => 'New',
        OrderListFilter.walkIn => 'Instant',
        OrderListFilter.outForDelivery => 'Out for delivery',
        OrderListFilter.payPending => 'Pay pending',
        OrderListFilter.delivered => 'Done',
        OrderListFilter.all => 'All',
      };

  Color get accent => switch (this) {
        OrderListFilter.pending => const Color(0xFFEA580C),
        OrderListFilter.walkIn => const Color(0xFF7C3AED),
        OrderListFilter.outForDelivery => CustomersColors.addButton,
        OrderListFilter.payPending => const Color(0xFFD97706),
        OrderListFilter.delivered => const Color(0xFF16A34A),
        OrderListFilter.all => CustomersColors.titleNavy,
      };

  IconData get icon => switch (this) {
        OrderListFilter.pending => Icons.notifications_active_outlined,
        OrderListFilter.walkIn => Icons.bolt_rounded,
        OrderListFilter.outForDelivery => Icons.local_shipping_outlined,
        OrderListFilter.payPending => Icons.payments_outlined,
        OrderListFilter.delivered => Icons.check_circle_outline,
        OrderListFilter.all => Icons.list_alt_rounded,
      };
}

/// Compact status filter — same pill pattern as Customers route/payment bar.
class OrdersStatusFilterBar extends StatelessWidget {
  const OrdersStatusFilterBar({
    super.key,
    required this.selected,
    required this.pendingCount,
    required this.counts,
    required this.onSelected,
  });

  final OrderListFilter selected;
  final int pendingCount;
  final Map<OrderListFilter, int> counts;
  final ValueChanged<OrderListFilter> onSelected;

  bool get _active => selected != OrderListFilter.outForDelivery;

  Future<void> _openSheet(BuildContext context) async {
    final picked = await showModalBottomSheet<OrderListFilter?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _OrdersStatusFilterSheet(
        selected: selected,
        pendingCount: pendingCount,
        counts: counts,
      ),
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: _OrdersFilterPill(
        label: selected.shortLabel,
        icon: selected.icon,
        active: _active,
        accent: selected.accent,
        badge: selected == OrderListFilter.pending && pendingCount > 0
            ? pendingCount
            : null,
        onTap: () => _openSheet(context),
      ),
    );
  }
}

class _OrdersFilterPill extends StatelessWidget {
  const _OrdersFilterPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? accent.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? accent : CustomersColors.cardBorder,
              width: active ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: active ? accent : CustomersColors.labelGrey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? accent : CustomersColors.titleNavy,
                  ),
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: active ? accent : CustomersColors.labelGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersStatusFilterSheet extends StatelessWidget {
  const _OrdersStatusFilterSheet({
    required this.selected,
    required this.pendingCount,
    required this.counts,
  });

  final OrderListFilter selected;
  final int pendingCount;
  final Map<OrderListFilter, int> counts;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CustomersColors.divider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Show orders',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: CustomersColors.titleNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Filter by delivery status',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: CustomersColors.labelGrey,
            ),
          ),
          const SizedBox(height: 14),
          ...OrderListFilter.values.map((filter) {
            final isSelected = filter == selected;
            final count = counts[filter] ?? 0;
            final badge = filter == OrderListFilter.pending && pendingCount > 0
                ? pendingCount
                : count;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected
                    ? filter.accent.withValues(alpha: 0.08)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => Navigator.pop(context, filter),
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? filter.accent : CustomersColors.cardBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        Icon(filter.icon, size: 20, color: filter.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            filter.label,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: CustomersColors.titleNavy,
                            ),
                          ),
                        ),
                        Text(
                          '$badge',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: CustomersColors.labelGrey,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_rounded, size: 20, color: filter.accent),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Fixed bottom-right — matches Customers / Products add buttons.
class OrdersQuickAddButton extends StatelessWidget {
  const OrdersQuickAddButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: CustomersColors.addButton.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      color: CustomersColors.addButton,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 6),
              Text(
                'New order',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Amount + payment line for instant / phone-call jobs on the admin list.
String? instantOrderAmountLabel(CustomerOrder order, double estimatedTotal) {
  if (!order.isPhoneDispatch || order.isInstantNoStock) return null;

  if (order.isDelivered) {
    final amount = order.collectedAmount;
    final status = order.collectionStatus;
    if (status == DispatchCollectionStatus.collected &&
        amount != null &&
        amount > 0) {
      final method = order.collectionMethod == 'upi' ? 'UPI' : 'Cash';
      return '${CurrencyUtils.format(amount)} · $method';
    }
    if (order.isPaymentPending && estimatedTotal > 0) {
      return '${CurrencyUtils.format(estimatedTotal)} · Pay pending';
    }
    if (status == DispatchCollectionStatus.waived) {
      return estimatedTotal > 0
          ? '${CurrencyUtils.format(estimatedTotal)} · Pay later'
          : 'Pay later';
    }
    if (estimatedTotal > 0) {
      return CurrencyUtils.format(estimatedTotal);
    }
    return null;
  }

  if (order.isActiveDispatch && estimatedTotal > 0) {
    return 'Est. ${CurrencyUtils.format(estimatedTotal)}';
  }
  return null;
}

class OrderListCard extends StatelessWidget {
  const OrderListCard({
    super.key,
    required this.order,
    required this.customerName,
    required this.customerPhone,
    required this.shopName,
    required this.isMonthlyCustomer,
    required this.initials,
    required this.colorIndex,
    required this.onTap,
    this.estimatedTotal = 0,
  });

  final CustomerOrder order;
  final String customerName;
  final String customerPhone;
  final String shopName;
  final bool isMonthlyCustomer;
  final String initials;
  final int colorIndex;
  final VoidCallback onTap;
  final double estimatedTotal;

  @override
  Widget build(BuildContext context) {
    final accent = CustomersColors
        .avatarBgs[colorIndex % CustomersColors.avatarBgs.length];
    final statusStyle = _dispatchStatusStyle(order);
    final statusLabel = order.isPhoneDispatch || order.isDelivered || order.isCancelled
        ? order.dispatchTrackerLabel
        : order.status.label;
    final amountLabel = instantOrderAmountLabel(order, estimatedTotal);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: order.isPending
                    ? statusStyle.border
                    : CustomersColors.cardBorder,
                width: order.isPending ? 1.5 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: accent.withValues(alpha: 0.14),
                  child: Text(
                    initials,
                    style: GoogleFonts.poppins(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customerName,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: CustomersColors.titleNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusBadge(
                            style: statusStyle,
                            label: statusLabel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CustomersColors.addButton,
                        ),
                      ),
                      if (amountLabel != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          amountLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: order.isPaymentPending
                                ? const Color(0xFFEA580C)
                                : order.isDelivered &&
                                        order.collectionStatus ==
                                            DispatchCollectionStatus.collected
                                    ? const Color(0xFF16A34A)
                                    : CustomersColors.titleNavy,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _InfoChip(
                            icon: Icons.account_balance_wallet_outlined,
                            label: isMonthlyCustomer
                                ? 'Monthly customer'
                                : 'Customer',
                            color: CustomersColors.addButton,
                          ),
                          if (customerPhone.isNotEmpty)
                            _InfoChip(
                              icon: Icons.phone_outlined,
                              label: customerPhone,
                              color: CustomersColors.labelGrey,
                            ),
                          if (order.isPhoneDispatch)
                            _InfoChip(
                              icon: Icons.bolt_rounded,
                              label: order.isInstantNoStock ? 'No stock' : 'Instant',
                              color: order.isInstantNoStock
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF7C3AED),
                            ),
                          if (order.isPaymentPending)
                            _InfoChip(
                              icon: Icons.schedule_rounded,
                              label: 'Pay pending',
                              color: const Color(0xFFEA580C),
                            ),
                          if (order.isDelivered &&
                              order.collectionStatus ==
                                  DispatchCollectionStatus.collected)
                            _InfoChip(
                              icon: Icons.check_circle_outline,
                              label: 'Paid',
                              color: const Color(0xFF16A34A),
                            ),
                          if (order.lineItems.isNotEmpty)
                            ...order.lineItems.map(
                              (l) => _CanChip(
                                label: '${l.quantity} ${l.label}',
                                cool: l.isCoolCan,
                              ),
                            )
                          else ...[
                            if (order.normalQty > 0)
                              _CanChip(
                                label: '${order.normalQty} Normal',
                                cool: false,
                              ),
                            if (order.coolQty > 0)
                              _CanChip(
                                label: '${order.coolQty} Cool',
                                cool: true,
                              ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Requested ${_timeAgo(order.createdAt)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: CustomersColors.labelGrey,
                        ),
                      ),
                      if (order.adminResponse != null &&
                          order.adminResponse!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          order.adminResponse!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: statusStyle.text,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: order.isPending
                      ? CustomersColors.addButton
                      : CustomersColors.labelGrey,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.style, required this.label});

  final _StatusStyle style;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: style.text,
        ),
      ),
    );
  }
}

class _CanChip extends StatelessWidget {
  const _CanChip({required this.label, required this.cool});

  final String label;
  final bool cool;

  @override
  Widget build(BuildContext context) {
    final color = cool ? const Color(0xFF0D9488) : CustomersColors.addButton;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.bg,
    required this.text,
    required this.border,
  });

  final Color bg;
  final Color text;
  final Color border;
}

_StatusStyle _statusStyle(OrderStatus status) {
  return switch (status) {
    OrderStatus.pending => const _StatusStyle(
      bg: Color(0xFFFFF7ED),
      text: Color(0xFF9A3412),
      border: Color(0xFFFDBA74),
    ),
    OrderStatus.accepted => const _StatusStyle(
      bg: Color(0xFFECFDF5),
      text: Color(0xFF166534),
      border: Color(0xFF86EFAC),
    ),
    OrderStatus.rejected => const _StatusStyle(
      bg: Color(0xFFFEF2F2),
      text: Color(0xFF991B1B),
      border: Color(0xFFFECACA),
    ),
    OrderStatus.cancelled => const _StatusStyle(
      bg: Color(0xFFF3F4F6),
      text: Color(0xFF4B5563),
      border: Color(0xFFD1D5DB),
    ),
  };
}

_StatusStyle _dispatchStatusStyle(CustomerOrder order) {
  if (order.isCancelled) {
    return const _StatusStyle(
      bg: Color(0xFFF3F4F6),
      text: Color(0xFF4B5563),
      border: Color(0xFFD1D5DB),
    );
  }
  if (order.isDelivered) {
    return const _StatusStyle(
      bg: Color(0xFFECFDF5),
      text: Color(0xFF166534),
      border: Color(0xFF86EFAC),
    );
  }
  if (order.isActiveDispatch) {
    return const _StatusStyle(
      bg: Color(0xFFEFF6FF),
      text: Color(0xFF1D4ED8),
      border: Color(0xFF93C5FD),
    );
  }
  return _statusStyle(order.status);
}

Widget dispatchStatusBadge(CustomerOrder order) {
  final style = _dispatchStatusStyle(order);
  final label = order.isPhoneDispatch || order.isDelivered || order.isCancelled
      ? order.dispatchTrackerLabel
      : order.status.label;
  return _StatusBadge(style: style, label: label);
}

String dispatchTimeLabel(DateTime date) {
  final h = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
  final ampm = date.hour >= 12 ? 'PM' : 'AM';
  return '$h:${date.minute.toString().padLeft(2, '0')} $ampm';
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays == 1) {
    final h = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return 'Yesterday, $h:${date.minute.toString().padLeft(2, '0')} $ampm';
  }
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return date.dayMonth;
}

/// View-only sheet for phone dispatch or completed requests.
Future<void> showDispatchDetailSheet({
  required BuildContext context,
  required CustomerOrder order,
  required String customerName,
  required String customerPhone,
  required String shopName,
  required bool isMonthlyCustomer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(ctx).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            order.isPhoneDispatch ? 'Walk-in dispatch' : 'Dispatch details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'Customer', value: customerName),
          _DetailRow(label: 'Phone', value: customerPhone),
          _DetailRow(label: 'Plant', value: shopName),
          _DetailRow(label: 'Products', value: order.itemsSummary),
          _DetailRow(label: 'Status', value: order.status.label),
          _DetailRow(label: 'Payment', value: order.paymentMode.label),
          if (order.customerNote != null && order.customerNote!.isNotEmpty)
            _DetailRow(label: 'Note', value: order.customerNote!),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),
  );
}

/// Bottom sheet: view order + accept / decline (pending only).
Future<void> showOrderRespondSheet({
  required BuildContext context,
  required CustomerOrder order,
  required String customerName,
  required String customerPhone,
  required String shopName,
  required bool isMonthlyCustomer,
  required VoidCallback onAccept,
  required void Function(String reason) onReject,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _OrderRespondSheet(
      order: order,
      customerName: customerName,
      customerPhone: customerPhone,
      shopName: shopName,
      isMonthlyCustomer: isMonthlyCustomer,
      onAccept: () {
        Navigator.pop(ctx);
        onAccept();
      },
      onReject: (reason) {
        Navigator.pop(ctx);
        onReject(reason);
      },
    ),
  );
}

class _OrderRespondSheet extends StatefulWidget {
  const _OrderRespondSheet({
    required this.order,
    required this.customerName,
    required this.customerPhone,
    required this.shopName,
    required this.isMonthlyCustomer,
    required this.onAccept,
    required this.onReject,
  });

  final CustomerOrder order;
  final String customerName;
  final String customerPhone;
  final String shopName;
  final bool isMonthlyCustomer;
  final VoidCallback onAccept;
  final void Function(String reason) onReject;

  @override
  State<_OrderRespondSheet> createState() => _OrderRespondSheetState();
}

class _OrderRespondSheetState extends State<_OrderRespondSheet> {
  static const _rejectReasons = [
    'Out of stock — Normal cans',
    'Out of stock — Cool cans',
    'Out of stock — All cans',
    'Cannot deliver today',
    'Shop closed',
  ];

  String? _selectedReason;
  final _customReason = TextEditingController();

  @override
  void dispose() {
    _customReason.dispose();
    super.dispose();
  }

  void _submitReject() {
    final reason = _selectedReason == 'Other'
        ? _customReason.text.trim()
        : _selectedReason;
    if (reason == null || reason.isEmpty) return;
    widget.onReject(reason);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isPending = order.isPending;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CustomersColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPending ? 'Review customer request' : 'Request details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CustomersColors.titleNavy,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'Customer', value: widget.customerName),
          _DetailRow(label: 'Phone', value: widget.customerPhone),
          _DetailRow(label: 'Plant', value: widget.shopName),
          _DetailRow(
            label: 'Account',
            value: widget.isMonthlyCustomer ? 'Monthly customer' : 'Customer',
          ),
          _DetailRow(label: 'Products', value: order.itemsSummary),
          _DetailRow(label: 'Requested', value: _timeAgo(order.createdAt)),
          if (order.customerNote != null && order.customerNote!.isNotEmpty)
            _DetailRow(label: 'Customer note', value: order.customerNote!),
          if (order.adminResponse != null && order.adminResponse!.isNotEmpty)
            _DetailRow(label: 'Your response', value: order.adminResponse!),
          if (isPending) ...[
            const SizedBox(height: 20),
            Text(
              'Decline reason (if not accepting)',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CustomersColors.titleNavy,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._rejectReasons.map(
                  (r) => ChoiceChip(
                    label: Text(r, style: GoogleFonts.poppins(fontSize: 11)),
                    selected: _selectedReason == r,
                    onSelected: (_) => setState(() => _selectedReason = r),
                    selectedColor: const Color(0xFFFEE2E2),
                    labelStyle: GoogleFonts.poppins(
                      color: _selectedReason == r
                          ? const Color(0xFF991B1B)
                          : CustomersColors.labelGrey,
                    ),
                  ),
                ),
                ChoiceChip(
                  label: Text(
                    'Other',
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                  selected: _selectedReason == 'Other',
                  onSelected: (_) => setState(() => _selectedReason = 'Other'),
                ),
              ],
            ),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customReason,
                decoration: InputDecoration(
                  hintText: 'Type your message to customer',
                  hintStyle: GoogleFonts.poppins(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _selectedReason != null &&
                            (_selectedReason != 'Other' ||
                                _customReason.text.trim().isNotEmpty)
                        ? _submitReject
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CustomersColors.balanceRed,
                      side: const BorderSide(color: CustomersColors.balanceRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Accept request',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: CustomersColors.addButton,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: CustomersColors.labelGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CustomersColors.titleNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
