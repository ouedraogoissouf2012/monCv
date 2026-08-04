import 'package:flutter/services.dart';

/// Port de copie vers le presse-papier (issue #245, G5).
///
/// Abstrait `Clipboard.setData` pour DECOUPLER la copie de la generation : le
/// controller et la sheet en dependent via cette interface, les tests
/// fournissent un double en memoire. C'est la separation "copie / generation"
/// demandee par #245.
abstract interface class ClipboardCopier {
  Future<void> copy(String text);
}

/// Implementation par defaut : presse-papier systeme.
class SystemClipboardCopier implements ClipboardCopier {
  const SystemClipboardCopier();

  @override
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
