class Cv {
  final int? id;
  final String titre;
  final PersonalInfo? personalInfo;
  final List<Education> educations;
  final List<Experience> experiences;
  final List<Skill> skills;
  final List<Language> languages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cv({
    this.id,
    required this.titre,
    this.personalInfo,
    this.educations = const [],
    this.experiences = const [],
    this.skills = const [],
    this.languages = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Cv.fromJson(Map<String, dynamic> json) {
    return Cv(
      id: json['id'],
      titre: json['titre'],
      personalInfo: json['personalInfo'] != null
          ? PersonalInfo.fromJson(json['personalInfo'])
          : null,
      educations: (json['educations'] as List<dynamic>?)
              ?.map((e) => Education.fromJson(e))
              .toList() ??
          [],
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((e) => Experience.fromJson(e))
              .toList() ??
          [],
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => Skill.fromJson(e))
              .toList() ??
          [],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => Language.fromJson(e))
              .toList() ??
          [],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'titre': titre,
      'personalInfo': personalInfo?.toJson(),
      'educations': educations.map((e) => e.toJson()).toList(),
      'experiences': experiences.map((e) => e.toJson()).toList(),
      'skills': skills.map((e) => e.toJson()).toList(),
      'languages': languages.map((e) => e.toJson()).toList(),
    };
  }

  Cv copyWith({
    int? id,
    String? titre,
    PersonalInfo? personalInfo,
    List<Education>? educations,
    List<Experience>? experiences,
    List<Skill>? skills,
    List<Language>? languages,
  }) {
    return Cv(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      personalInfo: personalInfo ?? this.personalInfo,
      educations: educations ?? this.educations,
      experiences: experiences ?? this.experiences,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class PersonalInfo {
  final String? nom;
  final String? prenom;
  final String? email;
  final String? telephone;
  final String? adresse;
  final String? ville;
  final String? codePostal;
  final String? pays;
  final String? photoUrl;
  final String? linkedIn;
  final String? portfolio;
  final String? titrePoste;
  final String? resumeProfessionnel;

  PersonalInfo({
    this.nom,
    this.prenom,
    this.email,
    this.telephone,
    this.adresse,
    this.ville,
    this.codePostal,
    this.pays,
    this.photoUrl,
    this.linkedIn,
    this.portfolio,
    this.titrePoste,
    this.resumeProfessionnel,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      telephone: json['telephone'],
      adresse: json['adresse'],
      ville: json['ville'],
      codePostal: json['codePostal'],
      pays: json['pays'],
      photoUrl: json['photoUrl'],
      linkedIn: json['linkedIn'],
      portfolio: json['portfolio'],
      titrePoste: json['titrePoste'],
      resumeProfessionnel: json['resumeProfessionnel'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'ville': ville,
      'codePostal': codePostal,
      'pays': pays,
      'photoUrl': photoUrl,
      'linkedIn': linkedIn,
      'portfolio': portfolio,
      'titrePoste': titrePoste,
      'resumeProfessionnel': resumeProfessionnel,
    };
  }

  String get fullName {
    if (prenom != null && nom != null) {
      return '$prenom $nom';
    }
    return prenom ?? nom ?? '';
  }
}

class Education {
  final int? id;
  final String? etablissement;
  final String? diplome;
  final String? domaine;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? description;

  Education({
    this.id,
    this.etablissement,
    this.diplome,
    this.domaine,
    this.dateDebut,
    this.dateFin,
    this.description,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'],
      etablissement: json['etablissement'],
      diplome: json['diplome'],
      domaine: json['domaine'],
      dateDebut:
          json['dateDebut'] != null ? DateTime.parse(json['dateDebut']) : null,
      dateFin:
          json['dateFin'] != null ? DateTime.parse(json['dateFin']) : null,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'etablissement': etablissement,
      'diplome': diplome,
      'domaine': domaine,
      'dateDebut': dateDebut?.toIso8601String().split('T')[0],
      'dateFin': dateFin?.toIso8601String().split('T')[0],
      'description': description,
    };
  }
}

class Experience {
  final int? id;
  final String? entreprise;
  final String? poste;
  final String? lieu;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? description;
  final bool actuel;

  Experience({
    this.id,
    this.entreprise,
    this.poste,
    this.lieu,
    this.dateDebut,
    this.dateFin,
    this.description,
    this.actuel = false,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'],
      entreprise: json['entreprise'],
      poste: json['poste'],
      lieu: json['lieu'],
      dateDebut:
          json['dateDebut'] != null ? DateTime.parse(json['dateDebut']) : null,
      dateFin:
          json['dateFin'] != null ? DateTime.parse(json['dateFin']) : null,
      description: json['description'],
      actuel: json['actuel'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'entreprise': entreprise,
      'poste': poste,
      'lieu': lieu,
      'dateDebut': dateDebut?.toIso8601String().split('T')[0],
      'dateFin': dateFin?.toIso8601String().split('T')[0],
      'description': description,
      'actuel': actuel,
    };
  }
}

class Skill {
  final int? id;
  final String? nom;
  final int? niveau;
  final String? categorie;

  Skill({
    this.id,
    this.nom,
    this.niveau,
    this.categorie,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'],
      nom: json['nom'],
      niveau: json['niveau'],
      categorie: json['categorie'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      'niveau': niveau,
      'categorie': categorie,
    };
  }
}

class Language {
  final int? id;
  final String? langue;
  final String? niveau;

  Language({
    this.id,
    this.langue,
    this.niveau,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'],
      langue: json['langue'],
      niveau: json['niveau'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'langue': langue,
      'niveau': niveau,
    };
  }
}
