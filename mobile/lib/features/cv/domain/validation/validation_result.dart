import 'validation_code.dart';

/// Un resultat de validation : un [ValidationCode] + sa [ValidationSeverity],
/// la section concernee et les parametres necessaires a la traduction
/// (ex. index d'un item, longueur, nom), sans aucun texte traduit (issue #241).
///
/// Immuable et pur : ne depend ni de Flutter, ni de `AppLocalizations`.
class ValidationMessage {
  /// Section fonctionnelle (identite, profil, experiences, formations,
  /// competences, langues, certifications, projets).
  final String section;

  final ValidationCode code;
  final ValidationSeverity severity;

  /// Parametres pour la traduction (ex. `{'label': 'Experience 1'}`,
  /// `{'length': 42}`). Vides si le message n'en a pas.
  final Map<String, Object> params;

  const ValidationMessage({
    required this.section,
    required this.code,
    required this.severity,
    this.params = const {},
  });

  ValidationMessage.error(this.section, this.code, {this.params = const {}})
      : severity = ValidationSeverity.error;

  ValidationMessage.warning(this.section, this.code, {this.params = const {}})
      : severity = ValidationSeverity.warning;

  ValidationMessage.info(this.section, this.code, {this.params = const {}})
      : severity = ValidationSeverity.info;

  bool get isError => severity == ValidationSeverity.error;
  bool get isWarning => severity == ValidationSeverity.warning;

  @override
  String toString() =>
      'ValidationMessage($section, $code, $severity, $params)';
}

/// Rapport complet de validation : liste ordonnee et deterministe de messages.
///
/// Ne calcule pas de score ici (la politique de score reste separee, cf.
/// `CvValidationThresholds`). L'ordre reflete l'ordre d'evaluation des regles.
class ValidationOutcome {
  final List<ValidationMessage> messages;

  const ValidationOutcome(this.messages);

  const ValidationOutcome.empty() : messages = const [];

  Iterable<ValidationMessage> get errors => messages.where((m) => m.isError);
  Iterable<ValidationMessage> get warnings =>
      messages.where((m) => m.isWarning);

  bool get hasErrors => messages.any((m) => m.isError);

  /// Premier message bloquant, ou `null` s'il n'y en a pas.
  ValidationMessage? get firstError =>
      messages.where((m) => m.isError).firstOrNull;
}
