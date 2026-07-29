import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/providers/repository_providers.dart';
import '../../data/repositories/firestore_transaction_repository.dart';
import '../../presentation/providers/asset_provider.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/category_notifier.dart';
import '../../presentation/providers/savings_goal_provider.dart';
import '../../presentation/providers/transaction_notifier.dart';
import '../models/category.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/transfer.dart';
import 'transaction_effects_service.dart';

part 'internal_transfer_migration_service.g.dart';

class InternalTransferMigrationCandidate {
  final Transaction expense;
  final Transaction income;

  const InternalTransferMigrationCandidate({
    required this.expense,
    required this.income,
  });

  String get id => '${expense.id}:${income.id}';
  int get dayDifference => expense.date.difference(income.date).inDays.abs();
}

class InternalTransferMigrationPlan {
  final InternalTransferMigrationCandidate candidate;
  final Transaction? savingsTransaction;
  final Transaction? expenseToReplace;
  final String? savingsGoalId;
  final String? savingsGoalName;
  final double? savingsBalanceBefore;
  final double? savingsBalanceAfter;
  final String? blockedReason;

  const InternalTransferMigrationPlan({
    required this.candidate,
    required this.savingsTransaction,
    required this.expenseToReplace,
    required this.savingsGoalId,
    required this.savingsGoalName,
    required this.savingsBalanceBefore,
    required this.savingsBalanceAfter,
    required this.blockedReason,
  });

  bool get canConvert =>
      blockedReason == null &&
      savingsTransaction != null &&
      expenseToReplace != null &&
      savingsGoalId != null &&
      savingsBalanceBefore != null &&
      savingsBalanceAfter != null;
}

bool isInternalTransferMigrationSeed(Transaction tx) {
  final sub = tx.subCategoryName.toLowerCase();
  final concept = tx.concept.toLowerCase();
  return tx.subCategoryId.startsWith('fcf6fcf7') ||
      sub.contains('bizum') ||
      sub.contains('traspass') ||
      sub.contains('ingrés guardiola jose') ||
      sub.contains('ingres guardiola jose') ||
      concept.contains('traspassos propis');
}

List<InternalTransferMigrationCandidate> findInternalTransferCandidates(
  Iterable<Transaction> transactions,
) {
  final expenses = transactions.where((tx) => !tx.isIncome).toList();
  final incomes = transactions.where((tx) => tx.isIncome).toList();
  final result = <InternalTransferMigrationCandidate>[];

  for (final expense in expenses) {
    for (final income in incomes) {
      if (!isInternalTransferMigrationSeed(expense) &&
          !isInternalTransferMigrationSeed(income)) {
        continue;
      }
      if ((expense.amount - income.amount).abs() > 0.02) continue;
      if (expense.date.difference(income.date).inDays.abs() > 3) continue;
      result.add(
        InternalTransferMigrationCandidate(
          expense: expense,
          income: income,
        ),
      );
    }
  }
  result.sort((a, b) => b.expense.date.compareTo(a.expense.date));
  return result;
}

