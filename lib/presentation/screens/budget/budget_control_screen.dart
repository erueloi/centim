import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/budget_provider.dart';

import '../../providers/date_provider.dart';
import '../../../domain/models/category.dart';
import '../categories/manage_categories_screen.dart';
import '../../widgets/responsive_center.dart';
import 'package:centim/l10n/app_localizations.dart';
import '../../providers/auth_providers.dart';
import '../../../data/providers/repository_providers.dart';
import '../../providers/transaction_notifier.dart';
import '../../providers/billing_cycle_provider.dart';
import '../../../domain/models/budget_entry.dart';
import '../../widgets/cycle_selector.dart';
import '../../widgets/trends_tab.dart'; // Import TrendsTab
import '../../providers/transaction_filter_provider.dart';
import '../../widgets/main_scaffold.dart';

class BudgetControlScreen extends ConsumerStatefulWidget {
  final bool isReadOnly;
  const BudgetControlScreen({super.key, this.isReadOnly = false});

  @override
  ConsumerState<BudgetControlScreen> createState() =>
      _BudgetControlScreenState();
}

class _BudgetControlScreenState extends ConsumerState<BudgetControlScreen> {
  TransactionType _selectedType = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final budgetStatusAsync = ref.watch(budgetNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isReadOnly ? 'Detall estat' : l10n.budgetScreenTitle,
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mensual'),
              Tab(text: 'Tendències'),
            ],
          ),
          actions: widget.isReadOnly
              ? []
              : [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageCategoriesScreen(),
                        ),
                      );
                    },
                  ),
                ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Mensual (Existing content)
            ResponsiveCenter(
              child: Column(
                children: [
                  // Cycle Selector
                  const CycleSelector(),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('Despeses'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text('Ingressos'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedType = newSelection.first;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: budgetStatusAsync.when(
                      data: (statuses) {
                        final filteredStatuses = statuses
                            .where((s) => s.category.type == _selectedType)
                            .toList();

                        if (filteredStatuses.isEmpty) {
                          return Center(
                            child: Text(
                              'No hi ha dades de ${_selectedType == TransactionType.expense ? "despesa" : "ingrés"}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filteredStatuses.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final status = filteredStatuses[index];
                            return _BudgetCard(
                              status: status,
                              type: _selectedType, // Pass type for color logic
                              isReadOnly: widget.isReadOnly,
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) =>
                          Center(child: Text(l10n.errorText(e.toString()))),
                    ),
                  ),
                ],
              ),
            ),
            // Tab 2: Tendències (New content)
            const ResponsiveCenter(child: TrendsTab()),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final BudgetStatus status;
  final TransactionType type;
  final bool isReadOnly;

  const _BudgetCard({
    required this.status,
    required this.type,
    required this.isReadOnly,
  });

  Color _getProgressColor(double percentage) {
    if (status.category.color != null) {
      return Color(status.category.color!);
    }
    if (type == TransactionType.expense) {
      // Expense: Green -> Red (Bad if high)
      if (percentage >= 1.0) return Colors.red;
      if (percentage >= 0.75) return AppTheme.copper;
      return Colors.green[700]!;
    } else {
      // Income: Red -> Green (Good if high)
      if (percentage >= 1.0) return Colors.green[700]!;
      if (percentage >= 0.75) return AppTheme.copper;
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressColor = _getProgressColor(status.percentage);
    final isSpentZero = status.spent == 0;
    final isTotalZero = status.total == 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.copper.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              status.category.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: InkWell(
          onTap: () {
            ref
                .read(transactionFilterNotifierProvider.notifier)
                .setCategory(status.category.id, status.category.name);
            ref.read(selectedIndexProvider.notifier).state = 2;
          },
          child: Text(
            status.category.name.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.anthracite,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.copper,
              decorationStyle: TextDecorationStyle.dotted,
            ),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: isTotalZero
                          ? (isSpentZero ? 0 : 1)
                          : (status.spent / status.total).clamp(0.0, 1.0),
                      backgroundColor: AppTheme.anthracite.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${status.spent.toStringAsFixed(2).replaceAll('.', ',')}€ / ${status.total.toStringAsFixed(2).replaceAll('.', ',')}€',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color:
                        status.isOverBudget ? Colors.red : AppTheme.anthracite,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          // Subcategory details
          if (status.subcategoryStatuses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Cap subcategoria definida',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            )
          else
            ...status.subcategoryStatuses.map((subStatus) {
              return _SubcategoryRow(
                subStatus: subStatus,
                category: status.category,
                type: type, // Pass type
                isReadOnly: isReadOnly,
              );
            }),

          if (status.spent > 0 || status.total > 0) const Divider(height: 24),

          if (status.spent > 0 || status.total > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: _CategoryTrendsCharts(
                categoryId: status.category.id,
                totalBudget: status.total,
                isIncome: type == TransactionType.income,
              ),
            ),
        ],
      ),
    );
  }
}

class _SubcategoryRow extends ConsumerWidget {
  final SubcategoryBudgetStatus subStatus;
  final Category category;
  final TransactionType type;
  final bool isReadOnly;

  const _SubcategoryRow({
    required this.subStatus,
    required this.category,
    required this.type,
    required this.isReadOnly,
  });

  Color _getProgressColor(double percentage) {
    if (category.color != null) {
      return Color(category.color!);
    }
    if (type == TransactionType.expense) {
      // Expense: Green -> Red
      if (percentage >= 1.0) return Colors.red;
      if (percentage >= 0.75) return AppTheme.copper;
      return Colors.green[700]!;
    } else {
      // Income: Red -> Green
      if (percentage >= 1.0) return Colors.green[700]!;
      if (percentage >= 0.75) return AppTheme.copper;
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressColor = _getProgressColor(subStatus.percentage);
    final isBudgetZero = subStatus.budget == 0;
    final isSpentZero = subStatus.spent == 0;

    return InkWell(
      onTap: () {
        ref.read(transactionFilterNotifierProvider.notifier).setSubCategory(
              category.id,
              category.name,
              subStatus.subcategory.id,
              subStatus.subcategory.name,
            );
        ref.read(selectedIndexProvider.notifier).state = 2;
        // Pop back if we're in a nested navigator
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Subcategory name
            Expanded(
              flex: 3,
              child: Text(
                subStatus.subcategory.name,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.anthracite,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Progress bar
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: isBudgetZero
                      ? (isSpentZero ? 0 : 1)
                      : (subStatus.spent / subStatus.budget).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.anthracite.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Amount display
            SizedBox(
              width: 85,
              child: Text(
                '${subStatus.spent.toStringAsFixed(2).replaceAll('.', ',')}€/${subStatus.budget.toStringAsFixed(2).replaceAll('.', ',')}€',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.right,
              ),
            ),
            // Edit button
            if (!isReadOnly)
              SizedBox(
                width: 32,
                child: IconButton(
                  icon: Icon(Icons.edit, size: 16, color: Colors.grey[500]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showQuickBudgetDialog(context, ref),
                ),
              )
            else
              const SizedBox(width: 32), // Placeholder to keep alignment
          ],
        ),
      ),
    );
  }

  Future<void> _showQuickBudgetDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final budgetController = TextEditingController(
      text: subStatus.budget.toStringAsFixed(2).replaceAll('.', ','),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Pressupost', style: TextStyle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subStatus.subcategory.name,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: budgetController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Objectiu Mensual (€)',
                suffixText: '€',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBudget =
                  double.tryParse(budgetController.text.replaceAll(',', '.')) ??
                      0.0;
              final selectedDate = ref.read(selectedDateProvider);
              final groupId = ref.read(currentGroupIdProvider).valueOrNull;

              if (groupId == null) {
                if (context.mounted) Navigator.pop(context);
                return;
              }

              final repo = ref.read(budgetEntryRepositoryProvider);
              final entryId =
                  '${subStatus.subcategory.id}_${selectedDate.year}_${selectedDate.month}';

              // If new budget matches the base budget, remove the exception
              if (newBudget == subStatus.subcategory.monthlyBudget) {
                await repo.deleteEntry(groupId, entryId);
              } else {
                // Otherwise set/update the exception
                final entry = BudgetEntry(
                  id: entryId,
                  subCategoryId: subStatus.subcategory.id,
                  year: selectedDate.year,
                  month: selectedDate.month,
                  amount: newBudget,
                );
                await repo.setEntry(groupId, entry);
              }

              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.copper,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTrendsCharts extends ConsumerWidget {
  final String categoryId;
  final double totalBudget;
  final bool isIncome;

  const _CategoryTrendsCharts({
    required this.categoryId,
    required this.totalBudget,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCycle = ref.watch(activeCycleProvider);
    final transactionsAsync = ref.watch(transactionNotifierProvider);

    return transactionsAsync.when(
      data: (transactions) {
        // Prepare data for the charts
        final now = DateTime.now();
        final cycleStart = activeCycle.startDate;
        final cycleEnd = activeCycle.endDate;
        final totalDays = cycleEnd.difference(cycleStart).inDays + 1;

        // --- 1. Burn Rate (LineChart) Data ---
        // Accumulate spent amount per day for current cycle
        final dailySpent = <int, double>{};
        var cumulativeSpent = 0.0;

        // Filter current cycle transactions for this category
        final currentCycleTx = transactions
            .where((t) =>
                t.categoryId == categoryId &&
                t.date.isAfter(cycleStart.subtract(const Duration(days: 1))) &&
                t.date.isBefore(cycleEnd.add(const Duration(days: 1))) &&
                t.isIncome == isIncome)
            .toList();

        // Sort by date from older to newer
        currentCycleTx.sort((a, b) => a.date.compareTo(b.date));

        for (int i = 0; i < totalDays; i++) {
          final currentDate = cycleStart.add(Duration(days: i));
          // If the day hasn't happened yet, we stop the actual line
          if (currentDate.isAfter(now)) {
            break;
          }

          final spentThatDay = currentCycleTx
              .where((t) =>
                  t.date.year == currentDate.year &&
                  t.date.month == currentDate.month &&
                  t.date.day == currentDate.day)
              .fold(0.0, (sum, t) => sum + t.amount);

          cumulativeSpent += spentThatDay;
          dailySpent[i] = cumulativeSpent;
        }

        // --- 2. Month-over-Month (BarChart) Data ---
        // Calculate previous cycle dates (rough approx: minus 1 month)
        final prevCycleStart =
            DateTime(cycleStart.year, cycleStart.month - 1, cycleStart.day);
        final prevCycleEnd = cycleStart.subtract(const Duration(days: 1));

        final prevCycleTx = transactions
            .where((t) =>
                t.categoryId == categoryId &&
                t.date.isAfter(
                    prevCycleStart.subtract(const Duration(days: 1))) &&
                t.date.isBefore(prevCycleEnd.add(const Duration(days: 1))) &&
                t.isIncome == isIncome)
            .toList();

        final totalCurrentStr =
            currentCycleTx.fold(0.0, (sum, t) => sum + t.amount);
        final totalPrevStr = prevCycleTx.fold(0.0, (sum, t) => sum + t.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Burn Rate title
            Text(
              'Ritme de Despesa vs Pressupost',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            // Burn Rate Chart
            SizedBox(
              height: 140,
              child: _buildBurnRateChart(
                  dailySpent, totalDays, totalBudget, isIncome),
            ),

            const SizedBox(height: 24),

            // MoM title
            Text(
              'Comparativa (Aquest mes vs Anterior)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            // MoM Chart
            SizedBox(
              height: 120,
              child: _buildMoMChart(totalCurrentStr, totalPrevStr, isIncome),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildBurnRateChart(Map<int, double> dailySpent, int totalDays,
      double totalBudget, bool isIncome) {
    if (totalBudget == 0 && dailySpent.isEmpty) return const SizedBox();

    final maxY = [
      totalBudget,
      if (dailySpent.isNotEmpty)
        dailySpent.values.reduce((a, b) => a > b ? a : b),
    ].reduce((a, b) => a > b ? a : b);

    final finalMaxY = (maxY * 1.2).ceilToDouble(); // Add some padding

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: finalMaxY == 0 ? 10 : finalMaxY,
        minX: 0,
        maxX: (totalDays - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: finalMaxY > 0 ? finalMaxY / 4 : 2.5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey[200]!,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final day = value.toInt() + 1;
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '$day',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == finalMaxY) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${value.toInt()}€',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Ideal Budget Line (Linear)
          if (totalBudget > 0)
            LineChartBarData(
              spots: [
                const FlSpot(0, 0),
                FlSpot((totalDays - 1).toDouble(), totalBudget),
              ],
              isCurved: false,
              color: Colors.grey[400],
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              dashArray: [5, 5],
            ),

          // Actual Spent Line
          if (dailySpent.isNotEmpty)
            LineChartBarData(
              spots: dailySpent.entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: isIncome ? Colors.green : AppTheme.copper,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: (isIncome ? Colors.green : AppTheme.copper)
                    .withValues(alpha: 0.1),
              ),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isIdeal = spot.barIndex == 0 && totalBudget > 0;
                return LineTooltipItem(
                  '${isIdeal ? "Ideal: " : ""}${spot.y.toStringAsFixed(0)}€',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMoMChart(double currentMonth, double prevMonth, bool isIncome) {
    if (currentMonth == 0 && prevMonth == 0) return const SizedBox();

    final maxVal = [currentMonth, prevMonth].reduce((a, b) => a > b ? a : b);
    final isHigher = currentMonth > prevMonth;

    // Determine color based on type
    final currentColor = isIncome
        ? Colors.green[600]!
        : (isHigher ? Colors.red[400]! : Colors.green[400]!);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: (maxVal * 1.2).ceilToDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(0)}€',
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final style = TextStyle(
                  color: Colors.grey[700],
                  fontWeight: value == 1 ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                );
                return SideTitleWidget(
                  meta: meta,
                  child: Text(value == 0 ? 'Mes Ant.' : 'Actual', style: style),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          // Previous Month
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: prevMonth,
                color: Colors.grey[400],
                width: 28,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
          // Current Month
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: currentMonth,
                color: currentColor,
                width: 28,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
