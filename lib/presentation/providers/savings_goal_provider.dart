import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/savings_goal.dart';
import '../../domain/models/transaction.dart';
import '../../data/providers/repository_providers.dart';

import 'auth_providers.dart';
import 'category_notifier.dart';

part 'savings_goal_provider.g.dart';

@riverpod
class SavingsGoalNotifier extends _$SavingsGoalNotifier {
  @override
  Stream<List<SavingsGoal>> build() {
    return _watchSavingsGoals();
  }

  Stream<List<SavingsGoal>> _watchSavingsGoals() async* {
    final groupId = await ref.watch(currentGroupIdProvider.future);
    if (groupId == null) {
      yield [];
      return;
    }
    final repo = ref.watch(savingsGoalRepositoryProvider);
    yield* repo.watchSavingsGoals(groupId);
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    final repo = ref.read(savingsGoalRepositoryProvider);
    await repo.addSavingsGoal(goal);
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    final repo = ref.read(savingsGoalRepositoryProvider);
    await repo.updateSavingsGoal(goal);
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    final repo = ref.read(savingsGoalRepositoryProvider);
    await repo.deleteSavingsGoal(goalId);
  }

  Future<void> addContribution(String goalId, double amount) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;

    final repo = ref.read(savingsGoalRepositoryProvider);
    final goals = await future;
    final goal = goals.firstWhere((g) => g.id == goalId);

    // 1. Update Goal
    final newEntry = SavingsEntry(
      date: DateTime.now(),
      amount: amount,
      note: 'Aportació ràpida',
    );
    final history = [...goal.history, newEntry];
    final updatedGoal = goal.copyWith(
      currentAmount: goal.currentAmount + amount,
      history: history,
    );
    await repo.updateSavingsGoal(updatedGoal);

    // 2. Find real category/subcategory linked to this goal
    final categories = await ref.read(categoryNotifierProvider.future);
    String categoryId = 'savings_category_id';
    String subCategoryId = 'contribution_sub';
    String categoryName = 'Estalvi';
    String subCategoryName = 'Aportació';

    for (var cat in categories) {
      for (var sub in cat.subcategories) {
        if (sub.linkedSavingsGoalId == goalId) {
          categoryId = cat.id;
          subCategoryId = sub.id;
          categoryName = cat.name;
          subCategoryName = sub.name;
          break;
        }
      }
    }

    final userProfile = ref.read(userProfileProvider).valueOrNull;
    final payer =
        userProfile?.name ?? userProfile?.email.split('@').first ?? 'User';

    final transactionRepo = ref.read(transactionRepositoryProvider);
    final transaction = Transaction(
      id: null, // Auto-generated
      groupId: groupId,
      date: DateTime.now(),
      amount: amount,
      concept: 'Aportació a ${goal.name}',
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      categoryName: categoryName,
      subCategoryName: subCategoryName,
      payer: payer,
      isIncome: false,
    );

    await transactionRepo.addTransaction(transaction);
  }

  /// Withdraw money from a savings goal.
  /// This only updates the goal balance and history.
  /// The transaction (income) is created separately by AddTransactionSheet._save.
  Future<void> withdrawFromGoal(
    String goalId,
    double amount, {
    String? concept,
  }) async {
    final repo = ref.read(savingsGoalRepositoryProvider);
    final goals = await future;
    final goal = goals.firstWhere((g) => g.id == goalId);

    final newEntry = SavingsEntry(
      date: DateTime.now(),
      amount: -amount, // Negative = withdrawal
      note: concept ?? 'Retirada',
    );
    final history = [...goal.history, newEntry];
    final updatedGoal = goal.copyWith(
      currentAmount: goal.currentAmount - amount,
      history: history,
    );
    await repo.updateSavingsGoal(updatedGoal);
  }

  Future<void> adjustBalance(String goalId, double newAmount) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;

    final repo = ref.read(savingsGoalRepositoryProvider);
    final goals = await future;
    final goal = goals.firstWhere((g) => g.id == goalId);

    if (newAmount == goal.currentAmount) return;

    final difference = newAmount - goal.currentAmount;

    // 1. Update Goal
    final newEntry = SavingsEntry(
      date: DateTime.now(),
      amount: difference,
      note: 'Ajust de saldo',
    );
    final history = [...goal.history, newEntry];
    final updatedGoal = goal.copyWith(
      currentAmount: newAmount,
      history: history,
    );
    await repo.updateSavingsGoal(updatedGoal);

  }
}
