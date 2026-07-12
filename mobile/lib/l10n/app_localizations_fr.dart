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
  String get createMyAccount => 'Creer mon compte';

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
  String get generateWithAi => 'Generer avec l\'IA';

  @override
  String get generating => 'Generation...';

  @override
  String get aiSuggestionsApplied => 'Suggestions IA appliquees';

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
  String get phone => 'Telephone';

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
  String get addExperience => 'Ajouter une experience';

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
  String get errorGeneric => 'Une erreur est survenue';
}
