import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/services/admin_dispatch_service.dart';
import 'package:sri_sai_ro_water/core/constants/customer_pricing_keys.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/delivery_line_item.dart';
import 'package:sri_sai_ro_water/data/models/order_line_item.dart';
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

  Future<_AdminCollectionChoice?> _pickCollection() {
    return showDialog<_AdminCollectionChoice>(
      context: context,
      builder: (ctx) => const _AdminCollectionDialog(),
    );
  }

  Future<_AdminFulfillmentChoice?> _pickFulfillment(
    CustomerOrder order,
    WaterPlantRepository repo,
  ) {
    final customer = repo.customerById(order.customerId);
    if (customer == null) {
      _snack('Instant customer record not found. Refresh and try again.');
      return Future.value(null);
    }
    return showDialog<_AdminFulfillmentChoice>(
      context: context,
      builder: (ctx) => _AdminFulfillmentDialog(
        order: order,
        customer: customer,
        repo: repo,
      ),
    );
  }

  List<Map<String, dynamic>> _deliveryLinesForChoice({
    required _AdminFulfillmentChoice choice,
    required Customer customer,
    required WaterPlantRepository repo,
  }) {
    final bottles = <BottleDeliveryInput>[
      for (final item in choice.items)
        if (!item.isNormalCan && !item.isCoolCan && item.quantity > 0)
          BottleDeliveryInput(
            label: item.label,
            quantity: item.quantity,
            unitPrice: repo.customerUnitPrice(
              customer,
              productId: item.productId,
              variantId: item.variantId,
            ),
            productId: item.productId,
            variantId: item.variantId,
          ),
    ];

    return repo.buildDeliveryLineMaps(
      customerId: customer.id,
      date: DateTime.now(),
      normalQty: choice.normalQty,
      coolQty: choice.coolQty,
      bottles: bottles,
      customer: customer,
    );
  }

  Future<void> _confirmMarkDelivered(
    CustomerOrder order,
    WaterPlantRepository repo,
  ) async {
    final choice = await _pickFulfillment(order, repo);
    if (choice == null || !mounted) return;
    final customer = repo.customerById(order.customerId);
    if (customer == null) {
      _snack('Instant customer record not found. Refresh and try again.');
      return;
    }
    final lines = _deliveryLinesForChoice(
      choice: choice,
      customer: customer,
      repo: repo,
    );
    await _run(
      () => context.read<AdminDispatchService>().markDeliveredByAdmin(
            orderId: widget.orderId,
            lines: lines,
            emptyNormalReturned: choice.emptyNormalReturned,
            emptyCoolReturned: choice.emptyCoolReturned,
            collectionStatus: choice.status,
            collectedAmount: choice.amount,
            collectionMethod: choice.method,
          ),
      'Delivery saved and ledger updated',
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _updatePayment(CustomerOrder order) async {
    final choice = await _pickCollection();
    if (choice == null || !mounted) return;
    await _run(
      () => context.read<AdminDispatchService>().updateCollectionByAdmin(
            orderId: widget.orderId,
            collectionStatus: choice.status,
            collectedAmount: choice.amount,
            collectionMethod: choice.method,
          ),
      'Payment status updated',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final order = _order(repo)!;
        final bottom = MediaQuery.paddingOf(context).bottom;
        final canManage = order.isActiveDispatch && order.isPhoneDispatch;
        final canUpdatePayment =
            order.isDelivered && order.isPhoneDispatch && order.isPaymentPending;

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
                                    order.isInstantNoStock
                                        ? 'Instant — no stock'
                                        : order.isPhoneDispatch
                                            ? 'Instant delivery'
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
                          body: order.isDelivered && order.collectionStatus != null
                              ? order.collectionSummary.isNotEmpty
                                  ? order.collectionSummary +
                                      (order.collectedAmount != null &&
                                              order.collectedAmount! > 0
                                          ? ' · ${CurrencyUtils.format(order.collectedAmount!)}'
                                          : '')
                                  : order.paymentMode.label
                              : order.paymentMode.label,
                        ),
                        if (order.isInstantNoStock) ...[
                          const SizedBox(height: 14),
                          _InfoCard(
                            icon: Icons.inventory_2_outlined,
                            title: 'Stock',
                            body: order.adminResponse ??
                                'No stock — customer was informed.',
                          ),
                        ],
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
                        if (canUpdatePayment) ...[
                          FilledButton.icon(
                            onPressed: _busy ? null : () => _updatePayment(order),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEA580C),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.payments_outlined),
                            label: Text(
                              'Update payment status',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (canManage) ...[
                          FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _confirmMarkDelivered(order, repo),
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
      label: order.isInstantNoStock ? 'Not sent' : 'Sent to driver',
      done: order.isInstantNoStock ||
          order.status == OrderStatus.accepted ||
          order.isDelivered ||
          order.isCancelled,
      active: order.isActiveDispatch,
      time: order.respondedAt,
      cancelled: order.isInstantNoStock,
    );
    final done = _Step(
      label: order.isInstantNoStock
          ? 'No stock'
          : order.isCancelled
              ? 'Cancelled'
              : 'Delivered',
      done: order.isInstantNoStock || order.isDelivered || order.isCancelled,
      active: order.isDelivered || order.isInstantNoStock || order.isCancelled,
      time: order.isDelivered ? order.fulfilledAt : null,
      cancelled: order.isCancelled || order.isInstantNoStock,
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

class _AdminCollectionChoice {
  const _AdminCollectionChoice({
    required this.status,
    required this.amount,
    required this.method,
  });

  final String status;
  final double amount;
  final String method;
}

class _AdminFulfillmentChoice {
  const _AdminFulfillmentChoice({
    required this.items,
    required this.normalQty,
    required this.coolQty,
    required this.emptyNormalReturned,
    required this.emptyCoolReturned,
    required this.status,
    required this.amount,
    required this.method,
  });

  final List<OrderLineItem> items;
  final int normalQty;
  final int coolQty;
  final int emptyNormalReturned;
  final int emptyCoolReturned;
  final String status;
  final double amount;
  final String method;
}

class _AdminFulfillmentDialog extends StatefulWidget {
  const _AdminFulfillmentDialog({
    required this.order,
    required this.customer,
    required this.repo,
  });

  final CustomerOrder order;
  final Customer customer;
  final WaterPlantRepository repo;

  @override
  State<_AdminFulfillmentDialog> createState() =>
      _AdminFulfillmentDialogState();
}

class _AdminFulfillmentDialogState extends State<_AdminFulfillmentDialog> {
  final Map<String, int> _qtyByKey = {};
  final _amount = TextEditingController();
  String _status = 'collected';
  String _method = 'cash';
  int _emptyNormal = 0;
  int _emptyCool = 0;

  @override
  void initState() {
    super.initState();
    final items = widget.order.lineItems.isNotEmpty
        ? widget.order.lineItems
        : [
            if (widget.order.normalQty > 0)
              OrderLineItem(
                productId: CustomerPricingKeys.canProductId,
                variantId: CustomerPricingKeys.normalVariantId,
                label: 'Normal Can',
                quantity: widget.order.normalQty,
              ),
            if (widget.order.coolQty > 0)
              OrderLineItem(
                productId: CustomerPricingKeys.canProductId,
                variantId: CustomerPricingKeys.coolVariantId,
                label: 'Cool Can',
                quantity: widget.order.coolQty,
              ),
          ];
    for (final item in items) {
      _qtyByKey[_key(item)] = item.quantity;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String _key(OrderLineItem item) => '${item.productId}|${item.variantId}';

  List<OrderLineItem> get _templateItems {
    if (widget.order.lineItems.isNotEmpty) return widget.order.lineItems;
    return [
      if (widget.order.normalQty > 0)
        OrderLineItem(
          productId: CustomerPricingKeys.canProductId,
          variantId: CustomerPricingKeys.normalVariantId,
          label: 'Normal Can',
          quantity: widget.order.normalQty,
        ),
      if (widget.order.coolQty > 0)
        OrderLineItem(
          productId: CustomerPricingKeys.canProductId,
          variantId: CustomerPricingKeys.coolVariantId,
          label: 'Cool Can',
          quantity: widget.order.coolQty,
        ),
    ];
  }

  List<OrderLineItem> get _actualItems {
    return [
      for (final item in _templateItems)
        if ((_qtyByKey[_key(item)] ?? 0) > 0)
          OrderLineItem(
            productId: item.productId,
            variantId: item.variantId,
            label: item.label,
            quantity: _qtyByKey[_key(item)] ?? 0,
          ),
    ];
  }

  int get _normalQty => _actualItems
      .where((item) => item.isNormalCan)
      .fold<int>(0, (total, item) => total + item.quantity);

  int get _coolQty => _actualItems
      .where((item) => item.isCoolCan)
      .fold<int>(0, (total, item) => total + item.quantity);

  int get _deliveredTotal =>
      _actualItems.fold<int>(0, (total, item) => total + item.quantity);

  double get _estimate =>
      widget.repo.estimateDispatchTotal(widget.customer, _actualItems);

  void _submit() {
    if (_deliveredTotal <= 0) {
      _snack('Enter what was delivered');
      return;
    }
    final typedAmount = double.tryParse(_amount.text.trim());
    final amount = _status == 'collected' ? (typedAmount ?? _estimate) : 0.0;
    if (_status == 'collected' && amount <= 0) {
      _snack('Enter amount collected');
      return;
    }
    Navigator.pop(
      context,
      _AdminFulfillmentChoice(
        items: _actualItems,
        normalQty: _normalQty,
        coolQty: _coolQty,
        emptyNormalReturned: _emptyNormal,
        emptyCoolReturned: _emptyCool,
        status: _status,
        amount: amount,
        method: _method,
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.poppins())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Confirm delivered',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Actual delivered',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CustomersColors.titleNavy,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in _templateItems) ...[
              _AdminQtyRow(
                label: item.label,
                value: _qtyByKey[_key(item)] ?? 0,
                onChanged: (value) =>
                    setState(() => _qtyByKey[_key(item)] = value),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Empty returned',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CustomersColors.titleNavy,
              ),
            ),
            const SizedBox(height: 8),
            _AdminQtyRow(
              label: 'Empty normal',
              value: _emptyNormal,
              onChanged: (value) => setState(() => _emptyNormal = value),
            ),
            const SizedBox(height: 8),
            _AdminQtyRow(
              label: 'Empty cool',
              value: _emptyCool,
              onChanged: (value) => setState(() => _emptyCool = value),
            ),
            const SizedBox(height: 14),
            Text(
              'Payment',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CustomersColors.titleNavy,
              ),
            ),
            const SizedBox(height: 8),
            _RadioTile(
              title: 'Cash / UPI received',
              value: 'collected',
              group: _status,
              onChanged: (v) => setState(() => _status = v),
            ),
            _RadioTile(
              title: 'Not paid - customer will pay admin',
              value: 'pending',
              group: _status,
              onChanged: (v) => setState(() => _status = v),
            ),
            _RadioTile(
              title: 'Pay later / waived',
              value: 'waived',
              group: _status,
              onChanged: (v) => setState(() => _status = v),
            ),
            if (_status == 'collected') ...[
              const SizedBox(height: 8),
              Text(
                'Estimated amount: ${CurrencyUtils.format(_estimate)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CustomersColors.labelGrey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Collected amount',
                  hintText: _estimate > 0 ? _estimate.toStringAsFixed(0) : '',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: InputDecoration(
                  labelText: 'Method',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _method = v);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: CustomersColors.addButton,
          ),
          child: Text(
            'Save delivery',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _AdminQtyRow extends StatelessWidget {
  const _AdminQtyRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomersColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CustomersColors.titleNavy,
              ),
            ),
          ),
          IconButton(
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: CustomersColors.addButton,
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CustomersColors.titleNavy,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle),
            color: CustomersColors.addButton,
          ),
        ],
      ),
    );
  }
}

class _AdminCollectionDialog extends StatefulWidget {
  const _AdminCollectionDialog();

  @override
  State<_AdminCollectionDialog> createState() => _AdminCollectionDialogState();
}

class _AdminCollectionDialogState extends State<_AdminCollectionDialog> {
  String _status = 'collected';
  final _amount = TextEditingController();
  String _method = 'cash';

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (_status == 'collected' && amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter amount collected', style: GoogleFonts.poppins()),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _AdminCollectionChoice(
        status: _status,
        amount: _status == 'collected' ? amount : 0,
        method: _method,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Payment status', style: GoogleFonts.poppins()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Driver called or customer paid later?',
              style: GoogleFonts.poppins(fontSize: 13, color: CustomersColors.labelGrey),
            ),
            const SizedBox(height: 12),
            _RadioTile(
              title: 'Cash / UPI received',
              value: 'collected',
              group: _status,
              onChanged: (v) => setState(() => _status = v),
            ),
            _RadioTile(
              title: 'Not paid — customer will pay admin',
              value: 'pending',
              group: _status,
              onChanged: (v) => setState(() => _status = v),
            ),
            _RadioTile(
              title: 'Pay later / waived',
              value: 'waived',
              group: _status,
              onChanged: (v) => setState(() => _status = v),
            ),
            if (_status == 'collected') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: InputDecoration(
                  labelText: 'Method',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _method = v);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: CustomersColors.addButton),
          child: Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _RadioTile extends StatelessWidget {
  const _RadioTile({
    required this.title,
    required this.value,
    required this.group,
    required this.onChanged,
  });

  final String title;
  final String value;
  final String group;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      minLeadingWidth: 24,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? CustomersColors.addButton : CustomersColors.labelGrey,
        size: 20,
      ),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 13)),
      onTap: () => onChanged(value),
    );
  }
}
