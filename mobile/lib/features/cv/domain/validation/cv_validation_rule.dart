import '../entities/cv.dart';
import 'validation_result.dart';

/// Contrat d'une regle de validation CV (issue #241).
///
/// Une regle est PURE : elle inspecte un [Cv] et retourne des
/// [ValidationMessage] (codes + params), sans Flutter, sans `AppLocalizations`,
/// sans `BuildContext`. Elle ne construit jamais de texte traduit.
///
/// Les regles sont composables : un registre les evalue dans un ordre
/// deterministe pour produire un [ValidationOutcome].
abstract interface class CvValidationRule {
  /// Evalue la regle et retourne les messages produits (vide si tout va bien).
  List<ValidationMessage> evaluate(CvEntity cv);
}
