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
    Locale('en')
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

  /// No description provided for @editButton.
  ///
  /// In ca, this message translates to:
  /// **'Editar'**
  String get editButton;

  /// No description provided for @sortBy.
  ///
  /// In ca, this message translates to:
  /// **'Ordenar per'**
  String get sortBy;

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

  /// No description provided for @panoramicTitle.
  ///
  /// In ca, this message translates to:
  /// **'Panoràmica'**
  String get panoramicTitle;

  /// No description provided for @resetFilters.
  ///
  /// In ca, this message translates to:
  /// **'Restablir filtres'**
  String get resetFilters;

  /// No description provided for @savingsTotal.
  ///
  /// In ca, this message translates to:
  /// **'Resum d\'Estalvi'**
  String get savingsTotal;

  /// No description provided for @savingsAportat.
  ///
  /// In ca, this message translates to:
  /// **'Aportat'**
  String get savingsAportat;

  /// No description provided for @savingsRescatat.
  ///
  /// In ca, this message translates to:
  /// **'Rescatat'**
  String get savingsRescatat;

  /// No description provided for @savingsNet.
  ///
  /// In ca, this message translates to:
  /// **'Net'**
  String get savingsNet;

  /// No description provided for @howItWorks.
  ///
  /// In ca, this message translates to:
  /// **'Com funciona Cèntim?'**
  String get howItWorks;

  /// No description provided for @newTransaction.
  ///
  /// In ca, this message translates to:
  /// **'Nou Moviment'**
  String get newTransaction;

  /// No description provided for @expenseOrIncome.
  ///
  /// In ca, this message translates to:
  /// **'Despesa o ingrés'**
  String get expenseOrIncome;

  /// No description provided for @newTransfer.
  ///
  /// In ca, this message translates to:
  /// **'Nova Transferència'**
  String get newTransfer;

  /// No description provided for @transferDescription.
  ///
  /// In ca, this message translates to:
  /// **'Mou diners entre comptes o paga deutes'**
  String get transferDescription;

  /// No description provided for @navHome.
  ///
  /// In ca, this message translates to:
  /// **'Inici'**
  String get navHome;

  /// No description provided for @navDetail.
  ///
  /// In ca, this message translates to:
  /// **'Detall'**
  String get navDetail;

  /// No description provided for @navTransactions.
  ///
  /// In ca, this message translates to:
  /// **'Moviments'**
  String get navTransactions;

  /// No description provided for @navBudget.
  ///
  /// In ca, this message translates to:
  /// **'Pressupost'**
  String get navBudget;

  /// No description provided for @navWealth.
  ///
  /// In ca, this message translates to:
  /// **'Patrimoni'**
  String get navWealth;

  /// No description provided for @cycleClosedMessage.
  ///
  /// In ca, this message translates to:
  /// **'Cicle de {name} tancat. Benvingut al nou mes!'**
  String cycleClosedMessage(Object name);

  /// No description provided for @cycleHistoryTooltip.
  ///
  /// In ca, this message translates to:
  /// **'Historial de Cicles'**
  String get cycleHistoryTooltip;

  /// No description provided for @cycleSettingsTooltip.
  ///
  /// In ca, this message translates to:
  /// **'Configuració de Cicles'**
  String get cycleSettingsTooltip;

  /// No description provided for @profileTooltip.
  ///
  /// In ca, this message translates to:
  /// **'Perfil'**
  String get profileTooltip;

  /// No description provided for @endOfMonthBanner.
  ///
  /// In ca, this message translates to:
  /// **'S\'acosta final de mes. Has cobrat ja la nòmina?'**
  String get endOfMonthBanner;

  /// No description provided for @notYet.
  ///
  /// In ca, this message translates to:
  /// **'Encara no'**
  String get notYet;

  /// No description provided for @startNewMonth.
  ///
  /// In ca, this message translates to:
  /// **'SÍ, INICIAR NOU MES'**
  String get startNewMonth;

  /// No description provided for @alreadyPaid.
  ///
  /// In ca, this message translates to:
  /// **'Ja he cobrat!'**
  String get alreadyPaid;

  /// No description provided for @confirmSalary.
  ///
  /// In ca, this message translates to:
  /// **'💰 Confirmar nòmina'**
  String get confirmSalary;

  /// No description provided for @salaryConfirmationMessage.
  ///
  /// In ca, this message translates to:
  /// **'Has rebut la nòmina? Això tancarà el cicle actual i n\'obrirà un de nou.'**
  String get salaryConfirmationMessage;

  /// No description provided for @yesPaid.
  ///
  /// In ca, this message translates to:
  /// **'Sí, he cobrat!'**
  String get yesPaid;

  /// No description provided for @noCategories.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha categories'**
  String get noCategories;

  /// No description provided for @whereExpense.
  ///
  /// In ca, this message translates to:
  /// **'On has fet la despesa?'**
  String get whereExpense;

  /// No description provided for @whereIncome.
  ///
  /// In ca, this message translates to:
  /// **'D\'on prové l\'ingrés?'**
  String get whereIncome;

  /// No description provided for @assetsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Actius'**
  String get assetsTitle;

  /// No description provided for @liabilitiesTitle.
  ///
  /// In ca, this message translates to:
  /// **'Passius'**
  String get liabilitiesTitle;

  /// No description provided for @savingsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Objectius d\'Estalvi'**
  String get savingsTitle;

  /// No description provided for @netWorth.
  ///
  /// In ca, this message translates to:
  /// **'El meu Patrimoni'**
  String get netWorth;

  /// No description provided for @totalAssetsLabel.
  ///
  /// In ca, this message translates to:
  /// **'Actiu'**
  String get totalAssetsLabel;

  /// No description provided for @totalLiabilitiesLabel.
  ///
  /// In ca, this message translates to:
  /// **'Passiu'**
  String get totalLiabilitiesLabel;

  /// No description provided for @noAssets.
  ///
  /// In ca, this message translates to:
  /// **'No tens cap actiu registrat.'**
  String get noAssets;

  /// No description provided for @noDebts.
  ///
  /// In ca, this message translates to:
  /// **'No tens cap deute registrat.'**
  String get noDebts;

  /// No description provided for @noGoals.
  ///
  /// In ca, this message translates to:
  /// **'No tens cap objectiu d\'estalvi.'**
  String get noGoals;

  /// No description provided for @addAsset.
  ///
  /// In ca, this message translates to:
  /// **'Afegir Actiu'**
  String get addAsset;

  /// No description provided for @addDebt.
  ///
  /// In ca, this message translates to:
  /// **'Afegir Deute'**
  String get addDebt;

  /// No description provided for @addGoal.
  ///
  /// In ca, this message translates to:
  /// **'Crear Guardiola'**
  String get addGoal;

  /// No description provided for @editGoal.
  ///
  /// In ca, this message translates to:
  /// **'Editar Guardiola'**
  String get editGoal;

  /// No description provided for @newGoal.
  ///
  /// In ca, this message translates to:
  /// **'Nova Guardiola'**
  String get newGoal;

  /// No description provided for @goalUpdated.
  ///
  /// In ca, this message translates to:
  /// **'Guardiola actualitzada!'**
  String get goalUpdated;

  /// No description provided for @goalCreated.
  ///
  /// In ca, this message translates to:
  /// **'Guardiola creada correctament!'**
  String get goalCreated;

  /// No description provided for @goalNameLabel.
  ///
  /// In ca, this message translates to:
  /// **'Nom de l\'objectiu'**
  String get goalNameLabel;

  /// No description provided for @goalNameHint.
  ///
  /// In ca, this message translates to:
  /// **'Ex: Viatge a Japó'**
  String get goalNameHint;

  /// No description provided for @enterName.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix un nom'**
  String get enterName;

  /// No description provided for @enterAmount.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix un import'**
  String get enterAmount;

  /// No description provided for @invalidAmount.
  ///
  /// In ca, this message translates to:
  /// **'Import invàlid'**
  String get invalidAmount;

  /// No description provided for @goalTargetAmountLabel.
  ///
  /// In ca, this message translates to:
  /// **'Import Objectiu (€)'**
  String get goalTargetAmountLabel;

  /// No description provided for @simulateAmortization.
  ///
  /// In ca, this message translates to:
  /// **'Simular Amortització'**
  String get simulateAmortization;

  /// No description provided for @debtBank.
  ///
  /// In ca, this message translates to:
  /// **'Entitat Bancària'**
  String get debtBank;

  /// No description provided for @debtBankName.
  ///
  /// In ca, this message translates to:
  /// **'Nom del Banc'**
  String get debtBankName;

  /// No description provided for @debtInitialAmount.
  ///
  /// In ca, this message translates to:
  /// **'Import Inicial'**
  String get debtInitialAmount;

  /// No description provided for @debtPending.
  ///
  /// In ca, this message translates to:
  /// **'Pendent'**
  String get debtPending;

  /// No description provided for @debtInterest.
  ///
  /// In ca, this message translates to:
  /// **'Interès'**
  String get debtInterest;

  /// No description provided for @debtInstallment.
  ///
  /// In ca, this message translates to:
  /// **'Quota Mensual'**
  String get debtInstallment;

  /// No description provided for @debtMaturity.
  ///
  /// In ca, this message translates to:
  /// **'Data de Venciment'**
  String get debtMaturity;

  /// No description provided for @debtMaturityLabel.
  ///
  /// In ca, this message translates to:
  /// **'Venciment: {date}'**
  String debtMaturityLabel(Object date);

  /// No description provided for @assetValuation.
  ///
  /// In ca, this message translates to:
  /// **'Valoració Actual'**
  String get assetValuation;

  /// No description provided for @assetType.
  ///
  /// In ca, this message translates to:
  /// **'Tipus d\'Actiu'**
  String get assetType;

  /// No description provided for @assetTypeRealEstate.
  ///
  /// In ca, this message translates to:
  /// **'Immobiliari'**
  String get assetTypeRealEstate;

  /// No description provided for @assetTypeBankAccount.
  ///
  /// In ca, this message translates to:
  /// **'Compte Bancari'**
  String get assetTypeBankAccount;

  /// No description provided for @assetTypeCash.
  ///
  /// In ca, this message translates to:
  /// **'Efectiu'**
  String get assetTypeCash;

  /// No description provided for @assetTypeOther.
  ///
  /// In ca, this message translates to:
  /// **'Altres'**
  String get assetTypeOther;

  /// No description provided for @goalIcon.
  ///
  /// In ca, this message translates to:
  /// **'Icona (Emoji)'**
  String get goalIcon;

  /// No description provided for @goalHasTarget.
  ///
  /// In ca, this message translates to:
  /// **'Té un import objectiu?'**
  String get goalHasTarget;

  /// No description provided for @nameRequired.
  ///
  /// In ca, this message translates to:
  /// **'El nom és obligatori'**
  String get nameRequired;

  /// No description provided for @adjustBalance.
  ///
  /// In ca, this message translates to:
  /// **'Quadrar Saldo'**
  String get adjustBalance;

  /// No description provided for @withdrawFunds.
  ///
  /// In ca, this message translates to:
  /// **'Retirar'**
  String get withdrawFunds;

  /// No description provided for @adjustBalanceTitle.
  ///
  /// In ca, this message translates to:
  /// **'Ajustar saldo'**
  String get adjustBalanceTitle;

  /// No description provided for @adjustBalanceMessage.
  ///
  /// In ca, this message translates to:
  /// **'Aquest ajust registrarà un moviment per quadrar el saldo actual de la guardiola.'**
  String get adjustBalanceMessage;

  /// No description provided for @newBalanceLabel.
  ///
  /// In ca, this message translates to:
  /// **'Nou saldo actual (€)'**
  String get newBalanceLabel;

  /// No description provided for @balanceAdjusted.
  ///
  /// In ca, this message translates to:
  /// **'Saldo ajustat correctament.'**
  String get balanceAdjusted;

  /// No description provided for @withdrawTitle.
  ///
  /// In ca, this message translates to:
  /// **'Retirar fons'**
  String get withdrawTitle;

  /// No description provided for @withdrawMessage.
  ///
  /// In ca, this message translates to:
  /// **'Aquests fons es mouran a la teva cartera principal com a ingrés.'**
  String get withdrawMessage;

  /// No description provided for @withdrawAmountLabel.
  ///
  /// In ca, this message translates to:
  /// **'Import a retirar (€)'**
  String get withdrawAmountLabel;

  /// No description provided for @destinationAccount.
  ///
  /// In ca, this message translates to:
  /// **'Compte destí'**
  String get destinationAccount;

  /// No description provided for @unspecifiedAccount.
  ///
  /// In ca, this message translates to:
  /// **'Sense especificar'**
  String get unspecifiedAccount;

  /// No description provided for @notEnoughFunds.
  ///
  /// In ca, this message translates to:
  /// **'No tens prous fons a la guardiola.'**
  String get notEnoughFunds;

  /// No description provided for @withdrawalConcept.
  ///
  /// In ca, this message translates to:
  /// **'Retirada de {goalName}'**
  String withdrawalConcept(Object goalName);

  /// No description provided for @withdrawnSuccess.
  ///
  /// In ca, this message translates to:
  /// **'Retirats {amount}€ correctament.'**
  String withdrawnSuccess(Object amount);

  /// No description provided for @noMovementsYet.
  ///
  /// In ca, this message translates to:
  /// **'Encara no hi ha moviments.'**
  String get noMovementsYet;

  /// No description provided for @contributionLabel.
  ///
  /// In ca, this message translates to:
  /// **'Aportació'**
  String get contributionLabel;

  /// No description provided for @movementsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Moviments'**
  String get movementsTitle;

  /// No description provided for @importCSV.
  ///
  /// In ca, this message translates to:
  /// **'Importar CSV (CaixaBank)'**
  String get importCSV;

  /// No description provided for @noMovementsFound.
  ///
  /// In ca, this message translates to:
  /// **'No s\'han trobat moviments o s\'ha cancel·lat la selecció'**
  String get noMovementsFound;

  /// No description provided for @migrateOldMovements.
  ///
  /// In ca, this message translates to:
  /// **'Migrar Moviments Antics'**
  String get migrateOldMovements;

  /// No description provided for @allUpdated.
  ///
  /// In ca, this message translates to:
  /// **'Tots els moviments estan actualitzats ✅'**
  String get allUpdated;

  /// No description provided for @noLiquidAccounts.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha comptes líquids disponibles'**
  String get noLiquidAccounts;

  /// No description provided for @foundOrphaned.
  ///
  /// In ca, this message translates to:
  /// **'S\'han trobat {count} moviments sense compte assignat. A quin compte els vols vincular?'**
  String foundOrphaned(Object count);

  /// No description provided for @migrateSuccess.
  ///
  /// In ca, this message translates to:
  /// **'Migració completada amb èxit! {count} moviments actualitzats.'**
  String migrateSuccess(Object count);

  /// No description provided for @tabAll.
  ///
  /// In ca, this message translates to:
  /// **'Tots'**
  String get tabAll;

  /// No description provided for @tabFixed.
  ///
  /// In ca, this message translates to:
  /// **'Fixes'**
  String get tabFixed;

  /// No description provided for @searchHint.
  ///
  /// In ca, this message translates to:
  /// **'Buscar moviments...'**
  String get searchHint;

  /// No description provided for @noResultsFilter.
  ///
  /// In ca, this message translates to:
  /// **'Cap moviment coincideix amb els filtres'**
  String get noResultsFilter;

  /// No description provided for @noResultsCycle.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha moviments en aquest cicle'**
  String get noResultsCycle;

  /// No description provided for @resultsCount.
  ///
  /// In ca, this message translates to:
  /// **'{count, plural, =0{Cap resultat} =1{1 resultat} other{{count} resultats}}'**
  String resultsCount(num count);

  /// No description provided for @deleteMovementTitle.
  ///
  /// In ca, this message translates to:
  /// **'Esborrar moviment?'**
  String get deleteMovementTitle;

  /// No description provided for @cannotBeUndone.
  ///
  /// In ca, this message translates to:
  /// **'Aquesta acció no es pot desfer.'**
  String get cannotBeUndone;

  /// No description provided for @deleteTransferTitle.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar traspàs'**
  String get deleteTransferTitle;

  /// No description provided for @deleteTransferConfirm.
  ///
  /// In ca, this message translates to:
  /// **'Estàs segur que vols eliminar aquest traspàs? Els saldos es restauraran automàticament.'**
  String get deleteTransferConfirm;

  /// No description provided for @transferDeleted.
  ///
  /// In ca, this message translates to:
  /// **'Traspàs eliminat correctament'**
  String get transferDeleted;

  /// No description provided for @deleteButton.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar'**
  String get deleteButton;

  /// No description provided for @migrateButton.
  ///
  /// In ca, this message translates to:
  /// **'Migrar'**
  String get migrateButton;

  /// No description provided for @chooseColor.
  ///
  /// In ca, this message translates to:
  /// **'Tria un color'**
  String get chooseColor;

  /// No description provided for @debtLabel.
  ///
  /// In ca, this message translates to:
  /// **'Deute'**
  String get debtLabel;

  /// No description provided for @goalLabel.
  ///
  /// In ca, this message translates to:
  /// **'Objectiu'**
  String get goalLabel;

  /// No description provided for @advancedFilters.
  ///
  /// In ca, this message translates to:
  /// **'Filtres Avançats'**
  String get advancedFilters;

  /// No description provided for @type.
  ///
  /// In ca, this message translates to:
  /// **'Tipus'**
  String get type;

  /// No description provided for @all.
  ///
  /// In ca, this message translates to:
  /// **'Tots'**
  String get all;

  /// No description provided for @categories.
  ///
  /// In ca, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @subCategories.
  ///
  /// In ca, this message translates to:
  /// **'Subcategories'**
  String get subCategories;

  /// No description provided for @payer.
  ///
  /// In ca, this message translates to:
  /// **'Pagador'**
  String get payer;

  /// No description provided for @amountRange.
  ///
  /// In ca, this message translates to:
  /// **'Rang d\'import'**
  String get amountRange;

  /// No description provided for @minimum.
  ///
  /// In ca, this message translates to:
  /// **'Mínim'**
  String get minimum;

  /// No description provided for @maximum.
  ///
  /// In ca, this message translates to:
  /// **'Màxim'**
  String get maximum;

  /// No description provided for @dateRange.
  ///
  /// In ca, this message translates to:
  /// **'Rang de dates'**
  String get dateRange;

  /// No description provided for @from.
  ///
  /// In ca, this message translates to:
  /// **'Des de...'**
  String get from;

  /// No description provided for @to.
  ///
  /// In ca, this message translates to:
  /// **'Fins a...'**
  String get to;

  /// No description provided for @clear.
  ///
  /// In ca, this message translates to:
  /// **'Netejar'**
  String get clear;

  /// No description provided for @clearAll.
  ///
  /// In ca, this message translates to:
  /// **'Netejar tot'**
  String get clearAll;

  /// No description provided for @applyFilters.
  ///
  /// In ca, this message translates to:
  /// **'Aplicar Filtres'**
  String get applyFilters;

  /// No description provided for @allFixedPaid.
  ///
  /// In ca, this message translates to:
  /// **'Totes les despeses fixes pagades!'**
  String get allFixedPaid;

  /// No description provided for @allUpToDate.
  ///
  /// In ca, this message translates to:
  /// **'Aquest mes ja ho tens tot al dia.'**
  String get allUpToDate;

  /// No description provided for @income.
  ///
  /// In ca, this message translates to:
  /// **'Ingressos'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In ca, this message translates to:
  /// **'Despeses'**
  String get expenses;

  /// No description provided for @paymentOf.
  ///
  /// In ca, this message translates to:
  /// **'Pagament de {name}'**
  String paymentOf(Object name);

  /// No description provided for @heatmapTotal.
  ///
  /// In ca, this message translates to:
  /// **'TOTAL'**
  String get heatmapTotal;

  /// No description provided for @heatmapCycleRange.
  ///
  /// In ca, this message translates to:
  /// **'Rang de cicles'**
  String get heatmapCycleRange;

  /// No description provided for @heatmapAllCycles.
  ///
  /// In ca, this message translates to:
  /// **'Tots'**
  String get heatmapAllCycles;

  /// No description provided for @billingCyclesLabel.
  ///
  /// In ca, this message translates to:
  /// **'Cicles de Facturació'**
  String get billingCyclesLabel;

  /// No description provided for @categoriesLabel.
  ///
  /// In ca, this message translates to:
  /// **'Categories'**
  String get categoriesLabel;

  /// No description provided for @coachChatTitle.
  ///
  /// In ca, this message translates to:
  /// **'Cèntim Coach'**
  String get coachChatTitle;

  /// No description provided for @coachChatWelcome.
  ///
  /// In ca, this message translates to:
  /// **'Hola! 👋 Sóc el teu coach financer. Pregunta\'m qualsevol cosa sobre els teus moviments, pressupostos o estalvis.'**
  String get coachChatWelcome;

  /// No description provided for @coachChatHint.
  ///
  /// In ca, this message translates to:
  /// **'Escriu la teva pregunta...'**
  String get coachChatHint;

  /// No description provided for @coachSuggestion1.
  ///
  /// In ca, this message translates to:
  /// **'Quant vaig gastar de menjar el mes passat?'**
  String get coachSuggestion1;

  /// No description provided for @coachSuggestion2.
  ///
  /// In ca, this message translates to:
  /// **'Quines categories estan per sobre del pressupost?'**
  String get coachSuggestion2;

  /// No description provided for @coachSuggestion3.
  ///
  /// In ca, this message translates to:
  /// **'Quin és el meu estalvi mitjà?'**
  String get coachSuggestion3;

  /// No description provided for @coachAskButton.
  ///
  /// In ca, this message translates to:
  /// **'Pregunta al Coach'**
  String get coachAskButton;

  /// No description provided for @coachNewConversation.
  ///
  /// In ca, this message translates to:
  /// **'Nova conversa'**
  String get coachNewConversation;

  /// No description provided for @contributeButton.
  ///
  /// In ca, this message translates to:
  /// **'Aportar'**
  String get contributeButton;

  /// No description provided for @contributeTitle.
  ///
  /// In ca, this message translates to:
  /// **'Aportar a la guardiola'**
  String get contributeTitle;

  /// No description provided for @contributeMessage.
  ///
  /// In ca, this message translates to:
  /// **'Quant vols aportar a aquesta guardiola?'**
  String get contributeMessage;

  /// No description provided for @contributeAmountLabel.
  ///
  /// In ca, this message translates to:
  /// **'Import a aportar (€)'**
  String get contributeAmountLabel;

  /// No description provided for @contributedSuccess.
  ///
  /// In ca, this message translates to:
  /// **'Aportat {amount}€ correctament.'**
  String contributedSuccess(Object amount);

  /// No description provided for @adjustBalanceHint.
  ///
  /// In ca, this message translates to:
  /// **'Aquest ajust crearà un moviment de balanç automàtic'**
  String get adjustBalanceHint;

  /// No description provided for @savingsNotePlaceholder.
  ///
  /// In ca, this message translates to:
  /// **'Nota (opcional)'**
  String get savingsNotePlaceholder;

  /// No description provided for @today.
  ///
  /// In ca, this message translates to:
  /// **'Avui'**
  String get today;

  /// No description provided for @accountLabel.
  ///
  /// In ca, this message translates to:
  /// **'Compte'**
  String get accountLabel;

  /// No description provided for @noAccountsAvailable.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha comptes líquids disponibles'**
  String get noAccountsAvailable;

  /// No description provided for @selectAccount.
  ///
  /// In ca, this message translates to:
  /// **'Selecciona un compte'**
  String get selectAccount;

  /// No description provided for @noAccount.
  ///
  /// In ca, this message translates to:
  /// **'Sense compte'**
  String get noAccount;

  /// No description provided for @insufficientFunds.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha prous fons a la guardiola'**
  String get insufficientFunds;
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
      'that was used.');
}
