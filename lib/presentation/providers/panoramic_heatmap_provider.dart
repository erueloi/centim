import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/billing_cycle.dart';
import '../../domain/models/category.dart';
import '../../domain/models/heatmap_data.dart';
import '../../domain/models/budget_entry.dart';
import '../../domain/models/transaction.dart';
import '../../domain/services/ledger_service.dart';
import 'billing_cycle_provider.dart';
import 'budget_provider.dart';
import 'category_notifier.dart';
import 'transaction_notifier.dart';
import 'auth_providers.dart';
import '../../data/providers/repository_providers.dart';

part 'panoramic_heatmap_provider.g.dart';

/// Categoria que representa aportacions a guardioles, no despesa de vida.
///
/// No depèn del nom: ha de ser de despesa i TOTES les seves subcategories han
/// d'estar vinculades a una guardiola. Això identifica "Estalvi Menusal" sense
/// confondre-la amb "Ingressos", que és una categoria mixta.
bool isSavingsBudgetCategory(Category category) =>
    category.type == TransactionType.expense &&
    category.subcategories.isNotEmpty &&
    category.subcategories
        .every((subcategory) => subcategory.linkedSavingsGoalId != null);

/// Cicles que contenen almenys un moviment real, sigui de la categoria que
/// sigui. És el criteri visual per distingir dades de simples pressupostos.
Set<String> cycleIdsWithTransactions(
  Iterable<BillingCycle> cycles,
  Iterable<Transaction> transactions,
) {
  return {
    for (final cycle in cycles)
      if (transactionsInBillingCycle(transactions, cycle).isNotEmpty) cycle.id,
  };
}

/// Mitjana o acumulat d'una fila sobre els cicles indicats.
HeatmapCell? aggregateHeatmapCells(
  HeatmapRow row,
  Iterable<String> cycleIds, {
  required bool average,
}) {
  final cells = [
    for (final id in cycleIds)
      if (row.cells[id] != null) row.cells[id]!,
  ];
  if (cells.isEmpty) return null;

  final divisor = average ? cells.length : 1;
  final budgeted =
      cells.fold(0.0, (sum, cell) => sum + cell.budgeted) / divisor;
  final spent = cells.fold(0.0, (sum, cell) => sum + cell.spent) / divisor;
  return HeatmapCell(
    budgeted: budgeted,
    spent: spent,
    deviation: spent - budgeted,
  );
}

/// Construeix les files de la Panoràmica a partir del MATEIX càlcul pur que
/// alimenta la pantalla Detall (`calculateBudgetStatus`).
///
/// Això garanteix una sola semàntica per al "gastat":
/// - guardioles excloses;
/// - refunds resten;
/// - a la Panoràmica HISTÒRICA, pressupost i despesa arxivats es conserven;
/// - la fila pare d'estalvi usa el net canònic del ledger
///   (`saved - withdrawn`) i queda fora del TOTAL.
List<HeatmapRow> calculatePanoramicRows({
  required List<BillingCycle> cycles,
  required List<Category> categories,
  required List<Transaction> transactions,
  required Map<String, List<BudgetEntry>> budgetEntriesByCycleId,
  required Set<String> selectedCategoryIds,
  required Set<String> expandedCategoryIds,
}) {
  final visibleCategories = categories
      .where((category) =>
          category.type == TransactionType.expense &&
          selectedCategoryIds.contains(category.id))
      .toList();

  final lookups = LedgerLookups.from(categories);
  final statusesByCycle = <String, Map<String, BudgetStatus>>{};
  final ledgerByCycle = <String, LedgerSummary>{};
  for (final cycle in cycles) {
    final cycleTransactions = transactionsInBillingCycle(transactions, cycle);
    final statuses = calculateBudgetStatus(
      categories,
      transactions,
      budgetEntriesByCycleId[cycle.id] ?? const [],
      cycle,
      includeArchived: true,
    );
    statusesByCycle[cycle.id] = {
      for (final status in statuses)
        if (status.category.type == TransactionType.expense &&
            selectedCategoryIds.contains(status.category.id))
          status.category.id: status,
    };
    ledgerByCycle[cycle.id] = summarizeLedger(cycleTransactions, lookups);
  }

  final rows = <HeatmapRow>[];
  final savingsCategories =
      visibleCategories.where(isSavingsBudgetCategory).toList();
  final savingsCategoryIds = savingsCategories.map((item) => item.id).toSet();
  final regularCategories = visibleCategories
      .where((category) => !savingsCategoryIds.contains(category.id))
      .toList();

  void addCategoryRows(Category category, {required bool isSavings}) {
    final cells = <String, HeatmapCell>{};
    for (final cycle in cycles) {
      final status = statusesByCycle[cycle.id]![category.id]!;
      final spent = isSavings
          // Les aportacions són sota la categoria d'estalvi, però les retirades
          // viuen sota Ingressos. El pare ha de mostrar el net global del
          // ledger, igual que el Resum d'Estalvi del Dashboard.
          ? ledgerByCycle[cycle.id]!.netSaved
          : status.spent;
      cells[cycle.id] = HeatmapCell(
        budgeted: status.total,
        spent: spent,
        deviation: spent - status.total,
      );
    }

    final isExpanded = expandedCategoryIds.contains(category.id);
    rows.add(HeatmapRow(
      id: category.id,
      name: category.archived ? '${category.name} · arxivada' : category.name,
      icon: category.icon,
      isSubCategory: false,
      cells: cells,
      isExpanded: isExpanded,
    ));

    if (isExpanded) {
      for (final subcategory in category.subcategories) {
        final subCells = <String, HeatmapCell>{};
        for (final cycle in cycles) {
          final status = statusesByCycle[cycle.id]![category.id]!;
          final subStatus = status.subcategoryStatuses
              .firstWhere((item) => item.subcategory.id == subcategory.id);
          final spent = isSavings
              ? ledgerByCycle[cycle.id]!.savedBySubcategory[subcategory.id] ?? 0
              : subStatus.spent;
          subCells[cycle.id] = HeatmapCell(
            budgeted: subStatus.budget,
            spent: spent,
            deviation: spent - subStatus.budget,
          );
        }

        rows.add(HeatmapRow(
          id: subcategory.id,
          name: subcategory.archived
              ? '${subcategory.name} · arxivada'
              : subcategory.name,
          icon: '',
          isSubCategory: true,
          cells: subCells,
        ));
      }
    }
  }

  for (final category in regularCategories) {
    addCategoryRows(category, isSavings: false);
  }

  final totalCells = <String, HeatmapCell>{};
  for (final cycle in cycles) {
    final statuses = statusesByCycle[cycle.id]!.values.where(
          (status) => !savingsCategoryIds.contains(status.category.id),
        );
    final budgeted = statuses.fold(0.0, (sum, status) => sum + status.total);
    final spent = statuses.fold(0.0, (sum, status) => sum + status.spent);
    totalCells[cycle.id] = HeatmapCell(
      budgeted: budgeted,
      spent: spent,
      deviation: spent - budgeted,
    );
  }
  rows.add(HeatmapRow(
    id: '__total__',
    name: 'TOTAL',
    icon: '',
    isSubCategory: false,
    cells: totalCells,
    isTotalRow: true,
  ));

  // Peu de taula: visible i analitzable, però separat del TOTAL perquè moure
  // diners cap a una guardiola no és despesa.
  for (final category in savingsCategories) {
    addCategoryRows(category, isSavings: true);
  }

  return rows;
}

