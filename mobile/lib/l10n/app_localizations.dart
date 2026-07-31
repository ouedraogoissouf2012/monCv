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

  /// No description provided for @emailShort.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get emailShort;

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

  /// No description provided for @requiredFieldMessage.
  ///
  /// In fr, this message translates to:
  /// **'{section} : {field} obligatoire.'**
  String requiredFieldMessage(String section, String field);

  /// No description provided for @completePersonalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Identite : completez vos informations personnelles.'**
  String get completePersonalInfo;

  /// No description provided for @invalidEmailMessage.
  ///
  /// In fr, this message translates to:
  /// **'Identite : format email invalide.'**
  String get invalidEmailMessage;

  /// No description provided for @numberedItem.
  ///
  /// In fr, this message translates to:
  /// **'{section} {index}'**
  String numberedItem(String section, int index);

  /// No description provided for @endDateBeforeStart.
  ///
  /// In fr, this message translates to:
  /// **'{item} : la date de fin doit etre apres la date de debut.'**
  String endDateBeforeStart(String item);

  /// No description provided for @skillLevelRange.
  ///
  /// In fr, this message translates to:
  /// **'{item} : le niveau doit etre entre 1 et 5.'**
  String skillLevelRange(String item);

  /// No description provided for @certificationExpirationBeforeIssue.
  ///
  /// In fr, this message translates to:
  /// **'{item} : expiration avant obtention.'**
  String certificationExpirationBeforeIssue(String item);

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
  /// **'Créer mon compte'**
  String get createMyAccount;

  /// No description provided for @landingHeroTitle.
  ///
  /// In fr, this message translates to:
  /// **'Creez un CV\nqui parle aux recruteurs'**
  String get landingHeroTitle;

  /// No description provided for @landingHeroTitleMobile.
  ///
  /// In fr, this message translates to:
  /// **'Creez un CV\nqui parle aux\nrecruteurs'**
  String get landingHeroTitleMobile;

  /// No description provided for @landingHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Francais professionnel, formats ATS, partage WhatsApp et export PDF/DOCX pour candidatures locales ou internationales.'**
  String get landingHeroSubtitle;

  /// No description provided for @createCvFree.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon CV gratuitement'**
  String get createCvFree;

  /// No description provided for @bilingual.
  ///
  /// In fr, this message translates to:
  /// **'Bilingue'**
  String get bilingual;

  /// No description provided for @templates.
  ///
  /// In fr, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @compatible.
  ///
  /// In fr, this message translates to:
  /// **'Compatible'**
  String get compatible;

  /// No description provided for @aiFeatureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Intelligence Artificielle'**
  String get aiFeatureTitle;

  /// No description provided for @aiFeatureDescription.
  ///
  /// In fr, this message translates to:
  /// **'Un francais naturel, precis et sans phrases artificielles.'**
  String get aiFeatureDescription;

  /// No description provided for @templatesFeatureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Templates cibles'**
  String get templatesFeatureTitle;

  /// No description provided for @templatesFeatureDescription.
  ///
  /// In fr, this message translates to:
  /// **'Corporate, junior, senior, tech et ATS international.'**
  String get templatesFeatureDescription;

  /// No description provided for @atsFeatureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Score ATS'**
  String get atsFeatureTitle;

  /// No description provided for @atsFeatureDescription.
  ///
  /// In fr, this message translates to:
  /// **'Collez une offre et obtenez un score de correspondance.'**
  String get atsFeatureDescription;

  /// No description provided for @docxFeatureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Export DOCX'**
  String get docxFeatureTitle;

  /// No description provided for @docxFeatureDescription.
  ///
  /// In fr, this message translates to:
  /// **'Telechargez en Word pour une compatibilite ATS maximale.'**
  String get docxFeatureDescription;

  /// No description provided for @mobileFeatureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mobile-first Afrique'**
  String get mobileFeatureTitle;

  /// No description provided for @mobileFeatureDescription.
  ///
  /// In fr, this message translates to:
  /// **'Pense pour creer, corriger, exporter et partager depuis un telephone.'**
  String get mobileFeatureDescription;

  /// No description provided for @whatsAppFeatureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partage WhatsApp'**
  String get whatsAppFeatureTitle;

  /// No description provided for @whatsAppFeatureDescription.
  ///
  /// In fr, this message translates to:
  /// **'Envoyez un lien propre a un recruteur ou a un contact RH.'**
  String get whatsAppFeatureDescription;

  /// No description provided for @allYouNeed.
  ///
  /// In fr, this message translates to:
  /// **'Tout ce dont vous avez besoin'**
  String get allYouNeed;

  /// No description provided for @allYouNeedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Un outil complet pour creer des CV qui font la difference.'**
  String get allYouNeedSubtitle;

  /// No description provided for @clearCvTitle.
  ///
  /// In fr, this message translates to:
  /// **'Un CV clair pour candidater partout'**
  String get clearCvTitle;

  /// No description provided for @clearCvSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Un rendu lisible pour recruteurs, PME, cabinets et ATS'**
  String get clearCvSubtitle;

  /// No description provided for @sampleProfile.
  ///
  /// In fr, this message translates to:
  /// **'PROFIL'**
  String get sampleProfile;

  /// No description provided for @sampleProfileText.
  ///
  /// In fr, this message translates to:
  /// **'Ingenieur Full Stack avec 3 ans d\'experience. Expert Java/Spring Boot et Flutter.'**
  String get sampleProfileText;

  /// No description provided for @sampleSkills.
  ///
  /// In fr, this message translates to:
  /// **'COMPETENCES'**
  String get sampleSkills;

  /// No description provided for @sampleExperiences.
  ///
  /// In fr, this message translates to:
  /// **'EXPERIENCES'**
  String get sampleExperiences;

  /// No description provided for @howItWorks.
  ///
  /// In fr, this message translates to:
  /// **'Comment ca marche'**
  String get howItWorks;

  /// No description provided for @fillIn.
  ///
  /// In fr, this message translates to:
  /// **'Remplissez'**
  String get fillIn;

  /// No description provided for @fillInDescription.
  ///
  /// In fr, this message translates to:
  /// **'Des aides courtes guident titre, resume et experiences.'**
  String get fillInDescription;

  /// No description provided for @adapt.
  ///
  /// In fr, this message translates to:
  /// **'Adaptez'**
  String get adapt;

  /// No description provided for @adaptDescription.
  ///
  /// In fr, this message translates to:
  /// **'Corrigez le francais et choisissez un template selon le poste.'**
  String get adaptDescription;

  /// No description provided for @send.
  ///
  /// In fr, this message translates to:
  /// **'Partagez'**
  String get send;

  /// No description provided for @sendDescription.
  ///
  /// In fr, this message translates to:
  /// **'Exportez en PDF/DOCX ou envoyez le lien par WhatsApp.'**
  String get sendDescription;

  /// No description provided for @readyToApply.
  ///
  /// In fr, this message translates to:
  /// **'Pret a candidater avec un CV propre ?'**
  String get readyToApply;

  /// No description provided for @readyToApplySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Mobile, rapide, lisible et pense pour le marche francophone.'**
  String get readyToApplySubtitle;

  /// No description provided for @startNow.
  ///
  /// In fr, this message translates to:
  /// **'Commencer maintenant'**
  String get startNow;

  /// No description provided for @landingFooter.
  ///
  /// In fr, this message translates to:
  /// **'© 2026 MonCV. CV francophone, mobile-first et compatible ATS.'**
  String get landingFooter;

  /// No description provided for @sampleCandidateName.
  ///
  /// In fr, this message translates to:
  /// **'ISSOUF OUEDRAOGO'**
  String get sampleCandidateName;

  /// No description provided for @sampleCandidateRole.
  ///
  /// In fr, this message translates to:
  /// **'Ingenieur Logiciel Full Stack'**
  String get sampleCandidateRole;

  /// No description provided for @sampleCandidateContact.
  ///
  /// In fr, this message translates to:
  /// **'issouf@gmail.com | +225 07 44 21 01 12 | Abidjan'**
  String get sampleCandidateContact;

  /// No description provided for @sampleCandidatePosition.
  ///
  /// In fr, this message translates to:
  /// **'Lead Developer'**
  String get sampleCandidatePosition;

  /// No description provided for @sampleCandidateCompany.
  ///
  /// In fr, this message translates to:
  /// **'DIGIT AFRICAN - Abidjan'**
  String get sampleCandidateCompany;

  /// No description provided for @lite.
  ///
  /// In fr, this message translates to:
  /// **'Lite'**
  String get lite;

  /// No description provided for @medium.
  ///
  /// In fr, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @maximum.
  ///
  /// In fr, this message translates to:
  /// **'Max'**
  String get maximum;

  /// No description provided for @whatsApp.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

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

  /// No description provided for @adaptToJobDescription.
  ///
  /// In fr, this message translates to:
  /// **'Collez le texte d\'une offre d\'emploi pour analyser la correspondance'**
  String get adaptToJobDescription;

  /// No description provided for @jobOfferHint.
  ///
  /// In fr, this message translates to:
  /// **'Collez ici le texte de l\'offre d\'emploi...'**
  String get jobOfferHint;

  /// No description provided for @jobOfferTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Collez le texte complet de l\'offre (min 20 caracteres)'**
  String get jobOfferTooShort;

  /// No description provided for @jobMatchConsent.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte que le CV et le texte de l\'offre soient envoyes au service IA pour calculer la correspondance.'**
  String get jobMatchConsent;

  /// No description provided for @analyzing.
  ///
  /// In fr, this message translates to:
  /// **'Analyse en cours...'**
  String get analyzing;

  /// No description provided for @analyzeMatch.
  ///
  /// In fr, this message translates to:
  /// **'Analyser la correspondance'**
  String get analyzeMatch;

  /// No description provided for @analyzeAnotherOffer.
  ///
  /// In fr, this message translates to:
  /// **'Analyser une autre offre'**
  String get analyzeAnotherOffer;

  /// No description provided for @matchedKeywords.
  ///
  /// In fr, this message translates to:
  /// **'Mots-cles presents'**
  String get matchedKeywords;

  /// No description provided for @missingKeywords.
  ///
  /// In fr, this message translates to:
  /// **'Mots-cles manquants'**
  String get missingKeywords;

  /// No description provided for @suggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @atsCategoryBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Detail du score ATS'**
  String get atsCategoryBreakdown;

  /// No description provided for @atsActionPlan.
  ///
  /// In fr, this message translates to:
  /// **'Corrections prioritaires'**
  String get atsActionPlan;

  /// No description provided for @atsFormatChecks.
  ///
  /// In fr, this message translates to:
  /// **'Controle format ATS'**
  String get atsFormatChecks;

  /// No description provided for @atsNoFormatRisk.
  ///
  /// In fr, this message translates to:
  /// **'Aucun risque ATS majeur detecte sur le format actuel.'**
  String get atsNoFormatRisk;

  /// No description provided for @atsScoreHistory.
  ///
  /// In fr, this message translates to:
  /// **'Evolution du score'**
  String get atsScoreHistory;

  /// No description provided for @atsCurrentRun.
  ///
  /// In fr, this message translates to:
  /// **'Score actuel'**
  String get atsCurrentRun;

  /// No description provided for @atsRerunLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle analyse'**
  String get atsRerunLabel;

  /// No description provided for @creatingVariant.
  ///
  /// In fr, this message translates to:
  /// **'Creation en cours...'**
  String get creatingVariant;

  /// No description provided for @createAdaptedVariant.
  ///
  /// In fr, this message translates to:
  /// **'Creer une variante adaptee'**
  String get createAdaptedVariant;

  /// No description provided for @createOptimizedVariant.
  ///
  /// In fr, this message translates to:
  /// **'Creer une variante optimisee'**
  String get createOptimizedVariant;

  /// No description provided for @variantCreated.
  ///
  /// In fr, this message translates to:
  /// **'Variante \"{label}\" creee'**
  String variantCreated(String label);

  /// No description provided for @variantCreationError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la creation de la variante'**
  String get variantCreationError;

  /// No description provided for @errorWithDetails.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String errorWithDetails(String error);

  /// No description provided for @goodMatch.
  ///
  /// In fr, this message translates to:
  /// **'Bon match'**
  String get goodMatch;

  /// No description provided for @averageMatch.
  ///
  /// In fr, this message translates to:
  /// **'Match moyen'**
  String get averageMatch;

  /// No description provided for @lowMatch.
  ///
  /// In fr, this message translates to:
  /// **'Faible match'**
  String get lowMatch;

  /// No description provided for @jobMatchScore.
  ///
  /// In fr, this message translates to:
  /// **'Score de correspondance avec l\'offre'**
  String get jobMatchScore;

  /// No description provided for @prepareApplicationMessages.
  ///
  /// In fr, this message translates to:
  /// **'Preparer ma candidature'**
  String get prepareApplicationMessages;

  /// No description provided for @applicationMessagesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Messages de candidature'**
  String get applicationMessagesTitle;

  /// No description provided for @applicationMessagesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Des textes adaptes a votre CV et a cette offre'**
  String get applicationMessagesSubtitle;

  /// No description provided for @chooseTone.
  ///
  /// In fr, this message translates to:
  /// **'Ton'**
  String get chooseTone;

  /// No description provided for @toneSimple.
  ///
  /// In fr, this message translates to:
  /// **'Simple'**
  String get toneSimple;

  /// No description provided for @toneProfessional.
  ///
  /// In fr, this message translates to:
  /// **'Professionnel'**
  String get toneProfessional;

  /// No description provided for @toneDirect.
  ///
  /// In fr, this message translates to:
  /// **'Direct'**
  String get toneDirect;

  /// No description provided for @toneJunior.
  ///
  /// In fr, this message translates to:
  /// **'Junior'**
  String get toneJunior;

  /// No description provided for @toneSenior.
  ///
  /// In fr, this message translates to:
  /// **'Senior'**
  String get toneSenior;

  /// No description provided for @generateApplicationMessages.
  ///
  /// In fr, this message translates to:
  /// **'Generer les 4 textes'**
  String get generateApplicationMessages;

  /// No description provided for @generatingApplicationMessages.
  ///
  /// In fr, this message translates to:
  /// **'Generation en cours...'**
  String get generatingApplicationMessages;

  /// No description provided for @coverLetter.
  ///
  /// In fr, this message translates to:
  /// **'Lettre de motivation'**
  String get coverLetter;

  /// No description provided for @applicationEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email de candidature'**
  String get applicationEmail;

  /// No description provided for @linkedInMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message LinkedIn'**
  String get linkedInMessage;

  /// No description provided for @whatsAppMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message WhatsApp'**
  String get whatsAppMessage;

  /// No description provided for @applicationMessageCopied.
  ///
  /// In fr, this message translates to:
  /// **'Texte copie dans le presse-papier'**
  String get applicationMessageCopied;

  /// No description provided for @applicationMessagesFallback.
  ///
  /// In fr, this message translates to:
  /// **'Mode de secours utilise : verifiez et personnalisez les textes avant envoi.'**
  String get applicationMessagesFallback;

  /// No description provided for @generateWithAi.
  ///
  /// In fr, this message translates to:
  /// **'Generer avec l\'IA'**
  String get generateWithAi;

  /// No description provided for @proofreadingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Correction orthographique'**
  String get proofreadingTitle;

  /// No description provided for @proofreadingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Relisez tout le CV sans modifier le sens ni inventer de contenu.'**
  String get proofreadingSubtitle;

  /// No description provided for @enhancementSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le niveau d\'amelioration souhaite'**
  String get enhancementSubtitle;

  /// No description provided for @liteLevelDescription.
  ///
  /// In fr, this message translates to:
  /// **'Correction orthographe & grammaire uniquement'**
  String get liteLevelDescription;

  /// No description provided for @mediumLevelDescription.
  ///
  /// In fr, this message translates to:
  /// **'Correction et reformulation pour plus d\'impact'**
  String get mediumLevelDescription;

  /// No description provided for @maxLevelDescription.
  ///
  /// In fr, this message translates to:
  /// **'Restructuration complete, mots-cles ATS et verbes d\'action'**
  String get maxLevelDescription;

  /// No description provided for @proofreadingGuarantee.
  ///
  /// In fr, this message translates to:
  /// **'Orthographe, grammaire, accents et termes professionnels. Les niveaux et les faits restent inchanges.'**
  String get proofreadingGuarantee;

  /// No description provided for @proofreadingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Relecture en cours...'**
  String get proofreadingInProgress;

  /// No description provided for @proofreadCv.
  ///
  /// In fr, this message translates to:
  /// **'Relire le CV'**
  String get proofreadCv;

  /// No description provided for @improve.
  ///
  /// In fr, this message translates to:
  /// **'Ameliorer'**
  String get improve;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @aiConsent.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte que le contenu de ce CV soit envoye au service IA pour generer des corrections ou suggestions. Les changements restent a valider avant application.'**
  String get aiConsent;

  /// No description provided for @enhancementGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Amelioration generee'**
  String get enhancementGenerated;

  /// No description provided for @fallbackResult.
  ///
  /// In fr, this message translates to:
  /// **'Resultat degrade (fournisseur de secours utilise)'**
  String get fallbackResult;

  /// No description provided for @aiProofreadingComplete.
  ///
  /// In fr, this message translates to:
  /// **'Relecture IA terminee'**
  String get aiProofreadingComplete;

  /// No description provided for @localProofreadingComplete.
  ///
  /// In fr, this message translates to:
  /// **'Relecture locale terminee'**
  String get localProofreadingComplete;

  /// No description provided for @noCertainCorrection.
  ///
  /// In fr, this message translates to:
  /// **'Aucune correction certaine detectee.'**
  String get noCertainCorrection;

  /// No description provided for @correctedFields.
  ///
  /// In fr, this message translates to:
  /// **'{count} champ(s) corrige(s).'**
  String correctedFields(int count);

  /// No description provided for @textCanBeApplied.
  ///
  /// In fr, this message translates to:
  /// **'Le texte peut etre applique sans changement.'**
  String get textCanBeApplied;

  /// No description provided for @pointsToClarify.
  ///
  /// In fr, this message translates to:
  /// **'Points a preciser'**
  String get pointsToClarify;

  /// No description provided for @before.
  ///
  /// In fr, this message translates to:
  /// **'Avant'**
  String get before;

  /// No description provided for @after.
  ///
  /// In fr, this message translates to:
  /// **'Apres'**
  String get after;

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

  /// No description provided for @spellingCorrectionsApplied.
  ///
  /// In fr, this message translates to:
  /// **'Corrections appliquees'**
  String get spellingCorrectionsApplied;

  /// No description provided for @applicationError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'application'**
  String get applicationError;

  /// No description provided for @proofreadSpelling.
  ///
  /// In fr, this message translates to:
  /// **'Corriger l\'orthographe'**
  String get proofreadSpelling;

  /// No description provided for @adaptedVariantCreated.
  ///
  /// In fr, this message translates to:
  /// **'Variante adaptee creee'**
  String get adaptedVariantCreated;

  /// No description provided for @styleNotSaved.
  ///
  /// In fr, this message translates to:
  /// **'Style non sauvegarde'**
  String get styleNotSaved;

  /// No description provided for @customizeCv.
  ///
  /// In fr, this message translates to:
  /// **'Personnaliser le CV'**
  String get customizeCv;

  /// No description provided for @livePreview.
  ///
  /// In fr, this message translates to:
  /// **'Apercu en direct'**
  String get livePreview;

  /// No description provided for @savingShort.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde...'**
  String get savingShort;

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
  /// **'Téléphone'**
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

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @establishment.
  ///
  /// In fr, this message translates to:
  /// **'Etablissement'**
  String get establishment;

  /// No description provided for @degree.
  ///
  /// In fr, this message translates to:
  /// **'Diplome'**
  String get degree;

  /// No description provided for @fieldOfStudy.
  ///
  /// In fr, this message translates to:
  /// **'Domaine'**
  String get fieldOfStudy;

  /// No description provided for @organization.
  ///
  /// In fr, this message translates to:
  /// **'Organisme'**
  String get organization;

  /// No description provided for @technologies.
  ///
  /// In fr, this message translates to:
  /// **'Technologies'**
  String get technologies;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

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

  /// No description provided for @contactAndProfile.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnees & profil'**
  String get contactAndProfile;

  /// No description provided for @careerPath.
  ///
  /// In fr, this message translates to:
  /// **'Parcours professionnel'**
  String get careerPath;

  /// No description provided for @degreesAndStudies.
  ///
  /// In fr, this message translates to:
  /// **'Diplomes & etudes'**
  String get degreesAndStudies;

  /// No description provided for @skillsAndLanguages.
  ///
  /// In fr, this message translates to:
  /// **'Competences & langues'**
  String get skillsAndLanguages;

  /// No description provided for @extras.
  ///
  /// In fr, this message translates to:
  /// **'Extras'**
  String get extras;

  /// No description provided for @certificationsAndProjects.
  ///
  /// In fr, this message translates to:
  /// **'Certifications & projets'**
  String get certificationsAndProjects;

  /// No description provided for @myCv.
  ///
  /// In fr, this message translates to:
  /// **'Mon CV'**
  String get myCv;

  /// No description provided for @cvDefaultTitle.
  ///
  /// In fr, this message translates to:
  /// **'CV {firstName} {lastName}'**
  String cvDefaultTitle(String firstName, String lastName);

  /// No description provided for @cvCreatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'CV cree avec succes'**
  String get cvCreatedSuccess;

  /// No description provided for @cvUpdatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'CV mis a jour'**
  String get cvUpdatedSuccess;

  /// No description provided for @editCv.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le CV'**
  String get editCv;

  /// No description provided for @previous.
  ///
  /// In fr, this message translates to:
  /// **'Precedent'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @saving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement...'**
  String get saving;

  /// No description provided for @saveCv.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le CV'**
  String get saveCv;

  /// No description provided for @completion.
  ///
  /// In fr, this message translates to:
  /// **'Score ATS : {percent}%'**
  String completion(int percent);

  /// No description provided for @cvCompletion.
  ///
  /// In fr, this message translates to:
  /// **'SCORE ATS DU CV'**
  String get cvCompletion;

  /// No description provided for @toComplete.
  ///
  /// In fr, this message translates to:
  /// **'A completer'**
  String get toComplete;

  /// No description provided for @goodStart.
  ///
  /// In fr, this message translates to:
  /// **'Bon debut !'**
  String get goodStart;

  /// No description provided for @excellent.
  ///
  /// In fr, this message translates to:
  /// **'Excellent !'**
  String get excellent;

  /// No description provided for @addExperience.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une expérience'**
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

  /// No description provided for @editExperience.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'expérience'**
  String get editExperience;

  /// No description provided for @editEducation.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la formation'**
  String get editEducation;

  /// No description provided for @editSkill.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la competence'**
  String get editSkill;

  /// No description provided for @editLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la langue'**
  String get editLanguage;

  /// No description provided for @editCertification.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la certification'**
  String get editCertification;

  /// No description provided for @editProject.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le projet'**
  String get editProject;

  /// No description provided for @aiSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions IA'**
  String get aiSuggestions;

  /// No description provided for @tapSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur une suggestion pour l\'ajouter a la description.'**
  String get tapSuggestion;

  /// No description provided for @jobTitleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Intitulé du poste *'**
  String get jobTitleRequired;

  /// No description provided for @companyRequired.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise *'**
  String get companyRequired;

  /// No description provided for @location.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get location;

  /// No description provided for @startRequired.
  ///
  /// In fr, this message translates to:
  /// **'Debut *'**
  String get startRequired;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Debut'**
  String get start;

  /// No description provided for @end.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get end;

  /// No description provided for @responsibilitiesDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description des responsabilites'**
  String get responsibilitiesDescription;

  /// No description provided for @responsibilitiesHint.
  ///
  /// In fr, this message translates to:
  /// **'Decrivez vos missions principales...'**
  String get responsibilitiesHint;

  /// No description provided for @aiSuggestionsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions IA indisponibles'**
  String get aiSuggestionsUnavailable;

  /// No description provided for @noneExperience.
  ///
  /// In fr, this message translates to:
  /// **'Aucune expérience ajoutée'**
  String get noneExperience;

  /// No description provided for @noneEducation.
  ///
  /// In fr, this message translates to:
  /// **'Aucune formation ajoutee'**
  String get noneEducation;

  /// No description provided for @noneSkill.
  ///
  /// In fr, this message translates to:
  /// **'Aucune competence ajoutee'**
  String get noneSkill;

  /// No description provided for @noneLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Aucune langue ajoutee'**
  String get noneLanguage;

  /// No description provided for @noneCertification.
  ///
  /// In fr, this message translates to:
  /// **'Aucune certification ajoutee'**
  String get noneCertification;

  /// No description provided for @noneProject.
  ///
  /// In fr, this message translates to:
  /// **'Aucun projet ajoute'**
  String get noneProject;

  /// No description provided for @untitled.
  ///
  /// In fr, this message translates to:
  /// **'Sans titre'**
  String get untitled;

  /// No description provided for @currentPosition.
  ///
  /// In fr, this message translates to:
  /// **'En poste'**
  String get currentPosition;

  /// No description provided for @choose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir'**
  String get choose;

  /// No description provided for @currentRole.
  ///
  /// In fr, this message translates to:
  /// **'Poste actuel'**
  String get currentRole;

  /// No description provided for @firstNameExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Issouf'**
  String get firstNameExample;

  /// No description provided for @lastNameExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Ouedraogo'**
  String get lastNameExample;

  /// No description provided for @jobTitleExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Developpeur Full Stack'**
  String get jobTitleExample;

  /// No description provided for @emailExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex : nom@domaine.com'**
  String get emailExample;

  /// No description provided for @phoneExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex : +225 0544210112'**
  String get phoneExample;

  /// No description provided for @addressExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Cocody, Riviera 3'**
  String get addressExample;

  /// No description provided for @postalCodeExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex : 01 BP 1234'**
  String get postalCodeExample;

  /// No description provided for @cityExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Abidjan'**
  String get cityExample;

  /// No description provided for @countryExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Cote d\'Ivoire'**
  String get countryExample;

  /// No description provided for @technologiesExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Flutter, Dart, Firebase'**
  String get technologiesExample;

  /// No description provided for @educationInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Formation en cours'**
  String get educationInProgress;

  /// No description provided for @optionalDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnel)'**
  String get optionalDescription;

  /// No description provided for @skillRequired.
  ///
  /// In fr, this message translates to:
  /// **'Competence *'**
  String get skillRequired;

  /// No description provided for @skillHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : JavaScript, Python, Photoshop...'**
  String get skillHint;

  /// No description provided for @optionalCategory.
  ///
  /// In fr, this message translates to:
  /// **'Categorie (optionnel)'**
  String get optionalCategory;

  /// No description provided for @categoryHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Developpement, Design, Gestion...'**
  String get categoryHint;

  /// No description provided for @level.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get level;

  /// No description provided for @languageRequired.
  ///
  /// In fr, this message translates to:
  /// **'Langue *'**
  String get languageRequired;

  /// No description provided for @languageSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Tapez pour chercher une langue'**
  String get languageSearchHint;

  /// No description provided for @levelRequired.
  ///
  /// In fr, this message translates to:
  /// **'NIVEAU *'**
  String get levelRequired;

  /// No description provided for @native.
  ///
  /// In fr, this message translates to:
  /// **'Natif'**
  String get native;

  /// No description provided for @certificationNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la certification *'**
  String get certificationNameRequired;

  /// No description provided for @issuingOrganization.
  ///
  /// In fr, this message translates to:
  /// **'Organisme emetteur'**
  String get issuingOrganization;

  /// No description provided for @issueDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'obtention'**
  String get issueDate;

  /// No description provided for @expiration.
  ///
  /// In fr, this message translates to:
  /// **'Expiration'**
  String get expiration;

  /// No description provided for @verificationLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien de verification'**
  String get verificationLink;

  /// No description provided for @expired.
  ///
  /// In fr, this message translates to:
  /// **'Expire'**
  String get expired;

  /// No description provided for @projectNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom du projet *'**
  String get projectNameRequired;

  /// No description provided for @technologiesUsed.
  ///
  /// In fr, this message translates to:
  /// **'Technologies utilisees'**
  String get technologiesUsed;

  /// No description provided for @projectLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien du projet'**
  String get projectLink;

  /// No description provided for @projectDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Decrivez le projet et votre role...'**
  String get projectDescriptionHint;

  /// No description provided for @suggestionsGenerationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de generer des suggestions'**
  String get suggestionsGenerationFailed;

  /// No description provided for @profilePhotoOptional.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil (optionnel)'**
  String get profilePhotoOptional;

  /// No description provided for @gallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In fr, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @removePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get removePhoto;

  /// No description provided for @photoLocalOnly.
  ///
  /// In fr, this message translates to:
  /// **'Photo visible localement, mais l\'envoi a echoue : {error}'**
  String photoLocalOnly(String error);

  /// No description provided for @coordinates.
  ///
  /// In fr, this message translates to:
  /// **'COORDONNEES'**
  String get coordinates;

  /// No description provided for @online.
  ///
  /// In fr, this message translates to:
  /// **'EN LIGNE'**
  String get online;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'A PROPOS'**
  String get about;

  /// No description provided for @firstNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Prénom *'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom *'**
  String get lastNameRequired;

  /// No description provided for @firstNameMissing.
  ///
  /// In fr, this message translates to:
  /// **'Prenom requis'**
  String get firstNameMissing;

  /// No description provided for @lastNameMissing.
  ///
  /// In fr, this message translates to:
  /// **'Nom requis'**
  String get lastNameMissing;

  /// No description provided for @targetJobHelper.
  ///
  /// In fr, this message translates to:
  /// **'Le poste que vous visez ou occupez'**
  String get targetJobHelper;

  /// No description provided for @professionalEmailHelper.
  ///
  /// In fr, this message translates to:
  /// **'Votre email professionnel de contact'**
  String get professionalEmailHelper;

  /// No description provided for @emailMissing.
  ///
  /// In fr, this message translates to:
  /// **'Email requis'**
  String get emailMissing;

  /// No description provided for @phoneCountryHelper.
  ///
  /// In fr, this message translates to:
  /// **'Selectionnez un pays pour l\'indicatif automatique'**
  String get phoneCountryHelper;

  /// No description provided for @postalAddressHelper.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel - votre adresse postale'**
  String get postalAddressHelper;

  /// No description provided for @optional.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel'**
  String get optional;

  /// No description provided for @professionalLinksHelper.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel - ajoutez vos liens professionnels'**
  String get professionalLinksHelper;

  /// No description provided for @linkedinHelper.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel - votre profil LinkedIn'**
  String get linkedinHelper;

  /// No description provided for @portfolioHelper.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel - votre site ou portfolio'**
  String get portfolioHelper;

  /// No description provided for @generateSummaryHelper.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur le bouton IA pour generer automatiquement'**
  String get generateSummaryHelper;

  /// No description provided for @summaryGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Resume genere par l\'IA'**
  String get summaryGenerated;

  /// No description provided for @aiPersonalDataConsent.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte d\'envoyer ces informations au service IA.'**
  String get aiPersonalDataConsent;

  /// No description provided for @citySuggestionsForCountry.
  ///
  /// In fr, this message translates to:
  /// **'Tapez pour afficher les villes de {country}'**
  String citySuggestionsForCountry(String country);

  /// No description provided for @selectCountryForCities.
  ///
  /// In fr, this message translates to:
  /// **'Selectionnez un pays pour obtenir des suggestions'**
  String get selectCountryForCities;

  /// No description provided for @freeCityEntry.
  ///
  /// In fr, this message translates to:
  /// **'Saisie libre - ajoutez votre ville'**
  String get freeCityEntry;

  /// No description provided for @countryDialCodeHelper.
  ///
  /// In fr, this message translates to:
  /// **'Selectionnez pour ajouter l\'indicatif telephonique'**
  String get countryDialCodeHelper;

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

  /// No description provided for @intermediate.
  ///
  /// In fr, this message translates to:
  /// **'Intermediaire'**
  String get intermediate;

  /// No description provided for @confirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé'**
  String get confirmed;

  /// No description provided for @elementary.
  ///
  /// In fr, this message translates to:
  /// **'Elementaire'**
  String get elementary;

  /// No description provided for @upperIntermediate.
  ///
  /// In fr, this message translates to:
  /// **'Intermediaire avance'**
  String get upperIntermediate;

  /// No description provided for @fluent.
  ///
  /// In fr, this message translates to:
  /// **'Courant'**
  String get fluent;

  /// No description provided for @mastery.
  ///
  /// In fr, this message translates to:
  /// **'Maitrise'**
  String get mastery;

  /// No description provided for @nativeLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue maternelle'**
  String get nativeLanguage;

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

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'application'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Francais'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get english;

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

  /// No description provided for @privacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialite'**
  String get privacy;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialite'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Donnees, IA, export et suppression'**
  String get privacyPolicySubtitle;

  /// No description provided for @exportMyData.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mes donnees'**
  String get exportMyData;

  /// No description provided for @exportMyDataSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Copie JSON de votre compte et de vos CV'**
  String get exportMyDataSubtitle;

  /// No description provided for @deleteMyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get deleteMyAccount;

  /// No description provided for @deleteMyAccountSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suppression du compte et des CV associes'**
  String get deleteMyAccountSubtitle;

  /// No description provided for @exportCopied.
  ///
  /// In fr, this message translates to:
  /// **'Export copie dans le presse-papier'**
  String get exportCopied;

  /// No description provided for @exportFailed.
  ///
  /// In fr, this message translates to:
  /// **'Export impossible : {error}'**
  String exportFailed(String error);

  /// No description provided for @deleteAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Cette action supprime votre compte et les CV associes cote serveur. Elle est irreversible.'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In fr, this message translates to:
  /// **'Suppression impossible : {error}'**
  String deleteAccountFailed(String error);

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

  /// No description provided for @validationPersonalInfoMissing.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles manquantes'**
  String get validationPersonalInfoMissing;

  /// No description provided for @validationFieldMissing.
  ///
  /// In fr, this message translates to:
  /// **'{field} manquant'**
  String validationFieldMissing(String field);

  /// No description provided for @validationJobTitleMissing.
  ///
  /// In fr, this message translates to:
  /// **'Titre du poste manquant - important pour les recruteurs'**
  String get validationJobTitleMissing;

  /// No description provided for @validationSummaryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Resume professionnel vide - utilisez l\'IA pour le generer'**
  String get validationSummaryEmpty;

  /// No description provided for @validationSummaryShort.
  ///
  /// In fr, this message translates to:
  /// **'Resume trop court ({count} car.) - min 100 recommande'**
  String validationSummaryShort(int count);

  /// No description provided for @validationTechLinkMissing.
  ///
  /// In fr, this message translates to:
  /// **'LinkedIn ou GitHub manquant - tres attendu pour un profil tech'**
  String get validationTechLinkMissing;

  /// No description provided for @validationNoExperience.
  ///
  /// In fr, this message translates to:
  /// **'Aucune experience renseignee'**
  String get validationNoExperience;

  /// No description provided for @validationDescriptionMissing.
  ///
  /// In fr, this message translates to:
  /// **'{item} : description manquante'**
  String validationDescriptionMissing(String item);

  /// No description provided for @validationNoMetric.
  ///
  /// In fr, this message translates to:
  /// **'{item} : aucun chiffre ou indicateur - ajoutez des resultats mesurables'**
  String validationNoMetric(String item);

  /// No description provided for @validationEndBeforeStart.
  ///
  /// In fr, this message translates to:
  /// **'{item} : date de fin avant date de debut'**
  String validationEndBeforeStart(String item);

  /// No description provided for @validationFutureEnd.
  ///
  /// In fr, this message translates to:
  /// **'{item} : date de fin dans le futur'**
  String validationFutureEnd(String item);

  /// No description provided for @validationNoEducation.
  ///
  /// In fr, this message translates to:
  /// **'Aucune formation renseignee'**
  String get validationNoEducation;

  /// No description provided for @validationNoSkills.
  ///
  /// In fr, this message translates to:
  /// **'Aucune competence renseignee'**
  String get validationNoSkills;

  /// No description provided for @validationFewSkills.
  ///
  /// In fr, this message translates to:
  /// **'Seulement {count} competences - 8 a 12 recommande'**
  String validationFewSkills(int count);

  /// No description provided for @validationCombinedSkills.
  ///
  /// In fr, this message translates to:
  /// **'\"{name}\" semble contenir plusieurs competences - separez-les'**
  String validationCombinedSkills(String name);

  /// No description provided for @validationNoLanguages.
  ///
  /// In fr, this message translates to:
  /// **'Aucune langue renseignee'**
  String get validationNoLanguages;

  /// No description provided for @validationFutureCertification.
  ///
  /// In fr, this message translates to:
  /// **'\"{name}\" datee dans le futur - marquez En cours si necessaire'**
  String validationFutureCertification(String name);

  /// No description provided for @validationShortProject.
  ///
  /// In fr, this message translates to:
  /// **'\"{name}\" : description trop courte - developpez'**
  String validationShortProject(String name);

  /// No description provided for @validationTooMuchContent.
  ///
  /// In fr, this message translates to:
  /// **'Beaucoup de contenu ({count} elements) - risque de depasser 1 page'**
  String validationTooMuchContent(int count);

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorGeneric;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @staleCvReminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel de mise a jour'**
  String get staleCvReminder;

  /// No description provided for @staleCvReminderSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Me prevenir apres 30 jours sans modification'**
  String get staleCvReminderSubtitle;

  /// No description provided for @cvViewNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Vues du CV partage'**
  String get cvViewNotifications;

  /// No description provided for @cvViewNotificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Me prevenir tous les 10 nouveaux visiteurs'**
  String get cvViewNotificationsSubtitle;

  /// No description provided for @aiTipNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Conseils d\'amelioration IA'**
  String get aiTipNotifications;

  /// No description provided for @aiTipNotificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir des pistes pour renforcer mon CV'**
  String get aiTipNotificationsSubtitle;

  /// No description provided for @applications.
  ///
  /// In fr, this message translates to:
  /// **'Candidatures'**
  String get applications;

  /// No description provided for @addApplication.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une candidature'**
  String get addApplication;

  /// No description provided for @editApplication.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la candidature'**
  String get editApplication;

  /// No description provided for @deleteApplication.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la candidature'**
  String get deleteApplication;

  /// No description provided for @deleteApplicationConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la candidature chez {company} ?'**
  String deleteApplicationConfirm(String company);

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get all;

  /// No description provided for @noApplications.
  ///
  /// In fr, this message translates to:
  /// **'Aucune candidature'**
  String get noApplications;

  /// No description provided for @noApplicationsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos candidatures pour suivre les relances et les prochaines actions.'**
  String get noApplicationsDescription;

  /// No description provided for @followUpsDue.
  ///
  /// In fr, this message translates to:
  /// **'{count} relance(s) a effectuer aujourd\'hui'**
  String followUpsDue(int count);

  /// No description provided for @nextFollowUp.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine relance'**
  String get nextFollowUp;

  /// No description provided for @variant.
  ///
  /// In fr, this message translates to:
  /// **'Variante'**
  String get variant;

  /// No description provided for @openOffer.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir l\'offre'**
  String get openOffer;

  /// No description provided for @company.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise'**
  String get company;

  /// No description provided for @position.
  ///
  /// In fr, this message translates to:
  /// **'Poste'**
  String get position;

  /// No description provided for @status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// No description provided for @linkedCv.
  ///
  /// In fr, this message translates to:
  /// **'CV utilise'**
  String get linkedCv;

  /// No description provided for @noLinkedCv.
  ///
  /// In fr, this message translates to:
  /// **'Aucun CV lie'**
  String get noLinkedCv;

  /// No description provided for @offerLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien de l\'offre'**
  String get offerLink;

  /// No description provided for @sentDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'envoi'**
  String get sentDate;

  /// No description provided for @notes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @requiredField.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire'**
  String get requiredField;

  /// No description provided for @applicationDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get applicationDraft;

  /// No description provided for @applicationSent.
  ///
  /// In fr, this message translates to:
  /// **'Envoyee'**
  String get applicationSent;

  /// No description provided for @applicationInterview.
  ///
  /// In fr, this message translates to:
  /// **'Entretien'**
  String get applicationInterview;

  /// No description provided for @applicationTechnicalTest.
  ///
  /// In fr, this message translates to:
  /// **'Test technique'**
  String get applicationTechnicalTest;

  /// No description provided for @applicationOffer.
  ///
  /// In fr, this message translates to:
  /// **'Offre recue'**
  String get applicationOffer;

  /// No description provided for @applicationRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusee'**
  String get applicationRejected;

  /// No description provided for @applicationArchived.
  ///
  /// In fr, this message translates to:
  /// **'Archivee'**
  String get applicationArchived;

  /// No description provided for @downloadQrCode.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le QR code'**
  String get downloadQrCode;

  /// No description provided for @portfolioQrCode.
  ///
  /// In fr, this message translates to:
  /// **'QR code du portfolio'**
  String get portfolioQrCode;

  /// No description provided for @showQrCode.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le QR code'**
  String get showQrCode;

  /// No description provided for @shareViaWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'Partager par WhatsApp'**
  String get shareViaWhatsApp;

  /// No description provided for @contact.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @contactCandidate.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le candidat'**
  String get contactCandidate;

  /// No description provided for @publicPortfolioUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Ce portfolio est indisponible ou son propriétaire l\'a désactivé.'**
  String get publicPortfolioUnavailable;

  /// No description provided for @publicRecruiterPortfolio.
  ///
  /// In fr, this message translates to:
  /// **'Portfolio public recruteur'**
  String get publicRecruiterPortfolio;

  /// No description provided for @publicLinkActivationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'activer le lien public.'**
  String get publicLinkActivationFailed;

  /// No description provided for @deactivate.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get deactivate;

  /// No description provided for @publicPortfolioDescription.
  ///
  /// In fr, this message translates to:
  /// **'Ce lien ouvre une présentation professionnelle de votre CV sans connexion.'**
  String get publicPortfolioDescription;

  /// No description provided for @regeneratePublicLink.
  ///
  /// In fr, this message translates to:
  /// **'Régénérer le lien'**
  String get regeneratePublicLink;

  /// No description provided for @allowPublicContact.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser le contact'**
  String get allowPublicContact;

  /// No description provided for @allowPublicContactDescription.
  ///
  /// In fr, this message translates to:
  /// **'Affiche l\'e-mail et le bouton de contact.'**
  String get allowPublicContactDescription;

  /// No description provided for @allowPublicDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser PDF et DOCX'**
  String get allowPublicDownloads;

  /// No description provided for @allowPublicDownloadsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Les fichiers contiennent les coordonnées autorisées du CV.'**
  String get allowPublicDownloadsDescription;

  /// No description provided for @privacyControlTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos données restent sous votre contrôle'**
  String get privacyControlTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In fr, this message translates to:
  /// **'MonCV stocke les informations nécessaires à la création, l\'édition, l\'export et le partage de vos CV.'**
  String get privacyIntro;

  /// No description provided for @privacyStoredDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'Données stockées'**
  String get privacyStoredDataTitle;

  /// No description provided for @privacyStoredAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte : email, nom et prénom.'**
  String get privacyStoredAccount;

  /// No description provided for @privacyStoredCv.
  ///
  /// In fr, this message translates to:
  /// **'CV : identité, contacts, expériences, formations, compétences, langues, certifications, projets, style et liens de partage.'**
  String get privacyStoredCv;

  /// No description provided for @privacyStoredFiles.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers : photos importées et documents générés localement selon les actions demandées.'**
  String get privacyStoredFiles;

  /// No description provided for @privacyAiTitle.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation de l\'IA'**
  String get privacyAiTitle;

  /// No description provided for @privacyAiConsent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contenu de CV n\'est envoyé à l\'IA sans consentement explicite dans l\'écran concerné.'**
  String get privacyAiConsent;

  /// No description provided for @privacyAiReview.
  ///
  /// In fr, this message translates to:
  /// **'Les résultats IA sont affichés avant application et peuvent être refusés.'**
  String get privacyAiReview;

  /// No description provided for @privacyAiFallback.
  ///
  /// In fr, this message translates to:
  /// **'En absence de clé IA, l\'application utilise des corrections locales limitées quand elles existent.'**
  String get privacyAiFallback;

  /// No description provided for @privacyRightsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos droits'**
  String get privacyRightsTitle;

  /// No description provided for @privacyRightsExport.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez exporter vos données depuis le profil.'**
  String get privacyRightsExport;

  /// No description provided for @privacyRightsDelete.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez supprimer votre compte depuis le profil.'**
  String get privacyRightsDelete;

  /// No description provided for @privacyRightsCascade.
  ///
  /// In fr, this message translates to:
  /// **'La suppression du compte supprime aussi les CV rattachés côté backend.'**
  String get privacyRightsCascade;

  /// No description provided for @privacyPwaTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité PWA'**
  String get privacyPwaTitle;

  /// No description provided for @privacyPwaHttps.
  ///
  /// In fr, this message translates to:
  /// **'En production, l\'application doit utiliser HTTPS et une API HTTPS.'**
  String get privacyPwaHttps;

  /// No description provided for @privacyPwaStorage.
  ///
  /// In fr, this message translates to:
  /// **'Le stockage web des tokens repose sur le stockage local du navigateur : utilisez un appareil de confiance.'**
  String get privacyPwaStorage;

  /// No description provided for @privacyPwaEnterprise.
  ///
  /// In fr, this message translates to:
  /// **'La cible recommandée pour une version entreprise est une session serveur avec cookies HttpOnly/SameSite.'**
  String get privacyPwaEnterprise;

  /// No description provided for @googleAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte Google'**
  String get googleAccount;

  /// No description provided for @googleLinkSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Compte Google associé avec succès'**
  String get googleLinkSuccess;

  /// No description provided for @googleLinkFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'associer le compte Google'**
  String get googleLinkFailed;

  /// No description provided for @googleSignInFailed.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google impossible'**
  String get googleSignInFailed;

  /// No description provided for @countryDialCodeAdded.
  ///
  /// In fr, this message translates to:
  /// **'Indicatif {code} ajouté selon le pays'**
  String countryDialCodeAdded(String code);

  /// No description provided for @educationCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0 {Aucune formation} =1 {1 formation} other {{count} formations}}'**
  String educationCount(int count);

  /// No description provided for @experienceCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0 {Aucune expérience} =1 {1 expérience} other {{count} expériences}}'**
  String experienceCount(int count);

  /// No description provided for @skillCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0 {Aucune compétence} =1 {1 compétence} other {{count} compétences}}'**
  String skillCount(int count);

  /// No description provided for @languageCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0 {Aucune langue} =1 {1 langue} other {{count} langues}}'**
  String languageCount(int count);

  /// No description provided for @modifiedOn.
  ///
  /// In fr, this message translates to:
  /// **'Modifié le {date}'**
  String modifiedOn(String date);
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
