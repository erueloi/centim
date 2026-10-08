import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/asset.dart';
import '../../domain/models/financial_summary.dart';
import '../../domain/models/savings_goal.dart';
import '../../domain/services/ledger_service.dart';
import 'asset_provider.dart';
import 'transaction_notifier.dart';
import 'debt_provider.dart';
import 'billing_cycle_provider.dart';
import 'category_notifier.dart';
import 'savings_goal_provider.dart';

part 'financial_summary_provider.g.dart';

/// Actiu del patrimoni: actius registrats + guardioles. Les guardioles són
/// comptes reals de CaixaBank que no figuren entre els actius, així que
/// sumar-les no compta res dues vegades. Sense res introduït, és 0.
double totalAssetsOf(Iterable<Asset> assets, Iterable<SavingsGoal> goals) {
  final registered = assets.fold(0.0, (sum, a) => sum + a.amount);
  final saved = goals.fold(0.0, (sum, g) => sum + g.currentAmount);
  return registered + saved;
}

@riverpod
class FinancialSummaryNotifier extends _$FinancialSummaryNotifier {
  @override
  Future<FinancialSummary> build() async {
    final transactions = await ref.watch(transactionNotifierProvider.future);
    final debts = await ref.watch(debtNotifierProvider.future);
    final assets = await ref.watch(assetNotifierProvider.future);
    final goals = await ref.watch(savingsGoalNotifierProvider.future);
    final categories = await ref.watch(categoryNotifierProvider.future);
    final cycle = ref.watch(activeCycleProvider);

    // Moviments dins del cicle actiu.
    final currentMonthTransactions = transactions.where((t) {
      final tDay = DateTime(t.date.year, t.date.month, t.date.day, 12, 0, 0);
      final startDay = DateTime(cycle.startDate.year, cycle.startDate.month,
          cycle.startDate.day, 12, 0, 0);
      final endDay = DateTime(
          cycle.endDate.year, cycle.endDate.month, cycle.endDate.day, 12, 0, 0);
      return (tDay.isAtSameMomentAs(startDay) || tDay.isAfter(startDay)) &&
          !tDay.isAfter(endDay);
    }).toList();

    // ─── FONT ÚNICA DE CÀLCUL ───
    final look = LedgerLookups.from(categories);
    final ledger = summarizeLedger(currentMonthTransactions, look);

    // 1. Patrimoni i deute
    final totalAssets = totalAssetsOf(assets, goals);
    final totalLiabilities =
        debts.fold(0.0, (sum, d) => sum + d.currentBalance);
    final totalNetWorth = totalAssets - totalLiabilities;
    final equityRatio = totalAssets > 0 ? totalNetWorth / totalAssets : 0.0;

    // 2. Totals canònics (del ledger, sense filtrar res)
    final monthlyIncome = ledger.totalIncome;
    final monthlyExpenses = ledger.totalExpense;
    final netOfCycle = monthlyIncome - monthlyExpenses;

    // Els mapes per categoria: filtrar ≤ 0 és PRESENTACIÓ (el donut no vol
    // seccions buides/negatives). Els totals de dalt NO depenen d'aquest filtre.
    final incomesByCategory = Map<String, double>.from(ledger.incomeByCategory)
      ..removeWhere((k, v) => v <= 0);
    final expensesByCategory =
        Map<String, double>.from(ledger.expenseByCategory)
          ..removeWhere((k, v) => v <= 0);

    // 3. Mètriques 10/30/60 (estalvi = el que va a guardioles aquest cicle)
    final savings = ledger.savedThisCycle;
    final monthlyDebtInstallments =
        debts.fold(0.0, (sum, d) => sum + d.monthlyInstallment);
    final otherExpenses = monthlyExpenses;
    final totalForBudget = savings + monthlyDebtInstallments + otherExpenses;

    return FinancialSummary(
      totalNetWorth: totalNetWorth,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      equityRatio: equityRatio,
      monthlyIncome: monthlyIncome,
      savingsWithdrawalIncome: ledger.withdrawnThisCycle,
      monthlyExpenses: monthlyExpenses,
      netOfCycle: netOfCycle,
      savingsPercentage: totalForBudget > 0 ? savings / totalForBudget : 0.0,
      debtPercentage:
          totalForBudget > 0 ? monthlyDebtInstallments / totalForBudget : 0.0,
      livingExpensesPercentage:
          totalForBudget > 0 ? otherExpenses / totalForBudget : 0.0,
      incomesByCategory: incomesByCategory,
      expensesByCategory: expensesByCategory,
      savedThisCycle: ledger.savedThisCycle,
      withdrawnThisCycle: ledger.withdrawnThisCycle,
      savedByGoal: ledger.savedByGoal,
      withdrawnByGoal: ledger.withdrawnByGoal,
    );
  }
}
