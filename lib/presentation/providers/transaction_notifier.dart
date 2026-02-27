import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../domain/models/transaction.dart';
import '../../data/providers/repository_providers.dart';

import '../../domain/models/savings_goal.dart';
import 'auth_providers.dart';
import 'savings_goal_provider.dart';
import 'category_notifier.dart';
import 'asset_provider.dart';
import 'debt_provider.dart';

part 'transaction_notifier.g.dart';

@riverpod
class TransactionNotifier extends _$TransactionNotifier {
  @override
  Stream<List<Transaction>> build() {
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final groupId = userProfile?.currentGroupId;

    if (groupId == null) return Stream.value([]);

    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getAllTransactions(groupId).handleError((e) {
      if (e is FirebaseException && e.code == 'failed-precondition') {
        // Index missing.
      }
      // Return empty list to stop crash/loop
      return [];
    });
  }

  Future<void> addTransaction(Transaction transaction) async {
    final repository = ref.read(transactionRepositoryProvider);
    final savingsRepo = ref.read(savingsGoalRepositoryProvider);

    // 1. Spending from Savings
    if (transaction.savingsGoalId != null) {
      final goals = await ref.read(savingsGoalNotifierProvider.future);
      final goal = goals.firstWhere((g) => g.id == transaction.savingsGoalId);

      // Reduce goal amount
      final updatedGoal = goal.copyWith(
        currentAmount: goal.currentAmount - transaction.amount,
        history: [
          ...goal.history,
          SavingsEntry(
            date: transaction.date,
            amount: -transaction.amount, // Negative for expense
            note: 'Despesa: ${transaction.concept}',
          ),
        ],
      );
      await savingsRepo.updateSavingsGoal(updatedGoal);
    }

    // 2. Linked Fixed Expenses (Automatic Contribution)
    // We need to fetch the subcategory to check for links
    final categories = await ref.read(categoryNotifierProvider.future);
    String? linkedGoalId;
    String? linkedDebtId;

    for (var cat in categories) {
      for (var sub in cat.subcategories) {
        if (sub.id == transaction.subCategoryId) {
          linkedGoalId = sub.linkedSavingsGoalId;
          linkedDebtId = sub.linkedDebtId;
          break;
        }
      }
      if (linkedGoalId != null || linkedDebtId != null) break;
    }

    if (linkedGoalId != null) {
      // Linked expense = contribution TO goal (add)
      // Linked income = withdrawal FROM goal (subtract)
      final goals = await ref.read(savingsGoalNotifierProvider.future);
      try {
        final goal = goals.firstWhere((g) => g.id == linkedGoalId);
        final isWithdrawal = transaction.isIncome;
        final effectiveAmount =
            isWithdrawal ? -transaction.amount : transaction.amount;
        final updatedGoal = goal.copyWith(
          currentAmount: goal.currentAmount + effectiveAmount,
          history: [
            ...goal.history,
            SavingsEntry(
              date: transaction.date,
              amount: effectiveAmount,
              note: isWithdrawal
                  ? 'Retirada automàtica: ${transaction.concept}'
                  : 'Aportació automàtica: ${transaction.concept}',
            ),
          ],
        );
        await savingsRepo.updateSavingsGoal(updatedGoal);
      } catch (e) {
        // Goal not found or error, ignore to not block transaction creation
        debugPrint('Error updating linked goal: $e');
      }
    }

    // 3. Linked Debt (Directly reduce debt balance)
    if (linkedDebtId != null) {
      try {
        final debts = await ref.read(debtNotifierProvider.future);
        final debt = debts.firstWhere((d) => d.id == linkedDebtId);

        // Expense reduces debt. Income increases debt.
        // Usually it's an expense (debt payment), so we subtract from currentBalance
        final delta =
            transaction.isIncome ? transaction.amount : -transaction.amount;

        await ref.read(debtNotifierProvider.notifier).updateDebt(
              debt.copyWith(currentBalance: debt.currentBalance + delta),
            );
      } catch (e) {
        debugPrint('Error updating linked debt balance: $e');
      }
    }

    // 4. Update linked account balance
    if (transaction.accountId != null) {
      try {
        final assets = await ref.read(assetNotifierProvider.future);
        final asset = assets.firstWhere((a) => a.id == transaction.accountId);
        final delta =
            transaction.isIncome ? transaction.amount : -transaction.amount;
        await ref.read(assetNotifierProvider.notifier).updateAsset(
              asset.copyWith(amount: asset.amount + delta),
            );
      } catch (e) {
        debugPrint('Error updating account balance on add: $e');
      }
    }

    await repository.addTransaction(transaction);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final repository = ref.read(transactionRepositoryProvider);

    // Calculate balance difference if account changed or amount changed
    // We need to fetch the OLD transaction to compute the diff
    try {
      final allTransactions =
          await ref.read(transactionNotifierProvider.future);
      final oldTx = allTransactions.firstWhere((t) => t.id == transaction.id);

      // Reverse old effect
      if (oldTx.accountId != null) {
        final assets = await ref.read(assetNotifierProvider.future);
        try {
          final oldAsset = assets.firstWhere((a) => a.id == oldTx.accountId);
          final oldDelta = oldTx.isIncome ? -oldTx.amount : oldTx.amount;
          await ref.read(assetNotifierProvider.notifier).updateAsset(
                oldAsset.copyWith(amount: oldAsset.amount + oldDelta),
              );
        } catch (_) {}
      }

      // Apply new effect
      if (transaction.accountId != null) {
        final assets = await ref.read(assetNotifierProvider.future);
        try {
          final newAsset =
              assets.firstWhere((a) => a.id == transaction.accountId);
          final newDelta =
              transaction.isIncome ? transaction.amount : -transaction.amount;
          await ref.read(assetNotifierProvider.notifier).updateAsset(
                newAsset.copyWith(amount: newAsset.amount + newDelta),
              );
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error updating account balance on edit: $e');
    }

    await repository.updateTransaction(transaction);
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    final repository = ref.read(transactionRepositoryProvider);
    final savingsRepo = ref.read(savingsGoalRepositoryProvider);

    // 1. Reverse "Spending from Savings" — re-add the amount
    if (transaction.savingsGoalId != null) {
      try {
        final goals = await ref.read(savingsGoalNotifierProvider.future);
        final goal = goals.firstWhere((g) => g.id == transaction.savingsGoalId);
        final updatedGoal = goal.copyWith(
          currentAmount: goal.currentAmount + transaction.amount,
          history: [
            ...goal.history,
            SavingsEntry(
              date: DateTime.now(),
              amount: transaction.amount,
              note: 'Revertit: ${transaction.concept}',
            ),
          ],
        );
        await savingsRepo.updateSavingsGoal(updatedGoal);
      } catch (e) {
        debugPrint('Error reversing savings spending on delete: $e');
      }
    }

    // 2. Reverse linked subcategory effects
    final categories = await ref.read(categoryNotifierProvider.future);
    String? linkedGoalId;
    String? linkedDebtId;

    for (var cat in categories) {
      for (var sub in cat.subcategories) {
        if (sub.id == transaction.subCategoryId) {
          linkedGoalId = sub.linkedSavingsGoalId;
          linkedDebtId = sub.linkedDebtId;
          break;
        }
      }
      if (linkedGoalId != null || linkedDebtId != null) break;
    }

    // 2a. Reverse linked savings goal effect
    if (linkedGoalId != null) {
      try {
        final goals = await ref.read(savingsGoalNotifierProvider.future);
        final goal = goals.firstWhere((g) => g.id == linkedGoalId);
        // Reverse: if original was income (withdrawal, -amount), reverse = add back
        //          if original was expense (contribution, +amount), reverse = subtract
        final wasWithdrawal = transaction.isIncome;
        final reverseAmount =
            wasWithdrawal ? transaction.amount : -transaction.amount;
        final updatedGoal = goal.copyWith(
          currentAmount: goal.currentAmount + reverseAmount,
          history: [
            ...goal.history,
            SavingsEntry(
              date: DateTime.now(),
              amount: reverseAmount,
              note: 'Revertit: ${transaction.concept}',
            ),
          ],
        );
        await savingsRepo.updateSavingsGoal(updatedGoal);
      } catch (e) {
        debugPrint('Error reversing linked goal contribution: $e');
      }
    }

    // 2b. Reverse linked debt balance effect
    if (linkedDebtId != null) {
      try {
        final debts = await ref.read(debtNotifierProvider.future);
        final debt = debts.firstWhere((d) => d.id == linkedDebtId);

        // Reverse: if it was an expense (payment), we subtracted it, so now we add it back.
        final delta =
            transaction.isIncome ? -transaction.amount : transaction.amount;

        await ref.read(debtNotifierProvider.notifier).updateDebt(
              debt.copyWith(currentBalance: debt.currentBalance + delta),
            );
      } catch (e) {
        debugPrint('Error reversing linked debt balance: $e');
      }
    }

    // 3. Reverse linked account balance
    if (transaction.accountId != null) {
      try {
        final assets = await ref.read(assetNotifierProvider.future);
        final asset = assets.firstWhere((a) => a.id == transaction.accountId);
        final delta =
            transaction.isIncome ? -transaction.amount : transaction.amount;
        await ref.read(assetNotifierProvider.notifier).updateAsset(
              asset.copyWith(amount: asset.amount + delta),
            );
      } catch (e) {
        debugPrint('Error reversing account balance on delete: $e');
      }
    }

    await repository.deleteTransaction(transaction);
  }
}
