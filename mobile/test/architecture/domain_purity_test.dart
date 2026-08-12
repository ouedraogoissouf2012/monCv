import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde d'architecture Clean Architecture.
///
/// La couche domaine (`lib/features/<feature>/domain/`) ne doit JAMAIS dependre
/// de la presentation, de Flutter, ni de `dart:ui`. Les dependances pointent
/// vers le domaine, jamais vers l'exterieur.
///
/// Historique : la migration #416 avait revele 7 violations (regles de
/// validation et un view-model dependant du modele de presentation `Cv`, et un
/// copieur presse-papier utilisant `package:flutter/services`). Toutes ont ete
/// corrigees (#465, #466, #468). L'allowlist est donc VIDE : purete du domaine
/// en tolerance ZERO. Toute nouvelle violation fait echouer la CI.
///
/// Si une exception devait etre gelee temporairement, l'ajouter dans
/// l'allowlist ci-dessous avec un commentaire (issue + raison), jamais
/// silencieusement.
void main() {
  // Tolerance zero : aucune exception. Ne PAS etendre sans justification tracee.
  const allowlist = <String>{};

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

    final violations = offenders.difference(allowlist);
    expect(
      violations,
      isEmpty,
      reason: 'Dependance INTERDITE domaine -> presentation/Flutter/dart:ui. '
          'La couche domaine doit rester pure.\n'
          'Fichier(s) fautif(s):\n  ${violations.join('\n  ')}',
    );
  });
}
