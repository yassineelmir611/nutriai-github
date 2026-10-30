import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateLabel = DateFormat('EEE, MMM d');
  static final DateFormat _timeLabel = DateFormat('HH:mm');
  static final DateFormat _groupKey = DateFormat('yyyy-MM-dd');
  static final DateFormat _full = DateFormat('MMM d, yyyy • HH:mm');
  static final DateFormat _monthLabel = DateFormat('MMMM yyyy');

  static String formatDateLabel(DateTime date) => _dateLabel.format(date);
  static String formatTimeLabel(DateTime date) => _timeLabel.format(date);
  static String groupKey(DateTime date) => _groupKey.format(date);
  static String formatFull(DateTime date) => _full.format(date);
  static String formatMonthLabel(DateTime date) => _monthLabel.format(date);

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  static DateTime addMonths(DateTime date, int months) =>
      DateTime(date.year, date.month + months, 1);

  static int daysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;

  static bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static bool isSameMonth(DateTime first, DateTime second) {
    return first.year == second.year && first.month == second.month;
  }

  static DateTime dateFromKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date key: $key');
    }

    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }
}
