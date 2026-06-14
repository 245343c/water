import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/core/localization/customer_display_localization.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_can_balance.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_can_stepper.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

/// Driver-only bottom sheet — empty can return without a product delivery.
Future<bool?> showDriverRecordEmptyCanSheet(
  BuildContext context, {
  required String customerId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) => _DriverRecordEmptyCanSheet(customerId: customerId),
  );
}

class _DriverRecordEmptyCanSheet extends StatefulWidget {
  const _DriverRecordEmptyCanSheet({required this.customerId});

  final String customerId;

  @override
  State<_DriverRecordEmptyCanSheet> createState() =>
      _DriverRecordEmptyCanSheetState();
}

class _DriverRecordEmptyCanSheetState extends State<_DriverRecordEmptyCanSheet> {
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
    if (showNormal && _emptyNormal > 0) parts.add('$_emptyNormal normal');
    if (showCool && _emptyCool > 0) parts.add('$_emptyCool cool');
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
    final user = auth.currentUser;
    if (user == null || !user.isDriver) {
      setState(() => _saving = false);
      return;
    }
    final staffId = user.driverId;
    final date = DateTime.now();

    try {
      await repo.recordEmptyCanReturnToCurrentShop(
        customerId: widget.customerId,
        date: date,
        emptyNormalReturned: showNormal ? _emptyNormal : 0,
        emptyCoolReturned: showCool ? _emptyCool : 0,
        driverId: staffId,
        driverName: repo.driverById(staffId)?.name ?? user.ownerName,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 650));
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
          return _DriverSheetChrome(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
              child: Text(
                'Customer not found',
                style: GoogleFonts.poppins(color: DriverColors.labelGrey),
              ),
            ),
          );
        }

        final balance = repo.customerCanBalance(widget.customerId);
        final showNormal = repo.customerUsesNormalCans(customer);
        final showCool = repo.customerUsesCoolCans(customer);
        final canSave = _canSave(showNormal, showCool);
        final total =
            (showNormal ? _emptyNormal : 0) + (showCool ? _emptyCool : 0);

        if (_saved) {
          return _DriverSheetChrome(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: DriverColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 40,
                      color: DriverColors.success,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Empty return saved',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: DriverColors.titleNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _successSummary(showNormal, showCool),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: DriverColors.labelGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _DriverSheetChrome(
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
                                color: DriverColors.titleNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customer.driverDisplayName(context.l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: DriverColors.labelGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: DriverColors.labelGrey,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _DriverBalanceQuickRow(
                    balance: balance,
                    showNormal: showNormal,
                    showCool: showCool,
                    onFillNormal: showNormal && balance.normalWithCustomer > 0
                        ? () => setState(
                              () => _emptyNormal = balance.normalWithCustomer,
                            )
                        : null,
                    onFillCool: showCool && balance.coolWithCustomer > 0
                        ? () => setState(
                              () => _emptyCool = balance.coolWithCustomer,
                            )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                if (!showNormal && !showCool)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'No can products enabled for this customer.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: DriverColors.labelGrey,
                      ),
                    ),
                  )
                else ...[
                  if (showNormal)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: DriverCanStepperRow(
                        compact: true,
                        label: 'Normal empty',
                        subtitle: 'Max ${balance.normalWithCustomer} with customer',
                        value: _emptyNormal,
                        color: const Color(0xFF2563EB),
                        maxValue: balance.normalWithCustomer,
                        onChanged: (v) => setState(() => _emptyNormal = v),
                      ),
                    ),
                  if (showCool)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: DriverCanStepperRow(
                        compact: true,
                        label: 'Cool empty',
                        subtitle: 'Max ${balance.coolWithCustomer} with customer',
                        value: _emptyCool,
                        color: DriverColors.accent,
                        maxValue: balance.coolWithCustomer,
                        onChanged: (v) => setState(() => _emptyCool = v),
                      ),
                    ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: canSave && !_saving
                          ? () => _save(repo, customer, showNormal, showCool)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: DriverColors.accent,
                        disabledBackgroundColor:
                            DriverColors.accent.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                                  ? 'Save · $total empty can${total == 1 ? '' : 's'}'
                                  : 'Save return',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
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

class _DriverSheetChrome extends StatelessWidget {
  const _DriverSheetChrome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: DriverColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: DriverColors.accent.withValues(alpha: 0.15),
            blurRadius: 20,
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
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: DriverColors.cardBorder,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _DriverBalanceQuickRow extends StatelessWidget {
  const _DriverBalanceQuickRow({
    required this.balance,
    required this.showNormal,
    required this.showCool,
    this.onFillNormal,
    this.onFillCool,
  });

  final CustomerCanBalance balance;
  final bool showNormal;
  final bool showCool;
  final VoidCallback? onFillNormal;
  final VoidCallback? onFillCool;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DriverColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DriverColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'With customer now',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: DriverColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (showNormal)
                _QuickChip(
                  label: 'Normal ${balance.normalWithCustomer}',
                  onTap: onFillNormal,
                ),
              if (showCool)
                _QuickChip(
                  label: 'Cool ${balance.coolWithCustomer}',
                  onTap: onFillCool,
                ),
            ],
          ),
          if (onFillNormal != null || onFillCool != null) ...[
            const SizedBox(height: 6),
            Text(
              'Tap a chip to fill that amount',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: DriverColors.labelGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DriverColors.titleNavy,
            ),
          ),
        ),
      ),
    );
  }
}
