import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/financial_summary.dart';
import 'transaction_notifier.dart';
import 'debt_provider.dart';
import 'group_providers.dart';
import 'billing_cycle_provider.dart';

part 'financial_summary_provider.g.dart';

@riverpod
class FinancialSummaryNotifier extends _$FinancialSummaryNotifier {
  @override
  Future<FinancialSummary> build() async {
    final transactions = await ref.watch(transactionNotifierProvider.future);
    final debts = await ref.watch(debtNotifierProvider.future);
    final group = await ref.watch(currentGroupProvider.future);

    // Use Active Cycle instead of Natural Month
    final cycle = ref.watch(activeCycleProvider);

    // Logic: t.date >= cycle.startDate && t.date <= cycle.endDate
    // (Note: cycle.endDate is inclusive 23:59:59 in my implementation)
    // Actually, the provider logic was: date >= startDate && date < nextStartDate
    // My BillingCycle model has explicit startDate and endDate.
    // Let's use them.
    final currentMonthTransactions = transactions.where((t) {
      return t.date.isAfter(
            cycle.startDate.subtract(const Duration(seconds: 1)),
          ) &&
          t.date.isBefore(cycle.endDate.add(const Duration(seconds: 1)));
    }).toList();

    // 1. Assets & Liabilities
    // If group.totalAssets is 0, we fallback to the user's specific figure for a better initial experience
    final totalAssets =
        (group?.totalAssets ?? 0) > 0 ? group!.totalAssets : 100389.92;

    final totalLiabilities = debts.fold(
      0.0,
      (sum, d) => sum + d.currentBalance,
    );
    final totalNetWorth = totalAssets - totalLiabilities;
    final equityRatio = totalAssets > 0 ? totalNetWorth / totalAssets : 0.0;

    // 2. Cash Flow
    final monthlyIncome = currentMonthTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    final monthlyDebtInstallments = debts.fold(
      0.0,
      (sum, d) => sum + d.monthlyInstallment,
    );

    // Income minus expenses (which usually includes installments if recorded as transactions)
    // But if they want "Saldo restant un cop deduïts deutes i estalvi programat":
    // It implies: Income - Fixed Expenses - Savings.

    // EXCLUDE expenses paid from savings (savingsGoalId != null)
    final monthlyExpenses = currentMonthTransactions
        .where((t) => !t.isIncome && t.savingsGoalId == null)
        .fold(0.0, (sum, t) => sum + t.amount);

    final availableToSpend = monthlyIncome - monthlyExpenses;

    // 3. 10/30/60 Metrics
    // Savings: Transactions in categories name containing 'Estalvi' or 'Inversió'
    final savings = currentMonthTransactions
        .where(
          (t) =>
              !t.isIncome &&
              (t.categoryName.toLowerCase().contains('estalvi') ||
                  t.categoryName.toLowerCase().contains('invers') ||
                  t.categoryName.toLowerCase().contains('saving')),
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final debtsPayment = monthlyDebtInstallments; // Based on debt accounts
    final otherExpenses = monthlyExpenses - savings;

    final totalForBudget = savings + debtsPayment + otherExpenses;

    return FinancialSummary(
      totalNetWorth: totalNetWorth,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      equityRatio: equityRatio,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      availableToSpend: availableToSpend,
      savingsPercentage: totalForBudget > 0 ? savings / totalForBudget : 0.0,
      debtPercentage: totalForBudget > 0 ? debtsPayment / totalForBudget : 0.0,
      livingExpensesPercentage:
          totalForBudget > 0 ? otherExpenses / totalForBudget : 0.0,
    );
  }
}
