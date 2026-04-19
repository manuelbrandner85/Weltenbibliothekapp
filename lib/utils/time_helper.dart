/// Helper für realistische Zeitstempel-Formatierung
class TimeHelper {
  /// Formatiert einen Zeitstempel in relativer Form (z.B. "vor 2 Stunden")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'gerade eben';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'vor $minutes ${minutes == 1 ? 'Minute' : 'Minuten'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'vor $hours ${hours == 1 ? 'Stunde' : 'Stunden'}';
    } else if (difference.inDays == 1) {
      return 'gestern';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'vor $days ${days == 1 ? 'Tag' : 'Tagen'}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'vor $weeks ${weeks == 1 ? 'Woche' : 'Wochen'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'vor $months ${months == 1 ? 'Monat' : 'Monaten'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'vor $years ${years == 1 ? 'Jahr' : 'Jahren'}';
    }
  }

  /// Formatiert Datum in deutschem Format
  static String formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$day.$month.$year';
  }

  /// Formatiert Zeit in deutschem Format
  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formatiert Datum + Zeit kombiniert
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} um ${formatTime(dateTime)}';
  }
}
