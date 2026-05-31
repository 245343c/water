import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_card.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

class CustomerRequestCard extends StatefulWidget {
  const CustomerRequestCard({
    super.key,
    required this.order,
    required this.shopName,
    this.delivery,
    this.onEdit,
    this.onCancel,
  });

  final CustomerOrder order;
  final String shopName;
  final Delivery? delivery;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  @override
  State<CustomerRequestCard> createState() => _CustomerRequestCardState();
}

class _CustomerRequestCardState extends State<CustomerRequestCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (_expanded) {
      return Column(
        children: [
          _ExpandedCustomerRequestCard(
            order: widget.order,
            shopName: widget.shopName,
            delivery: widget.delivery,
            onEdit: widget.onEdit,
            onCancel: widget.onCancel,
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = false),
              icon: const Icon(Icons.expand_less_rounded, size: 18),
              label: const Text('Show less'),
            ),
          ),
        ],
      );
    }
    final style = _RequestStyle.from(_state);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _expanded = true),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CustomerColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(style.icon, color: style.color, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: CustomerColors.titleNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.order.cansSummary,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: CustomerColors.labelGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                PremiumStatusBadge(
                  label: style.label,
                  color: style.color,
                  icon: style.icon,
                  compact: true,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded, size: 19),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _RequestState get _state {
    if (widget.delivery != null) return _RequestState.delivered;
    if (widget.order.isOutForDelivery) return _RequestState.outForDelivery;
    if (widget.order.isDriverAssigned) return _RequestState.driverAssigned;
    return switch (widget.order.status) {
      OrderStatus.pending => _RequestState.pending,
      OrderStatus.accepted => _RequestState.accepted,
      OrderStatus.rejected => _RequestState.rejected,
      OrderStatus.cancelled => _RequestState.cancelled,
    };
  }
}

class _ExpandedCustomerRequestCard extends StatelessWidget {
  const _ExpandedCustomerRequestCard({
    required this.order,
    required this.shopName,
    this.delivery,
    this.onEdit,
    this.onCancel,
  });

  final CustomerOrder order;
  final String shopName;
  final Delivery? delivery;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  _RequestState get _state {
    if (delivery != null) return _RequestState.delivered;
    if (order.isOutForDelivery) return _RequestState.outForDelivery;
    if (order.isDriverAssigned) return _RequestState.driverAssigned;
    return switch (order.status) {
      OrderStatus.pending => _RequestState.pending,
      OrderStatus.accepted => _RequestState.accepted,
      OrderStatus.rejected => _RequestState.rejected,
      OrderStatus.cancelled => _RequestState.cancelled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = _RequestStyle.from(_state);
    final note = order.customerNote?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CustomerColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: style.color.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: style.color,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: style.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              style.icon,
                              color: style.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shopName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: CustomerColors.titleNavy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Requested ${_formatDate(order.createdAt)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: CustomerColors.labelGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PremiumStatusBadge(
                            label: style.label,
                            color: style.color,
                            icon: style.icon,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _RequestPill(
                            icon: Icons.water_drop_outlined,
                            label: order.cansSummary,
                            color: CustomerColors.accent,
                          ),
                          if (delivery != null)
                            _RequestPill(
                              icon: Icons.local_shipping_outlined,
                              label: 'Delivered ${delivery!.date.dayMonth}',
                              color: CustomerColors.success,
                            ),
                        ],
                      ),
                      if (note != null && note.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          note,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            height: 1.35,
                            color: CustomerColors.labelGrey,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      PremiumCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        margin: EdgeInsets.zero,
                        color: style.color.withValues(alpha: 0.05),
                        child: Row(
                          children: [
                            Icon(
                              style.messageIcon,
                              size: 16,
                              color: style.color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  color: CustomerColors.titleNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (order.canCustomerEdit &&
                          (onEdit != null || onCancel != null)) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (onEdit != null)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: onEdit,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Edit',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: CustomerColors.accent,
                                    side: const BorderSide(
                                      color: CustomerColors.cardBorder,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            if (onEdit != null && onCancel != null)
                              const SizedBox(width: 8),
                            if (onCancel != null)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: onCancel,
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Cancel',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFDC2626),
                                    side: const BorderSide(
                                      color: Color(0xFFFECACA),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _statusMessage {
    if (delivery != null) {
      return 'Delivered and added to your monthly account.';
    }
    if (order.isOutForDelivery) {
      return 'Driver started delivery. Your water is on the way.';
    }
    if (order.isDriverAssigned) {
      return 'Driver accepted this request and will start delivery soon.';
    }
    return switch (order.status) {
      OrderStatus.pending => 'Waiting for $shopName to confirm your request.',
      OrderStatus.accepted =>
        order.adminResponse ?? 'Confirmed. Waiting for driver assignment.',
      OrderStatus.rejected =>
        order.adminResponse == null || order.adminResponse!.trim().isEmpty
            ? '$shopName declined this request.'
            : 'Declined: ${order.adminResponse}',
      OrderStatus.cancelled =>
        'You cancelled this request before confirmation.',
    };
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _RequestPill extends StatelessWidget {
  const _RequestPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum _RequestState {
  pending,
  accepted,
  driverAssigned,
  outForDelivery,
  rejected,
  cancelled,
  delivered,
}

class _RequestStyle {
  const _RequestStyle({
    required this.label,
    required this.color,
    required this.icon,
    required this.messageIcon,
  });

  final String label;
  final Color color;
  final IconData icon;
  final IconData messageIcon;

  factory _RequestStyle.from(_RequestState state) {
    return switch (state) {
      _RequestState.pending => const _RequestStyle(
        label: 'Pending',
        color: CustomerColors.warning,
        icon: Icons.schedule_rounded,
        messageIcon: Icons.hourglass_bottom_rounded,
      ),
      _RequestState.accepted => const _RequestStyle(
        label: 'Accepted',
        color: CustomerColors.success,
        icon: Icons.check_circle_rounded,
        messageIcon: Icons.local_shipping_rounded,
      ),
      _RequestState.driverAssigned => const _RequestStyle(
        label: 'Driver Assigned',
        color: Color(0xFF0D9488),
        icon: Icons.assignment_ind_rounded,
        messageIcon: Icons.local_shipping_rounded,
      ),
      _RequestState.outForDelivery => const _RequestStyle(
        label: 'Out for Delivery',
        color: Color(0xFF2563EB),
        icon: Icons.delivery_dining_rounded,
        messageIcon: Icons.route_rounded,
      ),
      _RequestState.rejected => const _RequestStyle(
        label: 'Declined',
        color: Color(0xFFDC2626),
        icon: Icons.cancel_rounded,
        messageIcon: Icons.info_outline_rounded,
      ),
      _RequestState.cancelled => const _RequestStyle(
        label: 'Cancelled',
        color: Color(0xFF6B7280),
        icon: Icons.cancel_schedule_send_rounded,
        messageIcon: Icons.info_outline_rounded,
      ),
      _RequestState.delivered => const _RequestStyle(
        label: 'Delivered',
        color: CustomerColors.success,
        icon: Icons.done_all_rounded,
        messageIcon: Icons.verified_rounded,
      ),
    };
  }
}
