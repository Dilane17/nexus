import 'package:intl/intl.dart';

/// Formatter centralisé pour les montants monétaires UEMOA (FCFA).
/// Garantit la cohérence du formatage dans toute l'application.
class MoneyFormatter {
  MoneyFormatter._();

  /// Formateur standard pour FCFA avec décimales.
  static final _standard = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  /// Formateur avec décimales pour les calculs précis.
  static final _withDecimals = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 2,
  );

  /// Formateur compact pour les grands montants (ex: 1.2M FCFA).
  static final _compact = NumberFormat.compactCurrency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 1,
  );

  /// Formateur décimal simple (sans symbole) pour les champs de saisie.
  static final _decimal = NumberFormat.decimalPattern('fr_FR');

  /// Formate un montant en FCFA standard (sans décimales).
  /// Ex: 1000000 → "1 000 000 FCFA"
  static String format(num amount) {
    return _standard.format(amount);
  }

  /// Formate un montant avec décimales.
  /// Ex: 1000.50 → "1 000,50 FCFA"
  static String formatWithDecimals(num amount) {
    return _withDecimals.format(amount);
  }

  /// Formate un montant de manière compacte pour les grands nombres.
  /// Ex: 1000000 → "1,0 M FCFA"
  static String formatCompact(num amount) {
    return _compact.format(amount);
  }

  /// Formate un montant sans symbole monétaire (pour les champs de saisie).
  /// Ex: 1000000 → "1 000 000"
  static String formatPlain(num amount) {
    return _decimal.format(amount);
  }

  /// Parse une chaîne en montant.
  /// Ex: "1 000 000" → 1000000
  static num? parse(String formatted) {
    return _decimal.parse(formatted);
  }

  /// Formate un montant en texte court pour les listes compactes.
  /// Ex: 1500000 → "1,5M"
  static String formatShort(num amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
