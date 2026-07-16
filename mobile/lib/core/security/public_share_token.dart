final class PublicShareToken {
  static final RegExp _pattern = RegExp(
    r'^(?:[0-9a-fA-F]{32}|[A-Za-z0-9_-]{43})$',
  );

  static bool isValid(String? value) =>
      value != null && _pattern.hasMatch(value);

  static String requireValid(String value) {
    if (!isValid(value)) {
      throw const FormatException('Lien de partage invalide');
    }
    return value;
  }
}
