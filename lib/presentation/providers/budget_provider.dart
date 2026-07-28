import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../../domain/services/ledger_service.dart';
import 'category_notifier.dart';
import 'transaction_notifier.dart';
import 'auth_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../../domain/models/budget_entry.dart';

import 'billing_cycle_provider.dart';
import '../../domain/models/billing_cycle.dart';

part 'budget_provider.freezed.dart';
part 'budget_provider.g.dart';

/// Mes comptable del pressupost d'un cicle.
///
/// És deliberadament la data FINAL del cicle: un cicle que va del 30/03 al
/// 29/04 consumeix el pressupost d'abril. Panoràmica i Detall han de passar
/// sempre per aquesta funció perquè no puguin divergir.
DateTime budgetMonthForCycle(BillingCycle cycle) =>
    DateTime(cycle.endDate.year, cycle.endDate.month);

/// Moviments dins d'un cicle, amb `endDate` inclusiu i comparació per dia.
List<Transaction> transactionsInBillingCycle(
  Iterable<Transaction> transactions,
  BillingCycle cycle,
) {
  final startDay = DateTime(
    cycle.startDate.year,
    cycle.startDate.month,
    cycle.startDate.day,
    12,
  );
  final endDay = DateTime(
    cycle.endDate.year,
    cycle.endDate.month,
    cycle.endDate.day,
    12,
  );
  return transactions.where((transaction) {
    final day = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
      12,
    );
    return !day.isBefore(startDay) && !day.isAfter(endDay);
  }).toList();
}

@freezed
class SubcategoryBudgetStatus with _$SubcategoryBudgetStatus {
  const factory SubcategoryBudgetStatus({
    required SubCategory subcategory,
    required double spent,
    required double budget,
    required double percentage,
  }) = _SubcategoryBudgetStatus;
}

@freezed
class BudgetStatus with _$BudgetStatus {
  const factory BudgetStatus({
    required Category category,
    required double spent,
    required double total,
    required double percentage,
    required bool isOverBudget,
    @Default([]) List<SubcategoryBudgetStatus> subcategoryStatuses,
  }) = _BudgetStatus;
}

@riverpod
class BudgetNotifier extends _$BudgetNotifier {
  @override
  Future<List<BudgetStatus>> build() async {
    final groupId = await ref.watch(currentGroupIdProvider.future);
    if (groupId == null) return [];

    // Watch streams via future to get latest values and react to changes
    final categories = await ref.watch(categoryNotifierProvider.future);
    final transactions = await ref.watch(transactionNotifierProvider.future);

    // Watch ACTIVE CYCLE
    final activeCycle = ref.watch(activeCycleProvider);

    // BudgetEntries es desen per (year, month). El mes d'un cicle és el de la
    // seva data final: 28 gen – 27 feb consumeix el pressupost de febrer.
    // Aquesta regla està centralitzada a budgetMonthForCycle i és compartida
    // amb la Panoràmica.

    final budgetEntryRepo = ref.read(budgetEntryRepositoryProvider);
    final budgetMonth = budgetMonthForCycle(activeCycle);
    // Note: This matches entries stored with that year/month.
    final budgetEntries = await budgetEntryRepo
        .watchEntriesForMonth(
          groupId,
          budgetMonth.year,
          budgetMonth.month,
        )
        .first;

    // Use helper function with CYCLE dates
    return calculateBudgetStatus(
      categories,
      transactions,
      budgetEntries,
      activeCycle,
    );
  }
}

@riverpod
class DashboardBudgetNotifier extends _$DashboardBudgetNotifier {
  @override
  Future<List<BudgetStatus>> build() async {
    final groupId = await ref.watch(currentGroupIdProvider.future);
    if (groupId == null) return [];

    final categories = await ref.watch(categoryNotifierProvider.future);
    final transactions = await ref.watch(transactionNotifierProvider.future);
    final budgetEntryRepo = ref.read(budgetEntryRepositoryProvider);

    // Watch ACTIVE CYCLE
    final activeCycle = ref.watch(activeCycleProvider);
    final budgetMonth = budgetMonthForCycle(activeCycle);

    final budgetEntries = await budgetEntryRepo
        .watchEntriesForMonth(
          groupId,
          budgetMonth.year,
          budgetMonth.month,
        )
        .first;

    final statuses = calculateBudgetStatus(
      categories,
      transactions,
      budgetEntries,
      activeCycle,
    );

    // Sort by Absolute Spent Descending
    statuses.sort((a, b) => b.spent.compareTo(a.spent));

    return statuses;
  }
}

