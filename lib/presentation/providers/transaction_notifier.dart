import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../domain/models/transaction.dart';
import '../../domain/models/savings_goal.dart';
import '../../domain/models/category.dart';
import '../../data/providers/repository_providers.dart';

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
    await _mutateSideEffects(add: transaction);
    await ref.read(transactionRepositoryProvider).addTransaction(transaction);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    // Recupera el moviment antic per revertir-ne els efectes i aplicar els nous.
    Transaction? oldTx;
    try {
      final all = await ref.read(transactionNotifierProvider.future);
      oldTx = all.firstWhere((t) => t.id == transaction.id);
    } catch (_) {
      oldTx = null;
    }

    await _mutateSideEffects(remove: oldTx, add: transaction);
    await ref.read(transactionRepositoryProvider).updateTransaction(transaction);
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await _mutateSideEffects(remove: transaction);
    await ref.read(transactionRepositoryProvider).deleteTransaction(transaction);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EFECTES LATERALS (guardiola / deute / compte)
  //
  // Font ÚNICA d'aplicació. add = +1, delete = −1, update = (vell −1) + (nou +1).
  // Els deltes s'acumulen PER ENTITAT i s'escriuen UN SOL COP, així:
  //  - cada moviment aplica l'ajust de guardiola una sola vegada (precedència
  //    savingsGoalId > subcategoria enllaçada), i
  //  - l'update no pateix curses de lectura (una escriptura neta per entitat).
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _mutateSideEffects({Transaction? add, Transaction? remove}) async {
    final categories = await ref.read(categoryNotifierProvider.future);

    // Un delta NET per entitat → una sola escriptura (i, a la guardiola, una
    // sola entrada de log amb el net; mai el patró revert+apply de dues línies).
    final goalDeltas = <String, double>{};
    final goalNotes = <String, String>{};
    final goalDates = <String, DateTime>{};
    final goalsWithRemove = <String>{};
    final assetDeltas = <String, double>{};
    final debtDeltas = <String, double>{};

    void accumulate(Transaction tx, int sign) {
      // 1. Guardiola (UN sol efecte, per precedència).
      final ge = _goalEffect(tx, categories);
      if (ge != null) {
        goalDeltas[ge.goalId] = (goalDeltas[ge.goalId] ?? 0) + sign * ge.delta;
        if (sign < 0) {
          goalsWithRemove.add(ge.goalId);
          goalNotes.putIfAbsent(ge.goalId, () => 'Revertit: ${tx.concept}');
          goalDates.putIfAbsent(ge.goalId, () => tx.date);
        } else {
          // L'estat "actual" mana; si també hi ha hagut un revert, és una edició.
          goalNotes[ge.goalId] = goalsWithRemove.contains(ge.goalId)
              ? 'Ajust: ${tx.concept}'
              : tx.concept;
          goalDates[ge.goalId] = tx.date;
        }
      }

      final links = _linksFor(tx.subCategoryId, categories);

      // 2. Deute enllaçat (despesa redueix el deute; ingrés l'augmenta).
      if (links.debtId != null) {
        final d = sign * (tx.isIncome ? tx.amount : -tx.amount);
        debtDeltas[links.debtId!] = (debtDeltas[links.debtId!] ?? 0) + d;
      }

      // 3. Saldo del compte assignat.
      if (tx.accountId != null) {
        final d = sign * (tx.isIncome ? tx.amount : -tx.amount);
        assetDeltas[tx.accountId!] = (assetDeltas[tx.accountId!] ?? 0) + d;
      }
    }

    // IMPORTANT: primer el revert (perquè l'apply detecti que és una edició).
    if (remove != null) accumulate(remove, -1);
    if (add != null) accumulate(add, 1);

    for (final id in goalDeltas.keys) {
      await _writeGoalDelta(id, goalDeltas[id]!, goalDates[id]!, goalNotes[id]!);
    }
    for (final e in assetDeltas.entries) {
      await _writeAssetDelta(e.key, e.value);
    }
    for (final e in debtDeltas.entries) {
      await _writeDebtDelta(e.key, e.value);
    }
  }

  /// Efecte net d'un moviment sobre UNA guardiola. `delta` > 0 = suma a la
  /// guardiola. Precedència: `savingsGoalId` (pagar/retirar amb estalvis, que
  /// SEMPRE treu de la guardiola) per sobre de la subcategoria enllaçada
  /// (despesa = aportació, ingrés = retirada). Mai els dos alhora.
  ({String goalId, double delta})? _goalEffect(
    Transaction tx,
    List<Category> categories,
  ) {
    if (tx.savingsGoalId != null) {
      return (goalId: tx.savingsGoalId!, delta: -tx.amount);
    }
    final links = _linksFor(tx.subCategoryId, categories);
    if (links.goalId != null) {
      return (goalId: links.goalId!, delta: tx.isIncome ? -tx.amount : tx.amount);
    }
    return null;
  }

  ({String? goalId, String? debtId}) _linksFor(
    String subCategoryId,
    List<Category> categories,
  ) {
    for (final cat in categories) {
      for (final sub in cat.subcategories) {
        if (sub.id == subCategoryId) {
          return (goalId: sub.linkedSavingsGoalId, debtId: sub.linkedDebtId);
        }
      }
    }
    return (goalId: null, debtId: null);
  }

  /// Aplica un delta NET a una guardiola amb UNA sola entrada de log.
  /// Si el net és 0 (p.ex. update que no toca l'import) no escriu res.
  Future<void> _writeGoalDelta(
    String goalId,
    double delta,
    DateTime date,
    String note,
  ) async {
    if (delta == 0) return;
    try {
      final goals = await ref.read(savingsGoalNotifierProvider.future);
      final goal = goals.firstWhere((g) => g.id == goalId);
      await ref.read(savingsGoalRepositoryProvider).updateSavingsGoal(
            goal.copyWith(
              currentAmount: goal.currentAmount + delta,
              history: [
                ...goal.history,
                SavingsEntry(date: date, amount: delta, note: note),
              ],
            ),
          );
    } catch (e) {
      debugPrint('Error escrivint guardiola $goalId: $e');
    }
  }

  Future<void> _writeAssetDelta(String assetId, double delta) async {
    if (delta == 0) return;
    try {
      final assets = await ref.read(assetNotifierProvider.future);
      final asset = assets.firstWhere((a) => a.id == assetId);
      await ref
          .read(assetNotifierProvider.notifier)
          .updateAsset(asset.copyWith(amount: asset.amount + delta));
    } catch (e) {
      debugPrint('Error actualitzant compte $assetId: $e');
    }
  }

  Future<void> _writeDebtDelta(String debtId, double delta) async {
    if (delta == 0) return;
    try {
      final debts = await ref.read(debtNotifierProvider.future);
      final debt = debts.firstWhere((d) => d.id == debtId);
      await ref
          .read(debtNotifierProvider.notifier)
          .updateDebt(debt.copyWith(currentBalance: debt.currentBalance + delta));
    } catch (e) {
      debugPrint('Error actualitzant deute $debtId: $e');
    }
  }
}
