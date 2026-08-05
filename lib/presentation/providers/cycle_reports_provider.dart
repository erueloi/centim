import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/billing_cycle.dart';
import '../../domain/models/cycle_report.dart';
import '../../domain/models/financial_summary.dart';
import '../../data/providers/repository_providers.dart';
import 'auth_providers.dart';
import 'transaction_notifier.dart';
import 'category_notifier.dart';
import 'ai_coach_provider.dart';
import '../../domain/models/category.dart';
import '../../domain/services/ledger_service.dart';
import '../../domain/services/cycle_report_service.dart';
import 'budget_provider.dart';

part 'cycle_reports_provider.g.dart';

bool isCycleReportSpendingStatus(BudgetStatus status) =>
    status.category.type == TransactionType.expense &&
    !isSavingsBudgetCategory(status.category);

final cycleReportSourceFingerprintProvider = StreamProvider.autoDispose
    .family<String?, BillingCycle>((ref, cycle) async* {
  final groupId = await ref.watch(currentGroupIdProvider.future);
  if (groupId == null) {
    yield null;
    return;
  }
  final transactions = await ref.watch(transactionNotifierProvider.future);
  final categories = await ref.watch(categoryNotifierProvider.future);
  final budgetMonth = budgetMonthForCycle(cycle);
  final repository = ref.watch(budgetEntryRepositoryProvider);
  await for (final entries in repository.watchEntriesForMonth(
    groupId,
    budgetMonth.year,
    budgetMonth.month,
  )) {
    yield buildCycleReportSourceFingerprint(
      cycle: cycle,
      transactions: transactions,
      categories: categories,
      budgetEntries: entries,
    );
  }
});

@riverpod
class CycleReportNotifier extends _$CycleReportNotifier {
  @override
  Future<CycleReport?> build(String cycleId) async {
    final groupId = await ref.watch(currentGroupIdProvider.future);
    if (groupId == null) return null;

    final repo = ref.watch(cycleReportRepositoryProvider);
    return repo.getReport(groupId, cycleId);
  }

