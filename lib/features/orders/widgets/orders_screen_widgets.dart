import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

enum OrderListFilter { all, pending, accepted, rejected }

class OrdersFilterChips extends StatelessWidget {
  const OrdersFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.pendingCount,
  });

  final OrderListFilter selected;
  final ValueChanged<OrderListFilter> onSelected;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          _Chip(
            label: pendingCount > 0 ? 'New ($pendingCount)' : 'New',
            selected: selected == OrderListFilter.pending,
            onTap: () => onSelected(OrderListFilter.pending),
            highlight: pendingCount > 0,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Accepted',
            selected: selected == OrderListFilter.accepted,
            onTap: () => onSelected(OrderListFilter.accepted),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Declined',
            selected: selected == OrderListFilter.rejected,
            onTap: () => onSelected(OrderListFilter.rejected),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'All',
            selected: selected == OrderListFilter.all,
            onTap: () => onSelected(OrderListFilter.all),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.highlight = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? CustomersColors.addButton
        : (highlight ? const Color(0xFFFFF7ED) : Colors.white);
    final border = selected
        ? CustomersColors.addButton
        : (highlight ? const Color(0xFFFED7AA) : CustomersColors.cardBorder);
    final fg = selected
        ? Colors.white
        : (highlight ? const Color(0xFF9A3412) : CustomersColors.titleNavy);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class OrderListCard extends StatelessWidget {
  const OrderListCard({
    super.key,
    required this.order,
    required this.customerName,
    required this.initials,
    required this.colorIndex,
    required this.onTap,
  });

  final CustomerOrder order;
  final String customerName;
  final String initials;
  final int colorIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = CustomersColors.avatarBgs[colorIndex % CustomersColors.avatarBgs.length];
    final statusStyle = _statusStyle(order.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: order.isPending ? statusStyle.border : CustomersColors.cardBorder,
                width: order.isPending ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
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
                          _StatusBadge(style: statusStyle, label: order.status.label),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (order.normalQty > 0) _CanChip(label: '${order.normalQty} Normal', cool: false),
                          if (order.normalQty > 0 && order.coolQty > 0) const SizedBox(width: 6),
                          if (order.coolQty > 0) _CanChip(label: '${order.coolQty} Cool', cool: true),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _timeAgo(order.createdAt),
                        style: GoogleFonts.poppins(fontSize: 11, color: CustomersColors.labelGrey),
                      ),
                      if (order.adminResponse != null && order.adminResponse!.isNotEmpty) ...[
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
                  color: order.isPending ? CustomersColors.addButton : CustomersColors.labelGrey,
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
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({required this.bg, required this.text, required this.border});

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
  };
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays == 1) {
    final h = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return 'Yesterday, $h:${date.minute.toString().padLeft(2, '0')} $ampm';
  }
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return date.dayMonth;
}

/// Bottom sheet: view order + accept / decline (pending only).
Future<void> showOrderRespondSheet({
  required BuildContext context,
  required CustomerOrder order,
  required String customerName,
  required String customerPhone,
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
    required this.onAccept,
    required this.onReject,
  });

  final CustomerOrder order;
  final String customerName;
  final String customerPhone;
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
            isPending ? 'Respond to order' : 'Order details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CustomersColors.titleNavy,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'Customer', value: widget.customerName),
          _DetailRow(label: 'Phone', value: widget.customerPhone),
          _DetailRow(label: 'Water order', value: order.cansSummary),
          _DetailRow(label: 'Ordered', value: _timeAgo(order.createdAt)),
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
                  label: Text('Other', style: GoogleFonts.poppins(fontSize: 11)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectedReason != null &&
                            (_selectedReason != 'Other' || _customReason.text.trim().isNotEmpty)
                        ? _submitReject
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CustomersColors.balanceRed,
                      side: const BorderSide(color: CustomersColors.balanceRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Accept',
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Close', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
              style: GoogleFonts.poppins(fontSize: 12, color: CustomersColors.labelGrey),
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
