import 'package:centim/domain/models/billing_cycle.dart';
import 'package:centim/domain/models/budget_entry.dart';
import 'package:centim/domain/models/category.dart';
import 'package:centim/domain/models/heatmap_data.dart';
import 'package:centim/domain/models/transaction.dart';
import 'package:centim/domain/services/ledger_service.dart';
import 'package:centim/presentation/providers/budget_provider.dart';
import 'package:centim/presentation/providers/panoramic_heatmap_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cycle = BillingCycle(
    id: 'abril',
    groupId: 'g',
    name: 'Abril 2026',
    startDate: DateTime(2026, 3, 30),
    endDate: DateTime(2026, 4, 29),
  );

  SubCategory sub(
    String id, {
    double budget = 0,
    bool archived = false,
    String? goalId,
  }) =>
      SubCategory(
        id: id,
        name: id,
        monthlyBudget: budget,
        archived: archived,
        linkedSavingsGoalId: goalId,
      );

  Category category(
    String id,
    List<SubCategory> subs, {
    bool archived = false,
    TransactionType type = TransactionType.expense,
  }) =>
      Category(
        id: id,
        name: id,
        icon: '',
        subcategories: subs,
        archived: archived,
        type: type,
      );

  Transaction tx(
    String categoryId,
    String subcategoryId,
    double amount, {
    bool isIncome = false,
    String? savingsGoalId,
  }) =>
      Transaction(
        id: '$categoryId-$subcategoryId-$amount-$isIncome',
        groupId: 'g',
        date: DateTime(2026, 4, 10),
        amount: amount,
        concept: 'test',
        categoryId: categoryId,
        subCategoryId: subcategoryId,
        categoryName: categoryId,
        subCategoryName: subcategoryId,
        payer: 'test',
        isIncome: isIncome,
        savingsGoalId: savingsGoalId,
      );

  HeatmapCell cell(List<HeatmapRow> rows, String rowId) =>
      rows.firstWhere((row) => row.id == rowId).cells[cycle.id]!;

  test('el mes de pressupost és sempre el mes de cycle.endDate', () {
    final month = budgetMonthForCycle(cycle);
    expect(month.year, 2026);
    expect(month.month, DateTime.april);
  });

  test('Panoràmica coincideix amb budget_provider i usa estalvi net del ledger',
      () {
    final life = category('vida', [sub('compres', budget: 200)]);
    final savings = category(
      'estalvi',
      [sub('guardiola', budget: 200, goalId: 'goal')],
    );
    final income = category(
      'ingressos',
      [sub('retirada-guardiola', goalId: 'goal')],
      type: TransactionType.income,
    );
    final categories = [life, savings, income];
    final transactions = [
      tx('vida', 'compres', 100),
      tx('vida', 'compres', 20, isIncome: true), // refund: resta
      tx('estalvi', 'guardiola', 645), // guardiola enllaçada: exclòs
      tx(
        'ingressos',
        'retirada-guardiola',
        659,
        isIncome: true,
      ), // retirada: exclosa dels ingressos
    ];
    final ledger = summarizeLedger(
      transactionsInBillingCycle(transactions, cycle),
      LedgerLookups.from(categories),
    );

    final budgetStatuses =
        calculateBudgetStatus(categories, transactions, const [], cycle);
    final rows = calculatePanoramicRows(
      cycles: [cycle],
      categories: categories,
      transactions: transactions,
      budgetEntriesByCycleId: {cycle.id: const []},
      selectedCategoryIds: {'vida', 'estalvi'},
      expandedCategoryIds: const {},
    );

    for (final status in budgetStatuses.where(
      (item) =>
          item.category.type == TransactionType.expense &&
          item.category.id != 'estalvi',
    )) {
      final panoramic = cell(rows, status.category.id);
      expect(panoramic.spent, status.spent);
      expect(panoramic.budgeted, status.total);
    }
    expect(cell(rows, 'vida').spent, 80); // 100 − 20
    expect(ledger.savedThisCycle, 645);
    expect(ledger.withdrawnThisCycle, 659);
    expect(cell(rows, 'estalvi').spent, ledger.netSaved);
    expect(cell(rows, 'estalvi').spent, -14);
    expect(cell(rows, 'estalvi').deviation, -214);
    expect(cell(rows, '__total__').spent, 80);
    expect(cell(rows, '__total__').budgeted, 200);
    expect(
      rows.indexWhere((row) => row.id == 'estalvi'),
      greaterThan(rows.indexWhere((row) => row.id == '__total__')),
    );
  });

  test('una subcategoria arxivada conserva fila, pressupost i gastat històrics',
      () {
    final categories = [
      category('vida', [
        sub('activa', budget: 100),
        sub('antiga', budget: 50, archived: true),
      ]),
    ];
    final transactions = [
      tx('vida', 'activa', 70),
      tx('vida', 'antiga', 30),
    ];

    final rows = calculatePanoramicRows(
      cycles: [cycle],
      categories: categories,
      transactions: transactions,
      budgetEntriesByCycleId: {cycle.id: const <BudgetEntry>[]},
      selectedCategoryIds: {'vida'},
      expandedCategoryIds: {'vida'},
    );

    expect(
      rows.map((row) => row.id),
      containsAll(['vida', 'activa', 'antiga']),
    );
    expect(rows.firstWhere((row) => row.id == 'antiga').name,
        contains('arxivada'));
    expect(cell(rows, 'vida').spent, 100);
    expect(cell(rows, 'vida').budgeted, 150);
    expect(cell(rows, '__total__').spent, 100);
    expect(cell(rows, '__total__').budgeted, 150);
  });

  test('una categoria pare arxivada també conserva l’històric', () {
    final categories = [
      category('visible', [sub('visible-sub', budget: 100)]),
      category(
        'arxivada',
        [sub('arxivada-sub', budget: 100)],
        archived: true,
      ),
    ];
    final transactions = [
      tx('visible', 'visible-sub', 40),
      tx('arxivada', 'arxivada-sub', 90),
    ];

    final rows = calculatePanoramicRows(
      cycles: [cycle],
      categories: categories,
      transactions: transactions,
      budgetEntriesByCycleId: {cycle.id: const []},
      selectedCategoryIds: {'visible', 'arxivada'},
      expandedCategoryIds: const {},
    );

    expect(rows.map((row) => row.id), contains('arxivada'));
    expect(
      rows.firstWhere((row) => row.id == 'arxivada').name,
      contains('arxivada'),
    );
    expect(cell(rows, '__total__').spent, 130);
    expect(cell(rows, '__total__').budgeted, 200);
  });

  test('mesos sense moviments no entren a la mitjana ni a l’acumulat', () {
    final futureCycle = BillingCycle(
      id: 'maig',
      groupId: 'g',
      name: 'Maig 2026',
      startDate: DateTime(2026, 4, 30),
      endDate: DateTime(2026, 5, 29),
    );
    final categories = [
      category('vida', [sub('compres', budget: 200)]),
    ];
    final transactions = [tx('vida', 'compres', 260)];
    final rows = calculatePanoramicRows(
      cycles: [cycle, futureCycle],
      categories: categories,
      transactions: transactions,
      budgetEntriesByCycleId: {
        cycle.id: const [],
        futureCycle.id: const [],
      },
      selectedCategoryIds: {'vida'},
      expandedCategoryIds: const {},
    );
    final withData =
        cycleIdsWithTransactions([cycle, futureCycle], transactions);
    final row = rows.firstWhere((item) => item.id == 'vida');

    expect(withData, {cycle.id});
    expect(
      aggregateHeatmapCells(row, withData, average: true)?.deviation,
      60,
    );
    expect(
      aggregateHeatmapCells(row, withData, average: false)?.deviation,
      60,
    );
    expect(
      aggregateHeatmapCells(row, const <String>[], average: true),
      isNull,
    );
  });
}
