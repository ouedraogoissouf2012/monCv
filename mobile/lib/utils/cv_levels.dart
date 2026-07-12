String skillLevelLabel(int? level) {
  return switch ((level ?? 3).clamp(1, 5)) {
    1 => 'Débutant',
    2 => 'Intermédiaire',
    3 => 'Avancé',
    4 => 'Confirmé',
    _ => 'Expert',
  };
}

double skillLevelProgress(int? level) => (level ?? 3).clamp(1, 5) / 5;

String languageLevelLabel(String? level) {
  return switch (level?.trim().toUpperCase()) {
    'A1' => 'Débutant',
    'A2' => 'Élémentaire',
    'B1' => 'Intermédiaire',
    'B2' => 'Intermédiaire avancé',
    'C1' => 'Courant',
    'C2' => 'Maîtrise',
    'NATIF' => 'Langue maternelle',
    _ => level?.trim() ?? '',
  };
}

String languageLevelDisplay(String? level) {
  final code = level?.trim().toUpperCase() ?? '';
  if (code.isEmpty) return '';
  if (code == 'NATIF') return 'Natif';
  final label = languageLevelLabel(code);
  return label.isEmpty ? code : '$code - $label';
}

double languageLevelProgress(String? level) {
  return switch (level?.trim().toUpperCase()) {
    'A1' => 0.15,
    'A2' => 0.30,
    'B1' => 0.50,
    'B2' => 0.65,
    'C1' => 0.82,
    'C2' => 0.95,
    'NATIF' => 1.0,
    _ => 0.50,
  };
}
