import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/category.dart';
import '../../domain/services/ledger_service.dart';
import 'transaction_notifier.dart';
import 'category_notifier.dart';

part 'trends_provider.g.dart';

enum TrendsTimeFilter {
  thisMonth,
  lastMonth,
  last3Months,
  thisYear,
}

// Provider for the currently selected filter
@riverpod
class TrendsFilterNotifier extends _$TrendsFilterNotifier {
  @override
  TrendsTimeFilter build() {
    return TrendsTimeFilter.thisYear; // Default to 12 months/this year
  }

  void setFilter(TrendsTimeFilter filter) {
    state = filter;
  }
}

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

class SubcategoryTrendData {
  final String name;
  final double totalAmount;
  final double percentage; // percentage within parent category

  SubcategoryTrendData({
    required this.name,
    required this.totalAmount,
    required this.percentage,
  });
}

class CategoryTrendData {
  final Category category;
  final double totalAmount;
  final double percentage;
  final List<SubcategoryTrendData> subcategories;

  CategoryTrendData({
    required this.category,
    required this.totalAmount,
    required this.percentage,
    this.subcategories = const [],
  });
}

class TrendsData {
  final List<MonthlyTrendData> monthlyFlow;
  final List<CategoryTrendData> topCategories;
  final double savingsRate;
  final DateTime startDate;
  final DateTime endDate;

  TrendsData({
    required this.monthlyFlow,
    required this.topCategories,
    required this.savingsRate,
    required this.startDate,
    required this.endDate,
  });
}

@riverpod
class TrendsNotifier extends _$TrendsNotifier {
  @override
  Future<TrendsData> build() async {
    final transactions = await ref.watch(transactionNotifierProvider.future);
    final categories = await ref.watch(categoryNotifierProvider.future);
    final selectedFilter = ref.watch(trendsFilterNotifierProvider);

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    int monthsToPlot = 0;

    switch (selectedFilter) {
      case TrendsTimeFilter.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        monthsToPlot = 1;
        break;
      case TrendsTimeFilter.lastMonth:
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        monthsToPlot = 1;
        break;
      case TrendsTimeFilter.last3Months:
        // Include current month + 2 previous
        startDate = DateTime(now.year, now.month - 2, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        monthsToPlot = 3;
        break;
      case TrendsTimeFilter.thisYear:
        // Last 12 months (or current year, let's stick to last 12 for trends)
        startDate = DateTime(now.year, now.month - 11, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        monthsToPlot = 12;
        break;
    }

    final recentTransactions = transactions.where((t) {
      return t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // FONT ÚNICA DE CÀLCUL: classifiquem cada moviment amb les mateixes regles
    // que el Dashboard (exclou guardioles/transfers, refunds resten, etc.).
    final look = LedgerLookups.from(categories);

    // 2. Monthly Flow
    Map<String, MonthlyTrendData> monthlyMap = {};

    // Initialize map for the required months to ensure 0s
    for (int i = 0; i < monthsToPlot; i++) {
      // If filtering 'lastMonth', we start from now.month-1, so base date offset varies
      final offset = (selectedFilter == TrendsTimeFilter.lastMonth) ? i + 1 : i;
      final d = DateTime(now.year, now.month - offset, 1);
      final key = "${d.year}-${d.month}";
      monthlyMap[key] = MonthlyTrendData(month: d, income: 0, expense: 0);
    }

    for (var t in recentTransactions) {
      final key = "${t.date.year}-${t.date.month}";
      if (!monthlyMap.containsKey(key)) continue;
      final c = classifyTransaction(t, look);
      final current = monthlyMap[key]!;
      if (c.bucket == LedgerBucket.income) {
        monthlyMap[key] = MonthlyTrendData(
          month: current.month,
          income: current.income + c.delta,
          expense: current.expense,
        );
      } else if (c.bucket == LedgerBucket.expense) {
        monthlyMap[key] = MonthlyTrendData(
          month: current.month,
          income: current.income,
          expense: current.expense + c.delta,
        );
      }
      // saved/withdrawn (guardioles) no entren al flux mensual.
    }

    final monthlyFlow = monthlyMap.values.toList()
      ..sort((a, b) => a.month.compareTo(b.month)); // Oldest first

    // 3. Top Categories (despesa canònica: exclou guardioles, refunds resten)
    Map<String, double> categoryTotals = {};
    double totalExpenses = 0;

    for (var t in recentTransactions) {
      final c = classifyTransaction(t, look);
      if (c.bucket == LedgerBucket.expense) {
        categoryTotals[t.categoryId] =
            (categoryTotals[t.categoryId] ?? 0) + c.delta;
        totalExpenses += c.delta;
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

        // Compute subcategory breakdown for this category
        final subcatTotals = <String, double>{};
        for (var t in recentTransactions) {
          if (t.categoryId != entry.key) continue;
          final c = classifyTransaction(t, look);
          if (c.bucket != LedgerBucket.expense) continue;
          final subName = t.subCategoryName.isNotEmpty
              ? t.subCategoryName
              : 'Sense subcategoria';
          subcatTotals[subName] = (subcatTotals[subName] ?? 0) + c.delta;
        }
        final sortedSubcats = subcatTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final subcategories = sortedSubcats
            .map((s) => SubcategoryTrendData(
                  name: s.key,
                  totalAmount: s.value,
                  percentage: entry.value > 0 ? s.value / entry.value : 0,
                ))
            .toList();

        topCategories.add(
          CategoryTrendData(
            category: category,
            totalAmount: entry.value,
            percentage: totalExpenses > 0 ? entry.value / totalExpenses : 0,
            subcategories: subcategories,
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
    // Calculat sobre tot el període amb els totals canònics del ledger.
    final periodLedger = summarizeLedger(recentTransactions, look);
    double totalPeriodIncome = periodLedger.totalIncome;
    double totalPeriodExpense = periodLedger.totalExpense;

    double savingsRate = 0;
    if (totalPeriodIncome > 0) {
      savingsRate =
          (totalPeriodIncome - totalPeriodExpense) / totalPeriodIncome;
    }

    return TrendsData(
      monthlyFlow: monthlyFlow,
      topCategories: topCategories,
      savingsRate: savingsRate,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
