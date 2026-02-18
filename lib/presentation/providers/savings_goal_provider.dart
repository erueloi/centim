import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/savings_goal.dart';
import '../../domain/models/transaction.dart';
import '../../data/providers/repository_providers.dart';

import 'auth_providers.dart';

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

    // 2. Create Expense Transaction
    final transactionRepo = ref.read(transactionRepositoryProvider);
    // Ideally we should find the "Estalvi" category ID, but for now we'll use a placeholder or generic
    // In a real app we'd look up the category by name or use a constant ID
    const categoryId = 'savings_category_id'; // Placeholder
    const categoryName = 'Estalvi';

    final transaction = Transaction(
      id: null, // Auto-generated
      groupId: groupId,
      date: DateTime.now(),
      amount: amount,
      concept: 'Aportació a ${goal.name}',
      categoryId: categoryId,
      subCategoryId: 'contribution_sub',
      categoryName: categoryName,
      subCategoryName: 'Aportació',
      payer: 'User', // Should fetch current user name
      isIncome: false,
    );

    await transactionRepo.addTransaction(transaction);
  }
}
