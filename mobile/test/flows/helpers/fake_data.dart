import 'package:cv_mobile/models/user.dart';
import 'package:cv_mobile/models/cv.dart';

User fakeUser({int id = 1, String email = 'test@example.com'}) => User(
      id: id,
      email: email,
      nom: 'Dupont',
      prenom: 'Jean',
      role: 'USER',
    );

AuthResponse fakeAuthResponse() => AuthResponse(
      accessToken: 'fake-jwt-token',
      refreshToken: 'fake-refresh-token',
      tokenType: 'Bearer',
      expiresIn: 3600,
      user: fakeUser(),
    );

Cv fakeCv({int id = 1, String titre = 'CV Developpeur'}) => Cv(
      id: id,
      titre: titre,
      personalInfo: PersonalInfo(
        nom: 'Dupont',
        prenom: 'Jean',
        email: 'jean@example.com',
        telephone: '0600000000',
        ville: 'Paris',
        pays: 'France',
        titrePoste: 'Developpeur Flutter',
        resumeProfessionnel: 'Expert Flutter avec 5 ans d\'experience.',
      ),
      experiences: [
        Experience(
          id: 1,
          poste: 'Developpeur Senior',
          entreprise: 'TechCorp',
          lieu: 'Paris',
          dateDebut: DateTime(2020, 1, 1),
          description: 'Developpe des applications mobiles performantes',
          actuel: true,
        ),
      ],
      educations: [
        Education(
          id: 1,
          diplome: 'Master Informatique',
          etablissement: 'Universite Paris',
          dateDebut: DateTime(2015, 9, 1),
        ),
      ],
      skills: [
        Skill(nom: 'Flutter', niveau: 4),
        Skill(nom: 'Dart', niveau: 4),
      ],
      languages: [
        Language(langue: 'Francais', niveau: 'C2'),
      ],
      certifications: [],
      projects: [
        Project(
          id: 1,
          nom: 'MonApp',
          description: 'Application mobile',
          technologies: 'Flutter, Dart',
        ),
      ],
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 6, 1),
    );
