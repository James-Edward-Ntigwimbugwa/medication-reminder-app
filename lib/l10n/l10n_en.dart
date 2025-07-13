// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DoziYangu';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select your preferred language';

  @override
  String get english => 'English';

  @override
  String get swahili => 'Swahili';

  @override
  String get addMedication => 'Add Medication';

  @override
  String get medications => 'Medications';

  @override
  String get communication => 'Communication';

  @override
  String get permissionsRequired => 'Permissions Required';

  @override
  String get permissionExplanation => 'We need permissions to show reminders.';

  @override
  String get exactAlarmReason =>
      'Used to trigger medication reminders at exact times.';

  @override
  String get missedReminderWarning =>
      'Missing this may cause missed medication alerts.';

  @override
  String get later => 'Later';

  @override
  String get grantPermissions => 'Grant Permissions';

  @override
  String get allPermissionsGranted => 'All permissions granted!';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get permissionBanner => 'Some permissions are missing.';

  @override
  String get fix => 'Fix';

  @override
  String get healthInfo => 'Health Info';

  @override
  String get chat => 'Chat';

  @override
  String get saveMedication => 'Save Medication';

  @override
  String get currentTime => 'Current Time';

  @override
  String get setReminders => 'Set your medication reminders';

  @override
  String get medicationName => 'Medication Name';

  @override
  String get exampleMedication => 'e.g. Amoxicillin';

  @override
  String get medicationUnit => 'Unit (mg/ml/tablets)';

  @override
  String get exampleUnit => 'e.g. 500mg';

  @override
  String get frequency => 'Frequency';

  @override
  String get onceDaily => 'Once Daily';

  @override
  String get twiceDaily => 'Twice Daily';

  @override
  String get threeTimesDaily => 'Three Times Daily';

  @override
  String get custom => 'Custom';

  @override
  String get reminderTimes => 'Reminder Times';

  @override
  String get addTime => 'Add Time';

  @override
  String get noReminderSet => 'No reminder times set';

  @override
  String reminderNumber(Object number) {
    return 'Reminder $number';
  }

  @override
  String get incompleteFields => 'Please complete all fields';

  @override
  String get medicationSaved => 'Medication saved successfully';

  @override
  String get saveFailed => 'Failed to save medication';

  @override
  String get healthInformationHub => 'Health Information Hub';

  @override
  String get juaAfyaYako => 'Know Your Health';

  @override
  String get commonHealthTips => 'Common Health Tips';

  @override
  String get exploreDailyPractices =>
      'Explore daily practices to maintain a healthy lifestyle.';

  @override
  String get learnMore => 'Learn More';

  @override
  String get lisheBora => 'Balanced Nutrition';

  @override
  String get nutrition => 'Nutrition';

  @override
  String get understandNutritionImportance =>
      'Understand the importance of balanced nutrition.';

  @override
  String get mentalHealth => 'Mental Health';

  @override
  String get mentalWellBeing =>
      'Learn about mental well-being and stress management.';

  @override
  String get maternalChildHealth => 'Maternal & Child Health';

  @override
  String get maternalChildGuidance =>
      'Vital guidance for pregnant mothers and children.';

  @override
  String get diseasePrevention => 'Disease Prevention';

  @override
  String get protectFromDiseases =>
      'Protect yourself from malaria, HIV, TB and more.';

  @override
  String get chatbot => 'Chatbot';

  @override
  String get chatWithHealthAssistant => 'Chat with Health Assistant';

  @override
  String get typeYourMessage => 'Type your message...';

  @override
  String get createAccount => 'Create Your Account';

  @override
  String get registerToManageProviders =>
      'Register to manage your healthcare providers';

  @override
  String get fullName => 'Full Name';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get passwordMin6 => 'Password (min 6 characters)';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginToAccessProviders =>
      'Login to access your healthcare providers';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get register => 'Register';

  @override
  String get hello => 'Hello';

  @override
  String get email => 'Email';

  @override
  String get yourProviders => 'Your Healthcare Providers';

  @override
  String get noProvidersYet => 'No providers registered yet';

  @override
  String get addFirstProvider =>
      'Add your first healthcare provider to get started';

  @override
  String get addProvider => 'Add Provider';

  @override
  String get addNewProvider => 'Add New Provider';

  @override
  String get category => 'Category';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get emptyName => 'Please enter your full name';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get shortPassword => 'Password must be at least 6 characters long';

  @override
  String get accountCreated => 'Account created successfully!';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String get welcomeBackMessage => 'Welcome back!';

  @override
  String get loggedOut => 'Logged out successfully';

  @override
  String get providerName => 'Provider Name';

  @override
  String get providerCategory => 'Category (e.g., Doctor, Dentist)';

  @override
  String get whatsappNumber => 'WhatsApp Number (e.g., +1234567890)';

  @override
  String get cancel => 'Cancel';

  @override
  String get update => 'Update';

  @override
  String get save => 'Save';

  @override
  String get fillAllFields => 'Please fill all fields';

  @override
  String get invalidWhatsApp =>
      'Please enter a valid WhatsApp number (e.g., +1234567890)';

  @override
  String get providerUpdated => 'Provider updated successfully!';

  @override
  String get providerAdded => 'Provider added successfully!';

  @override
  String get deleteProvider => 'Delete Provider';

  @override
  String confirmDeleteProvider(Object providerName) {
    return 'Are you sure you want to delete $providerName?';
  }

  @override
  String get providerDeleted => 'Provider deleted successfully';

  @override
  String failedEmail(Object email) {
    return 'Failed to open email app for $email. Please open your email app and send to $email.';
  }

  @override
  String failedWhatsApp(Object phone) {
    return 'Failed to open WhatsApp for $phone. Please open WhatsApp and message $phone.';
  }

  @override
  String get userDataRecovered => 'User data recovered from backup';

  @override
  String get failedDecodeUserBackup => 'Failed to decode user backup';

  @override
  String get failedRecoverUserData => 'Failed to recover user data';

  @override
  String get errorSavingUserData => 'Error saving user data';

  @override
  String get failedSaveProviders => 'Failed to save providers';

  @override
  String get providersRecovered => 'Providers recovered from backup';

  @override
  String get clearedInvalidBackup => 'Cleared invalid provider backup';

  @override
  String get failedDecodeProviderBackup =>
      'Failed to decode provider backup, cleared corrupted data';

  @override
  String get noProviderBackup => 'No provider backup available';

  @override
  String get failedRecoverProviders => 'Failed to recover providers';

  @override
  String get debugStorage => 'Debug Storage';

  @override
  String get providersCount => 'Providers Count';

  @override
  String get clearCorruptedBackup => 'Clear corrupted backup?';

  @override
  String get clear => 'Clear';

  @override
  String get clearedBackupData => 'Cleared backup data';

  @override
  String get failedDebugStorage => 'Failed to debug storage';

  @override
  String get failedCreateBackup => 'Failed to create backup';

  @override
  String get logout => 'Logout';

  @override
  String get recoverProviders => 'Recover Providers';

  @override
  String get debugStorageAction => 'Debug Storage';

  @override
  String get appBarTitle => 'DoziYangu-support';

  @override
  String get registerDescription =>
      'Register to manage your healthcare providers';

  @override
  String get loginDescription => 'Login to access your healthcare providers';

  @override
  String get debugStorageTitle => 'Debug Storage';

  @override
  String get providersTitle => 'Your Healthcare Providers';

  @override
  String get noProviders => 'No providers registered yet';

  @override
  String get addProviderPrompt =>
      'Add your first healthcare provider to get started';

  @override
  String get emailAction => 'Email';

  @override
  String get whatsappAction => 'WhatsApp';

  @override
  String deleteConfirmation(Object provider) {
    return 'Are you sure you want to delete $provider?';
  }

  @override
  String get errorEmptyName => 'Please enter your full name';

  @override
  String get errorInvalidEmail => 'Please enter a valid email address';

  @override
  String get errorShortPassword =>
      'Password must be at least 6 characters long';

  @override
  String get errorInvalidCredentials => 'Invalid email or password';

  @override
  String get errorFillFields => 'Please fill all fields';

  @override
  String get errorInvalidWhatsApp =>
      'Please enter a valid WhatsApp number (e.g., +1234567890)';

  @override
  String get clearedBackup => 'Cleared invalid provider backup';

  @override
  String get errorCreateBackup => 'Failed to create backup';

  @override
  String errorEmailLaunch(Object toEmail) {
    return 'Failed to open email app for $toEmail. Please open your email app and send to $toEmail.';
  }

  @override
  String errorWhatsAppLaunch(Object phone) {
    return 'Failed to open WhatsApp for $phone. Please open WhatsApp and message $phone.';
  }

  @override
  String get clearCorrupted => 'Clear corrupted backup?';

  @override
  String get errorDebugStorage => 'Failed to debug storage';
}
