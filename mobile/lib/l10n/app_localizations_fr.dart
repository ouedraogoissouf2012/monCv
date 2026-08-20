// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'MonCV';

  @override
  String get login => 'Se connecter';

  @override
  String get register => 'Creer un compte';

  @override
  String get email => 'Adresse email';

  @override
  String get emailShort => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublie ?';

  @override
  String get noAccount => 'Pas encore de compte ?';

  @override
  String get hasAccount => 'Deja un compte ?';

  @override
  String get welcomeBack => 'Bon retour\nparmi nous.';

  @override
  String get welcomeSubtitle => 'Connectez-vous pour continuer sur MonCV';

  @override
  String get createAccount => 'Creez votre\ncompte.';

  @override
  String get createAccountSubtitle => 'Rejoignez MonCV gratuitement';

  @override
  String get emailHint => 'vous@exemple.com';

  @override
  String get fieldRequired => 'Champ requis';

  @override
  String requiredFieldMessage(String section, String field) {
    return '$section : $field obligatoire.';
  }

  @override
  String get completePersonalInfo =>
      'Identite : completez vos informations personnelles.';

  @override
  String get invalidEmailMessage => 'Identite : format email invalide.';

  @override
  String numberedItem(String section, int index) {
    return '$section $index';
  }

  @override
  String endDateBeforeStart(String item) {
    return '$item : la date de fin doit etre apres la date de debut.';
  }

  @override
  String skillLevelRange(String item) {
    return '$item : le niveau doit etre entre 1 et 5.';
  }

  @override
  String certificationExpirationBeforeIssue(String item) {
    return '$item : expiration avant obtention.';
  }

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get passwordMinLength => 'Minimum 6 caracteres';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordStrengthWeak => 'Faible';

  @override
  String get passwordStrengthMedium => 'Moyen';

  @override
  String get passwordStrengthGood => 'Bon';

  @override
  String get passwordStrengthStrong => 'Fort';

  @override
  String get loginError => 'Erreur de connexion';

  @override
  String get registerError => 'Erreur d\'inscription';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get forgotPasswordSubtitle =>
      'Entrez votre email : nous vous enverrons un lien de réinitialisation.';

  @override
  String get sendResetLink => 'Envoyer le lien';

  @override
  String get forgotPasswordSent =>
      'Si un compte existe pour cet email, un lien de réinitialisation vient d\'être envoyé.';

  @override
  String get resetLinkError =>
      'Envoi impossible. Vérifiez votre connexion et réessayez.';

  @override
  String get rememberedPassword => 'Vous vous en souvenez ?';

  @override
  String get resetPasswordTitle => 'Nouveau mot de passe';

  @override
  String get resetPasswordSubtitle =>
      'Choisissez un nouveau mot de passe pour votre compte.';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get resetPasswordButton => 'Réinitialiser le mot de passe';

  @override
  String get resetPasswordSuccess =>
      'Mot de passe réinitialisé. Vous pouvez vous connecter.';

  @override
  String get resetPasswordError =>
      'Lien invalide ou expiré. Redemandez un lien.';

  @override
  String get createMyAccount => 'Créer mon compte';

  @override
  String get landingHeroTitle => 'Creez un CV\nqui parle aux recruteurs';

  @override
  String get landingHeroTitleMobile => 'Creez un CV\nqui parle aux\nrecruteurs';

  @override
  String get landingHeroSubtitle =>
      'Francais professionnel, formats ATS, partage WhatsApp et export PDF/DOCX pour candidatures locales ou internationales.';

  @override
  String get createCvFree => 'Créer mon CV gratuitement';

  @override
  String get bilingual => 'Bilingue';

  @override
  String get templates => 'Templates';

  @override
  String get compatible => 'Compatible';

  @override
  String get aiFeatureTitle => 'Intelligence Artificielle';

  @override
  String get aiFeatureDescription =>
      'Un francais naturel, precis et sans phrases artificielles.';

  @override
  String get templatesFeatureTitle => 'Templates cibles';

  @override
  String get templatesFeatureDescription =>
      'Corporate, junior, senior, tech et ATS international.';

  @override
  String get atsFeatureTitle => 'Score ATS';

  @override
  String get atsFeatureDescription =>
      'Collez une offre et obtenez un score de correspondance.';

  @override
  String get docxFeatureTitle => 'Export DOCX';

  @override
  String get docxFeatureDescription =>
      'Telechargez en Word pour une compatibilite ATS maximale.';

  @override
  String get mobileFeatureTitle => 'Mobile-first Afrique';

  @override
  String get mobileFeatureDescription =>
      'Pense pour creer, corriger, exporter et partager depuis un telephone.';

  @override
  String get whatsAppFeatureTitle => 'Partage WhatsApp';

  @override
  String get whatsAppFeatureDescription =>
      'Envoyez un lien propre a un recruteur ou a un contact RH.';

  @override
  String get allYouNeed => 'Tout ce dont vous avez besoin';

  @override
  String get allYouNeedSubtitle =>
      'Un outil complet pour creer des CV qui font la difference.';

  @override
  String get clearCvTitle => 'Un CV clair pour candidater partout';

  @override
  String get clearCvSubtitle =>
      'Un rendu lisible pour recruteurs, PME, cabinets et ATS';

  @override
  String get sampleProfile => 'PROFIL';

  @override
  String get sampleProfileText =>
      'Ingenieur Full Stack avec 3 ans d\'experience. Expert Java/Spring Boot et Flutter.';

  @override
  String get sampleSkills => 'COMPETENCES';

  @override
  String get sampleExperiences => 'EXPERIENCES';

  @override
  String get howItWorks => 'Comment ca marche';

  @override
  String get fillIn => 'Remplissez';

  @override
  String get fillInDescription =>
      'Des aides courtes guident titre, resume et experiences.';

  @override
  String get adapt => 'Adaptez';

  @override
  String get adaptDescription =>
      'Corrigez le francais et choisissez un template selon le poste.';

  @override
  String get send => 'Partagez';

  @override
  String get sendDescription =>
      'Exportez en PDF/DOCX ou envoyez le lien par WhatsApp.';

  @override
  String get readyToApply => 'Pret a candidater avec un CV propre ?';

  @override
  String get readyToApplySubtitle =>
      'Mobile, rapide, lisible et pense pour le marche francophone.';

  @override
  String get startNow => 'Commencer maintenant';

  @override
  String get installApp => 'Telecharger l\'application';

  @override
  String get installAppHelp =>
      'Sur iPhone : Safari > Partager > Sur l\'ecran d\'accueil. Sur Android le fichier MonCV.apk se telecharge, puis ouvre-le pour installer.';

  @override
  String get landingFooter =>
      '© 2026 MonCV. CV francophone, mobile-first et compatible ATS.';

  @override
  String get sampleCandidateName => 'ALEX TRAORE';

  @override
  String get sampleCandidateRole => 'Ingenieur Logiciel Full Stack';

  @override
  String get sampleCandidateContact =>
      'alex.traore@email.com | +225 07 00 00 00 00 | Abidjan';

  @override
  String get sampleCandidatePosition => 'Lead Developer';

  @override
  String get sampleCandidateCompany => 'Studio Digital - Abidjan';

  @override
  String get lite => 'Lite';

  @override
  String get medium => 'Medium';

  @override
  String get maximum => 'Max';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get myCvs => 'Mes CVs';

  @override
  String get newCv => 'Nouveau CV';

  @override
  String get noCvYet => 'Aucun CV pour l\'instant';

  @override
  String get createFirstCv => 'Creez votre premier CV professionnel';

  @override
  String get createMyFirstCv => 'Creer mon premier CV';

  @override
  String get importCv => 'Importer un CV (PDF/DOCX)';

  @override
  String get deleteCvTitle => 'Supprimer le CV';

  @override
  String deleteCvConfirm(String titre) {
    return 'Voulez-vous vraiment supprimer \"$titre\" ?';
  }

  @override
  String get cvDeleted => 'CV supprime';

  @override
  String get cvMovedToTrash => 'CV mis a la corbeille';

  @override
  String get undo => 'Annuler';

  @override
  String get trashTitle => 'Corbeille';

  @override
  String get trashEmpty => 'Aucun CV dans la corbeille';

  @override
  String get restore => 'Restaurer';

  @override
  String get purgeForever => 'Supprimer definitivement';

  @override
  String get cvDuplicated => 'CV duplique';

  @override
  String get shareLinkTitle => 'Lien de partage';

  @override
  String get shareLinkDescription =>
      'Partagez ce lien pour que n\'importe qui puisse voir votre CV :';

  @override
  String get linkCopied => 'Lien copie dans le presse-papier';

  @override
  String get copy => 'Copier';

  @override
  String get close => 'Fermer';

  @override
  String get pdfDownloading => 'Generation du PDF en cours...';

  @override
  String get pdfDownloaded => 'PDF telecharge';

  @override
  String pdfError(String error) {
    return 'Erreur PDF: $error';
  }

  @override
  String get docxDownloading => 'Telechargement DOCX en cours...';

  @override
  String get docxDownloaded => 'DOCX telecharge';

  @override
  String docxError(String error) {
    return 'Erreur DOCX: $error';
  }

  @override
  String get importInProgress => 'Import du CV en cours...';

  @override
  String importSuccess(String titre) {
    return 'CV \"$titre\" importe avec succes';
  }

  @override
  String importError(String error) {
    return 'Erreur import: $error';
  }

  @override
  String get offlineBanner => 'Mode hors ligne — donnees en cache';

  @override
  String get view => 'Voir';

  @override
  String get profile => 'Profil';

  @override
  String get logout => 'Se deconnecter';

  @override
  String get logoutTitle => 'Deconnexion';

  @override
  String get logoutConfirm => 'Voulez-vous vraiment vous deconnecter ?';

  @override
  String get disconnect => 'Deconnecter';

  @override
  String get user => 'Utilisateur';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get update => 'Mettre a jour';

  @override
  String get delete => 'Supprimer';

  @override
  String get duplicate => 'Dupliquer';

  @override
  String get share => 'Partager';

  @override
  String get edit => 'Modifier';

  @override
  String get download => 'Telecharger';

  @override
  String get downloadPdf => 'Telecharger PDF';

  @override
  String get downloadDocx => 'Telecharger DOCX';

  @override
  String get customize => 'Personnaliser';

  @override
  String get preview => 'Apercu';

  @override
  String get options => 'Options';

  @override
  String get retry => 'Reessayer';

  @override
  String get enhanceWithAi => 'Ameliorer avec l\'IA';

  @override
  String get adaptToJob => 'Adapter a une offre';

  @override
  String get adaptToJobDescription =>
      'Collez le texte d\'une offre d\'emploi pour analyser la correspondance';

  @override
  String get jobOfferHint => 'Collez ici le texte de l\'offre d\'emploi...';

  @override
  String get jobOfferTooShort =>
      'Collez le texte complet de l\'offre (min 20 caracteres)';

  @override
  String get jobMatchConsent =>
      'J\'accepte que le CV et le texte de l\'offre soient envoyes au service IA pour calculer la correspondance.';

  @override
  String get analyzing => 'Analyse en cours...';

  @override
  String get analyzeMatch => 'Analyser la correspondance';

  @override
  String get analyzeAnotherOffer => 'Analyser une autre offre';

  @override
  String get matchedKeywords => 'Mots-cles presents';

  @override
  String get missingKeywords => 'Mots-cles manquants';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get atsCategoryBreakdown => 'Detail du score ATS';

  @override
  String get atsActionPlan => 'Corrections prioritaires';

  @override
  String get atsFormatChecks => 'Controle format ATS';

  @override
  String get atsNoFormatRisk =>
      'Aucun risque ATS majeur detecte sur le format actuel.';

  @override
  String get atsScoreHistory => 'Evolution du score';

  @override
  String get atsCurrentRun => 'Score actuel';

  @override
  String get atsRerunLabel => 'Nouvelle analyse';

  @override
  String get creatingVariant => 'Creation en cours...';

  @override
  String get createAdaptedVariant => 'Creer une variante adaptee';

  @override
  String get createOptimizedVariant => 'Creer une variante optimisee';

  @override
  String variantCreated(String label) {
    return 'Variante \"$label\" creee';
  }

  @override
  String get variantFidelityBlocked => 'Aucun fait inventé n\'a été conservé.';

  @override
  String get variantCreationError =>
      'Erreur lors de la creation de la variante';

  @override
  String errorWithDetails(String error) {
    return 'Erreur : $error';
  }

  @override
  String get goodMatch => 'Bon match';

  @override
  String get averageMatch => 'Match moyen';

  @override
  String get lowMatch => 'Faible match';

  @override
  String get jobMatchScore => 'Score de correspondance avec l\'offre';

  @override
  String get prepareApplicationMessages => 'Preparer ma candidature';

  @override
  String get applicationMessagesTitle => 'Messages de candidature';

  @override
  String get applicationMessagesSubtitle =>
      'Des textes adaptes a votre CV et a cette offre';

  @override
  String get chooseTone => 'Ton';

  @override
  String get toneSimple => 'Simple';

  @override
  String get toneProfessional => 'Professionnel';

  @override
  String get toneDirect => 'Direct';

  @override
  String get toneJunior => 'Junior';

  @override
  String get toneSenior => 'Senior';

  @override
  String get generateApplicationMessages => 'Generer les 4 textes';

  @override
  String get generatingApplicationMessages => 'Generation en cours...';

  @override
  String get coverLetter => 'Lettre de motivation';

  @override
  String get applicationEmail => 'Email de candidature';

  @override
  String get linkedInMessage => 'Message LinkedIn';

  @override
  String get whatsAppMessage => 'Message WhatsApp';

  @override
  String get applicationMessageCopied => 'Texte copie dans le presse-papier';

  @override
  String get applicationMessagesFallback =>
      'Mode de secours utilise : verifiez et personnalisez les textes avant envoi.';

  @override
  String get generateWithAi => 'Generer avec l\'IA';

  @override
  String get proofreadingTitle => 'Correction orthographique';

  @override
  String get proofreadingSubtitle =>
      'Relisez tout le CV sans modifier le sens ni inventer de contenu.';

  @override
  String get enhancementSubtitle =>
      'Choisissez le niveau d\'amelioration souhaite';

  @override
  String get liteLevelDescription =>
      'Correction orthographe & grammaire uniquement';

  @override
  String get mediumLevelDescription =>
      'Correction et reformulation pour plus d\'impact';

  @override
  String get maxLevelDescription =>
      'Restructuration complete, mots-cles ATS et verbes d\'action';

  @override
  String get proofreadingGuarantee =>
      'Orthographe, grammaire, accents et termes professionnels. Les niveaux et les faits restent inchanges.';

  @override
  String get proofreadingInProgress => 'Relecture en cours...';

  @override
  String get proofreadCv => 'Relire le CV';

  @override
  String get improve => 'Ameliorer';

  @override
  String get apply => 'Appliquer';

  @override
  String get aiConsent =>
      'J\'accepte que le contenu de ce CV soit envoye au service IA pour generer des corrections ou suggestions. Les changements restent a valider avant application.';

  @override
  String get enhancementGenerated => 'Amelioration generee';

  @override
  String get fallbackResult =>
      'Resultat degrade (fournisseur de secours utilise)';

  @override
  String get aiProofreadingComplete => 'Relecture IA terminee';

  @override
  String get localProofreadingComplete => 'Relecture locale terminee';

  @override
  String get noCertainCorrection => 'Ce CV est déjà corrigé.';

  @override
  String correctedFields(int count) {
    return '$count champ(s) corrige(s).';
  }

  @override
  String get textCanBeApplied => 'Le texte peut etre applique sans changement.';

  @override
  String get pointsToClarify => 'Points a preciser';

  @override
  String get before => 'Avant';

  @override
  String get after => 'Apres';

  @override
  String get generating => 'Generation...';

  @override
  String get aiSuggestionsApplied => 'Suggestions IA appliquees';

  @override
  String get spellingCorrectionsApplied => 'Corrections appliquees';

  @override
  String get applicationError => 'Erreur lors de l\'application';

  @override
  String get proofreadSpelling => 'Corriger l\'orthographe';

  @override
  String get adaptedVariantCreated => 'Variante adaptee creee';

  @override
  String get styleNotSaved => 'Style non sauvegarde';

  @override
  String get customizeCv => 'Personnaliser le CV';

  @override
  String get livePreview => 'Apercu en direct';

  @override
  String get savingShort => 'Sauvegarde...';

  @override
  String get template => 'Template';

  @override
  String get color => 'Couleur';

  @override
  String get font => 'Police';

  @override
  String get identity => 'Identite';

  @override
  String get firstName => 'Prenom';

  @override
  String get lastName => 'Nom';

  @override
  String get jobTitle => 'Titre du poste';

  @override
  String get phone => 'Téléphone';

  @override
  String get address => 'Adresse';

  @override
  String get city => 'Ville';

  @override
  String get postalCode => 'Code postal';

  @override
  String get country => 'Pays';

  @override
  String get linkedin => 'LinkedIn';

  @override
  String get portfolio => 'Portfolio / Site web';

  @override
  String get professionalSummary => 'Resume professionnel';

  @override
  String get description => 'Description';

  @override
  String get establishment => 'Etablissement';

  @override
  String get degree => 'Diplome';

  @override
  String get fieldOfStudy => 'Domaine';

  @override
  String get organization => 'Organisme';

  @override
  String get technologies => 'Technologies';

  @override
  String get name => 'Nom';

  @override
  String get experiences => 'Experiences';

  @override
  String get education => 'Formations';

  @override
  String get skills => 'Competences';

  @override
  String get languages => 'Langues';

  @override
  String get certifications => 'Certifications';

  @override
  String get projects => 'Projets';

  @override
  String get contactAndProfile => 'Coordonnees & profil';

  @override
  String get careerPath => 'Parcours professionnel';

  @override
  String get degreesAndStudies => 'Diplomes & etudes';

  @override
  String get skillsAndLanguages => 'Competences & langues';

  @override
  String get extras => 'Extras';

  @override
  String get certificationsAndProjects => 'Certifications & projets';

  @override
  String get myCv => 'Mon CV';

  @override
  String cvDefaultTitle(String firstName, String lastName) {
    return 'CV $firstName $lastName';
  }

  @override
  String get cvCreatedSuccess => 'CV cree avec succes';

  @override
  String get cvUpdatedSuccess => 'CV mis a jour';

  @override
  String get editCv => 'Modifier le CV';

  @override
  String get previous => 'Precedent';

  @override
  String get next => 'Suivant';

  @override
  String get saving => 'Enregistrement...';

  @override
  String get saveCv => 'Enregistrer le CV';

  @override
  String completion(int percent) {
    return 'Score ATS : $percent%';
  }

  @override
  String get cvCompletion => 'SCORE ATS DU CV';

  @override
  String get toComplete => 'A completer';

  @override
  String get goodStart => 'Bon debut !';

  @override
  String get excellent => 'Excellent !';

  @override
  String get addExperience => 'Ajouter une expérience';

  @override
  String get addEducation => 'Ajouter une formation';

  @override
  String get addSkill => 'Ajouter une competence';

  @override
  String get addLanguage => 'Ajouter une langue';

  @override
  String get addCertification => 'Ajouter une certification';

  @override
  String get addProject => 'Ajouter un projet';

  @override
  String get editExperience => 'Modifier l\'expérience';

  @override
  String get editEducation => 'Modifier la formation';

  @override
  String get editSkill => 'Modifier la competence';

  @override
  String get editLanguage => 'Modifier la langue';

  @override
  String get editCertification => 'Modifier la certification';

  @override
  String get editProject => 'Modifier le projet';

  @override
  String get aiSuggestions => 'Suggestions IA';

  @override
  String get tapSuggestion =>
      'Appuyez sur une suggestion pour l\'ajouter a la description.';

  @override
  String get jobTitleRequired => 'Intitulé du poste *';

  @override
  String get companyRequired => 'Entreprise *';

  @override
  String get location => 'Lieu';

  @override
  String get startRequired => 'Debut *';

  @override
  String get start => 'Debut';

  @override
  String get end => 'Fin';

  @override
  String get responsibilitiesDescription => 'Description des responsabilites';

  @override
  String get responsibilitiesHint => 'Decrivez vos missions principales...';

  @override
  String get aiSuggestionsUnavailable => 'Suggestions IA indisponibles';

  @override
  String get noneExperience => 'Aucune expérience ajoutée';

  @override
  String get noneEducation => 'Aucune formation ajoutee';

  @override
  String get noneSkill => 'Aucune competence ajoutee';

  @override
  String get noneLanguage => 'Aucune langue ajoutee';

  @override
  String get noneCertification => 'Aucune certification ajoutee';

  @override
  String get noneProject => 'Aucun projet ajoute';

  @override
  String get untitled => 'Sans titre';

  @override
  String get currentPosition => 'En poste';

  @override
  String get choose => 'Choisir';

  @override
  String get currentRole => 'Poste actuel';

  @override
  String get sensitiveInfo => 'Infos personnelles';

  @override
  String get showSensitiveInfo => 'Afficher ces infos sur mon CV';

  @override
  String get showSensitiveInfoHelp =>
      'Par defaut elles restent privees (annee de naissance, situation, sexe).';

  @override
  String get cvIsForMe => 'Ce CV est pour moi';

  @override
  String get cvIsForMeHelp =>
      'Remplit prenom, nom et email depuis votre compte.';

  @override
  String get birthYear => 'Annee de naissance';

  @override
  String get birthYearHelp =>
      'Superieure a 1926 et au plus annee actuelle moins 10 ans.';

  @override
  String birthYearRange(int min, int max) {
    return 'Annee entre $min et $max.';
  }

  @override
  String get maritalStatus => 'Situation matrimoniale';

  @override
  String get sex => 'Sexe';

  @override
  String get firstNameExample => 'Ex : Alex';

  @override
  String get lastNameExample => 'Ex : Traore';

  @override
  String get jobTitleExample => 'Ex : Developpeur Full Stack';

  @override
  String get emailExample => 'Ex : nom@domaine.com';

  @override
  String get phoneExample => 'Ex : +225 0544210112';

  @override
  String get addressExample => 'Ex : Cocody, Riviera 3';

  @override
  String get postalCodeExample => 'Ex : 01 BP 1234';

  @override
  String get cityExample => 'Ex : Abidjan';

  @override
  String get countryExample => 'Ex : Cote d\'Ivoire';

  @override
  String get technologiesExample => 'Ex : Flutter, Dart, Firebase';

  @override
  String get educationInProgress => 'Formation en cours';

  @override
  String get optionalDescription => 'Description (optionnel)';

  @override
  String get skillRequired => 'Competence *';

  @override
  String get skillHint => 'Ex : JavaScript, Python, Photoshop...';

  @override
  String get optionalCategory => 'Categorie (optionnel)';

  @override
  String get categoryHint => 'Ex : Developpement, Design, Gestion...';

  @override
  String get level => 'Niveau';

  @override
  String get languageRequired => 'Langue *';

  @override
  String get languageSearchHint => 'Tapez pour chercher une langue';

  @override
  String get levelRequired => 'NIVEAU *';

  @override
  String get native => 'Natif';

  @override
  String get certificationNameRequired => 'Nom de la certification *';

  @override
  String get issuingOrganization => 'Organisme emetteur';

  @override
  String get issueDate => 'Date d\'obtention';

  @override
  String get expiration => 'Expiration';

  @override
  String get verificationLink => 'Lien de verification';

  @override
  String get expired => 'Expire';

  @override
  String get projectNameRequired => 'Nom du projet *';

  @override
  String get technologiesUsed => 'Technologies utilisees';

  @override
  String get projectLink => 'Lien du projet';

  @override
  String get projectDescriptionHint => 'Decrivez le projet et votre role...';

  @override
  String get suggestionsGenerationFailed =>
      'Impossible de generer des suggestions';

  @override
  String get profilePhotoOptional => 'Photo de profil (optionnel)';

  @override
  String get gallery => 'Galerie';

  @override
  String get camera => 'Camera';

  @override
  String get removePhoto => 'Supprimer la photo';

  @override
  String photoLocalOnly(String error) {
    return 'Photo visible localement, mais l\'envoi a echoue : $error';
  }

  @override
  String get coordinates => 'COORDONNEES';

  @override
  String get online => 'EN LIGNE';

  @override
  String get about => 'A PROPOS';

  @override
  String get firstNameRequired => 'Prénom *';

  @override
  String get lastNameRequired => 'Nom *';

  @override
  String get firstNameMissing => 'Prenom requis';

  @override
  String get lastNameMissing => 'Nom requis';

  @override
  String get targetJobHelper => 'Le poste que vous visez ou occupez';

  @override
  String get professionalEmailHelper => 'Votre email professionnel de contact';

  @override
  String get emailMissing => 'Email requis';

  @override
  String get phoneCountryHelper =>
      'Selectionnez un pays pour l\'indicatif automatique';

  @override
  String get postalAddressHelper => 'Optionnel - votre adresse postale';

  @override
  String get optional => 'Optionnel';

  @override
  String get professionalLinksHelper =>
      'Optionnel - ajoutez vos liens professionnels';

  @override
  String get linkedinHelper => 'Optionnel - votre profil LinkedIn';

  @override
  String get portfolioHelper => 'Optionnel - votre site ou portfolio';

  @override
  String get linkedinHint => 'Ex : linkedin.com/in/votre-nom';

  @override
  String get portfolioHint => 'Ex : github.com/votre-nom';

  @override
  String get generateSummaryHelper =>
      'Cliquez sur le bouton IA pour generer automatiquement';

  @override
  String get summaryGenerated => 'Resume genere par l\'IA';

  @override
  String get aiPersonalDataConsent =>
      'J\'accepte d\'envoyer ces informations au service IA.';

  @override
  String citySuggestionsForCountry(String country) {
    return 'Tapez pour afficher les villes de $country';
  }

  @override
  String get selectCountryForCities =>
      'Selectionnez un pays pour obtenir des suggestions';

  @override
  String get freeCityEntry => 'Saisie libre - ajoutez votre ville';

  @override
  String get countryDialCodeHelper =>
      'Selectionnez pour ajouter l\'indicatif telephonique';

  @override
  String get required => 'Requis';

  @override
  String get invalidEmail => 'Email invalide';

  @override
  String get resumeTooShort =>
      'Resume trop court — utilisez l\'IA pour l\'ameliorer';

  @override
  String get goodResume => 'Bon resume';

  @override
  String get characters => 'caracteres';

  @override
  String get beginner => 'Debutant';

  @override
  String get basic => 'Base';

  @override
  String get good => 'Bon';

  @override
  String get advanced => 'Avance';

  @override
  String get expert => 'Expert';

  @override
  String get intermediate => 'Intermediaire';

  @override
  String get confirmed => 'Confirmé';

  @override
  String get elementary => 'Elementaire';

  @override
  String get upperIntermediate => 'Intermediaire avance';

  @override
  String get fluent => 'Courant';

  @override
  String get mastery => 'Maitrise';

  @override
  String get nativeLanguage => 'Langue maternelle';

  @override
  String get featureAi => 'Suggestions IA';

  @override
  String get featurePdf => 'Export PDF';

  @override
  String get featureShare => 'Partage public';

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Langue de l\'application';

  @override
  String get french => 'Francais';

  @override
  String get english => 'Anglais';

  @override
  String get information => 'Informations';

  @override
  String get fullName => 'Nom complet';

  @override
  String get cvsCreated => 'CVs crees';

  @override
  String get downloads => 'Telechargements';

  @override
  String get shares => 'Partages';

  @override
  String get views => 'Vues';

  @override
  String get privacy => 'Confidentialite';

  @override
  String get privacyPolicy => 'Politique de confidentialite';

  @override
  String get privacyPolicySubtitle => 'Donnees, IA, export et suppression';

  @override
  String get exportMyData => 'Exporter mes donnees';

  @override
  String get exportMyDataSubtitle => 'Copie JSON de votre compte et de vos CV';

  @override
  String get deleteMyAccount => 'Supprimer mon compte';

  @override
  String get deleteMyAccountSubtitle =>
      'Suppression du compte et des CV associes';

  @override
  String get exportCopied => 'Export copie dans le presse-papier';

  @override
  String exportFailed(String error) {
    return 'Export impossible : $error';
  }

  @override
  String get deleteAccountTitle => 'Supprimer le compte';

  @override
  String get deleteAccountConfirm =>
      'Cette action supprime votre compte et les CV associes cote serveur. Elle est irreversible.';

  @override
  String deleteAccountFailed(String error) {
    return 'Suppression impossible : $error';
  }

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String daysAgo(int count) {
    return 'Il y a $count jours';
  }

  @override
  String get complete => 'Complet';

  @override
  String get inProgress => 'En cours';

  @override
  String get incomplete => 'Incomplet';

  @override
  String get pdf => 'PDF';

  @override
  String get docx => 'DOCX';

  @override
  String nVariants(int count) {
    return '$count variante(s)';
  }

  @override
  String get errorInvalidCredentials =>
      'Identifiants incorrects. Verifiez votre email et mot de passe.';

  @override
  String get errorEmailAlreadyUsed =>
      'Cette adresse email est deja utilisee. Essayez de vous connecter.';

  @override
  String get errorNetworkUnavailable =>
      'Impossible de joindre le serveur. Verifiez votre connexion internet.';

  @override
  String get errorTimeout =>
      'Le serveur met trop de temps a repondre. Reessayez dans quelques instants.';

  @override
  String get errorServer =>
      'Une erreur serveur est survenue. Reessayez dans quelques instants.';

  @override
  String get errorForbidden => 'Acces refuse. Reconnectez-vous et reessayez.';

  @override
  String get errorRateLimit =>
      'Trop de tentatives. Patientez une minute avant de reessayer.';

  @override
  String get errorNotFound => 'Ce CV n\'existe plus ou a ete supprime.';

  @override
  String get errorDownload =>
      'Le telechargement a echoue. Reessayez dans quelques instants.';

  @override
  String get errorAiUnavailable =>
      'Le service IA est temporairement indisponible. Reessayez plus tard.';

  @override
  String get errorFileUpload =>
      'L\'envoi du fichier a echoue. Verifiez le format et la taille.';

  @override
  String get validationPersonalInfoMissing =>
      'Informations personnelles manquantes';

  @override
  String validationFieldMissing(String field) {
    return '$field manquant';
  }

  @override
  String get validationJobTitleMissing =>
      'Titre du poste manquant - important pour les recruteurs';

  @override
  String get validationSummaryEmpty =>
      'Resume professionnel vide - utilisez l\'IA pour le generer';

  @override
  String validationSummaryShort(int count) {
    return 'Resume trop court ($count car.) - min 100 recommande';
  }

  @override
  String get validationTechLinkMissing =>
      'LinkedIn ou GitHub manquant - tres attendu pour un profil tech';

  @override
  String get validationNoExperience => 'Aucune experience renseignee';

  @override
  String validationDescriptionMissing(String item) {
    return '$item : description manquante';
  }

  @override
  String validationNoMetric(String item) {
    return '$item : aucun chiffre ou indicateur - ajoutez des resultats mesurables';
  }

  @override
  String validationEndBeforeStart(String item) {
    return '$item : date de fin avant date de debut';
  }

  @override
  String validationFutureEnd(String item) {
    return '$item : date de fin dans le futur';
  }

  @override
  String get validationNoEducation => 'Aucune formation renseignee';

  @override
  String get validationNoSkills => 'Aucune competence renseignee';

  @override
  String validationFewSkills(int count) {
    return 'Seulement $count competences - 8 a 12 recommande';
  }

  @override
  String validationCombinedSkills(String name) {
    return '\"$name\" semble contenir plusieurs competences - separez-les';
  }

  @override
  String get validationNoLanguages => 'Aucune langue renseignee';

  @override
  String validationFutureCertification(String name) {
    return '\"$name\" datee dans le futur - marquez En cours si necessaire';
  }

  @override
  String validationShortProject(String name) {
    return '\"$name\" : description trop courte - developpez';
  }

  @override
  String validationTooMuchContent(int count) {
    return 'Beaucoup de contenu ($count elements) - risque de depasser 1 page';
  }

  @override
  String get errorGeneric => 'Une erreur est survenue';

  @override
  String get notifications => 'Notifications';

  @override
  String get staleCvReminder => 'Rappel de mise a jour';

  @override
  String get staleCvReminderSubtitle =>
      'Me prevenir apres 30 jours sans modification';

  @override
  String get cvViewNotifications => 'Vues du CV partage';

  @override
  String get cvViewNotificationsSubtitle =>
      'Me prevenir tous les 10 nouveaux visiteurs';

  @override
  String get aiTipNotifications => 'Conseils d\'amelioration IA';

  @override
  String get aiTipNotificationsSubtitle =>
      'Recevoir des pistes pour renforcer mon CV';

  @override
  String get applications => 'Candidatures';

  @override
  String get addApplication => 'Ajouter une candidature';

  @override
  String get editApplication => 'Modifier la candidature';

  @override
  String get deleteApplication => 'Supprimer la candidature';

  @override
  String deleteApplicationConfirm(String company) {
    return 'Supprimer la candidature chez $company ?';
  }

  @override
  String get all => 'Toutes';

  @override
  String get noApplications => 'Aucune candidature';

  @override
  String get noApplicationsDescription =>
      'Ajoutez vos candidatures pour suivre les relances et les prochaines actions.';

  @override
  String followUpsDue(int count) {
    return '$count relance(s) a effectuer aujourd\'hui';
  }

  @override
  String get nextFollowUp => 'Prochaine relance';

  @override
  String get variant => 'Variante';

  @override
  String get pendingSync => 'En attente de sync';

  @override
  String get importInvalidExtension =>
      'Format non supporte (PDF ou DOCX attendu)';

  @override
  String get importInvalidContent =>
      'Le contenu du fichier ne correspond pas a son extension';

  @override
  String get importEmptyFile => 'Fichier vide';

  @override
  String get importTooLarge => 'Fichier trop volumineux (max 10 Mo)';

  @override
  String get openOffer => 'Ouvrir l\'offre';

  @override
  String get company => 'Entreprise';

  @override
  String get position => 'Poste';

  @override
  String get status => 'Statut';

  @override
  String get linkedCv => 'CV utilise';

  @override
  String get noLinkedCv => 'Aucun CV lie';

  @override
  String get offerLink => 'Lien de l\'offre';

  @override
  String get sentDate => 'Date d\'envoi';

  @override
  String get notes => 'Notes';

  @override
  String get requiredField => 'Champ obligatoire';

  @override
  String get invalidUrl => 'Lien invalide (http ou https attendu)';

  @override
  String get couldNotOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get followUpBeforeSent => 'La relance ne peut pas preceder l\'envoi';

  @override
  String get applicationDraft => 'Brouillon';

  @override
  String get applicationSent => 'Envoyee';

  @override
  String get applicationInterview => 'Entretien';

  @override
  String get applicationTechnicalTest => 'Test technique';

  @override
  String get applicationOffer => 'Offre recue';

  @override
  String get applicationRejected => 'Refusee';

  @override
  String get applicationArchived => 'Archivee';

  @override
  String get downloadQrCode => 'Télécharger le QR code';

  @override
  String get portfolioQrCode => 'QR code du portfolio';

  @override
  String get showQrCode => 'Afficher le QR code';

  @override
  String get shareViaWhatsApp => 'Partager par WhatsApp';

  @override
  String get contact => 'Contact';

  @override
  String get contactCandidate => 'Contacter le candidat';

  @override
  String get publicPortfolioUnavailable =>
      'Ce portfolio est indisponible ou son propriétaire l\'a désactivé.';

  @override
  String get publicRecruiterPortfolio => 'Portfolio public recruteur';

  @override
  String get publicLinkActivationFailed =>
      'Impossible d\'activer le lien public.';

  @override
  String get deactivate => 'Désactiver';

  @override
  String get publicPortfolioDescription =>
      'Ce lien ouvre une présentation professionnelle de votre CV sans connexion.';

  @override
  String get regeneratePublicLink => 'Régénérer le lien';

  @override
  String get allowPublicContact => 'Autoriser le contact';

  @override
  String get allowPublicContactDescription =>
      'Affiche l\'e-mail et le bouton de contact.';

  @override
  String get allowPublicDownloads => 'Autoriser PDF et DOCX';

  @override
  String get allowPublicDownloadsDescription =>
      'Les fichiers contiennent les coordonnées autorisées du CV.';

  @override
  String get privacyControlTitle => 'Vos données restent sous votre contrôle';

  @override
  String get privacyIntro =>
      'MonCV stocke les informations nécessaires à la création, l\'édition, l\'export et le partage de vos CV.';

  @override
  String get privacyStoredDataTitle => 'Données stockées';

  @override
  String get privacyStoredAccount => 'Compte : email, nom et prénom.';

  @override
  String get privacyStoredCv =>
      'CV : identité, contacts, expériences, formations, compétences, langues, certifications, projets, style et liens de partage.';

  @override
  String get privacyStoredFiles =>
      'Fichiers : photos importées et documents générés localement selon les actions demandées.';

  @override
  String get privacyAiTitle => 'Utilisation de l\'IA';

  @override
  String get privacyAiConsent =>
      'Aucun contenu de CV n\'est envoyé à l\'IA sans consentement explicite dans l\'écran concerné.';

  @override
  String get privacyAiReview =>
      'Les résultats IA sont affichés avant application et peuvent être refusés.';

  @override
  String get privacyAiFallback =>
      'En absence de clé IA, l\'application utilise des corrections locales limitées quand elles existent.';

  @override
  String get privacyRightsTitle => 'Vos droits';

  @override
  String get privacyRightsExport =>
      'Vous pouvez exporter vos données depuis le profil.';

  @override
  String get privacyRightsDelete =>
      'Vous pouvez supprimer votre compte depuis le profil.';

  @override
  String get privacyRightsCascade =>
      'La suppression du compte supprime aussi les CV rattachés côté backend.';

  @override
  String get privacyPwaTitle => 'Sécurité PWA';

  @override
  String get privacyPwaHttps =>
      'En production, l\'application doit utiliser HTTPS et une API HTTPS.';

  @override
  String get privacyPwaStorage =>
      'Le stockage web des tokens repose sur le stockage local du navigateur : utilisez un appareil de confiance.';

  @override
  String get privacyPwaEnterprise =>
      'La cible recommandée pour une version entreprise est une session serveur avec cookies HttpOnly/SameSite.';

  @override
  String get googleAccount => 'Compte Google';

  @override
  String get googleLinkSuccess => 'Compte Google associé avec succès';

  @override
  String get googleLinkFailed => 'Impossible d\'associer le compte Google';

  @override
  String get googleSignInFailed => 'Connexion Google impossible';

  @override
  String countryDialCodeAdded(String code) {
    return 'Indicatif $code ajouté selon le pays';
  }

  @override
  String educationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count formations',
      one: '1 formation',
      zero: 'Aucune formation',
    );
    return '$_temp0';
  }

  @override
  String experienceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expériences',
      one: '1 expérience',
      zero: 'Aucune expérience',
    );
    return '$_temp0';
  }

  @override
  String skillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compétences',
      one: '1 compétence',
      zero: 'Aucune compétence',
    );
    return '$_temp0';
  }

  @override
  String languageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count langues',
      one: '1 langue',
      zero: 'Aucune langue',
    );
    return '$_temp0';
  }

  @override
  String modifiedOn(String date) {
    return 'Modifié le $date';
  }
}
