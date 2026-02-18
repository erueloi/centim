import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_en.dart';

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
    Locale('ca'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ca, this message translates to:
  /// **'Cèntim'**
  String get appTitle;

  /// No description provided for @quickAccessTitle.
  ///
  /// In ca, this message translates to:
  /// **'Accés Ràpid'**
  String get quickAccessTitle;

  /// No description provided for @totalBalanceTitle.
  ///
  /// In ca, this message translates to:
  /// **'Saldo Total'**
  String get totalBalanceTitle;

  /// No description provided for @supermarketLabel.
  ///
  /// In ca, this message translates to:
  /// **'Supermercat'**
  String get supermarketLabel;

  /// No description provided for @homeLabel.
  ///
  /// In ca, this message translates to:
  /// **'Llar'**
  String get homeLabel;

  /// No description provided for @renovationLabel.
  ///
  /// In ca, this message translates to:
  /// **'Reforma'**
  String get renovationLabel;

  /// No description provided for @entertainmentLabel.
  ///
  /// In ca, this message translates to:
  /// **'Oci'**
  String get entertainmentLabel;

  /// No description provided for @requiredError.
  ///
  /// In ca, this message translates to:
  /// **'Requerit'**
  String get requiredError;

  /// No description provided for @noActiveGroupError.
  ///
  /// In ca, this message translates to:
  /// **'Cap grup actiu'**
  String get noActiveGroupError;

  /// No description provided for @noMembersError.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha membres al grup'**
  String get noMembersError;

  /// No description provided for @budgetScreenTitle.
  ///
  /// In ca, this message translates to:
  /// **'Control Pressupostari'**
  String get budgetScreenTitle;

  /// No description provided for @noBudgetAssignedText.
  ///
  /// In ca, this message translates to:
  /// **'Sense pressupost assignat'**
  String get noBudgetAssignedText;

  /// No description provided for @editBudgetTitle.
  ///
  /// In ca, this message translates to:
  /// **'Pressupost {category}'**
  String editBudgetTitle(Object category);

  /// No description provided for @monthlyGoalLabel.
  ///
  /// In ca, this message translates to:
  /// **'Objectiu Mensual (€)'**
  String get monthlyGoalLabel;

  /// No description provided for @cancelButton.
  ///
  /// In ca, this message translates to:
  /// **'Cancel·lar'**
  String get cancelButton;

  /// No description provided for @saveButton.
  ///
  /// In ca, this message translates to:
  /// **'Guardar'**
  String get saveButton;

  /// No description provided for @catFood.
  ///
  /// In ca, this message translates to:
  /// **'Alimentació'**
  String get catFood;

  /// No description provided for @catTransport.
  ///
  /// In ca, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catShopping.
  ///
  /// In ca, this message translates to:
  /// **'Compres'**
  String get catShopping;

  /// No description provided for @catEntertainment.
  ///
  /// In ca, this message translates to:
  /// **'Oci'**
  String get catEntertainment;

  /// No description provided for @catHealth.
  ///
  /// In ca, this message translates to:
  /// **'Salut'**
  String get catHealth;

  /// No description provided for @catEducation.
  ///
  /// In ca, this message translates to:
  /// **'Educació'**
  String get catEducation;

  /// No description provided for @catBills.
  ///
  /// In ca, this message translates to:
  /// **'Factures'**
  String get catBills;

  /// No description provided for @catOther.
  ///
  /// In ca, this message translates to:
  /// **'Altres'**
  String get catOther;

  /// No description provided for @loginTitle.
  ///
  /// In ca, this message translates to:
  /// **'Inicia la sessió'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In ca, this message translates to:
  /// **'Registra\'t'**
  String get registerTitle;

  /// No description provided for @emailLabel.
  ///
  /// In ca, this message translates to:
  /// **'Correu electrònic'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In ca, this message translates to:
  /// **'Contrasenya'**
  String get passwordLabel;

  /// No description provided for @signInButton.
  ///
  /// In ca, this message translates to:
  /// **'Inicia la sessió'**
  String get signInButton;

  /// No description provided for @signUpButton.
  ///
  /// In ca, this message translates to:
  /// **'Registra\'t'**
  String get signUpButton;

  /// No description provided for @noAccountText.
  ///
  /// In ca, this message translates to:
  /// **'No tens compte? Registra\'t'**
  String get noAccountText;

  /// No description provided for @alreadyHaveAccountText.
  ///
  /// In ca, this message translates to:
  /// **'Ja tens compte? Inicia la sessió'**
  String get alreadyHaveAccountText;

  /// No description provided for @setupGroupTitle.
  ///
  /// In ca, this message translates to:
  /// **'Configural del Grup Familiar'**
  String get setupGroupTitle;

  /// No description provided for @createGroupTitle.
  ///
  /// In ca, this message translates to:
  /// **'Crea un grup nou'**
  String get createGroupTitle;

  /// No description provided for @groupNameLabel.
  ///
  /// In ca, this message translates to:
  /// **'Nom del Grup'**
  String get groupNameLabel;

  /// No description provided for @createGroupButton.
  ///
  /// In ca, this message translates to:
  /// **'Crea Grup'**
  String get createGroupButton;

  /// No description provided for @orJoinGroupText.
  ///
  /// In ca, this message translates to:
  /// **'O uneix-te a un grup existent'**
  String get orJoinGroupText;

  /// No description provided for @groupIdLabel.
  ///
  /// In ca, this message translates to:
  /// **'Codi d\'Invitació'**
  String get groupIdLabel;

  /// No description provided for @joinGroupButton.
  ///
  /// In ca, this message translates to:
  /// **'Uneix-te al Grup'**
  String get joinGroupButton;

  /// No description provided for @dashboardTitle.
  ///
  /// In ca, this message translates to:
  /// **'Tauler'**
  String get dashboardTitle;

  /// No description provided for @transactionsTab.
  ///
  /// In ca, this message translates to:
  /// **'Transaccions'**
  String get transactionsTab;

  /// No description provided for @budgetTab.
  ///
  /// In ca, this message translates to:
  /// **'Pressupostos'**
  String get budgetTab;

  /// No description provided for @profileTab.
  ///
  /// In ca, this message translates to:
  /// **'Perfil'**
  String get profileTab;

  /// No description provided for @addTransactionTitle.
  ///
  /// In ca, this message translates to:
  /// **'Afegeix Transacció'**
  String get addTransactionTitle;

  /// No description provided for @saveTransactionButton.
  ///
  /// In ca, this message translates to:
  /// **'Desa Transacció'**
  String get saveTransactionButton;

  /// No description provided for @amountLabel.
  ///
  /// In ca, this message translates to:
  /// **'Import'**
  String get amountLabel;

  /// No description provided for @conceptLabel.
  ///
  /// In ca, this message translates to:
  /// **'Concepte'**
  String get conceptLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In ca, this message translates to:
  /// **'Categoria'**
  String get categoryLabel;

  /// No description provided for @payerLabel.
  ///
  /// In ca, this message translates to:
  /// **'Pagador'**
  String get payerLabel;

  /// No description provided for @dateLabel.
  ///
  /// In ca, this message translates to:
  /// **'Data'**
  String get dateLabel;

  /// No description provided for @loadingText.
  ///
  /// In ca, this message translates to:
  /// **'Carregant...'**
  String get loadingText;

  /// No description provided for @errorText.
  ///
  /// In ca, this message translates to:
  /// **'Error: {error}'**
  String errorText(Object error);

  /// No description provided for @googleSignInButton.
  ///
  /// In ca, this message translates to:
  /// **'Continua amb Google'**
  String get googleSignInButton;

  /// No description provided for @googleSignInError.
  ///
  /// In ca, this message translates to:
  /// **'S\'ha produït un error en iniciar sessió amb Google'**
  String get googleSignInError;

  /// No description provided for @mainCategoryLabel.
  ///
  /// In ca, this message translates to:
  /// **'Categoria Principal'**
  String get mainCategoryLabel;

  /// No description provided for @subCategoryLabel.
  ///
  /// In ca, this message translates to:
  /// **'Subcategoria'**
  String get subCategoryLabel;

  /// No description provided for @expenseLabel.
  ///
  /// In ca, this message translates to:
  /// **'Despesa'**
  String get expenseLabel;

  /// No description provided for @incomeLabel.
  ///
  /// In ca, this message translates to:
  /// **'Ingrés'**
  String get incomeLabel;
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
      <String>['ca', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
