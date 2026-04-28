import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/financial_summary.dart';
import '../../domain/models/category.dart';
import 'transaction_notifier.dart';
import 'debt_provider.dart';
import 'group_providers.dart';
import 'billing_cycle_provider.dart';
import 'category_notifier.dart';

part 'financial_summary_provider.g.dart';

@riverpod
class FinancialSummaryNotifier extends _$FinancialSummaryNotifier {
  @override
  Future<FinancialSummary> build() async {
    final transactions = await ref.watch(transactionNotifierProvider.future);
    final debts = await ref.watch(debtNotifierProvider.future);
    final group = await ref.watch(currentGroupProvider.future);
    final categories = await ref.watch(categoryNotifierProvider.future);
    final cycle = ref.watch(activeCycleProvider);

    final linkedSavingsSubIds = <String>{};
    for (var cat in categories) {
      for (var sub in cat.subcategories) {
        if (sub.linkedSavingsGoalId != null) {
          linkedSavingsSubIds.add(sub.id);
        }
      }
    }

    final currentMonthTransactions = transactions.where((t) {
      final tDay = DateTime(t.date.year, t.date.month, t.date.day, 12, 0, 0);
      final startDay = DateTime(cycle.startDate.year, cycle.startDate.month,
          cycle.startDate.day, 12, 0, 0);
      final endDay = DateTime(
          cycle.endDate.year, cycle.endDate.month, cycle.endDate.day, 12, 0, 0);

      return (tDay.isAtSameMomentAs(startDay) || tDay.isAfter(startDay)) &&
          !tDay.isAfter(endDay);
    }).toList();

    // 1. Assets & Liabilities
    final totalAssets =
        (group?.totalAssets ?? 0) > 0 ? group!.totalAssets : 100389.92;
    final totalLiabilities =
        debts.fold(0.0, (sum, d) => sum + d.currentBalance);
    final totalNetWorth = totalAssets - totalLiabilities;
    final equityRatio = totalAssets > 0 ? totalNetWorth / totalAssets : 0.0;

    // 2. Net Categorical Aggregation
    final incomesByCategory = <String, double>{};
    final expensesByCategory = <String, double>{};

    double savedThisCycle = 0.0;
    double withdrawnThisCycle = 0.0;

    for (final t in currentMonthTransactions) {
      // EXCLUSION: If it's a savings goal movement, don't include in categorized charts or "External" totals
      final isSavingsMovement = t.savingsGoalId != null ||
          linkedSavingsSubIds.contains(t.subCategoryId);
      if (isSavingsMovement) {
        if (t.isIncome) {
          withdrawnThisCycle += t.amount;
        } else {
          savedThisCycle += t.amount;
        }
        continue;
      }

      final category = categories.cast<Category?>().firstWhere(
            (c) => c?.id == t.categoryId,
            orElse: () => null,
          );

      if (category == null) continue;

      if (category.type == TransactionType.income) {
        final current = incomesByCategory[t.categoryId] ?? 0.0;
        if (t.isIncome) {
          incomesByCategory[t.categoryId] = current + t.amount;
        } else {
          // Devolució d'ingrés
          incomesByCategory[t.categoryId] = current - t.amount;
        }
      } else {
        // Expense Type Category
        final current = expensesByCategory[t.categoryId] ?? 0.0;
        if (!t.isIncome) {
          // Normal expense
          expensesByCategory[t.categoryId] = current + t.amount;
        } else {
          // Refund
          expensesByCategory[t.categoryId] = current - t.amount;
        }
      }
    }

    // Filter out <= 0 values to avoid donut chart issues
    incomesByCategory.removeWhere((key, value) => value <= 0);
    expensesByCategory.removeWhere((key, value) => value <= 0);

    // 3. Totals (External only for high-level overview)
    final monthlyIncomeExternal =
        incomesByCategory.values.fold(0.0, (sum, val) => sum + val);
    final monthlyExpensesExternal =
        expensesByCategory.values.fold(0.0, (sum, val) => sum + val);

    final savingsWithdrawalIncome = currentMonthTransactions
        .where((t) =>
            t.isIncome &&
            (t.savingsGoalId != null ||
                linkedSavingsSubIds.contains(t.subCategoryId)))
        .fold(0.0, (sum, t) => sum + t.amount);

    // Balance available reflects categorized cash flow (excluding savings movements)
    final availableToSpend = monthlyIncomeExternal - monthlyExpensesExternal;

    // 10/30/60 Metrics (based on categorized expenses)
    // Savings: transactions in savings categories (external contributions, not internal transfers)
    final savings = expensesByCategory.entries.where((e) {
      final cat = categories.firstWhere((c) => c.id == e.key);
      final name = cat.name.toLowerCase();
      return name.contains('estalvi') ||
          name.contains('invers') ||
          name.contains('saving');
    }).fold(0.0, (sum, e) => sum + e.value);

    final monthlyDebtInstallments =
        debts.fold(0.0, (sum, d) => sum + d.monthlyInstallment);
    final otherExpenses = monthlyExpensesExternal - savings;
    final totalForBudget = savings + monthlyDebtInstallments + otherExpenses;

    return FinancialSummary(
      totalNetWorth: totalNetWorth,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      equityRatio: equityRatio,
      monthlyIncome: monthlyIncomeExternal,
      savingsWithdrawalIncome: savingsWithdrawalIncome,
      monthlyExpenses: monthlyExpensesExternal,
      availableToSpend: availableToSpend,
      savingsPercentage: totalForBudget > 0 ? savings / totalForBudget : 0.0,
      debtPercentage:
          totalForBudget > 0 ? monthlyDebtInstallments / totalForBudget : 0.0,
      livingExpensesPercentage:
          totalForBudget > 0 ? otherExpenses / totalForBudget : 0.0,
      incomesByCategory: incomesByCategory,
      expensesByCategory: expensesByCategory,
      savedThisCycle: savedThisCycle,
      withdrawnThisCycle: withdrawnThisCycle,
    );
  }
}
