import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _full = DateFormat('d MMM yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _monthOnly = DateFormat('MMMM');
  static final DateFormat _time = DateFormat('h:mm a');

  String get dayMonth => _dayMonth.format(this);
  String get timeLabel => _time.format(this);
  String get fullDate => _full.format(this);
  String get monthYear => _monthYear.format(this);
  /// Month name only, e.g. "May" (use when year is shown elsewhere).
  String get monthName => _monthOnly.format(this);

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  DateTime get monthStart => DateTime(year, month);
}
