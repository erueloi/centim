// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cèntim';

  @override
  String get quickAccessTitle => 'Quick Access';

  @override
  String get totalBalanceTitle => 'Total Balance';

  @override
  String get supermarketLabel => 'Supermarket';

  @override
  String get homeLabel => 'Home';

  @override
  String get renovationLabel => 'Renovation';

  @override
  String get entertainmentLabel => 'Entertainment';

  @override
  String get requiredError => 'Required';

  @override
  String get noActiveGroupError => 'No active group';

  @override
  String get noMembersError => 'No members in group';

  @override
  String get budgetScreenTitle => 'Budget Control';

  @override
  String get noBudgetAssignedText => 'No budget assigned';

  @override
  String editBudgetTitle(Object category) {
    return '$category Budget';
  }

  @override
  String get monthlyGoalLabel => 'Monthly Goal (€)';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get editButton => 'Edit';

  @override
  String get sortBy => 'Sort by';

  @override
  String get catFood => 'Food';

  @override
  String get catTransport => 'Transport';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catEntertainment => 'Entertainment';

  @override
  String get catHealth => 'Health';

  @override
  String get catEducation => 'Education';

  @override
  String get catBills => 'Bills';

  @override
  String get catOther => 'Other';

  @override
  String get loginTitle => 'Login';

  @override
  String get registerTitle => 'Register';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInButton => 'Sign In';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get noAccountText => 'Don\'t have an account? Sign up';

  @override
  String get alreadyHaveAccountText => 'Already have an account? Sign in';

  @override
  String get setupGroupTitle => 'Family Group Setup';

  @override
  String get createGroupTitle => 'Create a new group';

  @override
  String get groupNameLabel => 'Group Name';

  @override
  String get createGroupButton => 'Create Group';

  @override
  String get orJoinGroupText => 'Or join an existing group';

  @override
  String get groupIdLabel => 'Invitation Code';

  @override
  String get joinGroupButton => 'Join Group';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get transactionsTab => 'Transactions';

  @override
  String get budgetTab => 'Budgets';

  @override
  String get profileTab => 'Profile';

  @override
  String get addTransactionTitle => 'Add Transaction';

  @override
  String get saveTransactionButton => 'Save Transaction';

  @override
  String get amountLabel => 'Amount';

  @override
  String get conceptLabel => 'Concept';

  @override
  String get categoryLabel => 'Category';

  @override
  String get payerLabel => 'Payer';

  @override
  String get dateLabel => 'Date';

  @override
  String get loadingText => 'Loading...';

  @override
  String errorText(Object error) {
    return 'Error: $error';
  }

  @override
  String get googleSignInButton => 'Continue with Google';

  @override
  String get googleSignInError =>
      'An error occurred while signing in with Google';

  @override
  String get mainCategoryLabel => 'Main Category';

  @override
  String get subCategoryLabel => 'Subcategory';

  @override
  String get expenseLabel => 'Expense';

  @override
  String get incomeLabel => 'Income';

  @override
  String get panoramicTitle => 'Panoramic';

  @override
  String get resetFilters => 'Reset filters';

  @override
  String get savingsTotal => 'Savings Summary';

  @override
  String get savingsAportat => 'Contributed';

  @override
  String get savingsRescatat => 'Withdrawn';

  @override
  String get savingsNet => 'Net';

  @override
  String get howItWorks => 'How does Cèntim work?';

  @override
  String get newTransaction => 'New Movement';

  @override
  String get expenseOrIncome => 'Expense or income';

  @override
  String get newTransfer => 'New Transfer';

  @override
  String get transferDescription => 'Move money between accounts or pay debts';

  @override
  String get navHome => 'Home';

  @override
  String get navDetail => 'Detail';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navBudget => 'Budget';

  @override
  String get navWealth => 'Wealth';

  @override
  String cycleClosedMessage(Object name) {
    return '$name\'s cycle closed. Welcome to the new month!';
  }

  @override
  String get cycleHistoryTooltip => 'Cycle History';

  @override
  String get cycleSettingsTooltip => 'Cycle Settings';

  @override
  String get profileTooltip => 'Profile';

  @override
  String get endOfMonthBanner =>
      'The end of the month is near. Have you already received your salary?';

  @override
  String get notYet => 'Not yet';

  @override
  String get startNewMonth => 'YES, START NEW MONTH';

  @override
  String get alreadyPaid => 'I\'ve already been paid!';

  @override
  String get confirmSalary => '💰 Confirm salary';

  @override
  String get salaryConfirmationMessage =>
      'Have you received your salary? This will close the current cycle and open a new one.';

  @override
  String get yesPaid => 'Yes, I\'ve been paid!';

  @override
  String get noCategories => 'No categories';

  @override
  String get whereExpense => 'Where did you spend the money?';

  @override
  String get whereIncome => 'Where does the income come from?';

  @override
  String get assetsTitle => 'Assets';

  @override
  String get liabilitiesTitle => 'Liabilities';

  @override
  String get savingsTitle => 'Savings Goals';

  @override
  String get netWorth => 'My Net Worth';

  @override
  String get totalAssetsLabel => 'Asset';

  @override
  String get totalLiabilitiesLabel => 'Liability';

  @override
  String get noAssets => 'You have no assets registered.';

  @override
  String get noDebts => 'You have no debts registered.';

  @override
  String get noGoals => 'You have no savings goals.';

  @override
  String get addAsset => 'Add Asset';

  @override
  String get addDebt => 'Add Debt';

  @override
  String get addGoal => 'Create Savings Jar';

  @override
  String get editGoal => 'Edit Savings Jar';

  @override
  String get newGoal => 'New Savings Jar';

  @override
  String get goalUpdated => 'Savings jar updated!';

  @override
  String get goalCreated => 'Savings jar created correctly!';

  @override
  String get goalNameLabel => 'Goal name';

  @override
  String get goalNameHint => 'Ex: Trip to Japan';

  @override
  String get enterName => 'Enter a name';

  @override
  String get enterAmount => 'Enter an amount';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get goalTargetAmountLabel => 'Target Amount (€)';

  @override
  String get simulateAmortization => 'Simulate Amortization';

  @override
  String get debtBank => 'Bank Entity';

  @override
  String get debtBankName => 'Bank Name';

  @override
  String get debtInitialAmount => 'Initial Amount';

  @override
  String get debtPending => 'Pending';

  @override
  String get debtInterest => 'Interest';

  @override
  String get debtInstallment => 'Monthly Installment';

  @override
  String get debtMaturity => 'Maturity Date';

  @override
  String debtMaturityLabel(Object date) {
    return 'Maturity: $date';
  }

  @override
  String get assetValuation => 'Current Valuation';

  @override
  String get assetType => 'Asset Type';

  @override
  String get assetTypeRealEstate => 'Real Estate';

  @override
  String get assetTypeBankAccount => 'Bank Account';

  @override
  String get assetTypeCash => 'Cash';

  @override
  String get assetTypeOther => 'Other';

  @override
  String get goalIcon => 'Icon (Emoji)';

  @override
  String get goalHasTarget => 'Does it have a target amount?';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get adjustBalance => 'Adjust Balance';

  @override
  String get withdrawFunds => 'Withdraw';

  @override
  String get adjustBalanceTitle => 'Adjust balance';

  @override
  String get adjustBalanceMessage =>
      'This adjustment will record a movement to square the current balance of the savings jar.';

  @override
  String get newBalanceLabel => 'New current balance (€)';

  @override
  String get balanceAdjusted => 'Balance adjusted correctly.';

  @override
  String get withdrawTitle => 'Withdraw funds';

  @override
  String get withdrawMessage =>
      'These funds will be moved to your main wallet as income.';

  @override
  String get withdrawAmountLabel => 'Amount to withdraw (€)';

  @override
  String get destinationAccount => 'Destination account';

  @override
  String get unspecifiedAccount => 'Unspecified';

  @override
  String get notEnoughFunds =>
      'You don\'t have enough funds in the savings jar.';

  @override
  String withdrawalConcept(Object goalName) {
    return 'Withdrawal from $goalName';
  }

  @override
  String withdrawnSuccess(Object amount) {
    return 'Withdrawn $amount€ correctly.';
  }

  @override
  String get noMovementsYet => 'No movements yet.';

  @override
  String get contributionLabel => 'Contribution';

  @override
  String get movementsTitle => 'Movements';

  @override
  String get importCSV => 'Import CSV (CaixaBank)';

  @override
  String get noMovementsFound => 'No movements found or selection cancelled';

  @override
  String get migrateOldMovements => 'Migrate Old Movements';

  @override
  String get allUpdated => 'All movements are up to date ✅';

  @override
  String get noLiquidAccounts => 'No liquid accounts available';

  @override
  String foundOrphaned(Object count) {
    return '$count movements found without an assigned account. Which account do you want to link them to?';
  }

  @override
  String migrateSuccess(Object count) {
    return 'Migration completed successfully! $count movements updated.';
  }

  @override
  String get tabAll => 'All';

  @override
  String get tabFixed => 'Fixed';

  @override
  String get searchHint => 'Search movements...';

  @override
  String get noResultsFilter => 'No movement matches the filters';

  @override
  String get noResultsCycle => 'No movements in this cycle';

  @override
  String resultsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get deleteMovementTitle => 'Delete movement?';

  @override
  String get cannotBeUndone => 'This action cannot be undone.';

  @override
  String get deleteTransferTitle => 'Delete transfer';

  @override
  String get deleteTransferConfirm =>
      'Are you sure you want to delete this transfer? Balances will be restored automatically.';

  @override
  String get transferDeleted => 'Transfer deleted successfully';

  @override
  String get deleteButton => 'Delete';

  @override
  String get migrateButton => 'Migrate';

  @override
  String get chooseColor => 'Choose a color';

  @override
  String get debtLabel => 'Debt';

  @override
  String get goalLabel => 'Goal';

  @override
  String get advancedFilters => 'Advanced Filters';

  @override
  String get type => 'Type';

  @override
  String get all => 'All';

  @override
  String get categories => 'Categories';

  @override
  String get subCategories => 'Subcategories';

  @override
  String get payer => 'Payer';

  @override
  String get amountRange => 'Amount range';

  @override
  String get minimum => 'Minimum';

  @override
  String get maximum => 'Maximum';

  @override
  String get dateRange => 'Date range';

  @override
  String get from => 'From...';

  @override
  String get to => 'To...';

  @override
  String get clear => 'Clear';

  @override
  String get clearAll => 'Clear all';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get allFixedPaid => 'All fixed expenses paid!';

  @override
  String get allUpToDate => 'Everything is up to date this month.';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String paymentOf(Object name) {
    return 'Payment of $name';
  }

  @override
  String get heatmapTotal => 'TOTAL';

  @override
  String get heatmapCycleRange => 'Cycle range';

  @override
  String get heatmapAllCycles => 'All';

  @override
  String get billingCyclesLabel => 'Billing Cycles';

  @override
  String get categoriesLabel => 'Categories';

  @override
  String get coachChatTitle => 'Cèntim Coach';

  @override
  String get coachChatWelcome =>
      'Hi! 👋 I\'m your financial coach. Ask me anything about your movements, budgets or savings.';

  @override
  String get coachChatHint => 'Type your question...';

  @override
  String get coachSuggestion1 => 'How much did I spend on food last month?';

  @override
  String get coachSuggestion2 => 'Which categories are over budget?';

  @override
  String get coachSuggestion3 => 'What\'s my average savings?';

  @override
  String get coachAskButton => 'Ask the Coach';

  @override
  String get coachNewConversation => 'New conversation';

  @override
  String get contributeButton => 'Contribute';

  @override
  String get contributeTitle => 'Contribute to savings';

  @override
  String get contributeMessage => 'How much do you want to contribute?';

  @override
  String get contributeAmountLabel => 'Amount to contribute (€)';

  @override
  String contributedSuccess(Object amount) {
    return 'Contributed $amount€ successfully.';
  }

  @override
  String get adjustBalanceHint =>
      'This adjustment will create an automatic balance movement';

  @override
  String get savingsNotePlaceholder => 'Note (optional)';

  @override
  String get today => 'Today';

  @override
  String get accountLabel => 'Account';

  @override
  String get noAccountsAvailable => 'No liquid accounts available';

  @override
  String get selectAccount => 'Select an account';

  @override
  String get noAccount => 'No account';

  @override
  String get insufficientFunds => 'Insufficient funds in the savings goal';

  @override
  String get annualViewTab => 'Annual';

  @override
  String get annualCostQuestion =>
      'How much does living cost me per year and where does it go?';

  @override
  String get annualExpenseTotal => 'Total Annual Expense';

  @override
  String get annualMonthlyAverage => 'Monthly Average';

  @override
  String get annualRealSpent => 'Real accumulated';

  @override
  String get annualProjected => 'Projected remaining';

  @override
  String get annualDebtService => 'Bank Debt Service';

  @override
  String annualDebtServicePct(Object percent) {
    return '$percent% of annual expense';
  }

  @override
  String annualDebtServiceMonthly(Object amount) {
    return '$amount/mo installment';
  }

  @override
  String get annualExportSummary => 'Share Summary';

  @override
  String get annualExportCsv => 'Export CSV';

  @override
  String get annualSummaryCopied => 'Summary copied to clipboard!';

  @override
  String get annualNoData => 'No expense data for this year.';

  @override
  String get annualYoYDelta => 'vs previous year';

  @override
  String get annualPerMonth => '€/mo';

  @override
  String get annualPerYear => '€/yr';

  @override
  String annualRealBadge(Object amount, Object count) {
    return 'Real (${count}m): $amount';
  }

  @override
  String annualProjectedBadge(Object amount, Object count) {
    return 'Projected (${count}m): $amount';
  }

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPasswordButton => 'Forgot your password?';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordBody =>
      'Enter your email and we\'ll send you a link to choose a new password.';

  @override
  String get resetPasswordSendButton => 'Send link';

  @override
  String get resetPasswordSent =>
      'If an account exists for this email, you\'ll receive a link to reset your password. Check your spam folder too.';

  @override
  String get authErrorInvalidCredentials =>
      'The email or password is incorrect.';

  @override
  String get authErrorEmailInUse =>
      'An account with this email already exists. Sign in or reset your password.';

  @override
  String get authErrorWeakPassword =>
      'The password must be at least 6 characters long.';

  @override
  String get authErrorInvalidEmail => 'The email address is not valid.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Wait a while and try again.';

  @override
  String get authErrorNetwork =>
      'No connection. Check your network and try again.';

  @override
  String get authErrorGeneric =>
      'The operation could not be completed. Please try again.';

  @override
  String get bankNotEnabledForGroup =>
      'Bank connection is not available for your group yet.';

  @override
  String get bankNoAppTitle => 'Your group has no bank connection yet';

  @override
  String get bankNoAppForGroup =>
      'Your group has not set up the bank connection yet.';

  @override
  String get bankNoAppMember =>
      'Ask the group owner to set up the bank connection.';

  @override
  String get bankWizardIntro =>
      'Each group uses its own Enable Banking application. As the owner, you set it up in three steps.';

  @override
  String get bankWizardStep1Title => 'Create the application in Enable Banking';

  @override
  String get bankWizardStep1Body =>
      'In the Enable Banking control panel (Control panel → API applications), register a Production application. Choose to generate the private key in the browser and keep the .pem file somewhere safe. Use these values:';

  @override
  String get bankWizardRedirectUrl => 'Redirect URL';

  @override
  String get bankWizardPrivacyUrl => 'Privacy URL';

  @override
  String get bankWizardTermsUrl => 'Terms URL';

  @override
  String get bankWizardDescription => 'Description';

  @override
  String get bankWizardDescriptionValue =>
      'Cèntim: household finances. Reads the family\'s accounts to import their transactions.';

  @override
  String get bankWizardOpenPanel => 'Open Enable Banking';

  @override
  String get bankWizardStep2Title => 'Link the accounts';

  @override
  String get bankWizardStep2Body =>
      'In your application in the panel, use \"Link accounts\": choose the country, the bank and the \"personal\" type, and sign in to your bank. For the other members\' accounts, you start the Link and each member signs in to their bank and accepts.';

  @override
  String get bankWizardStep3Title => 'Paste the id and the key';

  @override
  String get bankWizardNext => 'Continue';

  @override
  String get bankWizardBack => 'Back';

  @override
  String get bankAppIdLabel => 'Application id';

  @override
  String get bankPemLabel => 'Private key (.pem)';

  @override
  String get bankPemUpload => 'Upload the .pem file';

  @override
  String bankPemLoaded(Object fileName) {
    return 'File loaded: $fileName';
  }

  @override
  String get bankCheckAndSave => 'Check and save';

  @override
  String get bankCredentialsHint =>
      'The key is checked with Enable Banking and stored encrypted. Nobody, not even you, will be able to see it again from Cèntim.';

  @override
  String get bankSaved => 'Group application saved.';

  @override
  String bankSavedReconnect(Object count) {
    return 'Application saved. Connections that must be reconnected: $count.';
  }

  @override
  String get bankCopy => 'Copy';

  @override
  String get bankCopied => 'Copied.';

  @override
  String get bankRestrictedNotice =>
      'Only the accounts linked in the group\'s Enable Banking panel can be read.';

  @override
  String get bankHelpLink => 'How to set up the bank connection';

  @override
  String get bankAppStatusTitle => 'Group\'s Enable Banking application';

  @override
  String bankAppStatusLine(Object appId, Object date, Object env) {
    return '$appId · $env · validated on $date';
  }

  @override
  String get bankEnvProduction => 'Production';

  @override
  String get bankEnvSandbox => 'Sandbox';

  @override
  String get bankChangeCredentials => 'Change credentials';

  @override
  String get bankDeleteCredentials => 'Delete';

  @override
  String get bankDeleteConfirmTitle => 'Delete the group application?';

  @override
  String get bankDeleteConfirmBody =>
      'All members\' bank connections will be closed and will have to be reconnected once you set up a new application.';

  @override
  String get bankDeleted => 'Group application deleted.';

  @override
  String get bankLegacyNotice =>
      'The group still uses the old shared application. Set up your own: with the same id and key, no bank needs to be reconnected.';

  @override
  String get bankSetupOwnApp => 'Set up the group application';

  @override
  String get bankAccessibleAccountsTitle => 'Accessible accounts';

  @override
  String get bankAccessibleAccountsBody =>
      'Accounts already connected by group members. This is not the list in the Enable Banking panel: if one is missing, link it in the panel and connect it from Cèntim.';

  @override
  String get bankNoAccessibleAccounts => 'No account has been connected yet.';

  @override
  String get bankNeedsReconnect => 'Needs reconnecting';

  @override
  String get bankReasonAppChanged =>
      'The group\'s Enable Banking application has changed.';

  @override
  String get bankReasonAppRemoved =>
      'The group\'s Enable Banking application has been deleted.';

  @override
  String get bankReasonLeftGroup => 'It dates from before you left the group.';

  @override
  String get bankReconnect => 'Reconnect';

  @override
  String get bankAddConnection => 'Add a connection';

  @override
  String get bankNoConnections => 'You haven\'t connected any bank yet.';

  @override
  String get bankPickTitle => 'Choose your bank';

  @override
  String get bankPickCountry => 'Country';

  @override
  String get bankPickSearch => 'Search for your bank';

  @override
  String get bankPickEmpty => 'No bank matches your search.';

  @override
  String get bankPickBeta => 'beta';

  @override
  String get bankNoLinkedAccounts =>
      'Connected, but the bank returned no accounts. Ask the group owner to link this account in the Enable Banking panel (Link).';

  @override
  String get bankConnectionNeedsReconnect =>
      'This connection must be reconnected (Settings → Bank / Sync).';
}
