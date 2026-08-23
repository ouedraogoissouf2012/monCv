import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde d'architecture du chemin d'ecriture CV (issue #501).
///
/// La couche UI (`lib/screens`, `lib/widgets`, `lib/providers`) ne doit jamais
/// muter le `CvStore` ni le resoudre depuis le service locator. Elle passe par
/// le port `CvWriter`, dont l'implementation reconcilie l'etat partage.
///
/// Historique : apres une edition, l'ecran de detail affichait l'ancien
/// contenu parce que le formulaire ecrivait via `CvRepository` sans toucher au
/// store. Un premier correctif avait ajoute `sl<CvStore>().replaceCv(...)`
/// DANS le widget : le symptome disparaissait, mais la reconciliation devenait
/// une politesse de chaque appelant plutot qu'un invariant. Ce garde empeche ce
/// retour en arriere.
///
/// L'allowlist est VIDE : tolerance zero. Si une exception devait etre gelee,
/// l'ajouter ici avec issue et raison, jamais silencieusement.
void main() {
  // Tolerance zero : aucune exception. Ne PAS etendre sans justification tracee.
  const allowlist = <String>{};

  const uiDirectories = <String>[
    'lib/screens',
    'lib/widgets',
    'lib/providers',
  ];

  // Resolution du store depuis le service locator, ou mutation directe de son
  // etat. Les lectures (`context.watch<CvStore>()`, `store.cvs`) restent
  // permises : seule l'ECRITURE doit passer par le port.
  final forbidden = RegExp(
    r'sl<CvStore>\(\)'
    r'|\.addCv\('
    r'|\.replaceCv\('
    r'|\.removeCv\('
    r'|\.setCurrentCv\(',
  );

  test('la couche UI n ecrit jamais directement dans le CvStore', () {
    final offenders = <String>{};

    for (final directory in uiDirectories) {
      final root = Directory(directory);
      expect(root.existsSync(), isTrue,
          reason: 'Test a lancer depuis la racine du package mobile '
              '(CWD=mobile/). Repertoire absent : $directory');

      for (final entity in root.listSync(recursive: true).whereType<File>()) {
        final path = entity.path.replaceAll(r'\', '/');
        if (!path.endsWith('.dart')) continue;

        for (final line in entity.readAsLinesSync()) {
          final trimmed = line.trim();
          // Les commentaires documentent souvent la regle : ne pas les compter.
          if (trimmed.startsWith('//')) continue;
          if (forbidden.hasMatch(trimmed)) {
            offenders.add(path.substring(path.indexOf('lib/')));
            break;
          }
        }
      }
    }

    final violations = offenders.difference(allowlist);
    expect(
      violations,
      isEmpty,
      reason: 'ECRITURE INTERDITE du CvStore depuis la couche UI (#501).\n'
          'Injectez le port CvWriter et appelez create / update / '
          'createVariant : il reconcilie la liste ET le CV courant.\n'
          'Fichier(s) fautif(s):\n  ${violations.join('\n  ')}',
    );
  });
}
