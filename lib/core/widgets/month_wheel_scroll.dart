import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Table header for the monthly overview list.
class MonthWheelTableHeader extends StatelessWidget {
  const MonthWheelTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: 0.92),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Month', style: style)),
          Expanded(flex: 3, child: Text('Total', style: style, textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text('Pending', style: style, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Status', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Month rows with **auto height** — grows with 1–4 months, no empty gap inside.
class MonthOverviewList extends StatelessWidget {
  const MonthOverviewList({
    super.key,
    required this.months,
    required this.itemBuilder,
    this.rowHeight = 54,
    this.maxScrollRows = 4,
  });

  final List<DateTime> months;
  final double rowHeight;
  final int maxScrollRows;
  final Widget Function(BuildContext context, DateTime month) itemBuilder;

  static const _borderColor = Color(0xFFD1D5DB);
  static const _bgColor = Color(0xFFF8FAFC);

  double _listHeight(int count) {
    if (count <= 0) return 0;
    const verticalPad = 8.0;
    const separator = 1.0;
    return verticalPad * 2 + count * rowHeight + (count - 1) * separator;
  }

  List<Widget> _buildRows(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < months.length; i++) {
      if (i > 0) {
        rows.add(const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFE5E7EB),
          indent: 10,
          endIndent: 10,
        ));
      }
      rows.add(
        SizedBox(
          height: rowHeight,
          child: itemBuilder(context, months[i]),
        ),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) return const SizedBox.shrink();

    final useScroll = months.length > maxScrollRows;
    final visibleCount = useScroll ? maxScrollRows : months.length;
    final boxHeight = _listHeight(visibleCount);

    final listBody = Column(
      mainAxisSize: MainAxisSize.min,
      children: _buildRows(context),
    );

    return Container(
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: useScroll
          ? SizedBox(
              height: boxHeight,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                physics: const BouncingScrollPhysics(),
                children: _buildRows(context),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: listBody,
            ),
    );
  }
}
