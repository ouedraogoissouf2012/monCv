import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde d'architecture du chemin d'ecriture CV (issues #501, #532).
///
/// Seuls les proprietaires declares ci-dessous ecrivent dans `CvStore`. Partout
/// ailleurs dans `lib/`, une ecriture de CV passe par le port `CvWriter`, dont
/// l'implementation reconcilie l'etat partage.
///
/// Historique : apres une edition, l'ecran de detail affichait l'ancien contenu
/// parce que le formulaire ecrivait via `CvRepository` sans toucher au store. Un
/// premier correctif avait ajoute `sl<CvStore>().replaceCv(...)` DANS le widget :
/// le symptome disparaissait, mais la reconciliation devenait une politesse de
/// chaque appelant plutot qu'un invariant.
///
/// La regle est ici formulee a l'ENVERS de sa premiere version. Celle-ci
/// enumerait les repertoires interdits (`lib/screens`, `lib/widgets`,
/// `lib/providers`) et laissait donc 131 fichiers de `lib/features/*/presentation`
/// hors de son champ — soit la majorite du code de presentation du projet.
/// Enumerer les proprietaires AUTORISES, liste courte et stable, couvre tout le
/// depot par defaut, y compris les fonctionnalites qui n'existent pas encore.
void main() {
  /// Fichiers et repertoires en droit de muter l'etat CV.
  ///
  /// Les controllers et le coordinateur de synchronisation portent la
  /// reconciliation ; le store se modifie lui-meme ; le cablage resout
  /// `sl<CvStore>()` par construction, c'est son role.
  const proprietaires = <String>[
    'lib/features/cv/presentation/controllers/',
    'lib/features/cv/application/sync/',
    'lib/features/cv/presentation/cv_store.dart',
    'lib/core/di/',
    'lib/main.dart',
  ];

  /// Ecritures de l'etat CV, et resolution du store depuis le service locator.
  ///
  /// `setCvs` figure ici alors qu'il manquait a la premiere version du garde :
  /// il remplace la liste entiere, c'est la mutation la plus large.
  /// Les lectures (`context.watch<CvStore>().cvs`) restent permises : seule
  /// l'ECRITURE doit passer par le port.
  final ecritures = RegExp(
    r'sl<CvStore>\(\)'
    r'|\.setCvs\('
    r'|\.setCurrentCv\('
    r'|\.addCv\('
    r'|\.replaceCv\('
    r'|\.removeCv\(',
  );

  bool estProprietaire(String chemin) =>
      proprietaires.any((autorise) => chemin.startsWith(autorise));

  test('seuls les proprietaires declares ecrivent dans le CvStore', () {
    final racine = Directory('lib');
    expect(racine.existsSync(), isTrue,
        reason: 'Test a lancer depuis la racine du package mobile (CWD=mobile/).');

    final fautifs = <String>{};

    for (final entite in racine.listSync(recursive: true).whereType<File>()) {
      final chemin = entite.path.replaceAll(r'\', '/');
      if (!chemin.endsWith('.dart')) continue;

      final relatif = chemin.substring(chemin.indexOf('lib/'));
      if (estProprietaire(relatif)) continue;

      for (final ligne in entite.readAsLinesSync()) {
        final texte = ligne.trim();
        // Les commentaires documentent souvent la regle : ne pas les compter.
        if (texte.startsWith('//')) continue;
        if (ecritures.hasMatch(texte)) {
          fautifs.add(relatif);
          break;
        }
      }
    }

    expect(
      fautifs,
      isEmpty,
      reason: 'ECRITURE INTERDITE du CvStore hors des proprietaires declares '
          '(#501, #532).\n'
          'Injectez le port CvWriter et appelez create / update / '
          'createVariant : il reconcilie la liste ET le CV courant.\n'
          'Fichier(s) fautif(s):\n  ${fautifs.join('\n  ')}',
    );
  });
}