List<InternalTransferMigrationPlan> buildInternalTransferMigrationPlans({
  required Iterable<InternalTransferMigrationCandidate> candidates,
  required List<Category> categories,
  required List<SavingsGoal> goals,
}) {
  return candidates.map((candidate) {
    final legs = [candidate.expense, candidate.income];
    final savingsLegs = <({Transaction tx, String goalId})>[];
    for (final tx in legs) {
      final effect = goalEffectForTransaction(tx, categories);
      if (effect != null) {
        savingsLegs.add((tx: tx, goalId: effect.goalId));
      }
    }

    if (savingsLegs.isEmpty) {
      return InternalTransferMigrationPlan(
        candidate: candidate,
        savingsTransaction: null,
        expenseToReplace: null,
        savingsGoalId: null,
        savingsGoalName: null,
        savingsBalanceBefore: null,
        savingsBalanceAfter: null,
        blockedReason:
            'Bloquejat: cap de les dues potes està vinculada a una guardiola.',
      );
    }
    if (savingsLegs.length != 1) {
      return InternalTransferMigrationPlan(
        candidate: candidate,
        savingsTransaction: null,
        expenseToReplace: null,
        savingsGoalId: null,
        savingsGoalName: null,
        savingsBalanceBefore: null,
        savingsBalanceAfter: null,
        blockedReason:
            'Bloquejat: les dues potes afecten una guardiola; el cas és ambigu.',
      );
    }

    final savingsLeg = savingsLegs.single;
    if (savingsLeg.tx.id != candidate.income.id) {
      return InternalTransferMigrationPlan(
        candidate: candidate,
        savingsTransaction: savingsLeg.tx,
        expenseToReplace: null,
        savingsGoalId: savingsLeg.goalId,
        savingsGoalName: null,
        savingsBalanceBefore: null,
        savingsBalanceAfter: null,
        blockedReason:
            'Bloquejat: la pota de guardiola és la despesa. Aquesta migració '
            'només pot conservar una retirada i substituir la despesa normal.',
      );
    }

    final goalMatches =
        goals.where((goal) => goal.id == savingsLeg.goalId).toList();
    if (goalMatches.length != 1) {
      return InternalTransferMigrationPlan(
        candidate: candidate,
        savingsTransaction: savingsLeg.tx,
        expenseToReplace: candidate.expense,
        savingsGoalId: savingsLeg.goalId,
        savingsGoalName: null,
        savingsBalanceBefore: null,
        savingsBalanceAfter: null,
        blockedReason:
            'Bloquejat: no s’ha pogut resoldre la guardiola afectada.',
      );
    }

    final goal = goalMatches.single;
    // La pota de guardiola es conserva byte per byte i el Transfer no té cap
    // guardiola com a extrem. Per tant aquesta migració té delta zero sobre
    // el seu saldo: el valor abans i després ha de ser idèntic.
    return InternalTransferMigrationPlan(
      candidate: candidate,
      savingsTransaction: savingsLeg.tx,
      expenseToReplace: candidate.expense,
      savingsGoalId: goal.id,
      savingsGoalName: goal.name,
      savingsBalanceBefore: goal.currentAmount,
      savingsBalanceAfter: goal.currentAmount,
      blockedReason: null,
    );
  }).toList(growable: false);
}

class InternalTransferMigrationService {
  final Ref ref;

  InternalTransferMigrationService(this.ref);

  Future<List<InternalTransferMigrationPlan>> findPlans() async {
    final transactions = await ref.read(transactionNotifierProvider.future);
    final categories = await ref.read(categoryNotifierProvider.future);
    final goals = await ref.read(savingsGoalNotifierProvider.future);
    return buildInternalTransferMigrationPlans(
      candidates: findInternalTransferCandidates(transactions),
      categories: categories,
      goals: goals,
    );
  }