/// Calcula l'estat de pressupost per categoria. Pública per poder-la testar:
/// aquí hi ha la regla que decideix quin cistell compta segons el tipus de
/// categoria (una regressió hi va deixar els ingressos a zero).
List<BudgetStatus> calculateBudgetStatus(
  List<Category> categories,
  List<Transaction> transactions,
  List<BudgetEntry> budgetEntries,
  BillingCycle cycle, {
  bool includeArchived = false,
}) {
  final look = LedgerLookups.from(categories);

  final currentCycleTransactions =
      transactionsInBillingCycle(transactions, cycle);

  return categories
      .where((category) => includeArchived || !category.archived)
      .map((category) {
    final activeSubcategories = category.subcategories
        .where((sub) => includeArchived || !sub.archived)
        .toList();

    // 1. Calculate Total Budget for this Category (sum of active subcategories, considering entries)
    final totalBudget = activeSubcategories.fold(0.0, (sum, sub) {
      // Find entry for this subcategory
      final entry = budgetEntries.firstWhere(
        (e) => e.subCategoryId == sub.id,
        orElse: () => BudgetEntry(
          id: '',
          subCategoryId: '',
          year: 0,
          month: 0,
          amount: sub.monthlyBudget,
        ),
      );

      final effectiveBudget =
          entry.id.isNotEmpty ? entry.amount : sub.monthlyBudget;
      return sum + effectiveBudget;
    });

    // 2. Executat de la categoria (regles canòniques: exclou guardioles i els
    //    moviments de signe contrari resten —refund en despesa, devolució en
    //    ingrés—).
    //
    //    El cistell que compta depèn del TIPUS de la categoria: a una categoria
    //    de despesa el "gastat" és la despesa, i a una d'ingrés (p.ex. NÒMINA)
    //    l'"executat" és l'ingrés rebut. Mirar només el cistell de despesa
    //    deixava totes les categories d'ingrés a 0.
    final relevantBucket = category.type == TransactionType.income
        ? LedgerBucket.income
        : LedgerBucket.expense;

    final categoryTransactions = currentCycleTransactions
        .where((t) => t.categoryId == category.id)
        .toList();

    double spent = 0.0;
    final subSpentById = <String, double>{};
    for (final t in categoryTransactions) {
      final c = classifyTransaction(t, look);
      if (c.bucket != relevantBucket) continue;
      spent += c.delta;
      subSpentById[t.subCategoryId] =
          (subSpentById[t.subCategoryId] ?? 0) + c.delta;
    }

    // 3. Calculate per-subcategory status
    final subcategoryStatuses = activeSubcategories.map((sub) {
      final entry = budgetEntries.firstWhere(
        (e) => e.subCategoryId == sub.id,
        orElse: () => BudgetEntry(
          id: '',
          subCategoryId: '',
          year: 0,
          month: 0,
          amount: sub.monthlyBudget,
        ),
      );
      final effectiveBudget =
          entry.id.isNotEmpty ? entry.amount : sub.monthlyBudget;

      final subSpent = subSpentById[sub.id] ?? 0.0;

      final subPercentage = effectiveBudget > 0
          ? (subSpent / effectiveBudget)
          : (subSpent > 0 ? 1.0 : 0.0);

      return SubcategoryBudgetStatus(
        subcategory: sub,
        spent: subSpent,
        budget: effectiveBudget,
        percentage: subPercentage,
      );
    }).toList();

    final percentage =
        totalBudget > 0 ? (spent / totalBudget) : (spent > 0 ? 1.0 : 0.0);

    return BudgetStatus(
      category: category,
      spent: spent,
      total: totalBudget,
      percentage: percentage,
      isOverBudget: spent > totalBudget,
      subcategoryStatuses: subcategoryStatuses,
    );
  }).toList();
}

@riverpod
Stream<List<BudgetEntry>> currentMonthBudgetEntries(Ref ref) async* {
  final groupId = await ref.watch(currentGroupIdProvider.future);
  if (groupId == null) {
    yield [];
    return;
  }

  final now = DateTime.now();
  final repo = ref.watch(budgetEntryRepositoryProvider);
  yield* repo.watchEntriesForMonth(groupId, now.year, now.month);
}

// ── Zero-Based Budgeting ──────────────────────────────────────────

@freezed
class ZeroBudgetSummary with _$ZeroBudgetSummary {
  const factory ZeroBudgetSummary({
    required double totalIncome,
    required double totalExpenses,
    required double remainder,
  }) = _ZeroBudgetSummary;
}

/// Holds the selected budget context. null = "Pressupost Estàndard" (base).
@riverpod
class BudgetContextNotifier extends _$BudgetContextNotifier {
  @override
  BillingCycle? build() => null;

  void select(BillingCycle? cycle) => state = cycle;
}

@riverpod
Future<ZeroBudgetSummary> zeroBudgetBalance(Ref ref) async {
  final cycle = ref.watch(budgetContextNotifierProvider);
  final categories = await ref.watch(categoryNotifierProvider.future);

  List<BudgetEntry> entries = [];
  if (cycle != null) {
    final groupId = await ref.watch(currentGroupIdProvider.future);
    if (groupId != null) {
      final repo = ref.read(budgetEntryRepositoryProvider);
      final budgetMonth = budgetMonthForCycle(cycle);
      entries = await repo
          .watchEntriesForMonth(
            groupId,
            budgetMonth.year,
            budgetMonth.month,
          )
          .first;
    }
  }

  double totalIncome = 0;
  double totalExpenses = 0;

  for (final cat in categories) {
    if (cat.archived) continue;
    for (final sub in cat.subcategories) {
      if (sub.archived) continue;
      // Determine effective budget
      double budget = sub.monthlyBudget;
      if (cycle != null) {
        final entry = entries.cast<BudgetEntry?>().firstWhere(
              (e) => e!.subCategoryId == sub.id,
              orElse: () => null,
            );
        if (entry != null) budget = entry.amount;
      }

      if (cat.type == TransactionType.income) {
        totalIncome += budget;
      } else {
        totalExpenses += budget;
      }
    }
  }

  return ZeroBudgetSummary(
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    remainder: totalIncome - totalExpenses,
  );
}
