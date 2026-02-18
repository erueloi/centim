// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitle => 'Cèntim';

  @override
  String get quickAccessTitle => 'Accés Ràpid';

  @override
  String get totalBalanceTitle => 'Saldo Total';

  @override
  String get supermarketLabel => 'Supermercat';

  @override
  String get homeLabel => 'Llar';

  @override
  String get renovationLabel => 'Reforma';

  @override
  String get entertainmentLabel => 'Oci';

  @override
  String get requiredError => 'Requerit';

  @override
  String get noActiveGroupError => 'Cap grup actiu';

  @override
  String get noMembersError => 'No hi ha membres al grup';

  @override
  String get budgetScreenTitle => 'Control Pressupostari';

  @override
  String get noBudgetAssignedText => 'Sense pressupost assignat';

  @override
  String editBudgetTitle(Object category) {
    return 'Pressupost $category';
  }

  @override
  String get monthlyGoalLabel => 'Objectiu Mensual (€)';

  @override
  String get cancelButton => 'Cancel·lar';

  @override
  String get saveButton => 'Guardar';

  @override
  String get catFood => 'Alimentació';

  @override
  String get catTransport => 'Transport';

  @override
  String get catShopping => 'Compres';

  @override
  String get catEntertainment => 'Oci';

  @override
  String get catHealth => 'Salut';

  @override
  String get catEducation => 'Educació';

  @override
  String get catBills => 'Factures';

  @override
  String get catOther => 'Altres';

  @override
  String get loginTitle => 'Inicia la sessió';

  @override
  String get registerTitle => 'Registra\'t';

  @override
  String get emailLabel => 'Correu electrònic';

  @override
  String get passwordLabel => 'Contrasenya';

  @override
  String get signInButton => 'Inicia la sessió';

  @override
  String get signUpButton => 'Registra\'t';

  @override
  String get noAccountText => 'No tens compte? Registra\'t';

  @override
  String get alreadyHaveAccountText => 'Ja tens compte? Inicia la sessió';

  @override
  String get setupGroupTitle => 'Configural del Grup Familiar';

  @override
  String get createGroupTitle => 'Crea un grup nou';

  @override
  String get groupNameLabel => 'Nom del Grup';

  @override
  String get createGroupButton => 'Crea Grup';

  @override
  String get orJoinGroupText => 'O uneix-te a un grup existent';

  @override
  String get groupIdLabel => 'Codi d\'Invitació';

  @override
  String get joinGroupButton => 'Uneix-te al Grup';

  @override
  String get dashboardTitle => 'Tauler';

  @override
  String get transactionsTab => 'Transaccions';

  @override
  String get budgetTab => 'Pressupostos';

  @override
  String get profileTab => 'Perfil';

  @override
  String get addTransactionTitle => 'Afegeix Transacció';

  @override
  String get saveTransactionButton => 'Desa Transacció';

  @override
  String get amountLabel => 'Import';

  @override
  String get conceptLabel => 'Concepte';

  @override
  String get categoryLabel => 'Categoria';

  @override
  String get payerLabel => 'Pagador';

  @override
  String get dateLabel => 'Data';

  @override
  String get loadingText => 'Carregant...';

  @override
  String errorText(Object error) {
    return 'Error: $error';
  }

  @override
  String get googleSignInButton => 'Continua amb Google';

  @override
  String get googleSignInError =>
      'S\'ha produït un error en iniciar sessió amb Google';

  @override
  String get mainCategoryLabel => 'Categoria Principal';

  @override
  String get subCategoryLabel => 'Subcategoria';

  @override
  String get expenseLabel => 'Despesa';

  @override
  String get incomeLabel => 'Ingrés';
}
