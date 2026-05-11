import 'package:intl/intl.dart';

/// Formatter centralisé pour les dates.
/// Garantit la cohérence du formatage dans toute l'application.
class DateFormatter {
  DateFormatter._();

  /// Format de date courte : dd/MM/yyyy
  static final _short = DateFormat('dd/MM/yyyy', 'fr_FR');

  /// Format de date avec heure : dd/MM/yyyy HH:mm
  static final _withTime = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  /// Format de date longue : EEEE dd MMMM yyyy
  static final _long = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');

  /// Format de mois : MMMM yyyy
  static final _monthYear = DateFormat('MMMM yyyy', 'fr_FR');

  /// Format de jour : EEEE
  static final _dayName = DateFormat('EEEE', 'fr_FR');

  /// Formate une date en format court (dd/MM/yyyy).
  /// Ex: 2024-01-15 → "15/01/2024"
  static String formatShort(DateTime date) {
    return _short.format(date);
  }

  /// Formate une date avec heure (dd/MM/yyyy HH:mm).
  /// Ex: 2024-01-15 14:30 → "15/01/2024 14:30"
  static String formatWithTime(DateTime date) {
    return _withTime.format(date);
  }

  /// Formate une date en format longue (EEEE dd MMMM yyyy).
  /// Ex: 2024-01-15 → "lundi 15 janvier 2024"
  static String formatLong(DateTime date) {
    return _long.format(date);
  }

  /// Formate une date en mois et année (MMMM yyyy).
  /// Ex: 2024-01-15 → "janvier 2024"
  static String formatMonthYear(DateTime date) {
    return _monthYear.format(date);
  }

  /// Formate le jour de la semaine (EEEE).
  /// Ex: 2024-01-15 → "lundi"
  static String formatDayName(DateTime date) {
    return _dayName.format(date);
  }

  /// Formate une date de manière relative (ex: "il y a 2 heures", "demain").
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'à l\'instant';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? 'il y a 1 minute' : 'il y a $minutes minutes';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? 'il y a 1 heure' : 'il y a $hours heures';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? 'hier' : 'il y a $days jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'la semaine dernière' : 'il y a $weeks semaines';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'le mois dernier' : 'il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? 'l\'année dernière' : 'il y a $years ans';
    }
  }

  /// Formate une date relative future.
  static String formatRelativeFuture(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inSeconds < 60) {
      return 'dans quelques secondes';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? 'dans 1 minute' : 'dans $minutes minutes';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? 'dans 1 heure' : 'dans $hours heures';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? 'demain' : 'dans $days jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'la semaine prochaine' : 'dans $weeks semaines';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'le mois prochain' : 'dans $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? 'l\'année prochaine' : 'dans $years ans';
    }
  }

  /// Formate une plage de dates.
  /// Ex: 2024-01-15 à 2024-01-20 → "15/01/2024 - 20/01/2024"
  static String formatRange(DateTime start, DateTime end) {
    return '${formatShort(start)} - ${formatShort(end)}';
  }

  /// Parse une chaîne en DateTime.
  static DateTime? parse(String formatted) {
    try {
      return _short.parse(formatted);
    } catch (_) {
      try {
        return _withTime.parse(formatted);
      } catch (_) {
        return null;
      }
    }
  }
}
