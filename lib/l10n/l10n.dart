import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/l10n.dart';
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
    Locale('sw'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DoziYangu'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @swahili.
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get swahili;

  /// No description provided for @addMedication.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @communication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get communication;

  /// No description provided for @permissionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get permissionsRequired;

  /// No description provided for @permissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'We need permissions to show reminders.'**
  String get permissionExplanation;

  /// No description provided for @exactAlarmReason.
  ///
  /// In en, this message translates to:
  /// **'Used to trigger medication reminders at exact times.'**
  String get exactAlarmReason;

  /// No description provided for @missedReminderWarning.
  ///
  /// In en, this message translates to:
  /// **'Missing this may cause missed medication alerts.'**
  String get missedReminderWarning;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @grantPermissions.
  ///
  /// In en, this message translates to:
  /// **'Grant Permissions'**
  String get grantPermissions;

  /// No description provided for @allPermissionsGranted.
  ///
  /// In en, this message translates to:
  /// **'All permissions granted!'**
  String get allPermissionsGranted;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @permissionBanner.
  ///
  /// In en, this message translates to:
  /// **'Some permissions are missing.'**
  String get permissionBanner;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @healthInfo.
  ///
  /// In en, this message translates to:
  /// **'Health Info'**
  String get healthInfo;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @saveMedication.
  ///
  /// In en, this message translates to:
  /// **'Save Medication'**
  String get saveMedication;

  /// No description provided for @currentTime.
  ///
  /// In en, this message translates to:
  /// **'Current Time'**
  String get currentTime;

  /// No description provided for @setReminders.
  ///
  /// In en, this message translates to:
  /// **'Set your medication reminders'**
  String get setReminders;

  /// No description provided for @medicationName.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationName;

  /// No description provided for @exampleMedication.
  ///
  /// In en, this message translates to:
  /// **'e.g. Amoxicillin'**
  String get exampleMedication;

  /// No description provided for @medicationUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit (mg/ml/tablets)'**
  String get medicationUnit;

  /// No description provided for @exampleUnit.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500mg'**
  String get exampleUnit;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @onceDaily.
  ///
  /// In en, this message translates to:
  /// **'Once Daily'**
  String get onceDaily;

  /// No description provided for @twiceDaily.
  ///
  /// In en, this message translates to:
  /// **'Twice Daily'**
  String get twiceDaily;

  /// No description provided for @threeTimesDaily.
  ///
  /// In en, this message translates to:
  /// **'Three Times Daily'**
  String get threeTimesDaily;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @reminderTimes.
  ///
  /// In en, this message translates to:
  /// **'Reminder Times'**
  String get reminderTimes;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add Time'**
  String get addTime;

  /// No description provided for @noReminderSet.
  ///
  /// In en, this message translates to:
  /// **'No reminder times set'**
  String get noReminderSet;

  /// No description provided for @reminderNumber.
  ///
  /// In en, this message translates to:
  /// **'Reminder {number}'**
  String reminderNumber(Object number);

  /// No description provided for @incompleteFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all fields'**
  String get incompleteFields;

  /// No description provided for @medicationSaved.
  ///
  /// In en, this message translates to:
  /// **'Medication saved successfully'**
  String get medicationSaved;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save medication'**
  String get saveFailed;

  /// No description provided for @healthInformationHub.
  ///
  /// In en, this message translates to:
  /// **'Health Information Hub'**
  String get healthInformationHub;

  /// No description provided for @juaAfyaYako.
  ///
  /// In en, this message translates to:
  /// **'Know Your Health'**
  String get juaAfyaYako;

  /// No description provided for @commonHealthTips.
  ///
  /// In en, this message translates to:
  /// **'Common Health Tips'**
  String get commonHealthTips;

  /// No description provided for @exploreDailyPractices.
  ///
  /// In en, this message translates to:
  /// **'Explore daily practices to maintain a healthy lifestyle.'**
  String get exploreDailyPractices;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @lisheBora.
  ///
  /// In en, this message translates to:
  /// **'Balanced Nutrition'**
  String get lisheBora;

  /// No description provided for @nutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutrition;

  /// No description provided for @understandNutritionImportance.
  ///
  /// In en, this message translates to:
  /// **'Understand the importance of balanced nutrition.'**
  String get understandNutritionImportance;

  /// No description provided for @mentalHealth.
  ///
  /// In en, this message translates to:
  /// **'Mental Health'**
  String get mentalHealth;

  /// No description provided for @mentalWellBeing.
  ///
  /// In en, this message translates to:
  /// **'Learn about mental well-being and stress management.'**
  String get mentalWellBeing;

  /// No description provided for @maternalChildHealth.
  ///
  /// In en, this message translates to:
  /// **'Maternal & Child Health'**
  String get maternalChildHealth;

  /// No description provided for @maternalChildGuidance.
  ///
  /// In en, this message translates to:
  /// **'Vital guidance for pregnant mothers and children.'**
  String get maternalChildGuidance;

  /// No description provided for @diseasePrevention.
  ///
  /// In en, this message translates to:
  /// **'Disease Prevention'**
  String get diseasePrevention;

  /// No description provided for @protectFromDiseases.
  ///
  /// In en, this message translates to:
  /// **'Protect yourself from malaria, HIV, TB and more.'**
  String get protectFromDiseases;

  /// No description provided for @chatbot.
  ///
  /// In en, this message translates to:
  /// **'Chatbot'**
  String get chatbot;

  /// No description provided for @chatWithHealthAssistant.
  ///
  /// In en, this message translates to:
  /// **'Chat with Health Assistant'**
  String get chatWithHealthAssistant;

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createAccount;

  /// No description provided for @registerToManageProviders.
  ///
  /// In en, this message translates to:
  /// **'Register to manage your healthcare providers'**
  String get registerToManageProviders;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @passwordMin6.
  ///
  /// In en, this message translates to:
  /// **'Password (min 6 characters)'**
  String get passwordMin6;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginToAccessProviders.
  ///
  /// In en, this message translates to:
  /// **'Login to access your healthcare providers'**
  String get loginToAccessProviders;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @yourProviders.
  ///
  /// In en, this message translates to:
  /// **'Your Healthcare Providers'**
  String get yourProviders;

  /// No description provided for @noProvidersYet.
  ///
  /// In en, this message translates to:
  /// **'No providers registered yet'**
  String get noProvidersYet;

  /// No description provided for @addFirstProvider.
  ///
  /// In en, this message translates to:
  /// **'Add your first healthcare provider to get started'**
  String get addFirstProvider;

  /// No description provided for @addProvider.
  ///
  /// In en, this message translates to:
  /// **'Add Provider'**
  String get addProvider;

  /// No description provided for @addNewProvider.
  ///
  /// In en, this message translates to:
  /// **'Add New Provider'**
  String get addNewProvider;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @emptyName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get emptyName;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @shortPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get shortPassword;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get accountCreated;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidCredentials;

  /// No description provided for @welcomeBackMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBackMessage;

  /// No description provided for @loggedOut.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get loggedOut;

  /// No description provided for @providerName.
  ///
  /// In en, this message translates to:
  /// **'Provider Name'**
  String get providerName;

  /// No description provided for @providerCategory.
  ///
  /// In en, this message translates to:
  /// **'Category (e.g., Doctor, Dentist)'**
  String get providerCategory;

  /// No description provided for @whatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Number (e.g., +1234567890)'**
  String get whatsappNumber;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// No description provided for @invalidWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid WhatsApp number (e.g., +1234567890)'**
  String get invalidWhatsApp;

  /// No description provided for @providerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Provider updated successfully!'**
  String get providerUpdated;

  /// No description provided for @providerAdded.
  ///
  /// In en, this message translates to:
  /// **'Provider added successfully!'**
  String get providerAdded;

  /// No description provided for @deleteProvider.
  ///
  /// In en, this message translates to:
  /// **'Delete Provider'**
  String get deleteProvider;

  /// No description provided for @confirmDeleteProvider.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {providerName}?'**
  String confirmDeleteProvider(Object providerName);

  /// No description provided for @providerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Provider deleted successfully'**
  String get providerDeleted;

  /// No description provided for @failedEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to open email app for {email}. Please open your email app and send to {email}.'**
  String failedEmail(Object email);

  /// No description provided for @failedWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Failed to open WhatsApp for {phone}. Please open WhatsApp and message {phone}.'**
  String failedWhatsApp(Object phone);

  /// No description provided for @userDataRecovered.
  ///
  /// In en, this message translates to:
  /// **'User data recovered from backup'**
  String get userDataRecovered;

  /// No description provided for @failedDecodeUserBackup.
  ///
  /// In en, this message translates to:
  /// **'Failed to decode user backup'**
  String get failedDecodeUserBackup;

  /// No description provided for @failedRecoverUserData.
  ///
  /// In en, this message translates to:
  /// **'Failed to recover user data'**
  String get failedRecoverUserData;

  /// No description provided for @errorSavingUserData.
  ///
  /// In en, this message translates to:
  /// **'Error saving user data'**
  String get errorSavingUserData;

  /// No description provided for @failedSaveProviders.
  ///
  /// In en, this message translates to:
  /// **'Failed to save providers'**
  String get failedSaveProviders;

  /// No description provided for @providersRecovered.
  ///
  /// In en, this message translates to:
  /// **'Providers recovered from backup'**
  String get providersRecovered;

  /// No description provided for @clearedInvalidBackup.
  ///
  /// In en, this message translates to:
  /// **'Cleared invalid provider backup'**
  String get clearedInvalidBackup;

  /// No description provided for @failedDecodeProviderBackup.
  ///
  /// In en, this message translates to:
  /// **'Failed to decode provider backup, cleared corrupted data'**
  String get failedDecodeProviderBackup;

  /// No description provided for @noProviderBackup.
  ///
  /// In en, this message translates to:
  /// **'No provider backup available'**
  String get noProviderBackup;

  /// No description provided for @failedRecoverProviders.
  ///
  /// In en, this message translates to:
  /// **'Failed to recover providers'**
  String get failedRecoverProviders;

  /// No description provided for @debugStorage.
  ///
  /// In en, this message translates to:
  /// **'Debug Storage'**
  String get debugStorage;

  /// No description provided for @providersCount.
  ///
  /// In en, this message translates to:
  /// **'Providers Count'**
  String get providersCount;

  /// No description provided for @clearCorruptedBackup.
  ///
  /// In en, this message translates to:
  /// **'Clear corrupted backup?'**
  String get clearCorruptedBackup;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearedBackupData.
  ///
  /// In en, this message translates to:
  /// **'Cleared backup data'**
  String get clearedBackupData;

  /// No description provided for @failedDebugStorage.
  ///
  /// In en, this message translates to:
  /// **'Failed to debug storage'**
  String get failedDebugStorage;

  /// No description provided for @failedCreateBackup.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup'**
  String get failedCreateBackup;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @recoverProviders.
  ///
  /// In en, this message translates to:
  /// **'Recover Providers'**
  String get recoverProviders;

  /// No description provided for @debugStorageAction.
  ///
  /// In en, this message translates to:
  /// **'Debug Storage'**
  String get debugStorageAction;

  /// No description provided for @appBarTitle.
  ///
  /// In en, this message translates to:
  /// **'DoziYangu-support'**
  String get appBarTitle;

  /// No description provided for @registerDescription.
  ///
  /// In en, this message translates to:
  /// **'Register to manage your healthcare providers'**
  String get registerDescription;

  /// No description provided for @loginDescription.
  ///
  /// In en, this message translates to:
  /// **'Login to access your healthcare providers'**
  String get loginDescription;

  /// No description provided for @debugStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug Storage'**
  String get debugStorageTitle;

  /// No description provided for @providersTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Healthcare Providers'**
  String get providersTitle;

  /// No description provided for @noProviders.
  ///
  /// In en, this message translates to:
  /// **'No providers registered yet'**
  String get noProviders;

  /// No description provided for @addProviderPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add your first healthcare provider to get started'**
  String get addProviderPrompt;

  /// No description provided for @emailAction.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailAction;

  /// No description provided for @whatsappAction.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsappAction;

  /// Confirmation message for deleting a provider
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {provider}?'**
  String deleteConfirmation(Object provider);

  /// No description provided for @errorEmptyName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get errorEmptyName;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get errorInvalidEmail;

  /// No description provided for @errorShortPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get errorShortPassword;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get errorInvalidCredentials;

  /// No description provided for @errorFillFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get errorFillFields;

  /// No description provided for @errorInvalidWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid WhatsApp number (e.g., +1234567890)'**
  String get errorInvalidWhatsApp;

  /// No description provided for @clearedBackup.
  ///
  /// In en, this message translates to:
  /// **'Cleared invalid provider backup'**
  String get clearedBackup;

  /// No description provided for @errorCreateBackup.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup'**
  String get errorCreateBackup;

  /// Error message when email app fails to launch
  ///
  /// In en, this message translates to:
  /// **'Failed to open email app for {toEmail}. Please open your email app and send to {toEmail}.'**
  String errorEmailLaunch(Object toEmail);

  /// Error message when WhatsApp fails to launch
  ///
  /// In en, this message translates to:
  /// **'Failed to open WhatsApp for {phone}. Please open WhatsApp and message {phone}.'**
  String errorWhatsAppLaunch(Object phone);

  /// No description provided for @clearCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Clear corrupted backup?'**
  String get clearCorrupted;

  /// No description provided for @errorDebugStorage.
  ///
  /// In en, this message translates to:
  /// **'Failed to debug storage'**
  String get errorDebugStorage;
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
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
