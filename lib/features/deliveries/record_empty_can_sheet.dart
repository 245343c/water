import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_can_balance.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/deliveries/widgets/add_delivery_widgets.dart';
import 'package:sri_sai_ro_water/features/deliveries/widgets/record_empty_can_widgets.dart';

/// Quick modal to record empty cans returned (no full-page navigation).
Future<bool?> showRecordEmptyCanReturnSheet(
  BuildContext context, {
  required String customerId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) => _RecordEmptyCanReturnSheet(customerId: customerId),
  );
}

class _RecordEmptyCanReturnSheet extends StatefulWidget {
  const _RecordEmptyCanReturnSheet({required this.customerId});

  final String customerId;

  @override
  State<_RecordEmptyCanReturnSheet> createState() =>
      _RecordEmptyCanReturnSheetState();
}

class _RecordEmptyCanReturnSheetState extends State<_RecordEmptyCanReturnSheet> {
  int _emptyNormal = 0;
  int _emptyCool = 0;
  bool _saving = false;
  bool _saved = false;

  bool _canSave(bool showNormal, bool showCool) {
    if (_emptyNormal > 0 && showNormal) return true;
    if (_emptyCool > 0 && showCool) return true;
    return false;
  }

  String _successSummary(bool showNormal, bool showCool) {
    final parts = <String>[];
    if (showNormal && _emptyNormal > 0) {
      parts.add('$_emptyNormal normal');
    }
    if (showCool && _emptyCool > 0) {
      parts.add('$_emptyCool cool');
    }
    return parts.join(' · ');
  }

  Future<void> _save(
    WaterPlantRepository repo,
    Customer customer,
    bool showNormal,
    bool showCool,
  ) async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final auth = context.read<AuthRepository>();
    final staffId = auth.currentUser?.role == AppRole.driver
        ? auth.currentUser?.driverId
        : auth.currentUser?.id;
    final date = DateTime.now();

    try {
      await repo.recordEmptyCanReturnToCurrentShop(
        customerId: widget.customerId,
        date: date,
        emptyNormalReturned: showNormal ? _emptyNormal : 0,
        emptyCoolReturned: showCool ? _emptyCool : 0,
        driverId: staffId,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save. Try again.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = repo.customerById(widget.customerId);
        if (customer == null) {
          return const _SheetChrome(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Customer not found'),
            ),
          );
        }

        final balance = repo.customerCanBalance(widget.customerId);
        final showNormal = repo.customerUsesNormalCans(customer);
        final showCool = repo.customerUsesCoolCans(customer);
        final canSave = _canSave(showNormal, showCool);
        final total = (showNormal ? _emptyNormal : 0) + (showCool ? _emptyCool : 0);

        if (_saved) {
          return _SheetChrome(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: RecordEmptyCanColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 40,
                      color: RecordEmptyCanColors.accent,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Saved',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: RecordEmptyCanColors.titleNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _successSummary(showNormal, showCool),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: RecordEmptyCanColors.labelGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _SheetChrome(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Return empty cans',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: RecordEmptyCanColors.titleNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customer.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: RecordEmptyCanColors.labelGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: RecordEmptyCanColors.labelGrey,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _BalanceQuickRow(
                    balance: balance,
                    showNormal: showNormal,
                    showCool: showCool,
                    onTapNormal: showNormal && balance.normalWithCustomer > 0
                        ? () => setState(
                              () => _emptyNormal = balance.normalWithCustomer,
                            )
                        : null,
                    onTapCool: showCool && balance.coolWithCustomer > 0
                        ? () => setState(
                              () => _emptyCool = balance.coolWithCustomer,
                            )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                if (!showNormal && !showCool)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'No can products enabled for this customer.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: RecordEmptyCanColors.labelGrey,
                      ),
                    ),
                  )
                else ...[
                  if (showNormal)
                    AddDeliveryCanStepper(
                      compact: true,
                      label: 'Normal empty',
                      value: _emptyNormal,
                      maxValue: balance.normalWithCustomer,
                      onChanged: (v) => setState(() => _emptyNormal = v),
                    ),
                  if (showCool)
                    AddDeliveryCanStepper(
                      compact: true,
                      label: 'Cool empty',
                      value: _emptyCool,
                      maxValue: balance.coolWithCustomer,
                      onChanged: (v) => setState(() => _emptyCool = v),
                    ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: canSave && !_saving
                          ? () => _save(repo, customer, showNormal, showCool)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: RecordEmptyCanColors.saveBtn,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            RecordEmptyCanColors.saveBtn.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              total > 0
                                  ? 'Save · $total can${total == 1 ? '' : 's'}'
                                  : 'Save',
                            ),
                    ),
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

class _SheetChrome extends StatelessWidget {
  const _SheetChrome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _BalanceQuickRow extends StatelessWidget {
  const _BalanceQuickRow({
    required this.balance,
    required this.showNormal,
    required this.showCool,
    this.onTapNormal,
    this.onTapCool,
  });

  final CustomerCanBalance balance;
  final bool showNormal;
  final bool showCool;
  final VoidCallback? onTapNormal;
  final VoidCallback? onTapCool;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RecordEmptyCanColors.accentBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RecordEmptyCanColors.accentBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'With customer now',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: RecordEmptyCanColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (showNormal)
                Expanded(
                  child: _BalanceTapChip(
                    label: 'Normal',
                    count: balance.normalWithCustomer,
                    color: const Color(0xFF2563EB),
                    onTap: onTapNormal,
                  ),
                ),
              if (showNormal && showCool) const SizedBox(width: 8),
              if (showCool)
                Expanded(
                  child: _BalanceTapChip(
                    label: 'Cool',
                    count: balance.coolWithCustomer,
                    color: RecordEmptyCanColors.accent,
                    onTap: onTapCool,
                  ),
                ),
            ],
          ),
          if (onTapNormal != null || onTapCool != null) ...[
            const SizedBox(height: 6),
            Text(
              'Tap a balance to return all',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: RecordEmptyCanColors.labelGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceTapChip extends StatelessWidget {
  const _BalanceTapChip({
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && count > 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: RecordEmptyCanColors.titleNavy,
                  ),
                ),
              ),
              Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
