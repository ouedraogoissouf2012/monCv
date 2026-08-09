import 'dart:ui';

import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/models/cv_style.dart';

Cv professionalCv({String templateId = 'moderne'}) => Cv(
      titre: 'Architecte logiciel',
      style: CvStyle(
        templateId: templateId,
        primaryColor: const Color(0xFF2563EB),
      ),
      personalInfo: const PersonalInfo(
        prenom: 'Aminata',
        nom: 'Traore',
        email: 'aminata@example.com',
        telephone: '+225 01 02 03 04 05',
        ville: 'Abidjan',
        pays: "Cote d'Ivoire",
        titrePoste: 'Architecte logiciel',
        linkedIn: 'linkedin.com/in/aminata-traore',
        resumeProfessionnel:
            'Architecte logiciel avec huit ans d experience en conception '
            'de plateformes fiables et accompagnement d equipes produit.',
      ),
      experiences: [
        Experience(
          poste: 'Lead developpeuse',
          entreprise: 'Ivoire Digital',
          lieu: 'Abidjan',
          dateDebut: DateTime(2021, 1),
          actuel: true,
          description: '- Conception de services utilises par 50 000 clients\n'
              '- Reduction de 35 % du temps de deploiement',
        ),
      ],
      educations: [
        Education(
          diplome: 'Master informatique',
          domaine: 'Genie logiciel',
          etablissement: 'Universite Felix Houphouet-Boigny',
          dateDebut: DateTime(2013, 9),
          dateFin: DateTime(2015, 7),
        ),
      ],
      skills: [
        const Skill(nom: 'Java', niveau: 5, categorie: 'Backend'),
        const Skill(nom: 'Flutter', niveau: 4, categorie: 'Mobile'),
        const Skill(nom: 'PostgreSQL', niveau: 4, categorie: 'Donnees'),
      ],
      languages: [
        const Language(langue: 'Francais', niveau: 'C2'),
        const Language(langue: 'Anglais', niveau: 'B2'),
      ],
      certifications: [
        Certification(
          nom: 'AWS Solutions Architect',
          organisme: 'Amazon Web Services',
          dateObtention: DateTime(2023, 4),
        ),
      ],
      projects: [
        const Project(
          nom: 'Plateforme de paiement',
          technologies: 'Java, PostgreSQL, Docker',
          description: 'Architecture et mise en production multi-pays.',
        ),
      ],
    );