  Future<void> generateReportForCycle(BillingCycle cycle) async {
    state = const AsyncValue.loading();

    try {
      final groupId = await ref.read(currentGroupIdProvider.future);
      if (groupId == null) throw Exception("No group ID");

      // 1. Dades font del cicle.
      final allTx = await ref.read(transactionNotifierProvider.future);
      final cycleTx = transactionsInBillingCycle(allTx, cycle);
      final categories = await ref.read(categoryNotifierProvider.future);
      final budgetMonth = budgetMonthForCycle(cycle);
      final budgetEntries = await ref
          .read(budgetEntryRepositoryProvider)
          .watchEntriesForMonth(
            groupId,
            budgetMonth.year,
            budgetMonth.month,
          )
          .first;

      // Mateix pressupost efectiu que Panoràmica: BudgetEntry del mes del cicle
      // i historial arxivat inclòs.
      final budgetStatuses = calculateBudgetStatus(
        categories,
        allTx,
        budgetEntries,
        cycle,
        includeArchived: true,
      );
      final categoryExpenses = <String, double>{};
      final categoryBudgets = <String, double>{};
      for (final status in budgetStatuses) {
        if (!isCycleReportSpendingStatus(status)) continue;
        categoryBudgets[status.category.name] = status.total;
        categoryExpenses[status.category.name] = status.spent;
      }

      // FONT ÚNICA DE CÀLCUL (mateixes regles que Dashboard i Trends).
      final look = LedgerLookups.from(categories);
      final ledger = summarizeLedger(cycleTx, look);
      final double totalIncome = ledger.totalIncome;
      final double totalExpense = ledger.totalExpense;

      // 3. Calculate metrics
      double savingsPercentage = 0;
      if (totalIncome > 0) {
        savingsPercentage = (ledger.netSaved / totalIncome) * 100;
      }

      // Dies sense despesa canònica: guardioles i refunds no creen falsos dies
      // de despesa.
      final totalDays = cycle.endDate.difference(cycle.startDate).inDays + 1;
      final zeroExpenseDays = countCanonicalZeroExpenseDays(
        cycle: cycle,
        cycleTransactions: cycleTx,
        lookups: look,
      );
      final personalTransferIncome = calculatePersonalTransferIncome(
        cycleTransactions: cycleTx,
        categories: categories,
        lookups: look,
      );

      // Deviations
      final deviations = <String, double>{};
      for (final cat in categoryExpenses.keys) {
        final spent = categoryExpenses[cat] ?? 0.0;
        final budget = categoryBudgets[cat] ?? 0.0;
        if (budget > 0) {
          deviations[cat] = spent - budget;
        }
      }

      final sortedDeviations = deviations.keys.toList()
        ..sort((a, b) => deviations[b]!.compareTo(deviations[a]!));

      final topOverspent = sortedDeviations
          .where((cat) => deviations[cat]! > 0)
          .take(3)
          .map((cat) => {
                'categoria': cat,
                'despesa': categoryExpenses[cat],
                'pressupost': categoryBudgets[cat],
                'desviacio': deviations[cat]
              })
          .toList();

      final topSaved = sortedDeviations.reversed
          .where((cat) => deviations[cat]! < 0)
          .take(3)
          .map((cat) => {
                'categoria': cat,
                'despesa': categoryExpenses[cat],
                'pressupost': categoryBudgets[cat],
                'estalvi': -(deviations[cat]!)
              })
          .toList();

      // Despeses fora de pressupost. No pressuposa que fossin imprevistes ni
      // intenta casar-les automàticament amb un ingrés compensatori.
      final unexpectedExpenses = <Map<String, dynamic>>[];
      for (final cat in categoryExpenses.keys) {
        final spent = categoryExpenses[cat] ?? 0.0;
        final budget = categoryBudgets[cat] ?? 0.0;
        if (spent > 0 && budget == 0.0) {
          unexpectedExpenses.add({
            'categoria': cat,
            'despesa': spent,
            'pressupost': budget,
            'desviacio': spent
          });
        }
      }

      // 4. Generate AI Insight (Simulating FinancialSummary for the AI context)
      final dummySummary = FinancialSummary(
        totalNetWorth: 0.0,
        totalAssets: 0.0,
        totalLiabilities: 0.0,
        equityRatio: 0.0,
        monthlyIncome: totalIncome,
        savingsWithdrawalIncome: ledger.withdrawnThisCycle,
        monthlyExpenses: totalExpense,
        netOfCycle: totalIncome - totalExpense,
        savingsPercentage: savingsPercentage,
        debtPercentage: 0.0,
        livingExpensesPercentage: 0.0,
        savedThisCycle: ledger.savedThisCycle,
        withdrawnThisCycle: ledger.withdrawnThisCycle,
      );

      final userProfile = await ref.read(userProfileProvider.future);
      final userName = userProfile?.name ?? 'Usuari';

      final aiService = ref.read(aiCoachServiceProvider);
      final insight = await aiService.generateCycleVerdict(
        userName: userName,
        summary: dummySummary,
        activeCycle: cycle,
        categoryExpenses: categoryExpenses,
        categoryBudgets: categoryBudgets,
        zeroExpenseDays: zeroExpenseDays,
        totalDays: totalDays,
        unexpectedExpenses: unexpectedExpenses,
        savedThisCycle: ledger.savedThisCycle,
        withdrawnThisCycle: ledger.withdrawnThisCycle,
        personalTransferIncome: personalTransferIncome,
        isHistorical: true,
      );

      // 5. Create Model & Save
      final report = CycleReport(
        id: cycle.id,
        groupId: groupId,
        cycleId: cycle.id,
        generatedAt: DateTime.now(),
        aiVerdict: insight,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        savingsPercentage: savingsPercentage,
        savedThisCycle: ledger.savedThisCycle,
        withdrawnThisCycle: ledger.withdrawnThisCycle,
        netSaved: ledger.netSaved,
        personalTransferIncome: personalTransferIncome,
        topOverspent: topOverspent,
        topSaved: topSaved,
        zeroExpenseDays: zeroExpenseDays > 0 ? zeroExpenseDays : 0,
        totalDays: totalDays,
        unexpectedExpenses: unexpectedExpenses,
        generatedForStartDate: cycle.startDate,
        generatedForEndDate: cycle.endDate,
        sourceFingerprint: buildCycleReportSourceFingerprint(
          cycle: cycle,
          transactions: allTx,
          categories: categories,
          budgetEntries: budgetEntries,
        ),
        reportSchemaVersion: kCycleReportSchemaVersion,
        ledgerSchemaVersion: kLedgerSchemaVersion,
        schemaVersion: kLedgerSchemaVersion,
      );

      final repo = ref.read(cycleReportRepositoryProvider);
      await repo.saveReport(report);

      state = AsyncValue.data(report);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
