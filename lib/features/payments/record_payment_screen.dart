import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/payment_allocation_preview.dart';
import 'package:sri_sai_ro_water/data/models/payment_method.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/payments/widgets/record_payment_widgets.dart';

class RecordPaymentScreen extends StatefulWidget {
  const RecordPaymentScreen({super.key, required this.customerId});

  final String customerId;

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  PaymentMethod _method = PaymentMethod.cash;
  DateTime _date = DateTime.now();
  bool _amountInitialized = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() => setState(() {});

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String _successMessage(PaymentAllocationPreview preview, double amount) {
    final parts = <String>['${CurrencyUtils.format(amount)} recorded'];
    if (preview.appliedToDue > 0) {
      parts.add('${CurrencyUtils.format(preview.appliedToDue)} cleared oldest due');
    }
    if (preview.hasAdvance) {
      parts.add('${CurrencyUtils.format(preview.advanceCredit)} advance credit');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = repo.customerById(widget.customerId);
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Record Payment')),
            body: const Center(child: Text('Customer not found')),
          );
        }

        final month = DateTime.now();
        final monthly = repo.monthlyStatsForCustomer(widget.customerId, month);
        final previousBalance = repo.previousBalanceForMonth(widget.customerId, month);
        final totalPayable = repo.customerBalance(widget.customerId);
        final existingAdvance = repo.customerAdvanceCredit(widget.customerId);

        if (!_amountInitialized && totalPayable > 0) {
          _amountInitialized = true;
          _amountController.text = totalPayable.round().toString();
        }

        final enteredAmount = double.tryParse(_amountController.text) ?? 0;
        final preview = repo.previewPayment(widget.customerId, enteredAmount);

        final colorIndex = repo.customers.indexWhere((c) => c.id == widget.customerId);

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: RecordPaymentScaffold(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  RecordPaymentHeader(onBack: () => context.pop()),
                  Expanded(
                    child: ListView(
                      children: [
                        RecordPaymentCustomerBar(
                          customer: customer,
                          colorIndex: colorIndex >= 0 ? colorIndex : 0,
                        ),
                        RecordPaymentSummaryBox(
                          month: month,
                          totalAmount: monthly.totalAmount,
                          previousBalance: previousBalance,
                          totalPayable: totalPayable,
                          advanceCredit: existingAdvance,
                        ),
                        RecordPaymentLabeledField(
                          label: 'Enter Payment Amount',
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: RecordPaymentColors.titleNavy,
                            ),
                            decoration: InputDecoration(
                              prefixText: '${CurrencyUtils.symbol} ',
                              prefixStyle: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: RecordPaymentColors.titleNavy,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: RecordPaymentColors.fieldBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: RecordPaymentColors.fieldBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: RecordPaymentColors.selectedBorder, width: 1.5),
                              ),
                            ),
                            validator: (v) {
                              final amount = double.tryParse(v ?? '');
                              if (amount == null || amount <= 0) {
                                return 'Enter a valid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        RecordPaymentAllocationPreview(preview: preview),
                        RecordPaymentMethodRow(
                          selected: _method,
                          onSelected: (m) => setState(() => _method = m),
                        ),
                        RecordPaymentLabeledField(
                          label: 'Payment Date',
                          child: RecordPaymentDateField(date: _date, onTap: _pickDate),
                        ),
                        RecordPaymentLabeledField(
                          label: 'Notes (Optional)',
                          child: TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              hintText: 'Enter notes...',
                              hintStyle: GoogleFonts.poppins(
                                color: RecordPaymentColors.labelGrey,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: RecordPaymentColors.fieldBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: RecordPaymentColors.fieldBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: RecordPaymentColors.selectedBorder, width: 1.5),
                              ),
                            ),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  RecordPaymentSaveButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final amount = double.parse(_amountController.text);
                      final split = repo.previewPayment(widget.customerId, amount);
                      try {
                        await repo.addPayment(
                          customerId: widget.customerId,
                          amount: amount,
                          method: _method,
                          date: _date,
                          notes: _notesController.text.trim().isEmpty
                              ? null
                              : _notesController.text.trim(),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not record payment: $e')),
                        );
                        return;
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _successMessage(split, amount),
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                      context.pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
