import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/services/admin_dispatch_service.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/orders/widgets/orders_screen_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showAdminDispatchManageSheet({
  required BuildContext context,
  required CustomerOrder order,
  required String customerName,
  required String customerPhone,
  required String customerAddress,
  required String shopName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AdminDispatchManageSheet(
      orderId: order.id,
      initialOrder: order,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      shopName: shopName,
    ),
  );
}

class _AdminDispatchManageSheet extends StatefulWidget {
  const _AdminDispatchManageSheet({
    required this.orderId,
    required this.initialOrder,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.shopName,
  });

  final String orderId;
  final CustomerOrder initialOrder;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String shopName;

  @override
  State<_AdminDispatchManageSheet> createState() =>
      _AdminDispatchManageSheetState();
}

class _AdminDispatchManageSheetState extends State<_AdminDispatchManageSheet> {
  late final TextEditingController _noteController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: widget.initialOrder.adminDispatchNote ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  CustomerOrder? _order(WaterPlantRepository repo) =>
      repo.orderById(widget.orderId) ?? widget.initialOrder;

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success, style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _snack(_messageForError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageForError(Object error) {
    if (error is FirebaseFunctionsException) {
      return error.message ?? error.code;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.poppins())),
    );
  }

  Future<void> _callPhone(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final uri = Uri.parse('tel:$digits');
    if (!await launchUrl(uri)) {
      _snack('Could not open phone dialer');
    }
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel dispatch?', style: GoogleFonts.poppins()),
        content: Text(
          'The driver will no longer see this delivery on their list.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep', style: GoogleFonts.poppins()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: Text('Cancel dispatch', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(
      () => context.read<AdminDispatchService>().cancelWalkInDispatch(widget.orderId),
      'Dispatch cancelled',
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmMarkDelivered() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark as delivered?', style: GoogleFonts.poppins()),
        content: Text(
          'Use this when the driver told you delivery is done but could not update the app.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Not yet', style: GoogleFonts.poppins()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: CustomersColors.addButton),
            child: Text('Mark delivered', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(
      () => context.read<AdminDispatchService>().markDeliveredByAdmin(widget.orderId),
      'Marked as delivered',
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final order = _order(repo)!;
        final bottom = MediaQuery.paddingOf(context).bottom;
        final canManage = order.isActiveDispatch && order.isPhoneDispatch;

        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CustomersColors.cardBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 16),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.isPhoneDispatch
                                        ? 'Walk-in dispatch'
                                        : 'Dispatch',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: CustomersColors.titleNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.shopName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: CustomersColors.addButton,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            dispatchStatusBadge(order),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _DispatchTimeline(order: order),
                        const SizedBox(height: 18),
                        _ContactCard(
                          name: widget.customerName,
                          phone: widget.customerPhone,
                          address: widget.customerAddress,
                          onCall: () => _callPhone(widget.customerPhone),
                        ),
                        const SizedBox(height: 14),
                        _ProductsCard(order: order),
                        if (order.customerNote != null &&
                            order.customerNote!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _InfoCard(
                            icon: Icons.notes_rounded,
                            title: 'Caller note',
                            body: order.customerNote!,
                          ),
                        ],
                        const SizedBox(height: 14),
                        _InfoCard(
                          icon: Icons.payments_outlined,
                          title: 'Payment',
                          body: order.paymentMode.label,
                        ),
                        if (order.isDelivered && order.fulfilledByLabel.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _InfoCard(
                            icon: Icons.verified_outlined,
                            title: 'Confirmed by',
                            body: order.fulfilledByLabel,
                          ),
                        ],
                        const SizedBox(height: 18),
                        Text(
                          'Admin note',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CustomersColors.titleNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _noteController,
                          enabled: canManage && !_busy,
                          maxLines: 3,
                          minLines: 2,
                          decoration: InputDecoration(
                            hintText:
                                'Driver called — delivered 8 cans, cash collected…',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: CustomersColors.labelGrey,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: CustomersColors.cardBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: CustomersColors.cardBorder,
                              ),
                            ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        if (canManage) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _run(
                                        () => context
                                            .read<AdminDispatchService>()
                                            .saveAdminNote(
                                              orderId: widget.orderId,
                                              note: _noteController.text.trim(),
                                            ),
                                        'Note saved',
                                      ),
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: Text(
                                'Save note',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (canManage) ...[
                          FilledButton.icon(
                            onPressed: _busy ? null : _confirmMarkDelivered,
                            style: FilledButton.styleFrom(
                              backgroundColor: CustomersColors.addButton,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            label: Text(
                              'Mark as delivered',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _confirmCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.cancel_outlined),
                            label: Text(
                              'Cancel dispatch',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ] else
                          FilledButton(
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
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DispatchTimeline extends StatelessWidget {
  const _DispatchTimeline({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final created = _Step(
      label: 'Created',
      done: true,
      active: order.isActiveDispatch,
      time: order.createdAt,
    );
    final sent = _Step(
      label: 'Sent to driver',
      done: order.status == OrderStatus.accepted || order.isDelivered || order.isCancelled,
      active: order.isActiveDispatch,
      time: order.respondedAt,
    );
    final done = _Step(
      label: order.isCancelled ? 'Cancelled' : 'Delivered',
      done: order.isDelivered || order.isCancelled,
      active: order.isDelivered || order.isCancelled,
      time: order.isDelivered ? order.fulfilledAt : null,
      cancelled: order.isCancelled,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomersColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _TimelineStep(step: created)),
          _TimelineConnector(filled: sent.done),
          Expanded(child: _TimelineStep(step: sent)),
          _TimelineConnector(filled: done.done),
          Expanded(child: _TimelineStep(step: done)),
        ],
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.label,
    required this.done,
    required this.active,
    this.time,
    this.cancelled = false,
  });

  final String label;
  final bool done;
  final bool active;
  final DateTime? time;
  final bool cancelled;
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 0,
      child: Container(
        width: 24,
        height: 2,
        margin: const EdgeInsets.only(bottom: 22),
        color: filled ? CustomersColors.addButton : CustomersColors.cardBorder,
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final color = step.cancelled
        ? const Color(0xFF6B7280)
        : step.done
            ? CustomersColors.addButton
            : CustomersColors.cardBorder;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: step.done ? color.withValues(alpha: 0.12) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: step.active ? 2 : 1),
          ),
          child: Icon(
            step.cancelled
                ? Icons.close_rounded
                : step.done
                    ? Icons.check_rounded
                    : Icons.circle,
            size: step.done ? 16 : 8,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          step.label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: CustomersColors.titleNavy,
          ),
        ),
        if (step.time != null) ...[
          const SizedBox(height: 2),
          Text(
            dispatchTimeLabel(step.time!),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: CustomersColors.labelGrey,
            ),
          ),
        ],
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.name,
    required this.phone,
    required this.address,
    required this.onCall,
  });

  final String name;
  final String phone;
  final String address;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomersColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CustomersColors.titleNavy,
                      ),
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: CustomersColors.labelGrey,
                        ),
                      ),
                  ],
                ),
              ),
              if (phone.isNotEmpty)
                IconButton.filledTonal(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFECFDF5),
                    foregroundColor: CustomersColors.addButton,
                  ),
                ),
            ],
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: CustomersColors.labelGrey.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.4,
                      color: CustomersColors.titleNavy,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductsCard extends StatelessWidget {
  const _ProductsCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomersColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Products',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CustomersColors.labelGrey,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (order.lineItems.isNotEmpty)
                ...order.lineItems.map(
                  (l) => _ProductChip(label: '${l.quantity} ${l.label}', cool: l.isCoolCan),
                )
              else ...[
                if (order.normalQty > 0)
                  _ProductChip(label: '${order.normalQty} Normal', cool: false),
                if (order.coolQty > 0)
                  _ProductChip(label: '${order.coolQty} Cool', cool: true),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  const _ProductChip({required this.label, required this.cool});

  final String label;
  final bool cool;

  @override
  Widget build(BuildContext context) {
    final color = cool ? const Color(0xFF0D9488) : const Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomersColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: CustomersColors.addButton),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CustomersColors.labelGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CustomersColors.titleNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