/// Mateixes dades ja carregades pels notifiers; no crea cap consulta nova.
final panoramicCycleIdsWithTransactionsProvider = Provider<Set<String>>((ref) {
  final cycles =
      ref.watch(billingCycleNotifierProvider).valueOrNull ?? const [];
  final transactions =
      ref.watch(transactionNotifierProvider).valueOrNull ?? const [];
  return cycleIdsWithTransactions(cycles, transactions);
});

@riverpod
class PanoramicHeatmap extends _$PanoramicHeatmap {
  // Use these to persist across invalidations
  Set<String>? _persistedSelectedCycles;
  Set<String>? _persistedSelectedCategories;
  Set<String> _expandedCategoryIds = {};
  int? _cycleRangeLimit; // null = use default (12), 0 = all

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
    // Default to last 12 cycles if no persisted selection
    if (_persistedSelectedCycles == null) {
      final rangeLimit = _cycleRangeLimit ?? 12;
      if (rangeLimit == 0 || sortedCycles.length <= rangeLimit) {
        _persistedSelectedCycles = sortedCycles.map((c) => c.id).toSet();
      } else {
        final lastN = sortedCycles.sublist(sortedCycles.length - rangeLimit);
        _persistedSelectedCycles = lastN.map((c) => c.id).toSet();
      }
    }

    final selectedCycleIds = _persistedSelectedCycles!;
    final selectedCategoryIds = _persistedSelectedCategories ??
        expenseCategories.map((c) => c.id).toSet();

    _persistedSelectedCategories = selectedCategoryIds;

    // 3. Aggregate data
    final allTransactions = await ref.watch(transactionNotifierProvider.future);
    final budgetEntryRepo = ref.read(budgetEntryRepositoryProvider);

    final filteredCycles =
        sortedCycles.where((c) => selectedCycleIds.contains(c.id)).toList();
    final filteredCategories = expenseCategories
        .where((c) => selectedCategoryIds.contains(c.id))
        .toList();

    // Una sola subscripció/lectura per cicle. El mes surt de la mateixa funció
    // que usa budget_provider: sempre `cycle.endDate`.
    final budgetEntriesByCycleId = <String, List<BudgetEntry>>{};
    for (final cycle in filteredCycles) {
      final budgetMonth = budgetMonthForCycle(cycle);
      budgetEntriesByCycleId[cycle.id] = await budgetEntryRepo
          .watchEntriesForMonth(
            groupId,
            budgetMonth.year,
            budgetMonth.month,
          )
          .first;
    }

    final visibleRows = calculatePanoramicRows(
      cycles: filteredCycles,
      categories: allCategories,
      transactions: allTransactions,
      budgetEntriesByCycleId: budgetEntriesByCycleId,
      selectedCategoryIds: filteredCategories.map((c) => c.id).toSet(),
      expandedCategoryIds: _expandedCategoryIds,
    );

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

  /// Sets cycle range to show the last N cycles (0 = all).
  void setCycleRange(int count) {
    _cycleRangeLimit = count;
    _persistedSelectedCycles = null; // Force recalculation
    ref.invalidateSelf();
  }

  /// Returns the current cycle range limit (0 = all, null = default 12).
  int get currentCycleRange => _cycleRangeLimit ?? 12;

  void resetFilters() {
    _persistedSelectedCycles = null;
    _persistedSelectedCategories = null;
    _expandedCategoryIds = {};
    _cycleRangeLimit = null;
    ref.invalidateSelf();
  }
}
