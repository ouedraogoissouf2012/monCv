import 'package:flutter/services.dart';

import '../domain/clipboard_copier.dart';

/// Adapter systeme du port [ClipboardCopier] : copie via le presse-papier de la
/// plateforme (`Clipboard.setData`).
///
/// Vit dans la couche data (infrastructure) pour garder le domaine PUR : c'est
/// ici, et non dans `domain/`, que reside la dependance `package:flutter`
/// (#245, deplacee hors du domaine).
class SystemClipboardCopier implements ClipboardCopier {
  const SystemClipboardCopier();

  @override
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
