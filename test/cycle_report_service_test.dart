import 'dart:convert';

import 'package:centim/domain/models/billing_cycle.dart';
import 'package:centim/domain/models/budget_entry.dart';
import 'package:centim/domain/models/category.dart';
import 'package:centim/domain/models/cycle_report.dart';
import 'package:centim/domain/models/financial_summary.dart';
import 'package:centim/domain/models/transaction.dart';
import 'package:centim/domain/services/ai_coach_service.dart';
import 'package:centim/domain/services/cycle_report_service.dart';
import 'package:centim/domain/services/ledger_service.dart';
import 'package:centim/presentation/providers/budget_provider.dart';
import 'package:centim/presentation/providers/cycle_reports_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cycle = BillingCycle(
    id: 'july',
    groupId: 'group',
    name: 'Juliol 2026',
    startDate: DateTime(2026, 6, 29, 12),
    endDate: DateTime(2026, 7, 29, 12),
  );

  Transaction transaction({
    required String id,
    required DateTime date,
    required double amount,
    required String categoryId,
    required String subcategoryId,
    bool isIncome = false,
    String concept = 'Moviment',
    String categoryName = '',
    String subcategoryName = '',
    String? savingsGoalId,
  }) {
    return Transaction(
      id: id,
      groupId: 'group',
      date: date,
      amount: amount,
      concept: concept,
      categoryId: categoryId,
      subCategoryId: subcategoryId,
      categoryName: categoryName,
      subCategoryName: subcategoryName,
      payer: 'Eloi',
      isIncome: isIncome,
      savingsGoalId: savingsGoalId,
    );
  }

  group('empremta i obsolescència', () {
    const category = Category(
      id: 'food',
      name: 'Menjar',
      icon: '🍽️',
      subcategories: [
        SubCategory(id: 'market', name: 'Mercat', monthlyBudget: 300),
      ],
    );
    const entry = BudgetEntry(
      id: 'market_2026_7',
      subCategoryId: 'market',
      year: 2026,
      month: 7,
      amount: 350,
    );
    final first = transaction(
      id: 'a',
      date: DateTime(2026, 7, 2),
      amount: 20,
      categoryId: 'food',
      subcategoryId: 'market',
    );
    final second = transaction(
      id: 'b',
      date: DateTime(2026, 7, 3),
      amount: 30,
      categoryId: 'food',
      subcategoryId: 'market',
    );

    test('és determinista i canvia quan canvia una dada font', () {
      final fingerprint = buildCycleReportSourceFingerprint(
        cycle: cycle,
        transactions: [first, second],
        categories: const [category],
        budgetEntries: const [entry],
      );
      final reordered = buildCycleReportSourceFingerprint(
        cycle: cycle,
        transactions: [second, first],
        categories: const [category],
        budgetEntries: const [entry],
      );
      final changed = buildCycleReportSourceFingerprint(
        cycle: cycle,
        transactions: [first.copyWith(amount: 21), second],
        categories: const [category],
        budgetEntries: const [entry],
      );

      expect(reordered, fingerprint);
      expect(changed, isNot(fingerprint));
      expect(fingerprint, hasLength(64));
    });

    test('un report vigent passa i un report llegat queda obsolet', () {
      final fingerprint = buildCycleReportSourceFingerprint(
        cycle: cycle,
        transactions: [first],
        categories: const [category],
        budgetEntries: const [entry],
      );
      final current = CycleReport(
        id: 'july',
        groupId: 'group',
        cycleId: 'july',
        generatedAt: DateTime(2026, 8, 1),
        aiVerdict: 'Test',
        totalIncome: 0,
        totalExpense: 20,
        savingsPercentage: 0,
        generatedForStartDate: cycle.startDate,
        generatedForEndDate: cycle.endDate,
        sourceFingerprint: fingerprint,
        reportSchemaVersion: kCycleReportSchemaVersion,
        ledgerSchemaVersion: kLedgerSchemaVersion,
      );

      expect(
        isCycleReportOutdated(
          report: current,
          cycle: cycle,
          currentFingerprint: fingerprint,
        ),
        isFalse,
      );
      expect(
        isCycleReportOutdated(
          report: current.copyWith(reportSchemaVersion: 0),
          cycle: cycle,
          currentFingerprint: fingerprint,
        ),
        isTrue,
      );
      expect(
        isCycleReportOutdated(
          report: current,
          cycle: cycle,
          currentFingerprint: 'different',
        ),
        isTrue,
      );
    });
  });

  test('els dies a zero usen el net diari del ledger i exclouen guardioles',
      () {
    const expense = Category(id: 'expense', name: 'Vida', icon: '-');
    const savings = Category(
      id: 'savings',
      name: 'Estalvi',
      icon: 'S',
      subcategories: [
        SubCategory(
          id: 'goal',
          name: 'Guardiola',
          monthlyBudget: 100,
          linkedSavingsGoalId: 'goal-id',
        ),
      ],
    );
    final shortCycle = BillingCycle(
      id: 'short',
      groupId: 'group',
      name: 'Curt',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 3),
    );
    final transactions = [
      transaction(
        id: 'expense',
        date: DateTime(2026, 7, 1),
        amount: 20,
        categoryId: 'expense',
        subcategoryId: '',
      ),
      transaction(
        id: 'refund',
        date: DateTime(2026, 7, 1),
        amount: 20,
        categoryId: 'expense',
        subcategoryId: '',
        isIncome: true,
      ),
      transaction(
        id: 'saving',
        date: DateTime(2026, 7, 2),
        amount: 100,
        categoryId: 'savings',
        subcategoryId: 'goal',
      ),
      transaction(
        id: 'real-expense',
        date: DateTime(2026, 7, 3),
        amount: 10,
        categoryId: 'expense',
        subcategoryId: '',
      ),
    ];

    expect(
      countCanonicalZeroExpenseDays(
        cycle: shortCycle,
        cycleTransactions: transactions,
        lookups: LedgerLookups.from(const [expense, savings]),
      ),
      2,
    );
  });

  test('agrega Bizums i ingressos a compte sense codificar persones', () {
    const income = Category(
      id: 'income',
      name: 'Ingressos',
      icon: '+',
      type: TransactionType.income,
      subcategories: [
        SubCategory(id: 'salary', name: 'Nòmina', monthlyBudget: 0),
        SubCategory(id: 'bizum', name: 'Bizum', monthlyBudget: 0),
        SubCategory(
          id: 'account-income',
          name: 'Ingrés a compte',
          monthlyBudget: 0,
        ),
      ],
    );
    final transactions = [
      transaction(
        id: 'salary',
        date: DateTime(2026, 7, 1),
        amount: 2600,
        categoryId: 'income',
        subcategoryId: 'salary',
        isIncome: true,
      ),
      transaction(
        id: 'bizum',
        date: DateTime(2026, 7, 2),
        amount: 700,
        categoryId: 'income',
        subcategoryId: 'bizum',
        isIncome: true,
      ),
      transaction(
        id: 'account-income',
        date: DateTime(2026, 7, 3),
        amount: 200,
        categoryId: 'income',
        subcategoryId: 'account-income',
        isIncome: true,
      ),
    ];
    final lookups = LedgerLookups.from(const [income]);

    expect(
      calculatePersonalTransferIncome(
        cycleTransactions: transactions,
        categories: const [income],
        lookups: lookups,
      ),
      900,
    );
  });

  test('el report pressupostari exclou ingressos i la categoria de guardioles',
      () {
    const expense = Category(id: 'expense', name: 'Vida', icon: '-');
    const income = Category(
      id: 'income',
      name: 'Ingressos',
      icon: '+',
      type: TransactionType.income,
    );
    const savings = Category(
      id: 'savings',
      name: 'Estalvi',
      icon: 'S',
      subcategories: [
        SubCategory(
          id: 'goal',
          name: 'Guardiola',
          monthlyBudget: 661,
          linkedSavingsGoalId: 'goal-id',
        ),
      ],
    );
    BudgetStatus status(Category category) => BudgetStatus(
          category: category,
          spent: 0,
          total: 661,
          percentage: 0,
          isOverBudget: false,
        );

    expect(isCycleReportSpendingStatus(status(expense)), isTrue);
    expect(isCycleReportSpendingStatus(status(income)), isFalse);
    expect(isCycleReportSpendingStatus(status(savings)), isFalse);
  });

  test('regressió Juliol: 645 aportats - 659 rescatats = -14, mai -661', () {
    const income = Category(
      id: 'income',
      name: 'Ingressos',
      icon: '+',
      type: TransactionType.income,
      subcategories: [
        SubCategory(
          id: 'withdrawal',
          name: 'Ingrés guardiola',
          monthlyBudget: 0,
          linkedSavingsGoalId: 'goal-id',
        ),
      ],
    );
    const savings = Category(
      id: 'savings',
      name: 'Estalvi Menusal',
      icon: 'S',
      subcategories: [
        SubCategory(
          id: 'saving',
          name: 'Aportació',
          monthlyBudget: 661,
          linkedSavingsGoalId: 'goal-id',
        ),
      ],
    );
    final transactions = [
      transaction(
        id: 'saved',
        date: DateTime(2026, 7, 5),
        amount: 645,
        categoryId: 'savings',
        subcategoryId: 'saving',
      ),
      transaction(
        id: 'withdrawn',
        date: DateTime(2026, 7, 6),
        amount: 659,
        categoryId: 'income',
        subcategoryId: 'withdrawal',
        isIncome: true,
      ),
    ];
    final ledger = summarizeLedger(
      transactions,
      LedgerLookups.from(const [income, savings]),
    );
    final status = calculateBudgetStatus(
      const [income, savings],
      transactions,
      const [
        BudgetEntry(
          id: 'saving_2026_7',
          subCategoryId: 'saving',
          year: 2026,
          month: 7,
          amount: 661,
        ),
      ],
      cycle,
      includeArchived: true,
    ).firstWhere((item) => item.category.id == 'savings');

    expect(ledger.savedThisCycle, 645);
    expect(ledger.withdrawnThisCycle, 659);
    expect(ledger.netSaved, -14);
    expect(status.total, 661);
    expect(status.spent, 0);
    expect(isCycleReportSpendingStatus(status), isFalse);
  });

  test(
      'el report usa el BudgetEntry històric encara que la categoria sigui arxivada',
      () {
    const education = Category(
      id: 'education',
      name: 'Educació',
      icon: 'E',
      archived: true,
      subcategories: [
        SubCategory(
          id: 'eoi',
          name: 'EOI',
          monthlyBudget: 0,
          archived: true,
        ),
      ],
    );
    final transactions = [
      transaction(
        id: 'eoi',
        date: DateTime(2026, 7, 8),
        amount: 327.60,
        categoryId: 'education',
        subcategoryId: 'eoi',
      ),
    ];
    final status = calculateBudgetStatus(
      const [education],
      transactions,
      const [
        BudgetEntry(
          id: 'eoi_2026_7',
          subCategoryId: 'eoi',
          year: 2026,
          month: 7,
          amount: 327.60,
        ),
      ],
      cycle,
      includeArchived: true,
    ).single;

    expect(status.total, 327.60);
    expect(status.spent, 327.60);
    expect(isCycleReportSpendingStatus(status), isTrue);
  });

  test('el context IA diferencia marge, particulars, estalvi i dies 3/31', () {
    const summary = FinancialSummary(
      totalNetWorth: 0,
      totalAssets: 0,
      totalLiabilities: 0,
      equityRatio: 0,
      monthlyIncome: 4826.18,
      savingsWithdrawalIncome: 0,
      monthlyExpenses: 4811.05,
      netOfCycle: 15.13,
      savingsPercentage: -0.29,
      debtPercentage: 0,
      livingExpensesPercentage: 0,
    );
    final raw = AiCoachService().buildCycleVerdictContextJson(
      summary: summary,
      activeCycle: cycle,
      categoryExpenses: const {'Menjar': 500},
      categoryBudgets: const {'Menjar': 450},
      zeroExpenseDays: 3,
      totalDays: 31,
      unexpectedExpenses: const [],
      savedThisCycle: 645,
      withdrawnThisCycle: 659,
      personalTransferIncome: 900,
      isHistorical: true,
    );
    final context = jsonDecode(raw) as Map<String, dynamic>;

    expect(context['dies_a_zero_despeses'], 3);
    expect(context['dies_totals_cicle'], 31);
    expect(context['marge_amb_tots_els_ingressos'], closeTo(15.13, 0.001));
    expect(context['marge_sense_bizum_transferencies_particulars'],
        closeTo(-884.87, 0.001));
    expect(context['tancament_positiu_depen_de_particulars'], isTrue);
    expect((context['estalvi'] as Map<String, dynamic>)['net'], -14);
  });

  test('els nous camps del report sobreviuen el round-trip JSON', () {
    final report = CycleReport(
      id: 'july',
      groupId: 'group',
      cycleId: 'july',
      generatedAt: DateTime(2026, 8, 5),
      aiVerdict: 'Resultat',
      totalIncome: 1000,
      totalExpense: 900,
      savingsPercentage: -1.4,
      savedThisCycle: 645,
      withdrawnThisCycle: 659,
      netSaved: -14,
      personalTransferIncome: 900,
      generatedForStartDate: cycle.startDate,
      generatedForEndDate: cycle.endDate,
      sourceFingerprint: 'abc',
      reportSchemaVersion: 1,
      ledgerSchemaVersion: 1,
    );

    final restored = CycleReport.fromJson(report.toJson());
    expect(restored.savedThisCycle, 645);
    expect(restored.withdrawnThisCycle, 659);
    expect(restored.netSaved, -14);
    expect(restored.personalTransferIncome, 900);
    expect(restored.generatedForEndDate, cycle.endDate);
    expect(restored.sourceFingerprint, 'abc');
  });
}
