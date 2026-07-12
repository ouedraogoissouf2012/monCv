import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'MonCV'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @register.
  ///
  /// In fr, this message translates to:
  /// **'Creer un compte'**
  String get register;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublie ?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In fr, this message translates to:
  /// **'Deja un compte ?'**
  String get hasAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In fr, this message translates to:
  /// **'Bon retour\nparmi nous.'**
  String get welcomeBack;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour continuer sur MonCV'**
  String get welcomeSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Creez votre\ncompte.'**
  String get createAccount;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez MonCV gratuitement'**
  String get createAccountSubtitle;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'vous@exemple.com'**
  String get emailHint;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Champ requis'**
  String get fieldRequired;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caracteres'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get passwordStrengthMedium;

  /// No description provided for @passwordStrengthGood.
  ///
  /// In fr, this message translates to:
  /// **'Bon'**
  String get passwordStrengthGood;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In fr, this message translates to:
  /// **'Fort'**
  String get passwordStrengthStrong;

  /// No description provided for @loginError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion'**
  String get loginError;

  /// No description provided for @registerError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'inscription'**
  String get registerError;

  /// No description provided for @createMyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Creer mon compte'**
  String get createMyAccount;

  /// No description provided for @myCvs.
  ///
  /// In fr, this message translates to:
  /// **'Mes CVs'**
  String get myCvs;

  /// No description provided for @newCv.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau CV'**
  String get newCv;

  /// No description provided for @noCvYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun CV pour l\'instant'**
  String get noCvYet;

  /// No description provided for @createFirstCv.
  ///
  /// In fr, this message translates to:
  /// **'Creez votre premier CV professionnel'**
  String get createFirstCv;

  /// No description provided for @createMyFirstCv.
  ///
  /// In fr, this message translates to:
  /// **'Creer mon premier CV'**
  String get createMyFirstCv;

  /// No description provided for @importCv.
  ///
  /// In fr, this message translates to:
  /// **'Importer un CV (PDF/DOCX)'**
  String get importCv;

  /// No description provided for @deleteCvTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le CV'**
  String get deleteCvTitle;

  /// No description provided for @deleteCvConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer \"{titre}\" ?'**
  String deleteCvConfirm(String titre);

  /// No description provided for @cvDeleted.
  ///
  /// In fr, this message translates to:
  /// **'CV supprime'**
  String get cvDeleted;

  /// No description provided for @cvDuplicated.
  ///
  /// In fr, this message translates to:
  /// **'CV duplique'**
  String get cvDuplicated;

  /// No description provided for @shareLinkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lien de partage'**
  String get shareLinkTitle;

  /// No description provided for @shareLinkDescription.
  ///
  /// In fr, this message translates to:
  /// **'Partagez ce lien pour que n\'importe qui puisse voir votre CV :'**
  String get shareLinkDescription;

  /// No description provided for @linkCopied.
  ///
  /// In fr, this message translates to:
  /// **'Lien copie dans le presse-papier'**
  String get linkCopied;

  /// No description provided for @copy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get copy;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @pdfDownloading.
  ///
  /// In fr, this message translates to:
  /// **'Generation du PDF en cours...'**
  String get pdfDownloading;

  /// No description provided for @pdfDownloaded.
  ///
  /// In fr, this message translates to:
  /// **'PDF telecharge'**
  String get pdfDownloaded;

  /// No description provided for @pdfError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur PDF: {error}'**
  String pdfError(String error);

  /// No description provided for @docxDownloading.
  ///
  /// In fr, this message translates to:
  /// **'Telechargement DOCX en cours...'**
  String get docxDownloading;

  /// No description provided for @docxDownloaded.
  ///
  /// In fr, this message translates to:
  /// **'DOCX telecharge'**
  String get docxDownloaded;

  /// No description provided for @docxError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur DOCX: {error}'**
  String docxError(String error);

  /// No description provided for @importInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Import du CV en cours...'**
  String get importInProgress;

  /// No description provided for @importSuccess.
  ///
  /// In fr, this message translates to:
  /// **'CV \"{titre}\" importe avec succes'**
  String importSuccess(String titre);

  /// No description provided for @importError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur import: {error}'**
  String importError(String error);

  /// No description provided for @offlineBanner.
  ///
  /// In fr, this message translates to:
  /// **'Mode hors ligne — donnees en cache'**
  String get offlineBanner;

  /// No description provided for @view.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get view;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se deconnecter'**
  String get logout;

  /// No description provided for @logoutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Deconnexion'**
  String get logoutTitle;

  /// No description provided for @logoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous deconnecter ?'**
  String get logoutConfirm;

  /// No description provided for @disconnect.
  ///
  /// In fr, this message translates to:
  /// **'Deconnecter'**
  String get disconnect;

  /// No description provided for @user.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get user;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @update.
  ///
  /// In fr, this message translates to:
  /// **'Mettre a jour'**
  String get update;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @duplicate.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get duplicate;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @download.
  ///
  /// In fr, this message translates to:
  /// **'Telecharger'**
  String get download;

  /// No description provided for @downloadPdf.
  ///
  /// In fr, this message translates to:
  /// **'Telecharger PDF'**
  String get downloadPdf;

  /// No description provided for @downloadDocx.
  ///
  /// In fr, this message translates to:
  /// **'Telecharger DOCX'**
  String get downloadDocx;

  /// No description provided for @customize.
  ///
  /// In fr, this message translates to:
  /// **'Personnaliser'**
  String get customize;

  /// No description provided for @preview.
  ///
  /// In fr, this message translates to:
  /// **'Apercu'**
  String get preview;

  /// No description provided for @options.
  ///
  /// In fr, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Reessayer'**
  String get retry;

  /// No description provided for @enhanceWithAi.
  ///
  /// In fr, this message translates to:
  /// **'Ameliorer avec l\'IA'**
  String get enhanceWithAi;

  /// No description provided for @adaptToJob.
  ///
  /// In fr, this message translates to:
  /// **'Adapter a une offre'**
  String get adaptToJob;

  /// No description provided for @generateWithAi.
  ///
  /// In fr, this message translates to:
  /// **'Generer avec l\'IA'**
  String get generateWithAi;

  /// No description provided for @generating.
  ///
  /// In fr, this message translates to:
  /// **'Generation...'**
  String get generating;

  /// No description provided for @aiSuggestionsApplied.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions IA appliquees'**
  String get aiSuggestionsApplied;

  /// No description provided for @template.
  ///
  /// In fr, this message translates to:
  /// **'Template'**
  String get template;

  /// No description provided for @color.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get color;

  /// No description provided for @font.
  ///
  /// In fr, this message translates to:
  /// **'Police'**
  String get font;

  /// No description provided for @identity.
  ///
  /// In fr, this message translates to:
  /// **'Identite'**
  String get identity;

  /// No description provided for @firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prenom'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastName;

  /// No description provided for @jobTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre du poste'**
  String get jobTitle;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Telephone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @city.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get city;

  /// No description provided for @postalCode.
  ///
  /// In fr, this message translates to:
  /// **'Code postal'**
  String get postalCode;

  /// No description provided for @country.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get country;

  /// No description provided for @linkedin.
  ///
  /// In fr, this message translates to:
  /// **'LinkedIn'**
  String get linkedin;

  /// No description provided for @portfolio.
  ///
  /// In fr, this message translates to:
  /// **'Portfolio / Site web'**
  String get portfolio;

  /// No description provided for @professionalSummary.
  ///
  /// In fr, this message translates to:
  /// **'Resume professionnel'**
  String get professionalSummary;

  /// No description provided for @experiences.
  ///
  /// In fr, this message translates to:
  /// **'Experiences'**
  String get experiences;

  /// No description provided for @education.
  ///
  /// In fr, this message translates to:
  /// **'Formations'**
  String get education;

  /// No description provided for @skills.
  ///
  /// In fr, this message translates to:
  /// **'Competences'**
  String get skills;

  /// No description provided for @languages.
  ///
  /// In fr, this message translates to:
  /// **'Langues'**
  String get languages;

  /// No description provided for @certifications.
  ///
  /// In fr, this message translates to:
  /// **'Certifications'**
  String get certifications;

  /// No description provided for @projects.
  ///
  /// In fr, this message translates to:
  /// **'Projets'**
  String get projects;

  /// No description provided for @addExperience.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une experience'**
  String get addExperience;

  /// No description provided for @addEducation.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une formation'**
  String get addEducation;

  /// No description provided for @addSkill.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une competence'**
  String get addSkill;

  /// No description provided for @addLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une langue'**
  String get addLanguage;

  /// No description provided for @addCertification.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une certification'**
  String get addCertification;

  /// No description provided for @addProject.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un projet'**
  String get addProject;

  /// No description provided for @required.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get required;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get invalidEmail;

  /// No description provided for @resumeTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Resume trop court — utilisez l\'IA pour l\'ameliorer'**
  String get resumeTooShort;

  /// No description provided for @goodResume.
  ///
  /// In fr, this message translates to:
  /// **'Bon resume'**
  String get goodResume;

  /// No description provided for @characters.
  ///
  /// In fr, this message translates to:
  /// **'caracteres'**
  String get characters;

  /// No description provided for @beginner.
  ///
  /// In fr, this message translates to:
  /// **'Debutant'**
  String get beginner;

  /// No description provided for @basic.
  ///
  /// In fr, this message translates to:
  /// **'Base'**
  String get basic;

  /// No description provided for @good.
  ///
  /// In fr, this message translates to:
  /// **'Bon'**
  String get good;

  /// No description provided for @advanced.
  ///
  /// In fr, this message translates to:
  /// **'Avance'**
  String get advanced;

  /// No description provided for @expert.
  ///
  /// In fr, this message translates to:
  /// **'Expert'**
  String get expert;

  /// No description provided for @featureAi.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions IA'**
  String get featureAi;

  /// No description provided for @featurePdf.
  ///
  /// In fr, this message translates to:
  /// **'Export PDF'**
  String get featurePdf;

  /// No description provided for @featureShare.
  ///
  /// In fr, this message translates to:
  /// **'Partage public'**
  String get featureShare;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @information.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get information;

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get fullName;

  /// No description provided for @cvsCreated.
  ///
  /// In fr, this message translates to:
  /// **'CVs crees'**
  String get cvsCreated;

  /// No description provided for @downloads.
  ///
  /// In fr, this message translates to:
  /// **'Telechargements'**
  String get downloads;

  /// No description provided for @shares.
  ///
  /// In fr, this message translates to:
  /// **'Partages'**
  String get shares;

  /// No description provided for @views.
  ///
  /// In fr, this message translates to:
  /// **'Vues'**
  String get views;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} jours'**
  String daysAgo(int count);

  /// No description provided for @complete.
  ///
  /// In fr, this message translates to:
  /// **'Complet'**
  String get complete;

  /// No description provided for @inProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get inProgress;

  /// No description provided for @incomplete.
  ///
  /// In fr, this message translates to:
  /// **'Incomplet'**
  String get incomplete;

  /// No description provided for @pdf.
  ///
  /// In fr, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @docx.
  ///
  /// In fr, this message translates to:
  /// **'DOCX'**
  String get docx;

  /// No description provided for @nVariants.
  ///
  /// In fr, this message translates to:
  /// **'{count} variante(s)'**
  String nVariants(int count);

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants incorrects. Verifiez votre email et mot de passe.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse email est deja utilisee. Essayez de vous connecter.'**
  String get errorEmailAlreadyUsed;

  /// No description provided for @errorNetworkUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de joindre le serveur. Verifiez votre connexion internet.'**
  String get errorNetworkUnavailable;

  /// No description provided for @errorTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur met trop de temps a repondre. Reessayez dans quelques instants.'**
  String get errorTimeout;

  /// No description provided for @errorServer.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur serveur est survenue. Reessayez dans quelques instants.'**
  String get errorServer;

  /// No description provided for @errorForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Acces refuse. Reconnectez-vous et reessayez.'**
  String get errorForbidden;

  /// No description provided for @errorRateLimit.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Patientez une minute avant de reessayer.'**
  String get errorRateLimit;

  /// No description provided for @errorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce CV n\'existe plus ou a ete supprime.'**
  String get errorNotFound;

  /// No description provided for @errorDownload.
  ///
  /// In fr, this message translates to:
  /// **'Le telechargement a echoue. Reessayez dans quelques instants.'**
  String get errorDownload;

  /// No description provided for @errorAiUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le service IA est temporairement indisponible. Reessayez plus tard.'**
  String get errorAiUnavailable;

  /// No description provided for @errorFileUpload.
  ///
  /// In fr, this message translates to:
  /// **'L\'envoi du fichier a echoue. Verifiez le format et la taille.'**
  String get errorFileUpload;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
