import 'package:intl/intl.dart';

/// Realistische Zeitstempel-Formatierung für professionelle UX
class DateHelpers {
  /// Konvertiert DateTime in realistischen, deutschen Zeitstempel
  /// Beispiele: "Gerade eben", "Vor 5 Min.", "Heute, 14:30", "Gestern, 09:15", "15.03.2024"
  static String getRealisticTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Gerade eben (< 1 Minute)
    if (difference.inSeconds < 60) {
      return 'Gerade eben';
    }

    // Vor X Minuten (< 1 Stunde)
    if (difference.inMinutes < 60) {
      return 'Vor ${difference.inMinutes} Min.';
    }

    // Vor X Stunden (heute, < 24 Stunden)
    if (difference.inHours < 24 && dateTime.day == now.day) {
      if (difference.inHours == 1) {
        return 'Vor 1 Std.';
      }
      return 'Vor ${difference.inHours} Std.';
    }

    // Heute + Uhrzeit
    if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) {
      final timeFormat = DateFormat('HH:mm', 'de_DE');
      return 'Heute, ${timeFormat.format(dateTime)}';
    }

    // Gestern + Uhrzeit
    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.day == yesterday.day && dateTime.month == yesterday.month && dateTime.year == yesterday.year) {
      final timeFormat = DateFormat('HH:mm', 'de_DE');
      return 'Gestern, ${timeFormat.format(dateTime)}';
    }

    // Vor X Tagen (< 7 Tage)
    if (difference.inDays < 7) {
      return 'Vor ${difference.inDays} Tagen';
    }

    // Vollständiges Datum (> 7 Tage)
    final dateFormat = DateFormat('dd.MM.yyyy', 'de_DE');
    return dateFormat.format(dateTime);
  }

  /// Formatiert Datum im deutschen Format (dd.MM.yyyy)
  static String formatDate(DateTime dateTime) {
    final dateFormat = DateFormat('dd.MM.yyyy', 'de_DE');
    return dateFormat.format(dateTime);
  }

  /// Formatiert Zeit im deutschen Format (HH:mm)
  static String formatTime(DateTime dateTime) {
    final timeFormat = DateFormat('HH:mm', 'de_DE');
    return timeFormat.format(dateTime);
  }

  /// Formatiert Datum + Zeit komplett
  static String formatDateTime(DateTime dateTime) {
    final format = DateFormat('dd.MM.yyyy, HH:mm', 'de_DE');
    return format.format(dateTime);
  }

  /// Berechnet realistische Zeitstempel für Demo-Daten
  static DateTime getRealisticDemoTime(int hoursAgo) {
    return DateTime.now().subtract(Duration(hours: hoursAgo));
  }

  /// Berechnet realistische Zeitstempel für Demo-Daten (Tage)
  static DateTime getRealisticDemoDate(int daysAgo) {
    return DateTime.now().subtract(Duration(days: daysAgo));
  }
}
