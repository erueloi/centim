import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
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
  final bool isIncomplete;

  MonthlyTrendData({
    required this.month,
    required this.income,
    required this.expense,
    this.isIncomplete = false,
  });
}

class SubcategoryTrendData {
  final String id;
  final String name;
  final double totalAmount;
  final double percentage; // percentage within parent category

  SubcategoryTrendData({
    required this.id,
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
  final Set<String> categoryIds;

  CategoryTrendData({
    required this.category,
    required this.totalAmount,
    required this.percentage,
    this.subcategories = const [],
    Set<String>? categoryIds,
  }) : categoryIds = categoryIds ?? {category.id};
}

class TrendsData {
  final List<MonthlyTrendData> monthlyFlow;
  final List<CategoryTrendData> topCategories;
  final double savingsRate;
  final DateTime startDate;
  final DateTime endDate;
  final bool currentMonthExcludedFromFlow;

  TrendsData({
    required this.monthlyFlow,
    required this.topCategories,
    required this.savingsRate,
    required this.startDate,
    required this.endDate,
    this.currentMonthExcludedFromFlow = false,
  });
}

enum SavingsRateLevel { veryTight, improvable, good, veryGood }

SavingsRateLevel savingsRateLevel(double rate) {
  if (rate < 0.05) return SavingsRateLevel.veryTight;
  if (rate < 0.10) return SavingsRateLevel.improvable;
  if (rate <= 0.20) return SavingsRateLevel.good;
  return SavingsRateLevel.veryGood;
}

String savingsRateMessage(double rate) => switch (savingsRateLevel(rate)) {
      SavingsRateLevel.veryTight => 'Molt just',
      SavingsRateLevel.improvable => 'Millorable',
      SavingsRateLevel.good => 'Vas bé',
      SavingsRateLevel.veryGood => 'Molt bé',
    };

@riverpod
class TrendsNotifier extends _$TrendsNotifier {
  @override
  Future<TrendsData> build() async {
    final transactions = await ref.watch(transactionNotifierProvider.future);
    final categories = await ref.watch(categoryNotifierProvider.future);
    final selectedFilter = ref.watch(trendsFilterNotifierProvider);

    return calculateTrendsData(
      transactions: transactions,
      categories: categories,
      selectedFilter: selectedFilter,
      now: DateTime.now(),
    );
  }
}

TrendsData calculateTrendsData({
  required List<Transaction> transactions,
  required List<Category> categories,
  required TrendsTimeFilter selectedFilter,
  required DateTime now,
}) {
  DateTime startDate;
  DateTime endDate;

  switch (selectedFilter) {
    case TrendsTimeFilter.thisMonth:
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      break;
    case TrendsTimeFilter.lastMonth:
      startDate = DateTime(now.year, now.month - 1, 1);
      endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
      break;
    case TrendsTimeFilter.last3Months:
      // Include current month + 2 previous
      startDate = DateTime(now.year, now.month - 2, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      break;
    case TrendsTimeFilter.thisYear:
      // Last 12 months (or current year, let's stick to last 12 for trends)
      startDate = DateTime(now.year, now.month - 11, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      break;
  }

  final recentTransactions = transactions.where((t) {
    return t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.date.isBefore(endDate.add(const Duration(days: 1)));
  }).toList();

  // FONT ÚNICA DE CÀLCUL: classifiquem cada moviment amb les mateixes regles
  // que el Dashboard (exclou guardioles/transfers, refunds resten, etc.).
  final look = LedgerLookups.from(categories);

  // Només es creen punts per als mesos que contenen moviments canònics.
  // Així un mes sense dades no es dibuixa com si fos un zero real.
  final monthlyMap = <String, MonthlyTrendData>{};
  var currentMonthExcludedFromFlow = false;

  for (var t in recentTransactions) {
    final key = "${t.date.year}-${t.date.month}";
    final c = classifyTransaction(t, look);
    if (c.bucket != LedgerBucket.income && c.bucket != LedgerBucket.expense) {
      continue;
    }
    final isCurrentMonth = t.date.year == now.year && t.date.month == now.month;
    if (isCurrentMonth && selectedFilter != TrendsTimeFilter.thisMonth) {
      currentMonthExcludedFromFlow = true;
      continue;
    }
    final current = monthlyMap[key] ??
        MonthlyTrendData(
          month: DateTime(t.date.year, t.date.month),
          income: 0,
          expense: 0,
          isIncomplete: isCurrentMonth,
        );
    if (c.bucket == LedgerBucket.income) {
      monthlyMap[key] = MonthlyTrendData(
        month: current.month,
        income: current.income + c.delta,
        expense: current.expense,
        isIncomplete: current.isIncomplete,
      );
    } else if (c.bucket == LedgerBucket.expense) {
      monthlyMap[key] = MonthlyTrendData(
        month: current.month,
        income: current.income,
        expense: current.expense + c.delta,
        isIncomplete: current.isIncomplete,
      );
    }
    // saved/withdrawn (guardioles) no entren al flux mensual.
  }

  final monthlyFlow = monthlyMap.values.toList()
    ..sort((a, b) => a.month.compareTo(b.month)); // Oldest first

  // 3. Top Categories (despesa canònica: exclou guardioles, refunds resten)
  final categoryTotals = <String, double>{};
  final subcategoryTotals = <String, Map<String, double>>{};
  final historicalCategoryNames = <String, String>{};
  final historicalSubcategoryNames = <String, String>{};

  for (var t in recentTransactions) {
    final c = classifyTransaction(t, look);
    if (c.bucket == LedgerBucket.expense) {
      categoryTotals[t.categoryId] =
          (categoryTotals[t.categoryId] ?? 0) + c.delta;
      final subcategoryKey =
          t.subCategoryId.isEmpty ? '__without_subcategory__' : t.subCategoryId;
      final totals = subcategoryTotals.putIfAbsent(t.categoryId, () => {});
      totals[subcategoryKey] = (totals[subcategoryKey] ?? 0) + c.delta;
      if (t.categoryName.isNotEmpty) {
        historicalCategoryNames[t.categoryId] = t.categoryName;
      }
      if (t.subCategoryName.isNotEmpty) {
        historicalSubcategoryNames['${t.categoryId}:$subcategoryKey'] =
            t.subCategoryName;
      }
    }
  }

  // Sort by amount desc
  final sortedCategories = categoryTotals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final categoryById = {
    for (final category in categories) category.id: category
  };
  final subcategoryByKey = <String, SubCategory>{
    for (final category in categories)
      for (final subcategory in category.subcategories)
        '${category.id}:${subcategory.id}': subcategory,
  };
  final periodLedger = summarizeLedger(recentTransactions, look);
  final totalExpenses = periodLedger.totalExpense;

  // Vuit categories amb nom propi; la cua queda a «Altres» i també té detall.
  const visibleCategoryCount = 8;
  final topCategories = <CategoryTrendData>[];
  double othersTotal = 0;
  final otherEntries = <MapEntry<String, double>>[];

  for (int i = 0; i < sortedCategories.length; i++) {
    final entry = sortedCategories[i];
    if (i < visibleCategoryCount) {
      final category = categoryById[entry.key] ??
          Category(
            id: entry.key,
            name: historicalCategoryNames[entry.key] ?? 'Desconegut',
            icon: '❓',
            type: TransactionType.expense,
          );

      // Compute subcategory breakdown for this category
      final sortedSubcats = (subcategoryTotals[entry.key] ??
              const <String, double>{})
          .entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final subcategories = sortedSubcats
          .map((s) => SubcategoryTrendData(
                id: s.key,
                name: s.key == '__without_subcategory__'
                    ? 'Sense subcategoria'
                    : subcategoryByKey['${entry.key}:${s.key}']?.name ??
                        historicalSubcategoryNames['${entry.key}:${s.key}'] ??
                        'Subcategoria desconeguda',
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
      otherEntries.add(entry);
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
        categoryIds: otherEntries.map((entry) => entry.key).toSet(),
        subcategories: otherEntries
            .map(
              (entry) => SubcategoryTrendData(
                id: entry.key,
                name: categoryById[entry.key]?.name ??
                    historicalCategoryNames[entry.key] ??
                    'Categoria desconeguda',
                totalAmount: entry.value,
                percentage: othersTotal > 0 ? entry.value / othersTotal : 0,
              ),
            )
            .toList(),
      ),
    );
  }

  // 4. Savings Rate (Total Income - Total Expense) / Total Income
  // Calculat sobre tot el període amb els totals canònics del ledger.
  double totalPeriodIncome = periodLedger.totalIncome;
  double totalPeriodExpense = periodLedger.totalExpense;

  double savingsRate = 0;
  if (totalPeriodIncome > 0) {
    savingsRate = (totalPeriodIncome - totalPeriodExpense) / totalPeriodIncome;
  }

  return TrendsData(
    monthlyFlow: monthlyFlow,
    topCategories: topCategories,
    savingsRate: savingsRate,
    startDate: startDate,
    endDate: endDate,
    currentMonthExcludedFromFlow: currentMonthExcludedFromFlow,
  );
}
