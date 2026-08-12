import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde d'architecture Clean Architecture.
///
/// La couche domaine (`lib/features/<feature>/domain/`) ne doit JAMAIS dependre
/// de la presentation, de Flutter, ni de `dart:ui`. Les dependances pointent
/// vers le domaine, jamais vers l'exterieur.
///
/// Cette regle n'etait couverte par aucun test : la migration #416 a revele
/// que des regles de validation et un view-model importaient le modele de
/// PRESENTATION `Cv` (qui transporte `dart:ui` via `CvStyle`).
///
/// RATCHET : [_allowlist] tolere temporairement les violations HERITEES. Toute
/// NOUVELLE violation (fichier domaine hors allowlist) fait echouer la CI.
/// L'allowlist doit etre VIDEE une fois mergees :
///   - #465 : regles de validation -> CvEntity ;
///   - #466 : relocalisation de cv_document_view_model en presentation/.
void main() {
  // Violations heritees connues, tolerees le temps de leur resorption.
  // NE JAMAIS ETENDRE cette liste : une nouvelle entree = une regression.
  const allowlist = <String>{
    // Regles de validation dependant du modele de presentation Cv.
    // Corrige par #465 (-> CvEntity) : a retirer une fois merge.
    'lib/features/cv/domain/validation/cv_validation_rule.dart',
    'lib/features/cv/domain/validation/cv_validation_rules.dart',
    'lib/features/cv/domain/validation/rules/personal_info_rules.dart',
    'lib/features/cv/domain/validation/rules/save_rules.dart',
    'lib/features/cv/domain/validation/rules/section_rules.dart',
    // View-model de rendu mal place en domain/. Corrige par #466
    // (relocalisation en presentation/) : a retirer une fois merge.
    'lib/features/cv_preview/domain/cv_document_view_model.dart',
    // Copie presse-papier implementee avec package:flutter/services dans le
    // domaine (Flutter dans le domaine). Dette pre-existante independante de
    // #416 : a resorber via un port domaine + adapter (cf. #245).
    'lib/features/application_messages/domain/clipboard_copier.dart',
  };

  // Un import/export de domaine est interdit s'il vise Flutter, dart:ui, ou un
  // repertoire `presentation/` (relatif ou en `package:`).
  final forbidden = RegExp(r'(dart:ui|package:flutter/|/presentation/)');

  test('la couche domaine ne depend ni de la presentation ni de Flutter/dart:ui',
      () {
    final root = Directory('lib/features');
    expect(root.existsSync(), isTrue,
        reason: 'Test a lancer depuis la racine du package mobile (CWD=mobile/).');

    final offenders = <String>{};
    for (final entity in root.listSync(recursive: true).whereType<File>()) {
      final path = entity.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;
      if (!path.contains('/domain/')) continue; // uniquement la couche domaine
      for (final line in entity.readAsLinesSync()) {
        final t = line.trim();
        if (!t.startsWith('import ') && !t.startsWith('export ')) continue;
        if (forbidden.hasMatch(t)) {
          offenders.add(path.substring(path.indexOf('lib/')));
          break;
        }
      }
    }

    final newViolations = offenders.difference(allowlist);
    expect(
      newViolations,
      isEmpty,
      reason: 'Nouvelle dependance INTERDITE domaine -> presentation/Flutter/'
          'dart:ui. La couche domaine doit rester pure.\n'
          'Fichier(s) fautif(s):\n  ${newViolations.join('\n  ')}',
    );

    // Non bloquant : signale les entrees d'allowlist devenues inutiles pour
    // inciter a les retirer (ratchet) une fois #465/#466 mergees.
    final stale = allowlist.difference(offenders);
    if (stale.isNotEmpty) {
      // ignore: avoid_print
      print('[domain-purity] allowlist a nettoyer (plus en violation): '
          '${stale.join(', ')}');
    }
  });
}
