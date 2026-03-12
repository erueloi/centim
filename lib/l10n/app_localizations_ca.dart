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
  String get editButton => 'Editar';

  @override
  String get sortBy => 'Ordenar per';

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

  @override
  String get panoramicTitle => 'Panoràmica';

  @override
  String get resetFilters => 'Restablir filtres';

  @override
  String get savingsTotal => 'Resum d\'Estalvi';

  @override
  String get savingsAportat => 'Aportat';

  @override
  String get savingsRescatat => 'Rescatat';

  @override
  String get savingsNet => 'Net';

  @override
  String get howItWorks => 'Com funciona Cèntim?';

  @override
  String get newTransaction => 'Nou Moviment';

  @override
  String get expenseOrIncome => 'Despesa o ingrés';

  @override
  String get newTransfer => 'Nova Transferència';

  @override
  String get transferDescription => 'Mou diners entre comptes o paga deutes';

  @override
  String get navHome => 'Inici';

  @override
  String get navDetail => 'Detall';

  @override
  String get navTransactions => 'Moviments';

  @override
  String get navBudget => 'Pressupost';

  @override
  String get navWealth => 'Patrimoni';

  @override
  String cycleClosedMessage(Object name) {
    return 'Cicle de $name tancat. Benvingut al nou mes!';
  }

  @override
  String get cycleHistoryTooltip => 'Historial de Cicles';

  @override
  String get cycleSettingsTooltip => 'Configuració de Cicles';

  @override
  String get profileTooltip => 'Perfil';

  @override
  String get endOfMonthBanner =>
      'S\'acosta final de mes. Has cobrat ja la nòmina?';

  @override
  String get notYet => 'Encara no';

  @override
  String get startNewMonth => 'SÍ, INICIAR NOU MES';

  @override
  String get alreadyPaid => 'Ja he cobrat!';

  @override
  String get confirmSalary => '💰 Confirmar nòmina';

  @override
  String get salaryConfirmationMessage =>
      'Has rebut la nòmina? Això tancarà el cicle actual i n\'obrirà un de nou.';

  @override
  String get yesPaid => 'Sí, he cobrat!';

  @override
  String get noCategories => 'No hi ha categories';

  @override
  String get whereExpense => 'On has fet la despesa?';

  @override
  String get whereIncome => 'D\'on prové l\'ingrés?';

  @override
  String get assetsTitle => 'Actius';

  @override
  String get liabilitiesTitle => 'Passius';

  @override
  String get savingsTitle => 'Objectius d\'Estalvi';

  @override
  String get netWorth => 'El meu Patrimoni';

  @override
  String get totalAssetsLabel => 'Actiu';

  @override
  String get totalLiabilitiesLabel => 'Passiu';

  @override
  String get noAssets => 'No tens cap actiu registrat.';

  @override
  String get noDebts => 'No tens cap deute registrat.';

  @override
  String get noGoals => 'No tens cap objectiu d\'estalvi.';

  @override
  String get addAsset => 'Afegir Actiu';

  @override
  String get addDebt => 'Afegir Deute';

  @override
  String get addGoal => 'Crear Guardiola';

  @override
  String get editGoal => 'Editar Guardiola';

  @override
  String get newGoal => 'Nova Guardiola';

  @override
  String get goalUpdated => 'Guardiola actualitzada!';

  @override
  String get goalCreated => 'Guardiola creada correctament!';

  @override
  String get goalNameLabel => 'Nom de l\'objectiu';

  @override
  String get goalNameHint => 'Ex: Viatge a Japó';

  @override
  String get enterName => 'Introdueix un nom';

  @override
  String get enterAmount => 'Introdueix un import';

  @override
  String get invalidAmount => 'Import invàlid';

  @override
  String get goalTargetAmountLabel => 'Import Objectiu (€)';

  @override
  String get simulateAmortization => 'Simular Amortització';

  @override
  String get debtBank => 'Entitat Bancària';

  @override
  String get debtBankName => 'Nom del Banc';

  @override
  String get debtInitialAmount => 'Import Inicial';

  @override
  String get debtPending => 'Pendent';

  @override
  String get debtInterest => 'Interès';

  @override
  String get debtInstallment => 'Quota Mensual';

  @override
  String get debtMaturity => 'Data de Venciment';

  @override
  String debtMaturityLabel(Object date) {
    return 'Venciment: $date';
  }

  @override
  String get assetValuation => 'Valoració Actual';

  @override
  String get assetType => 'Tipus d\'Actiu';

  @override
  String get assetTypeRealEstate => 'Immobiliari';

  @override
  String get assetTypeBankAccount => 'Compte Bancari';

  @override
  String get assetTypeCash => 'Efectiu';

  @override
  String get assetTypeOther => 'Altres';

  @override
  String get goalIcon => 'Icona (Emoji)';

  @override
  String get goalHasTarget => 'Té un import objectiu?';

  @override
  String get nameRequired => 'El nom és obligatori';

  @override
  String get adjustBalance => 'Quadrar Saldo';

  @override
  String get withdrawFunds => 'Retirar Fons';

  @override
  String get adjustBalanceTitle => 'Ajustar saldo';

  @override
  String get adjustBalanceMessage =>
      'Aquest ajust registrarà un moviment per quadrar el saldo actual de la guardiola.';

  @override
  String get newBalanceLabel => 'Nou saldo actual (€)';

  @override
  String get balanceAdjusted => 'Saldo ajustat correctament.';

  @override
  String get withdrawTitle => 'Retirar estalvis';

  @override
  String get withdrawMessage =>
      'Aquests fons es mouran a la teva cartera principal com a ingrés.';

  @override
  String get withdrawAmountLabel => 'Import a retirar (€)';

  @override
  String get destinationAccount => 'Compte destí';

  @override
  String get unspecifiedAccount => 'Sense especificar';

  @override
  String get notEnoughFunds => 'No tens prous fons a la guardiola.';

  @override
  String withdrawalConcept(Object goalName) {
    return 'Retirada de $goalName';
  }

  @override
  String withdrawnSuccess(Object amount) {
    return 'Retirats $amount€ correctament.';
  }

  @override
  String get noMovementsYet => 'Encara no hi ha moviments.';

  @override
  String get contributionLabel => 'Aportació';

  @override
  String get movementsTitle => 'Moviments';

  @override
  String get importCSV => 'Importar CSV (CaixaBank)';

  @override
  String get noMovementsFound =>
      'No s\'han trobat moviments o s\'ha cancel·lat la selecció';

  @override
  String get migrateOldMovements => 'Migrar Moviments Antics';

  @override
  String get allUpdated => 'Tots els moviments estan actualitzats ✅';

  @override
  String get noLiquidAccounts => 'No hi ha comptes líquids disponibles';

  @override
  String foundOrphaned(Object count) {
    return 'S\'han trobat $count moviments sense compte assignat. A quin compte els vols vincular?';
  }

  @override
  String migrateSuccess(Object count) {
    return 'Migració completada amb èxit! $count moviments actualitzats.';
  }

  @override
  String get tabAll => 'Tots';

  @override
  String get tabFixed => 'Fixes';

  @override
  String get searchHint => 'Buscar moviments...';

  @override
  String get noResultsFilter => 'Cap moviment coincideix amb els filtres';

  @override
  String get noResultsCycle => 'No hi ha moviments en aquest cicle';

  @override
  String resultsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultats',
      one: '1 resultat',
      zero: 'Cap resultat',
    );
    return '$_temp0';
  }

  @override
  String get deleteMovementTitle => 'Esborrar moviment?';

  @override
  String get cannotBeUndone => 'Aquesta acció no es pot desfer.';

  @override
  String get deleteTransferTitle => 'Eliminar traspàs';

  @override
  String get deleteTransferConfirm =>
      'Estàs segur que vols eliminar aquest traspàs? Els saldos es restauraran automàticament.';

  @override
  String get transferDeleted => 'Traspàs eliminat correctament';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get migrateButton => 'Migrar';

  @override
  String get chooseColor => 'Tria un color';

  @override
  String get debtLabel => 'Deute';

  @override
  String get goalLabel => 'Objectiu';

  @override
  String get advancedFilters => 'Filtres Avançats';

  @override
  String get type => 'Tipus';

  @override
  String get all => 'Tots';

  @override
  String get categories => 'Categories';

  @override
  String get subCategories => 'Subcategories';

  @override
  String get payer => 'Pagador';

  @override
  String get amountRange => 'Rang d\'import';

  @override
  String get minimum => 'Mínim';

  @override
  String get maximum => 'Màxim';

  @override
  String get dateRange => 'Rang de dates';

  @override
  String get from => 'Des de...';

  @override
  String get to => 'Fins a...';

  @override
  String get clear => 'Netejar';

  @override
  String get clearAll => 'Netejar tot';

  @override
  String get applyFilters => 'Aplicar Filtres';

  @override
  String get allFixedPaid => 'Totes les despeses fixes pagades!';

  @override
  String get allUpToDate => 'Aquest mes ja ho tens tot al dia.';

  @override
  String get income => 'Ingressos';

  @override
  String get expenses => 'Despeses';

  @override
  String paymentOf(Object name) {
    return 'Pagament de $name';
  }
}
