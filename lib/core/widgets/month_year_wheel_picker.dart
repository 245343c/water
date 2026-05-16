import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Scroll-style month + year picker in a bottom sheet (iOS wheel style).
Future<DateTime?> showMonthYearWheelPicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final first = firstDate ?? DateTime(2020);
  final last = lastDate ?? DateTime.now();
  final clampedInitial = _clampMonth(initial, first, last);

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _MonthYearWheelSheet(
      initial: clampedInitial,
      firstDate: DateTime(first.year, first.month),
      lastDate: DateTime(last.year, last.month),
    ),
  );
}

DateTime _clampMonth(DateTime value, DateTime first, DateTime last) {
  final v = DateTime(value.year, value.month);
  final f = DateTime(first.year, first.month);
  final l = DateTime(last.year, last.month);
  if (v.isBefore(f)) return f;
  if (v.isAfter(l)) return l;
  return v;
}

class _MonthYearWheelSheet extends StatefulWidget {
  const _MonthYearWheelSheet({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_MonthYearWheelSheet> createState() => _MonthYearWheelSheetState();
}

class _MonthYearWheelSheetState extends State<_MonthYearWheelSheet> {
  static final _monthNames = List.generate(
    12,
    (i) => DateFormat.MMMM().format(DateTime(2024, i + 1)),
  );

  late final List<int> _years;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    _years = [
      for (var y = widget.firstDate.year; y <= widget.lastDate.year; y++) y,
    ];
    _month = widget.initial.month;
    _year = widget.initial.year;
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_year).clamp(0, _years.length - 1),
    );
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int get _minMonth => _year == widget.firstDate.year ? widget.firstDate.month : 1;

  int get _maxMonth => _year == widget.lastDate.year ? widget.lastDate.month : 12;

  void _onYearChanged(int index) {
    setState(() {
      _year = _years[index];
      if (_month < _minMonth) {
        _month = _minMonth;
        _monthController.jumpToItem(_month - 1);
      } else if (_month > _maxMonth) {
        _month = _maxMonth;
        _monthController.jumpToItem(_month - 1);
      }
    });
  }

  void _onMonthChanged(int index) {
    setState(() => _month = _minMonth + index);
  }

  void _confirm() {
    Navigator.pop(context, DateTime(_year, _month));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: Row(
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Select month',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onPressed: _confirm,
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1A73E8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    key: ValueKey('$_year-$_minMonth-$_maxMonth'),
                    scrollController: _monthController,
                    itemExtent: 40,
                    magnification: 1.08,
                    squeeze: 1.1,
                    useMagnifier: true,
                    onSelectedItemChanged: _onMonthChanged,
                    children: [
                      for (var m = _minMonth; m <= _maxMonth; m++)
                        Center(
                          child: Text(
                            _monthNames[m - 1],
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _yearController,
                    itemExtent: 40,
                    magnification: 1.08,
                    squeeze: 1.1,
                    useMagnifier: true,
                    onSelectedItemChanged: _onYearChanged,
                    children: [
                      for (final y in _years)
                        Center(
                          child: Text(
                            '$y',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
