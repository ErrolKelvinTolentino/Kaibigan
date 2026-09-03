import 'package:intl/intl.dart';

class DateFormatter {
  // Example: Hulyo 15 - 9:41 PM
  static String formatFullDate(DateTime date, {String language = 'taglish'}) {
    final monthsFilipino = [
      'Enero',
      'Pebrero',
      'Marso',
      'Abril',
      'Mayo',
      'Hunyo',
      'Hulyo',
      'Agosto',
      'Setyembre',
      'Oktubre',
      'Nobyembre',
      'Disyembre'
    ];

    if (language == 'filipino' || language == 'taglish') {
      final month = monthsFilipino[date.month - 1];
      final timeStr = DateFormat('h:mm a').format(date);
      return '$month ${date.day} - $timeStr';
    }

    return DateFormat('MMMM d - h:mm a').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatJournalDate(DateTime date, {String language = 'taglish'}) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final isToday = localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day;
    final timeStr = DateFormat('h:mm a').format(localDate);
    if (isToday) {
      final todayLabel = language == 'filipino' ? 'Ngayon' : 'Today';
      return '$todayLabel • $timeStr';
    }
    return '${DateFormat('MMM d, yyyy').format(localDate)} • $timeStr';
  }

  static String formatTimeOnly(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
}
