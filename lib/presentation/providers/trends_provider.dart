import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/category.dart';
import 'transaction_notifier.dart';
import 'category_notifier.dart';

part 'trends_provider.g.dart';

class MonthlyTrendData {
  final DateTime month;
  final double income;
  final double expense;

  MonthlyTrendData({
    required this.month,
    required this.income,
    required this.expense,
  });
}

class CategoryTrendData {
  final Category category;
  final double totalAmount;
  final double percentage;

  CategoryTrendData({
    required this.category,
    required this.totalAmount,
    required this.percentage,
  });
}

class TrendsData {
  final List<MonthlyTrendData> monthlyFlow;
  final List<CategoryTrendData> topCategories;
  final double savingsRate;

  TrendsData({
    required this.monthlyFlow,
    required this.topCategories,
    required this.savingsRate,
  });
}

@riverpod
class TrendsNotifier extends _$TrendsNotifier {
  @override
  Future<TrendsData> build() async {
    final transactions = await ref.watch(transactionNotifierProvider.future);
    final categories = await ref.watch(categoryNotifierProvider.future);

    // 1. Filter Last 12 Months
    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month - 11,
      1,
    ); // 12 months roughly

    final recentTransactions = transactions.where((t) {
      return t.date.isAfter(startDate.subtract(const Duration(days: 1)));
    }).toList();

    // 2. Monthly Flow
    Map<String, MonthlyTrendData> monthlyMap = {};

    // Initialize map for all 12 months to ensure 0s
    for (int i = 0; i < 12; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = "${d.year}-${d.month}";
      monthlyMap[key] = MonthlyTrendData(month: d, income: 0, expense: 0);
    }

    for (var t in recentTransactions) {
      final key = "${t.date.year}-${t.date.month}";
      if (monthlyMap.containsKey(key)) {
        final current = monthlyMap[key]!;
        if (t.isIncome) {
          monthlyMap[key] = MonthlyTrendData(
            month: current.month,
            income: current.income + t.amount,
            expense: current.expense,
          );
        } else {
          monthlyMap[key] = MonthlyTrendData(
            month: current.month,
            income: current.income,
            expense: current.expense + t.amount,
          );
        }
      }
    }

    final monthlyFlow = monthlyMap.values.toList()
      ..sort((a, b) => a.month.compareTo(b.month)); // Oldest first

    // 3. Top Categories (Expense only)
    Map<String, double> categoryTotals = {};
    double totalExpenses = 0;

    for (var t in recentTransactions) {
      if (!t.isIncome) {
        categoryTotals[t.categoryId] =
            (categoryTotals[t.categoryId] ?? 0) + t.amount;
        totalExpenses += t.amount;
      }
    }

    // Sort by amount desc
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5
    List<CategoryTrendData> topCategories = [];
    double othersTotal = 0;

    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      if (i < 5) {
        final category = categories.firstWhere(
          (c) => c.id == entry.key,
          orElse: () => const Category(
            id: 'unknown',
            name: 'Desconegut',
            icon: '❓',
            type: TransactionType.expense,
          ),
        );
        topCategories.add(
          CategoryTrendData(
            category: category,
            totalAmount: entry.value,
            percentage: totalExpenses > 0 ? entry.value / totalExpenses : 0,
          ),
        );
      } else {
        othersTotal += entry.value;
      }
    }

    if (othersTotal > 0) {
      topCategories.add(
        CategoryTrendData(
          category: const Category(
            id: 'others',
            name: 'Altres',
            icon: '📦',
            type: TransactionType.expense,
            color: 0xFF9E9E9E,
          ), // Grey
          totalAmount: othersTotal,
          percentage: totalExpenses > 0 ? othersTotal / totalExpenses : 0,
        ),
      );
    }

    // 4. Savings Rate (Total Income - Total Expense) / Total Income
    // Calculated over the whole period
    double totalPeriodIncome = recentTransactions
        .where((t) => t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);
    double totalPeriodExpense = recentTransactions
        .where((t) => !t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);

    double savingsRate = 0;
    if (totalPeriodIncome > 0) {
      savingsRate =
          (totalPeriodIncome - totalPeriodExpense) / totalPeriodIncome;
    }

    return TrendsData(
      monthlyFlow: monthlyFlow,
      topCategories: topCategories,
      savingsRate: savingsRate,
    );
  }
}
