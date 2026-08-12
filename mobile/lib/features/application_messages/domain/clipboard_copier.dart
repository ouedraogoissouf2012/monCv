/// Port de copie vers le presse-papier (issue #245, G5).
///
/// Interface PURE du domaine : `copy(text)` sans aucune dependance Flutter. Le
/// controller et la sheet en dependent via ce contrat ; les tests fournissent
/// un double en memoire, et l'implementation systeme vit dans la couche data
/// ([SystemClipboardCopier], `data/system_clipboard_copier.dart`).
///
/// C'est la separation "copie / generation" demandee par #245, en gardant la
/// couche domaine pure (aucun `package:flutter`).
abstract interface class ClipboardCopier {
  Future<void> copy(String text);
}
