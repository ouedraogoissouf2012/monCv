/// Saisie date jj/mm/aaaa : refuse un mois > 12 avant l'annee.
class StrictDateInput {
  static const minYearDefault = 1927;

  static int maxCareerYear([DateTime? now]) => (now ?? DateTime.now()).year;

  static int maxBirthYear([DateTime? now]) =>
      (now ?? DateTime.now()).year - 10;

  static String format(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  static DateTime? parse(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final day = int.parse(digits.substring(0, 2));
    final month = int.parse(digits.substring(2, 4));
    final year = int.parse(digits.substring(4, 8));
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > _daysInMonth(month, year)) return null;
    return DateTime(year, month, day);
  }

  static String mask(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  /// `null` si le prefixe de chiffres est acceptable.
  static String? rejectReason(
    String digits, {
    required int minYear,
    required int maxYear,
  }) {
    if (digits.isEmpty) return null;
    if (digits.isNotEmpty && int.parse(digits[0]) > 3) {
      return 'Jour invalide (01-31).';
    }
    if (digits.length >= 2) {
      final day = int.parse(digits.substring(0, 2));
      if (day < 1 || day > 31) return 'Jour invalide (01-31).';
    }
    if (digits.length >= 3 && int.parse(digits[2]) > 1) {
      return 'Nous n\'avons que 12 mois. Merci de respecter la syntaxe.';
    }
    if (digits.length >= 4) {
      final month = int.parse(digits.substring(2, 4));
      if (month < 1 || month > 12) {
        return 'Nous n\'avons que 12 mois. Merci de respecter la syntaxe.';
      }
      final day = int.parse(digits.substring(0, 2));
      final yearHint =
          digits.length >= 8 ? int.parse(digits.substring(4, 8)) : 2000;
      if (day > _daysInMonth(month, yearHint)) {
        return 'Ce jour n\'existe pas pour ce mois.';
      }
    }
    if (digits.length == 8) {
      final year = int.parse(digits.substring(4, 8));
      if (year < minYear || year > maxYear) {
        return 'Annee entre $minYear et $maxYear.';
      }
    }
    return null;
  }

  static String? rangeError(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    if (end.isBefore(start)) {
      return 'La date de fin doit etre posterieure a la date de debut.';
    }
    return null;
  }

  static int _daysInMonth(int month, int year) {
    if (month == 2) {
      final leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
      return leap ? 29 : 28;
    }
    const thirty = {4, 6, 9, 11};
    return thirty.contains(month) ? 30 : 31;
  }
}
