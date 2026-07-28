/// Fixtures JSON representatives des payloads backend AI, partagees entre les
/// tests de contrat du data source et des mappers. Refletent la forme complete
/// de `EnhanceCvResponse` / `JobMatchResponse` / `ApplicationMessagesResponse`.
library;

const enhanceCvResponseJson = {
  'titrePoste': 'Developpeur Flutter',
  'resumeProfessionnel': 'Resume ameliore.',
  'titreOffre': 'Lead Mobile',
  'experiences': [
    {'id': 1, 'poste': 'Dev', 'description': 'Developpe des apps.'},
  ],
  'educations': [
    {
      'id': 2,
      'etablissement': 'Universite',
      'diplome': 'Master',
      'domaine': 'Informatique',
      'description': 'Mention bien.',
    },
  ],
  'skills': [
    {'nom': 'Dart', 'niveau': 5},
  ],
  'languages': [
    {'id': 3, 'langue': 'Anglais'},
  ],
  'certifications': [
    {'id': 4, 'nom': 'AWS', 'organisme': 'Amazon'},
  ],
  'projects': [
    {
      'id': 5,
      'nom': 'MonCV',
      'description': 'App de CV.',
      'technologies': 'Flutter',
    },
  ],
  'warnings': ['Verifier les dates'],
  'correctionCount': 3,
  'aiGenerated': true,
  'fallback': false,
  'level': 'MAX',
};

const jobMatchResponseJson = {
  'score': 82,
  'matchedKeywords': ['Flutter', 'Dart'],
  'missingKeywords': ['Kotlin'],
  'suggestions': ['Ajouter Kotlin'],
  'categories': [
    {
      'key': 'skills',
      'label': 'Competences',
      'score': 90,
      'summary': 'Bon match',
      'evidence': ['Flutter'],
    },
  ],
  'prioritizedRecommendations': [
    {
      'priority': 1,
      'title': 'Mots-cles',
      'description': 'Ajouter des mots-cles',
      'keywords': ['Kotlin'],
    },
  ],
  'formatChecks': [
    {'severity': 'WARNING', 'label': 'Longueur', 'detail': 'CV trop long'},
  ],
  'optimizedResume': 'Resume optimise.',
  'aiGenerated': true,
  'fallback': false,
};

const applicationMessagesResponseJson = {
  'coverLetter': 'Lettre de motivation.',
  'email': 'Email de candidature.',
  'linkedIn': 'Message LinkedIn.',
  'whatsApp': 'Message WhatsApp.',
  'tone': 'FORMAL',
  'aiGenerated': true,
  'fallback': false,
};
