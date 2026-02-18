import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../repositories/firestore_transaction_repository.dart';

import '../repositories/auth_repository.dart';
import '../repositories/group_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/debt_repository.dart';
import '../repositories/budget_entry_repository.dart';
import '../repositories/asset_repository.dart';
import '../../domain/repositories/billing_cycle_repository.dart';
import '../repositories/firestore_billing_cycle_repository.dart';
import '../repositories/firestore_savings_goal_repository.dart';
import '../repositories/transfer_repository.dart';

final billingCycleRepositoryProvider = Provider<BillingCycleRepository>((ref) {
  return FirestoreBillingCycleRepository();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  // Isar is no longer needed for transactions
  // final isar = ref.watch(isarProvider).valueOrNull;
  return FirestoreTransactionRepository();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepository();
});

final budgetEntryRepositoryProvider = Provider<BudgetEntryRepository>((ref) {
  return BudgetEntryRepository();
});

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository();
});

final savingsGoalRepositoryProvider = Provider<FirestoreSavingsGoalRepository>((
  ref,
) {
  return FirestoreSavingsGoalRepository();
});

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  return TransferRepository();
});
