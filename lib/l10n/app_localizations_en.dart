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
    return 'Budget $category';
  }

  @override
  String get monthlyGoalLabel => 'Monthly Goal (€)';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

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
  String get noAccountText => 'No account? Sign Up';

  @override
  String get alreadyHaveAccountText => 'Already have an account? Sign In';

  @override
  String get setupGroupTitle => 'Setup Household Group';

  @override
  String get createGroupTitle => 'Create a new group';

  @override
  String get groupNameLabel => 'Group Name';

  @override
  String get createGroupButton => 'Create Group';

  @override
  String get orJoinGroupText => 'Or join an existing group';

  @override
  String get groupIdLabel => 'Invite Code';

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
}
