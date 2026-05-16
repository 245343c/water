import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _full = DateFormat('d MMM yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');

  String get dayMonth => _dayMonth.format(this);
  String get fullDate => _full.format(this);
  String get monthYear => _monthYear.format(this);

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  DateTime get monthStart => DateTime(year, month);
}