  Future<void> convert({
    required InternalTransferMigrationPlan plan,
    required String sourceAssetId,
    required String destinationAssetId,
  }) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) throw StateError('No hi ha cap grup actiu');
    final assets = await ref.read(assetNotifierProvider.future);
    final categories = await ref.read(categoryNotifierProvider.future);
    final goals = await ref.read(savingsGoalNotifierProvider.future);
    final verified = buildInternalTransferMigrationPlans(
      candidates: [plan.candidate],
      categories: categories,
      goals: goals,
    ).single;
    if (!verified.canConvert) {
      throw StateError(
        verified.blockedReason ?? 'La conversió ja no és segura',
      );
    }
    if ((verified.savingsBalanceBefore! - verified.savingsBalanceAfter!).abs() >
        0.000001) {
      throw StateError(
        'La conversió canviaria el saldo de la guardiola i s’ha bloquejat.',
      );
    }
    if (plan.savingsGoalId != verified.savingsGoalId ||
        plan.savingsBalanceBefore == null ||
        (plan.savingsBalanceBefore! - verified.savingsBalanceBefore!).abs() >
            0.000001) {
      throw StateError(
        'El saldo de la guardiola ha canviat des del dry-run. '
        'Recarrega la proposta abans de convertir.',
      );
    }

    final candidate = verified.candidate;
    final expenseToReplace = verified.expenseToReplace!;
    final source = assets.firstWhere((asset) => asset.id == sourceAssetId);
    final destination =
        assets.firstWhere((asset) => asset.id == destinationAssetId);

    // La retirada real de la guardiola es conserva intacta. Només la despesa
    // normal es reemplaça pel Transfer entre comptes.
    final replacedTransactions = [expenseToReplace];
    final bankLegs = replacedTransactions
        .where(
          (tx) =>
              tx.bankAccountKey != null &&
              tx.bankAccountKey!.isNotEmpty &&
              tx.bankTxId != null &&
              tx.bankTxId!.isNotEmpty &&
              tx.accountId != null,
        )
        .map(
          (tx) => BankTransferLeg(
            bankAccountKey: tx.bankAccountKey!,
            bankTxId: tx.bankTxId!,
            signedAmount: tx.isIncome ? tx.amount : -tx.amount,
            date: tx.date,
            centimAssetId: tx.accountId!,
            concept: tx.concept,
          ),
        )
        .toList();

    final snapshots = replacedTransactions.map((tx) {
      return <String, dynamic>{
        '_id': tx.id,
        ...transactionToFirestoreMap(tx),
      };
    }).toList();

    final transfer = Transfer(
      id: const Uuid().v4(),
      groupId: groupId,
      date: candidate.expense.date,
      amount: candidate.expense.amount,
      sourceAssetId: source.id,
      sourceAssetName: source.name,
      destinationType: TransferDestinationType.asset,
      destinationId: destination.id,
      destinationName: destination.name,
      concept: candidate.expense.concept,
      note: '${candidate.expense.concept} / ${candidate.income.concept}'.trim(),
      source: 'migration',
      bankLegs: bankLegs,
      awaitsBankCounterpart: false,
      migratedTransactionSnapshots: snapshots,
    );

    await ref.read(transferRepositoryProvider).replaceTransactionsAndTransfer(
          groupId: groupId,
          categories: categories,
          removeTransactions: replacedTransactions,
          newTransfer: transfer,
          auditNote: 'Conversió a traspàs intern (${transfer.note})',
        );
  }

  Future<void> undo(Transfer transfer) async {
    if (transfer.migratedTransactionSnapshots.isEmpty) return;
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) throw StateError('No hi ha cap grup actiu');
    final categories = await ref.read(categoryNotifierProvider.future);
    final originals = transfer.migratedTransactionSnapshots.map((snapshot) {
      final data = Map<String, dynamic>.from(snapshot);
      final id = data.remove('_id') as String?;
      if (id == null) throw StateError('Snapshot de migració sense id');
      return transactionFromFirestoreMap(data, id);
    }).toList();

    await ref.read(transferRepositoryProvider).replaceTransactionsAndTransfer(
          groupId: groupId,
          categories: categories,
          addTransactions: originals,
          oldTransfer: transfer,
          auditNote:
              'Reversió auditable: desfeta la conversió a traspàs intern',
        );
  }
}

@riverpod
InternalTransferMigrationService internalTransferMigrationService(Ref ref) {
  return InternalTransferMigrationService(ref);
}

@riverpod
Future<List<InternalTransferMigrationPlan>> internalTransferCandidates(
  Ref ref,
) async {
  ref.watch(transactionNotifierProvider);
  ref.watch(categoryNotifierProvider);
  ref.watch(savingsGoalNotifierProvider);
  return ref.read(internalTransferMigrationServiceProvider).findPlans();
}
