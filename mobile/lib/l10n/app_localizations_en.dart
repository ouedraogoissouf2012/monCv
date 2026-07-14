// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MonCV';

  @override
  String get login => 'Log in';

  @override
  String get register => 'Create account';

  @override
  String get email => 'Email address';

  @override
  String get emailShort => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get hasAccount => 'Already have an account?';

  @override
  String get welcomeBack => 'Welcome\nback.';

  @override
  String get welcomeSubtitle => 'Log in to continue on MonCV';

  @override
  String get createAccount => 'Create your\naccount.';

  @override
  String get createAccountSubtitle => 'Join MonCV for free';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get fieldRequired => 'Required field';

  @override
  String requiredFieldMessage(String section, String field) {
    return '$section: $field is required.';
  }

  @override
  String get completePersonalInfo =>
      'Identity: complete your personal information.';

  @override
  String get invalidEmailMessage => 'Identity: invalid email format.';

  @override
  String numberedItem(String section, int index) {
    return '$section $index';
  }

  @override
  String endDateBeforeStart(String item) {
    return '$item: the end date must be after the start date.';
  }

  @override
  String skillLevelRange(String item) {
    return '$item: the level must be between 1 and 5.';
  }

  @override
  String certificationExpirationBeforeIssue(String item) {
    return '$item: expiration is before the issue date.';
  }

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordMinLength => 'Minimum 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthMedium => 'Fair';

  @override
  String get passwordStrengthGood => 'Good';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get loginError => 'Login error';

  @override
  String get registerError => 'Registration error';

  @override
  String get createMyAccount => 'Create my account';

  @override
  String get landingHeroTitle => 'Create a CV\nthat speaks to recruiters';

  @override
  String get landingHeroTitleMobile =>
      'Create a CV\nthat speaks to\nrecruiters';

  @override
  String get landingHeroSubtitle =>
      'Professional language, ATS formats, WhatsApp sharing and PDF/DOCX export for local or international applications.';

  @override
  String get createCvFree => 'Create my CV for free';

  @override
  String get bilingual => 'Bilingual';

  @override
  String get templates => 'Templates';

  @override
  String get compatible => 'Compatible';

  @override
  String get aiFeatureTitle => 'Artificial Intelligence';

  @override
  String get aiFeatureDescription =>
      'Natural, precise language without artificial wording.';

  @override
  String get templatesFeatureTitle => 'Targeted templates';

  @override
  String get templatesFeatureDescription =>
      'Corporate, junior, senior, tech and international ATS.';

  @override
  String get atsFeatureTitle => 'ATS score';

  @override
  String get atsFeatureDescription =>
      'Paste a job posting and get a match score.';

  @override
  String get docxFeatureTitle => 'DOCX export';

  @override
  String get docxFeatureDescription =>
      'Download as Word for maximum ATS compatibility.';

  @override
  String get mobileFeatureTitle => 'Mobile-first Africa';

  @override
  String get mobileFeatureDescription =>
      'Designed to create, improve, export and share from a phone.';

  @override
  String get whatsAppFeatureTitle => 'WhatsApp sharing';

  @override
  String get whatsAppFeatureDescription =>
      'Send a clean link to a recruiter or HR contact.';

  @override
  String get allYouNeed => 'Everything you need';

  @override
  String get allYouNeedSubtitle =>
      'A complete tool for creating CVs that stand out.';

  @override
  String get clearCvTitle => 'A clear CV for every application';

  @override
  String get clearCvSubtitle =>
      'A readable result for recruiters, businesses, agencies and ATS';

  @override
  String get sampleProfile => 'PROFILE';

  @override
  String get sampleProfileText =>
      'Full Stack Engineer with 3 years of experience. Java/Spring Boot and Flutter expert.';

  @override
  String get sampleSkills => 'SKILLS';

  @override
  String get sampleExperiences => 'EXPERIENCE';

  @override
  String get howItWorks => 'How it works';

  @override
  String get fillIn => 'Fill it in';

  @override
  String get fillInDescription =>
      'Short tips guide your title, summary and experience.';

  @override
  String get adapt => 'Adapt';

  @override
  String get adaptDescription =>
      'Improve the wording and choose a template for the role.';

  @override
  String get send => 'Share';

  @override
  String get sendDescription =>
      'Export as PDF/DOCX or send the link through WhatsApp.';

  @override
  String get readyToApply => 'Ready to apply with a polished CV?';

  @override
  String get readyToApplySubtitle =>
      'Mobile, fast, readable and designed for francophone markets.';

  @override
  String get startNow => 'Start now';

  @override
  String get landingFooter => '© 2026 MonCV. Mobile-first, ATS-compatible CVs.';

  @override
  String get sampleCandidateName => 'ALEX SMITH';

  @override
  String get sampleCandidateRole => 'Full Stack Software Engineer';

  @override
  String get sampleCandidateContact =>
      'alex@example.com | +44 7700 900000 | London';

  @override
  String get sampleCandidatePosition => 'Lead Developer';

  @override
  String get sampleCandidateCompany => 'DIGITAL COMPANY - London';

  @override
  String get lite => 'Lite';

  @override
  String get medium => 'Medium';

  @override
  String get maximum => 'Max';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get myCvs => 'My CVs';

  @override
  String get newCv => 'New CV';

  @override
  String get noCvYet => 'No CV yet';

  @override
  String get createFirstCv => 'Create your first professional CV';

  @override
  String get createMyFirstCv => 'Create my first CV';

  @override
  String get importCv => 'Import CV (PDF/DOCX)';

  @override
  String get deleteCvTitle => 'Delete CV';

  @override
  String deleteCvConfirm(String titre) {
    return 'Are you sure you want to delete \"$titre\"?';
  }

  @override
  String get cvDeleted => 'CV deleted';

  @override
  String get cvDuplicated => 'CV duplicated';

  @override
  String get shareLinkTitle => 'Share link';

  @override
  String get shareLinkDescription =>
      'Share this link for anyone to view your CV:';

  @override
  String get linkCopied => 'Link copied to clipboard';

  @override
  String get copy => 'Copy';

  @override
  String get close => 'Close';

  @override
  String get pdfDownloading => 'Generating PDF...';

  @override
  String get pdfDownloaded => 'PDF downloaded';

  @override
  String pdfError(String error) {
    return 'PDF error: $error';
  }

  @override
  String get docxDownloading => 'Downloading DOCX...';

  @override
  String get docxDownloaded => 'DOCX downloaded';

  @override
  String docxError(String error) {
    return 'DOCX error: $error';
  }

  @override
  String get importInProgress => 'Importing CV...';

  @override
  String importSuccess(String titre) {
    return 'CV \"$titre\" imported successfully';
  }

  @override
  String importError(String error) {
    return 'Import error: $error';
  }

  @override
  String get offlineBanner => 'Offline mode — cached data';

  @override
  String get view => 'View';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Log out';

  @override
  String get logoutTitle => 'Log out';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get disconnect => 'Log out';

  @override
  String get user => 'User';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get update => 'Update';

  @override
  String get delete => 'Delete';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get share => 'Share';

  @override
  String get edit => 'Edit';

  @override
  String get download => 'Download';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get downloadDocx => 'Download DOCX';

  @override
  String get customize => 'Customize';

  @override
  String get preview => 'Preview';

  @override
  String get options => 'Options';

  @override
  String get retry => 'Retry';

  @override
  String get enhanceWithAi => 'Enhance with AI';

  @override
  String get adaptToJob => 'Adapt to job';

  @override
  String get adaptToJobDescription =>
      'Paste a job posting to analyze the match';

  @override
  String get jobOfferHint => 'Paste the job posting here...';

  @override
  String get jobOfferTooShort =>
      'Paste the full job posting (at least 20 characters)';

  @override
  String get jobMatchConsent =>
      'I agree that my CV and the job posting may be sent to the AI service to calculate the match.';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get analyzeMatch => 'Analyze match';

  @override
  String get analyzeAnotherOffer => 'Analyze another job';

  @override
  String get matchedKeywords => 'Matched keywords';

  @override
  String get missingKeywords => 'Missing keywords';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get atsCategoryBreakdown => 'ATS score breakdown';

  @override
  String get atsActionPlan => 'Priority fixes';

  @override
  String get atsFormatChecks => 'ATS format checks';

  @override
  String get atsNoFormatRisk =>
      'No major ATS format risk detected for the current CV.';

  @override
  String get atsScoreHistory => 'Score history';

  @override
  String get atsCurrentRun => 'Current score';

  @override
  String get atsRerunLabel => 'New analysis';

  @override
  String get creatingVariant => 'Creating...';

  @override
  String get createAdaptedVariant => 'Create an adapted variant';

  @override
  String get createOptimizedVariant => 'Create an optimized variant';

  @override
  String variantCreated(String label) {
    return 'Variant \"$label\" created';
  }

  @override
  String get variantCreationError => 'Could not create the variant';

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get goodMatch => 'Good match';

  @override
  String get averageMatch => 'Average match';

  @override
  String get lowMatch => 'Low match';

  @override
  String get jobMatchScore => 'Match score with the job posting';

  @override
  String get prepareApplicationMessages => 'Prepare my application';

  @override
  String get applicationMessagesTitle => 'Application messages';

  @override
  String get applicationMessagesSubtitle =>
      'Texts tailored to your CV and this job posting';

  @override
  String get chooseTone => 'Tone';

  @override
  String get toneSimple => 'Simple';

  @override
  String get toneProfessional => 'Professional';

  @override
  String get toneDirect => 'Direct';

  @override
  String get toneJunior => 'Junior';

  @override
  String get toneSenior => 'Senior';

  @override
  String get generateApplicationMessages => 'Generate all 4 texts';

  @override
  String get generatingApplicationMessages => 'Generating...';

  @override
  String get coverLetter => 'Cover letter';

  @override
  String get applicationEmail => 'Application email';

  @override
  String get linkedInMessage => 'LinkedIn message';

  @override
  String get whatsAppMessage => 'WhatsApp message';

  @override
  String get applicationMessageCopied => 'Text copied to clipboard';

  @override
  String get applicationMessagesFallback =>
      'Fallback mode was used. Review and personalize the texts before sending.';

  @override
  String get generateWithAi => 'Generate with AI';

  @override
  String get proofreadingTitle => 'Spelling and grammar correction';

  @override
  String get proofreadingSubtitle =>
      'Proofread the entire CV without changing its meaning or inventing content.';

  @override
  String get enhancementSubtitle => 'Choose the desired enhancement level';

  @override
  String get liteLevelDescription => 'Spelling and grammar correction only';

  @override
  String get mediumLevelDescription =>
      'Correction and rewriting for greater impact';

  @override
  String get maxLevelDescription =>
      'Full restructuring, ATS keywords and action verbs';

  @override
  String get proofreadingGuarantee =>
      'Spelling, grammar, accents and professional terms. Levels and facts remain unchanged.';

  @override
  String get proofreadingInProgress => 'Proofreading...';

  @override
  String get proofreadCv => 'Proofread CV';

  @override
  String get improve => 'Improve';

  @override
  String get apply => 'Apply';

  @override
  String get aiConsent =>
      'I agree that this CV may be sent to the AI service to generate corrections or suggestions. Changes remain subject to my approval before application.';

  @override
  String get enhancementGenerated => 'Enhancement generated';

  @override
  String get fallbackResult => 'Degraded result (fallback provider used)';

  @override
  String get aiProofreadingComplete => 'AI proofreading complete';

  @override
  String get localProofreadingComplete => 'Local proofreading complete';

  @override
  String get noCertainCorrection => 'No certain correction detected.';

  @override
  String correctedFields(int count) {
    return '$count field(s) corrected.';
  }

  @override
  String get textCanBeApplied => 'The text can be applied without changes.';

  @override
  String get pointsToClarify => 'Points to clarify';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String get generating => 'Generating...';

  @override
  String get aiSuggestionsApplied => 'AI suggestions applied';

  @override
  String get spellingCorrectionsApplied => 'Corrections applied';

  @override
  String get applicationError => 'Could not apply changes';

  @override
  String get proofreadSpelling => 'Correct spelling';

  @override
  String get adaptedVariantCreated => 'Adapted variant created';

  @override
  String get styleNotSaved => 'Style not saved';

  @override
  String get customizeCv => 'Customize CV';

  @override
  String get livePreview => 'Live preview';

  @override
  String get savingShort => 'Saving...';

  @override
  String get template => 'Template';

  @override
  String get color => 'Color';

  @override
  String get font => 'Font';

  @override
  String get identity => 'Identity';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get jobTitle => 'Job title';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get postalCode => 'Postal code';

  @override
  String get country => 'Country';

  @override
  String get linkedin => 'LinkedIn';

  @override
  String get portfolio => 'Portfolio / Website';

  @override
  String get professionalSummary => 'Professional summary';

  @override
  String get description => 'Description';

  @override
  String get establishment => 'Institution';

  @override
  String get degree => 'Degree';

  @override
  String get fieldOfStudy => 'Field of study';

  @override
  String get organization => 'Organization';

  @override
  String get technologies => 'Technologies';

  @override
  String get name => 'Name';

  @override
  String get experiences => 'Work experience';

  @override
  String get education => 'Education';

  @override
  String get skills => 'Skills';

  @override
  String get languages => 'Languages';

  @override
  String get certifications => 'Certifications';

  @override
  String get projects => 'Projects';

  @override
  String get contactAndProfile => 'Contact details & profile';

  @override
  String get careerPath => 'Career history';

  @override
  String get degreesAndStudies => 'Degrees & studies';

  @override
  String get skillsAndLanguages => 'Skills & languages';

  @override
  String get extras => 'Extras';

  @override
  String get certificationsAndProjects => 'Certifications & projects';

  @override
  String get myCv => 'My CV';

  @override
  String cvDefaultTitle(String firstName, String lastName) {
    return '$firstName $lastName CV';
  }

  @override
  String get cvCreatedSuccess => 'CV created successfully';

  @override
  String get cvUpdatedSuccess => 'CV updated';

  @override
  String get editCv => 'Edit CV';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get saving => 'Saving...';

  @override
  String get saveCv => 'Save CV';

  @override
  String completion(int percent) {
    return 'Completion: $percent%';
  }

  @override
  String get cvCompletion => 'CV COMPLETION';

  @override
  String get toComplete => 'To complete';

  @override
  String get goodStart => 'Good start!';

  @override
  String get excellent => 'Excellent!';

  @override
  String get addExperience => 'Add experience';

  @override
  String get addEducation => 'Add education';

  @override
  String get addSkill => 'Add skill';

  @override
  String get addLanguage => 'Add language';

  @override
  String get addCertification => 'Add certification';

  @override
  String get addProject => 'Add project';

  @override
  String get editExperience => 'Edit experience';

  @override
  String get editEducation => 'Edit education';

  @override
  String get editSkill => 'Edit skill';

  @override
  String get editLanguage => 'Edit language';

  @override
  String get editCertification => 'Edit certification';

  @override
  String get editProject => 'Edit project';

  @override
  String get aiSuggestions => 'AI suggestions';

  @override
  String get tapSuggestion => 'Tap a suggestion to add it to the description.';

  @override
  String get jobTitleRequired => 'Job title *';

  @override
  String get companyRequired => 'Company *';

  @override
  String get location => 'Location';

  @override
  String get startRequired => 'Start *';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get responsibilitiesDescription => 'Responsibilities description';

  @override
  String get responsibilitiesHint => 'Describe your main responsibilities...';

  @override
  String get aiSuggestionsUnavailable => 'AI suggestions unavailable';

  @override
  String get noneExperience => 'No experience added';

  @override
  String get noneEducation => 'No education added';

  @override
  String get noneSkill => 'No skill added';

  @override
  String get noneLanguage => 'No language added';

  @override
  String get noneCertification => 'No certification added';

  @override
  String get noneProject => 'No project added';

  @override
  String get untitled => 'Untitled';

  @override
  String get currentPosition => 'Current position';

  @override
  String get choose => 'Choose';

  @override
  String get currentRole => 'Current role';

  @override
  String get firstNameExample => 'E.g. Alex';

  @override
  String get lastNameExample => 'E.g. Smith';

  @override
  String get jobTitleExample => 'E.g. Full Stack Developer';

  @override
  String get emailExample => 'E.g. name@example.com';

  @override
  String get phoneExample => 'E.g. +44 7700 900000';

  @override
  String get addressExample => 'E.g. 10 High Street';

  @override
  String get postalCodeExample => 'E.g. SW1A 1AA';

  @override
  String get cityExample => 'E.g. London';

  @override
  String get countryExample => 'E.g. United Kingdom';

  @override
  String get technologiesExample => 'E.g. Flutter, Dart, Firebase';

  @override
  String get educationInProgress => 'Education in progress';

  @override
  String get optionalDescription => 'Description (optional)';

  @override
  String get skillRequired => 'Skill *';

  @override
  String get skillHint => 'E.g. JavaScript, Python, Photoshop...';

  @override
  String get optionalCategory => 'Category (optional)';

  @override
  String get categoryHint => 'E.g. Development, Design, Management...';

  @override
  String get level => 'Level';

  @override
  String get languageRequired => 'Language *';

  @override
  String get languageSearchHint => 'Type to search for a language';

  @override
  String get levelRequired => 'LEVEL *';

  @override
  String get native => 'Native';

  @override
  String get certificationNameRequired => 'Certification name *';

  @override
  String get issuingOrganization => 'Issuing organization';

  @override
  String get issueDate => 'Issue date';

  @override
  String get expiration => 'Expiration';

  @override
  String get verificationLink => 'Verification link';

  @override
  String get expired => 'Expired';

  @override
  String get projectNameRequired => 'Project name *';

  @override
  String get technologiesUsed => 'Technologies used';

  @override
  String get projectLink => 'Project link';

  @override
  String get projectDescriptionHint => 'Describe the project and your role...';

  @override
  String get suggestionsGenerationFailed => 'Could not generate suggestions';

  @override
  String get profilePhotoOptional => 'Profile photo (optional)';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String photoLocalOnly(String error) {
    return 'Photo is visible locally, but upload failed: $error';
  }

  @override
  String get coordinates => 'CONTACT DETAILS';

  @override
  String get online => 'ONLINE';

  @override
  String get about => 'ABOUT';

  @override
  String get firstNameRequired => 'First name *';

  @override
  String get lastNameRequired => 'Last name *';

  @override
  String get firstNameMissing => 'First name required';

  @override
  String get lastNameMissing => 'Last name required';

  @override
  String get targetJobHelper => 'The role you hold or are targeting';

  @override
  String get professionalEmailHelper => 'Your professional contact email';

  @override
  String get emailMissing => 'Email required';

  @override
  String get phoneCountryHelper =>
      'Select a country for the automatic dial code';

  @override
  String get postalAddressHelper => 'Optional - your postal address';

  @override
  String get optional => 'Optional';

  @override
  String get professionalLinksHelper =>
      'Optional - add your professional links';

  @override
  String get linkedinHelper => 'Optional - your LinkedIn profile';

  @override
  String get portfolioHelper => 'Optional - your website or portfolio';

  @override
  String get generateSummaryHelper =>
      'Use the AI button to generate it automatically';

  @override
  String get summaryGenerated => 'Summary generated by AI';

  @override
  String get aiPersonalDataConsent =>
      'I agree to send this information to the AI service.';

  @override
  String citySuggestionsForCountry(String country) {
    return 'Type to show cities in $country';
  }

  @override
  String get selectCountryForCities => 'Select a country to get suggestions';

  @override
  String get freeCityEntry => 'Free entry - add your city';

  @override
  String get countryDialCodeHelper => 'Select to add the phone dial code';

  @override
  String get required => 'Required';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get resumeTooShort => 'Summary too short — use AI to improve it';

  @override
  String get goodResume => 'Good summary';

  @override
  String get characters => 'characters';

  @override
  String get beginner => 'Beginner';

  @override
  String get basic => 'Basic';

  @override
  String get good => 'Good';

  @override
  String get advanced => 'Advanced';

  @override
  String get expert => 'Expert';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get confirmed => 'Proficient';

  @override
  String get elementary => 'Elementary';

  @override
  String get upperIntermediate => 'Upper intermediate';

  @override
  String get fluent => 'Fluent';

  @override
  String get mastery => 'Mastery';

  @override
  String get nativeLanguage => 'Native language';

  @override
  String get featureAi => 'AI Suggestions';

  @override
  String get featurePdf => 'PDF Export';

  @override
  String get featureShare => 'Public sharing';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'App language';

  @override
  String get french => 'French';

  @override
  String get english => 'English';

  @override
  String get information => 'Information';

  @override
  String get fullName => 'Full name';

  @override
  String get cvsCreated => 'CVs created';

  @override
  String get downloads => 'Downloads';

  @override
  String get shares => 'Shares';

  @override
  String get views => 'Views';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get privacyPolicySubtitle => 'Data, AI, export and deletion';

  @override
  String get exportMyData => 'Export my data';

  @override
  String get exportMyDataSubtitle => 'JSON copy of your account and CVs';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get deleteMyAccountSubtitle => 'Delete the account and associated CVs';

  @override
  String get exportCopied => 'Export copied to clipboard';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'This action deletes your account and associated CVs from the server. It cannot be undone.';

  @override
  String deleteAccountFailed(String error) {
    return 'Deletion failed: $error';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get complete => 'Complete';

  @override
  String get inProgress => 'In progress';

  @override
  String get incomplete => 'Incomplete';

  @override
  String get pdf => 'PDF';

  @override
  String get docx => 'DOCX';

  @override
  String nVariants(int count) {
    return '$count variant(s)';
  }

  @override
  String get errorInvalidCredentials =>
      'Invalid credentials. Check your email and password.';

  @override
  String get errorEmailAlreadyUsed =>
      'This email is already in use. Try logging in.';

  @override
  String get errorNetworkUnavailable =>
      'Cannot reach the server. Check your internet connection.';

  @override
  String get errorTimeout =>
      'The server is taking too long. Try again shortly.';

  @override
  String get errorServer => 'A server error occurred. Try again shortly.';

  @override
  String get errorForbidden => 'Access denied. Log in again and retry.';

  @override
  String get errorRateLimit =>
      'Too many attempts. Wait a minute before trying again.';

  @override
  String get errorNotFound => 'This CV no longer exists or has been deleted.';

  @override
  String get errorDownload => 'Download failed. Try again shortly.';

  @override
  String get errorAiUnavailable =>
      'AI service is temporarily unavailable. Try again later.';

  @override
  String get errorFileUpload =>
      'File upload failed. Check the format and size.';

  @override
  String get validationPersonalInfoMissing => 'Personal information is missing';

  @override
  String validationFieldMissing(String field) {
    return 'Missing $field';
  }

  @override
  String get validationJobTitleMissing =>
      'Job title is missing - important for recruiters';

  @override
  String get validationSummaryEmpty =>
      'Professional summary is empty - use AI to generate it';

  @override
  String validationSummaryShort(int count) {
    return 'Summary is too short ($count chars) - 100 recommended';
  }

  @override
  String get validationTechLinkMissing =>
      'LinkedIn or GitHub is missing - strongly expected for a tech profile';

  @override
  String get validationNoExperience => 'No experience provided';

  @override
  String validationDescriptionMissing(String item) {
    return '$item: description is missing';
  }

  @override
  String validationNoMetric(String item) {
    return '$item: no figures or metrics - add measurable results';
  }

  @override
  String validationEndBeforeStart(String item) {
    return '$item: end date is before start date';
  }

  @override
  String validationFutureEnd(String item) {
    return '$item: end date is in the future';
  }

  @override
  String get validationNoEducation => 'No education provided';

  @override
  String get validationNoSkills => 'No skills provided';

  @override
  String validationFewSkills(int count) {
    return 'Only $count skills - 8 to 12 recommended';
  }

  @override
  String validationCombinedSkills(String name) {
    return '\"$name\" appears to contain several skills - separate them';
  }

  @override
  String get validationNoLanguages => 'No languages provided';

  @override
  String validationFutureCertification(String name) {
    return '\"$name\" is dated in the future - mark it In progress if needed';
  }

  @override
  String validationShortProject(String name) {
    return '\"$name\": description is too short - add more detail';
  }

  @override
  String validationTooMuchContent(int count) {
    return 'A lot of content ($count items) - may exceed one page';
  }

  @override
  String get errorGeneric => 'An error occurred';

  @override
  String get notifications => 'Notifications';

  @override
  String get staleCvReminder => 'Update reminder';

  @override
  String get staleCvReminderSubtitle =>
      'Notify me after 30 days without changes';

  @override
  String get cvViewNotifications => 'Shared CV views';

  @override
  String get cvViewNotificationsSubtitle => 'Notify me every 10 new visitors';

  @override
  String get aiTipNotifications => 'AI improvement tips';

  @override
  String get aiTipNotificationsSubtitle => 'Receive ideas to strengthen my CV';
}
