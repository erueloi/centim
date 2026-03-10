import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/billing_cycle.dart';
import '../../domain/models/category.dart';
import '../../domain/models/heatmap_data.dart';
import '../../domain/models/budget_entry.dart';
import 'billing_cycle_provider.dart';
import 'category_notifier.dart';
import 'transaction_notifier.dart';
import 'auth_providers.dart';
import '../../data/providers/repository_providers.dart';

part 'panoramic_heatmap_provider.g.dart';

@riverpod
class PanoramicHeatmap extends _$PanoramicHeatmap {
  // Use these to persist across invalidations
  Set<String>? _persistedSelectedCycles;
  Set<String>? _persistedSelectedCategories;
  Set<String> _expandedCategoryIds = {};

  @override
  Future<HeatmapState> build() async {
    final groupId = await ref.watch(currentGroupIdProvider.future);
    if (groupId == null) {
      return const HeatmapState(
        allCycles: [],
        allCategories: [],
        visibleRows: [],
        expandedCategoryIds: {},
        selectedCycleIds: {},
        selectedCategoryIds: {},
      );
    }

    // 1. Fetch cycles and categories
    final cycles = await ref.watch(billingCycleNotifierProvider.future);
    final sortedCycles = List<BillingCycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final allCategories = await ref.watch(categoryNotifierProvider.future);
    final expenseCategories =
        allCategories.where((c) => c.type == TransactionType.expense).toList();

    // 2. Determine selected filters
    // If we have persisted values, use them. Otherwise, default to all.
    final selectedCycleIds =
        _persistedSelectedCycles ?? sortedCycles.map((c) => c.id).toSet();
    final selectedCategoryIds = _persistedSelectedCategories ??
        expenseCategories.map((c) => c.id).toSet();

    _persistedSelectedCycles = selectedCycleIds;
    _persistedSelectedCategories = selectedCategoryIds;

    // 3. Aggregate data
    final allTransactions = await ref.watch(transactionNotifierProvider.future);
    final budgetEntryRepo = ref.read(budgetEntryRepositoryProvider);

    final filteredCycles =
        sortedCycles.where((c) => selectedCycleIds.contains(c.id)).toList();
    final filteredCategories = expenseCategories
        .where((c) => selectedCategoryIds.contains(c.id))
        .toList();

    final List<HeatmapRow> visibleRows = [];

    for (final category in filteredCategories) {
      final Map<String, HeatmapCell> parentCells = {};
      final isExpanded = _expandedCategoryIds.contains(category.id);

      for (final cycle in filteredCycles) {
        final budgetEntries = await budgetEntryRepo
            .watchEntriesForMonth(
                groupId, cycle.endDate.year, cycle.endDate.month)
            .first;

        final cycleTransactions = allTransactions.where((t) {
          final tDay =
              DateTime(t.date.year, t.date.month, t.date.day, 12, 0, 0);
          final startDay = DateTime(cycle.startDate.year, cycle.startDate.month,
              cycle.startDate.day, 12, 0, 0);
          final endDay = DateTime(cycle.endDate.year, cycle.endDate.month,
              cycle.endDate.day, 12, 0, 0);
          return (tDay.isAtSameMomentAs(startDay) || tDay.isAfter(startDay)) &&
              !tDay.isAfter(endDay);
        }).toList();

        final totalBudget = category.subcategories.fold(0.0, (sum, sub) {
          final entry = budgetEntries.cast<BudgetEntry?>().firstWhere(
              (e) => e!.subCategoryId == sub.id,
              orElse: () => null);
          return sum + (entry != null ? entry.amount : sub.monthlyBudget);
        });

        final spent = cycleTransactions
            .where((t) => t.categoryId == category.id)
            .fold(0.0, (sum, t) => sum + (t.amount as num).toDouble());

        parentCells[cycle.id] = HeatmapCell(
          budgeted: totalBudget,
          spent: spent,
          deviation: spent - totalBudget,
        );
      }

      visibleRows.add(HeatmapRow(
        id: category.id,
        name: category.name,
        icon: category.icon,
        isSubCategory: false,
        cells: parentCells,
        isExpanded: isExpanded,
      ));

      if (isExpanded) {
        for (final sub in category.subcategories) {
          final Map<String, HeatmapCell> subCells = {};
          for (final cycle in filteredCycles) {
            final budgetEntries = await budgetEntryRepo
                .watchEntriesForMonth(
                    groupId, cycle.endDate.year, cycle.endDate.month)
                .first;

            final cycleTransactions = allTransactions.where((t) {
              final tDay =
                  DateTime(t.date.year, t.date.month, t.date.day, 12, 0, 0);
              final startDay = DateTime(cycle.startDate.year,
                  cycle.startDate.month, cycle.startDate.day, 12, 0, 0);
              final endDay = DateTime(cycle.endDate.year, cycle.endDate.month,
                  cycle.endDate.day, 12, 0, 0);
              return (tDay.isAtSameMomentAs(startDay) ||
                      tDay.isAfter(startDay)) &&
                  !tDay.isAfter(endDay);
            }).toList();

            final entry = budgetEntries.cast<BudgetEntry?>().firstWhere(
                (e) => e!.subCategoryId == sub.id,
                orElse: () => null);
            final subBudget = entry != null ? entry.amount : sub.monthlyBudget;
            final subSpent = cycleTransactions
                .where((t) => t.subCategoryId == sub.id)
                .fold(0.0, (sum, t) => sum + (t.amount as num).toDouble());

            subCells[cycle.id] = HeatmapCell(
              budgeted: subBudget,
              spent: subSpent,
              deviation: subSpent - subBudget,
            );
          }

          visibleRows.add(HeatmapRow(
            id: sub.id,
            name: sub.name,
            icon: '',
            isSubCategory: true,
            cells: subCells,
          ));
        }
      }
    }

    return HeatmapState(
      allCycles: sortedCycles,
      allCategories: expenseCategories,
      visibleRows: visibleRows,
      expandedCategoryIds: _expandedCategoryIds,
      selectedCycleIds: selectedCycleIds,
      selectedCategoryIds: selectedCategoryIds,
    );
  }

  void toggleCategoryExpansion(String categoryId) {
    if (_expandedCategoryIds.contains(categoryId)) {
      _expandedCategoryIds.remove(categoryId);
    } else {
      _expandedCategoryIds.add(categoryId);
    }
    ref.invalidateSelf();
  }

  void toggleCycleFilter(String cycleId) {
    final current = _persistedSelectedCycles ?? {};
    final next = Set<String>.from(current);
    if (next.contains(cycleId)) {
      if (next.length > 1) next.remove(cycleId);
    } else {
      next.add(cycleId);
    }
    _persistedSelectedCycles = next;
    ref.invalidateSelf();
  }

  void toggleCategoryFilter(String categoryId) {
    final current = _persistedSelectedCategories ?? {};
    final next = Set<String>.from(current);
    if (next.contains(categoryId)) {
      if (next.length > 1) next.remove(categoryId);
    } else {
      next.add(categoryId);
    }
    _persistedSelectedCategories = next;
    ref.invalidateSelf();
  }

  void resetFilters() {
    _persistedSelectedCycles = null;
    _persistedSelectedCategories = null;
    _expandedCategoryIds = {};
    ref.invalidateSelf();
  }
}
