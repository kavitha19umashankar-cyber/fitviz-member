import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class FitDateUtils {
  FitDateUtils._();

  static String formatDate(DateTime dt) =>
      DateFormat(AppConstants.dateFormat).format(dt.toLocal());

  static String formatTime(DateTime dt) =>
      DateFormat(AppConstants.timeFormat).format(dt.toLocal());

  /// Formats a time string like "09:00:00" or ISO datetime → "09:00 AM".
  static String formatTimeString(String s) {
    final dt = DateTime.tryParse(s) ??
        DateTime.tryParse('1970-01-01T$s') ??
        DateTime.now();
    return formatTime(dt);
  }

  static String formatDateTime(DateTime dt) =>
      DateFormat(AppConstants.dateTimeFormat).format(dt.toLocal());

  static String toApiDate(DateTime dt) =>
      DateFormat(AppConstants.apiDateFormat).format(dt);

  static DateTime? parseApiDate(String? s) {
    if (s == null) return null;
    return DateTime.tryParse(s);
  }

  /// Returns "Today", "Yesterday", or formatted date.
  static String relativeDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final local = dt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return formatDate(dt);
  }

  /// Days until a future date (negative = past).
  static int daysUntil(DateTime dt) =>
      dt.difference(DateTime.now()).inDays;

  /// Consecutive attendance streak from a list of dates (most recent first).
  static int attendanceStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    // De-duplicate to unique calendar days first — multiple check-ins on
    // the same day would otherwise sit next to each other in the sorted
    // list with a 0-day gap, which the loop below reads as a broken streak.
    final sorted = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i - 1].difference(sorted[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
