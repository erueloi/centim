import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/category.dart';
import 'category_notifier.dart';
import 'transaction_notifier.dart';
import 'auth_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../../domain/models/budget_entry.dart';

import 'billing_cycle_provider.dart';
import '../../domain/models/billing_cycle.dart';

part 'budget_provider.freezed.dart';
part 'budget_provider.g.dart';

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

    // Watch budget entries for the cycle's start month/year,
    // OR we might need to change how budget entries are stored?
    // User requested "Logic of consultation: A movement belongs to Cycle X if date >= StartX and < StartY".
    // Budgets are usually monthly.
    // If we have custom cycles, do budgets align with cycles?
    // Usually yes. "My budget for this Billing Period".
    // But BudgetEntries are stored by (year, month).
    // If a cycle is "28 Jan - 27 Feb", which month is it?
    // It's usually named "Februar".
    // Let's assume the cycle.startDate determines the "Budget Month" roughly,
    // OR we map it to the month index of the cycle name?
    // Simple approach: Use start date's month/year for fetching budget entries.
    // If cycle is 28 Jan, maybe it maps to Feb budget?
    // For now, let's use cycle.startDate.year/month.
    // If the user wants to align budgets to cycles, we might need to migrate BudgetEntry to use CycleID.
    // But for now, let's stick to (year, month) of the cycle start.

    final budgetEntryRepo = ref.read(budgetEntryRepositoryProvider);
    // Note: This matches entries stored with that year/month.
    final budgetEntries = await budgetEntryRepo
        .watchEntriesForMonth(
          groupId,
          activeCycle.endDate.year,
          activeCycle.endDate.month,
        )
        .first;

    // Use helper function with CYCLE dates
    return _calculateBudgetStatus(
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

    final budgetEntries = await budgetEntryRepo
        .watchEntriesForMonth(
          groupId,
          activeCycle.endDate.year,
          activeCycle.endDate.month,
        )
        .first;

    final statuses = _calculateBudgetStatus(
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

// Helper function to avoid code duplication
List<BudgetStatus> _calculateBudgetStatus(
  List<Category> categories,
  List<dynamic> transactions,
  List<BudgetEntry> budgetEntries,
  BillingCycle cycle,
) {
  final currentCycleTransactions = transactions.where((t) {
    // Assuming Transaction model has date
    return t.date.isAfter(
          cycle.startDate.subtract(const Duration(seconds: 1)),
        ) &&
        t.date.isBefore(cycle.endDate.add(const Duration(seconds: 1)));
  }).toList();

  return categories.map((category) {
    // 1. Calculate Total Budget for this Category (sum of subcategories, considering entries)
    final totalBudget = category.subcategories.fold(0.0, (sum, sub) {
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

      final effectiveBudget = entry.id.isNotEmpty
          ? entry.amount
          : sub.monthlyBudget;
      return sum + effectiveBudget;
    });

    // 2. Calculate Spent for this Category
    final categoryTransactions = currentCycleTransactions
        .where((t) => t.categoryId == category.id)
        .toList();

    final spent = categoryTransactions.fold(
      0.0,
      (sum, t) => sum + ((t.amount as num).toDouble()),
    );

    // 3. Calculate per-subcategory status
    final subcategoryStatuses = category.subcategories.map((sub) {
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
      final effectiveBudget = entry.id.isNotEmpty
          ? entry.amount
          : sub.monthlyBudget;

      // Get transactions for this specific subcategory
      final subSpent = categoryTransactions
          .where((t) => t.subCategoryId == sub.id)
          .fold(0.0, (sum, t) => sum + ((t.amount as num).toDouble()));

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

    final percentage = totalBudget > 0
        ? (spent / totalBudget)
        : (spent > 0 ? 1.0 : 0.0);

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
      entries = await repo
          .watchEntriesForMonth(
            groupId,
            cycle.endDate.year,
            cycle.endDate.month,
          )
          .first;
    }
  }

  double totalIncome = 0;
  double totalExpenses = 0;

  for (final cat in categories) {
    for (final sub in cat.subcategories) {
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
