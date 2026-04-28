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

part 'cycle_reports_provider.g.dart';

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

      // 1. Get all transactions and filter for this cycle
      final allTx = await ref.read(transactionNotifierProvider.future);
      final cycleTx = allTx.where((t) {
        final tDay = DateTime(t.date.year, t.date.month, t.date.day, 12, 0, 0);
        final startDay = DateTime(cycle.startDate.year, cycle.startDate.month,
            cycle.startDate.day, 12, 0, 0);
        final endDay = DateTime(cycle.endDate.year, cycle.endDate.month,
            cycle.endDate.day, 12, 0, 0);

        return (tDay.isAtSameMomentAs(startDay) || tDay.isAfter(startDay)) &&
            !tDay.isAfter(endDay);
      }).toList();

      // 2. Get categories and calculate expenses/budgets
      final categories = await ref.read(categoryNotifierProvider.future);
      final categoryExpenses = <String, double>{};
      final categoryBudgets = <String, double>{};

      for (final cat in categories) {
        if (cat.type == TransactionType.income) continue;
        double catBudget = 0.0;
        for (final sub in cat.subcategories) {
          catBudget += sub.monthlyBudget;
        }
        categoryBudgets[cat.name] = catBudget;
        categoryExpenses[cat.name] = 0.0;
      }

      double totalIncome = 0;
      double totalExpense = 0;

      for (final tx in cycleTx) {
        if (tx.isIncome) {
          totalIncome += tx.amount;
        } else {
          totalExpense += tx.amount;
          if (tx.categoryId.isNotEmpty) {
            final cat = categories.firstWhere((c) => c.id == tx.categoryId,
                orElse: () => categories.first);
            if (cat.id == tx.categoryId) {
              categoryExpenses[cat.name] =
                  (categoryExpenses[cat.name] ?? 0.0) + tx.amount;
            }
          }
        }
      }

      // 3. Calculate metrics
      double savingsPercentage = 0;
      if (totalIncome > 0) {
        final saved = totalIncome - totalExpense;
        savingsPercentage = (saved / totalIncome) * 100;
        if (savingsPercentage < 0) savingsPercentage = 0;
      }

      // Zero Expense Days
      final totalDays = cycle.endDate.difference(cycle.startDate).inDays + 1;
      final expenseDays = <String>{};
      for (final tx in cycleTx) {
        if (!tx.isIncome && tx.amount > 0) {
          final dayKey = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
          expenseDays.add(dayKey);
        }
      }
      final zeroExpenseDays = totalDays - expenseDays.length;

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

      // Unexpected Expenses (Imprevistos purs)
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
        savingsWithdrawalIncome: 0.0,
        monthlyExpenses: totalExpense,
        availableToSpend: totalIncome - totalExpense,
        savingsPercentage: savingsPercentage,
        debtPercentage: 0.0,
        livingExpensesPercentage: 0.0,
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
        unexpectedExpenses: unexpectedExpenses,
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
        topOverspent: topOverspent,
        topSaved: topSaved,
        zeroExpenseDays: zeroExpenseDays > 0 ? zeroExpenseDays : 0,
        totalDays: totalDays,
        unexpectedExpenses: unexpectedExpenses,
      );

      final repo = ref.read(cycleReportRepositoryProvider);
      await repo.saveReport(report);

      state = AsyncValue.data(report);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
