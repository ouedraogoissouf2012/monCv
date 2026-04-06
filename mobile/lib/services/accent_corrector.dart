/// Service de correction automatique des accents francais.
/// Applique a la perte de focus sur les champs texte du formulaire.
/// Les donnees sont corrigees AVANT d'etre stockees en base.
class AccentCorrector {
  static final AccentCorrector _instance = AccentCorrector._();
  AccentCorrector._();
  factory AccentCorrector() => _instance;

  // Dictionnaire mot entier → correction
  // Utilise des word boundaries pour ne pas corriger au milieu d'un mot
  static const Map<String, String> _wordFixes = {
    // Metiers
    'Developpeur': 'Développeur', 'developpeur': 'développeur',
    'Ingenieur': 'Ingénieur', 'ingenieur': 'ingénieur',
    'Secretaire': 'Secrétaire', 'secretaire': 'secrétaire',
    'Comptabilite': 'Comptabilité', 'comptabilite': 'comptabilité',

    // Education
    'Universite': 'Université', 'universite': 'université',
    'Lycee': 'Lycée', 'lycee': 'lycée',
    'Baccalaureat': 'Baccalauréat', 'baccalaureat': 'baccalauréat',
    'Specialite': 'Spécialité', 'specialite': 'spécialité',
    'diplome': 'diplôme', 'Diplome': 'Diplôme',

    // Competences
    'experience': 'expérience', 'Experience': 'Expérience',
    'competence': 'compétence', 'Competence': 'Compétence',
    'competences': 'compétences', 'Competences': 'Compétences',
    'securite': 'sécurité', 'Securite': 'Sécurité',
    'deploiement': 'déploiement', 'Deploiement': 'Déploiement',
    'developpement': 'développement', 'Developpement': 'Développement',
    'integration': 'intégration', 'Integration': 'Intégration',
    'creation': 'création', 'Creation': 'Création',
    'amelioration': 'amélioration', 'Amelioration': 'Amélioration',
    'optimisation': 'optimisation',
    'reponse': 'réponse', 'Reponse': 'Réponse',
    'resultat': 'résultat', 'Resultat': 'Résultat',
    'resultats': 'résultats', 'Resultats': 'Résultats',
    'equipe': 'équipe', 'Equipe': 'Équipe',
    'methodologie': 'méthodologie', 'Methodologie': 'Méthodologie',
    'systeme': 'système', 'Systeme': 'Système',
    'systemes': 'systèmes', 'Systemes': 'Systèmes',
    'reseau': 'réseau', 'Reseau': 'Réseau',
    'reseaux': 'réseaux', 'Reseaux': 'Réseaux',
    'redige': 'rédigé', 'Redige': 'Rédigé',
    'realise': 'réalisé', 'Realise': 'Réalisé',
    'reduit': 'réduit', 'Reduit': 'Réduit',
    'ameliore': 'amélioré', 'Ameliore': 'Amélioré',
    'deploye': 'déployé', 'Deploye': 'Déployé',
    'implemente': 'implémenté', 'Implemente': 'Implémenté',
    'cree': 'créé', 'Cree': 'Créé',
    'integre': 'intégré', 'Integre': 'Intégré',
    'integree': 'intégrée', 'Integree': 'Intégrée',
    'concue': 'conçue', 'Concue': 'Conçue',
    'concu': 'conçu', 'Concu': 'Conçu',

    // Geographie
    'Cote d\'Ivoire': 'Côte d\'Ivoire',

    // Langues
    'Francais': 'Français', 'francais': 'français',
    'Anglais': 'Anglais', // deja correct
    'Intermediaire': 'Intermédiaire', 'intermediaire': 'intermédiaire',
    'Avance': 'Avancé', 'avance': 'avancé',
    'Debutant': 'Débutant', 'debutant': 'débutant',
    'Elementaire': 'Élémentaire', 'elementaire': 'élémentaire',

    // Mots courants
    'generale': 'générale', 'Generale': 'Générale',
    'genie': 'génie', 'Genie': 'Génie',
    'reussi': 'réussi', 'Reussi': 'Réussi',
    'resolu': 'résolu', 'Resolu': 'Résolu',
    'fonctionnalite': 'fonctionnalité', 'Fonctionnalite': 'Fonctionnalité',
    'fonctionnalites': 'fonctionnalités', 'Fonctionnalites': 'Fonctionnalités',
    'performante': 'performante',
    'professionnelle': 'professionnelle',
    'evenement': 'événement', 'Evenement': 'Événement',
    'etude': 'étude', 'Etude': 'Étude',
    'etudes': 'études', 'Etudes': 'Études',
    'annee': 'année', 'Annee': 'Année',
    'annees': 'années', 'Annees': 'Années',
  };

  /// Corrige les accents manquants dans un texte.
  /// Appele quand l'utilisateur quitte un champ texte.
  String correct(String text) {
    if (text.isEmpty) return text;

    String result = text;

    // Appliquer chaque correction de mot
    for (final entry in _wordFixes.entries) {
      // Utiliser un remplacement simple mais sur les mots entiers
      // en evitant de corriger au milieu d'un mot compose
      if (result.contains(entry.key)) {
        result = _replaceWord(result, entry.key, entry.value);
      }
    }

    return result;
  }

  /// Remplace un mot en respectant les limites de mots.
  String _replaceWord(String text, String from, String to) {
    // Pour les expressions multi-mots (ex: "Cote d'Ivoire")
    if (from.contains(' ')) {
      return text.replaceAll(from, to);
    }

    // Pour les mots simples, verifier les limites
    final pattern = RegExp('\\b${RegExp.escape(from)}\\b');
    return text.replaceAll(pattern, to);
  }

  /// Corrige un champ si non vide.
  String? correctNullable(String? text) {
    if (text == null || text.isEmpty) return text;
    return correct(text);
  }
}
