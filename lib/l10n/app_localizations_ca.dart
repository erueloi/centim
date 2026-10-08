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
  String get withdrawFunds => 'Retirar';

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
  String get withdrawTitle => 'Retirar fons';

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

  @override
  String get heatmapTotal => 'TOTAL';

  @override
  String get heatmapCycleRange => 'Rang de cicles';

  @override
  String get heatmapAllCycles => 'Tots';

  @override
  String get billingCyclesLabel => 'Cicles de Facturació';

  @override
  String get categoriesLabel => 'Categories';

  @override
  String get coachChatTitle => 'Cèntim Coach';

  @override
  String get coachChatWelcome =>
      'Hola! 👋 Sóc el teu coach financer. Pregunta\'m qualsevol cosa sobre els teus moviments, pressupostos o estalvis.';

  @override
  String get coachChatHint => 'Escriu la teva pregunta...';

  @override
  String get coachSuggestion1 => 'Quant vaig gastar de menjar el mes passat?';

  @override
  String get coachSuggestion2 =>
      'Quines categories estan per sobre del pressupost?';

  @override
  String get coachSuggestion3 => 'Quin és el meu estalvi mitjà?';

  @override
  String get coachAskButton => 'Pregunta al Coach';

  @override
  String get coachNewConversation => 'Nova conversa';

  @override
  String get contributeButton => 'Aportar';

  @override
  String get contributeTitle => 'Aportar a la guardiola';

  @override
  String get contributeMessage => 'Quant vols aportar a aquesta guardiola?';

  @override
  String get contributeAmountLabel => 'Import a aportar (€)';

  @override
  String contributedSuccess(Object amount) {
    return 'Aportat $amount€ correctament.';
  }

  @override
  String get adjustBalanceHint =>
      'Aquest ajust crearà un moviment de balanç automàtic';

  @override
  String get savingsNotePlaceholder => 'Nota (opcional)';

  @override
  String get today => 'Avui';

  @override
  String get accountLabel => 'Compte';

  @override
  String get noAccountsAvailable => 'No hi ha comptes líquids disponibles';

  @override
  String get selectAccount => 'Selecciona un compte';

  @override
  String get noAccount => 'Sense compte';

  @override
  String get insufficientFunds => 'No hi ha prous fons a la guardiola';

  @override
  String get annualViewTab => 'Anual';

  @override
  String get annualCostQuestion => 'Quant em costa la vida a l\'any i on va?';

  @override
  String get annualExpenseTotal => 'Despesa Anual Total';

  @override
  String get annualMonthlyAverage => 'Mitjana Mensual';

  @override
  String get annualRealSpent => 'Real acumulat';

  @override
  String get annualProjected => 'Projecció restant';

  @override
  String get annualDebtService => 'Servei de Deute Bancari';

  @override
  String annualDebtServicePct(Object percent) {
    return '$percent% de la despesa anual';
  }

  @override
  String annualDebtServiceMonthly(Object amount) {
    return '$amount/mes de quota';
  }

  @override
  String get annualExportSummary => 'Compartir Resum';

  @override
  String get annualExportCsv => 'Exportar CSV';

  @override
  String get annualSummaryCopied => 'Resum copiat al portapapers!';

  @override
  String get annualNoData => 'No hi ha dades de despesa per a aquest any.';

  @override
  String get annualYoYDelta => 'vs any anterior';

  @override
  String get annualPerMonth => '€/mes';

  @override
  String get annualPerYear => '€/any';

  @override
  String annualRealBadge(Object amount, Object count) {
    return 'Real (${count}m): $amount';
  }

  @override
  String annualProjectedBadge(Object amount, Object count) {
    return 'Projecció (${count}m): $amount';
  }

  @override
  String get showPassword => 'Mostra la contrasenya';

  @override
  String get hidePassword => 'Amaga la contrasenya';

  @override
  String get forgotPasswordButton => 'Has oblidat la contrasenya?';

  @override
  String get resetPasswordTitle => 'Restableix la contrasenya';

  @override
  String get resetPasswordBody =>
      'Introdueix el teu correu i t\'enviarem un enllaç per triar una contrasenya nova.';

  @override
  String get resetPasswordSendButton => 'Envia l\'enllaç';

  @override
  String get resetPasswordSent =>
      'Si hi ha un compte amb aquest correu, rebràs un enllaç per restablir la contrasenya. Revisa també la carpeta de correu brossa.';

  @override
  String get authErrorInvalidCredentials =>
      'El correu o la contrasenya no són correctes.';

  @override
  String get authErrorEmailInUse =>
      'Ja hi ha un compte amb aquest correu. Inicia la sessió o recupera la contrasenya.';

  @override
  String get authErrorWeakPassword =>
      'La contrasenya ha de tenir almenys 6 caràcters.';

  @override
  String get authErrorInvalidEmail => 'El correu electrònic no és vàlid.';

  @override
  String get authErrorTooManyRequests =>
      'Massa intents seguits. Espera una estona i torna-ho a provar.';

  @override
  String get authErrorNetwork =>
      'No hi ha connexió. Revisa la xarxa i torna-ho a provar.';

  @override
  String get authErrorGeneric =>
      'No s\'ha pogut completar l\'operació. Torna-ho a provar.';

  @override
  String get bankNotEnabledForGroup =>
      'La connexió bancària encara no està disponible per al teu grup.';

  @override
  String get bankNoAppTitle => 'El grup encara no té connexió bancària';

  @override
  String get bankNoAppForGroup =>
      'El teu grup encara no té configurada la connexió bancària.';

  @override
  String get bankNoAppMember =>
      'Demana a l\'owner del grup que configuri la connexió bancària.';

  @override
  String get bankWizardIntro =>
      'Cada grup fa servir la seva pròpia aplicació d\'Enable Banking. Com a owner, la configures en tres passos.';

  @override
  String get bankWizardStep1Title => 'Crea l\'aplicació a Enable Banking';

  @override
  String get bankWizardStep1Body =>
      'Al panell d\'Enable Banking (Control panel → API applications), registra una aplicació de tipus Production. Tria generar la clau privada al navegador i desa el fitxer .pem en un lloc segur. Fes servir aquests valors:';

  @override
  String get bankWizardRedirectUrl => 'Redirect URL';

  @override
  String get bankWizardPrivacyUrl => 'URL de privacitat';

  @override
  String get bankWizardTermsUrl => 'URL de condicions';

  @override
  String get bankWizardDescription => 'Descripció';

  @override
  String get bankWizardDescriptionValue =>
      'Cèntim: finances de la llar. Llegeix els comptes de la família per importar-ne els moviments.';

  @override
  String get bankWizardOpenPanel => 'Obre Enable Banking';

  @override
  String get bankWizardStep2Title => 'Enllaça els comptes';

  @override
  String get bankWizardStep2Body =>
      'A la teva aplicació del panell, fes «Link accounts»: tria el país, el banc i el tipus «personal», i autentica\'t al teu banc. Per als comptes dels altres membres, fes tu el Link i deixa que cada membre s\'autentiqui al seu banc i ho accepti.';

  @override
  String get bankWizardStep3Title => 'Enganxa l\'id i la clau';

  @override
  String get bankWizardNext => 'Continua';

  @override
  String get bankWizardBack => 'Enrere';

  @override
  String get bankAppIdLabel => 'Id de l\'aplicació';

  @override
  String get bankPemLabel => 'Clau privada (.pem)';

  @override
  String get bankPemUpload => 'Puja el fitxer .pem';

  @override
  String bankPemLoaded(Object fileName) {
    return 'Fitxer carregat: $fileName';
  }

  @override
  String get bankCheckAndSave => 'Comprova i desa';

  @override
  String get bankCredentialsHint =>
      'La clau es comprova amb Enable Banking i es desa xifrada. Ningú, ni tu, la podrà tornar a veure des de Cèntim.';

  @override
  String get bankSaved => 'Aplicació del grup desada.';

  @override
  String bankSavedReconnect(Object count) {
    return 'Aplicació desada. Connexions que cal tornar a connectar: $count.';
  }

  @override
  String get bankCopy => 'Copia';

  @override
  String get bankCopied => 'Copiat.';

  @override
  String get bankRestrictedNotice =>
      'Només es poden llegir els comptes enllaçats al panell d\'Enable Banking del grup.';

  @override
  String get bankHelpLink => 'Com configurar la connexió bancària';

  @override
  String get bankAppStatusTitle => 'Aplicació d\'Enable Banking del grup';

  @override
  String bankAppStatusLine(Object appId, Object date, Object env) {
    return '$appId · $env · validada el $date';
  }

  @override
  String get bankEnvProduction => 'Producció';

  @override
  String get bankEnvSandbox => 'Sandbox';

  @override
  String get bankChangeCredentials => 'Canvia les credencials';

  @override
  String get bankDeleteCredentials => 'Elimina';

  @override
  String get bankDeleteConfirmTitle => 'Eliminar l\'aplicació del grup?';

  @override
  String get bankDeleteConfirmBody =>
      'Es tancaran les connexions bancàries de tots els membres i caldrà tornar-les a connectar quan configuris una aplicació nova.';

  @override
  String get bankDeleted => 'Aplicació del grup eliminada.';

  @override
  String get bankLegacyNotice =>
      'El grup encara fa servir l\'aplicació compartida antiga. Configura la vostra: amb el mateix id i la mateixa clau, no caldrà reconnectar cap banc.';

  @override
  String get bankSetupOwnApp => 'Configura l\'aplicació del grup';

  @override
  String get bankAccessibleAccountsTitle => 'Comptes accessibles';

  @override
  String get bankAccessibleAccountsBody =>
      'Comptes ja connectats pels membres del grup. No és la llista del panell d\'Enable Banking: si en falta algun, cal enllaçar-lo al panell i connectar-lo des de Cèntim.';

  @override
  String get bankNoAccessibleAccounts =>
      'Encara no hi ha cap compte connectat.';

  @override
  String get bankNeedsReconnect => 'Cal reconnectar';

  @override
  String get bankReasonAppChanged =>
      'S\'ha canviat l\'aplicació d\'Enable Banking del grup.';

  @override
  String get bankReasonAppRemoved =>
      'S\'ha eliminat l\'aplicació d\'Enable Banking del grup.';

  @override
  String get bankReasonLeftGroup => 'És d\'abans que sortissis del grup.';

  @override
  String get bankReconnect => 'Reconnecta';

  @override
  String get bankAddConnection => 'Afegeix una connexió';

  @override
  String get bankNoConnections => 'Encara no has connectat cap banc.';

  @override
  String get bankPickTitle => 'Tria el teu banc';

  @override
  String get bankPickCountry => 'País';

  @override
  String get bankPickSearch => 'Cerca el banc';

  @override
  String get bankPickEmpty => 'Cap banc coincideix amb la cerca.';

  @override
  String get bankPickBeta => 'beta';

  @override
  String get bankNoLinkedAccounts =>
      'Connexió feta, però el banc no ha retornat cap compte. Demana a l\'owner del grup que enllaci aquest compte al panell d\'Enable Banking (Link).';

  @override
  String get bankConnectionNeedsReconnect =>
      'Aquesta connexió s\'ha de tornar a connectar (Configuració → Banc / Sincronització).';
}
