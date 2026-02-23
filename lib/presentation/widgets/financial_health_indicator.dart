import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/billing_cycle_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_notifier.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart' as model;

class FinancialHealthIndicator extends ConsumerWidget {
  const FinancialHealthIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCycle = ref.watch(activeCycleProvider);
    final budgetAsync = ref.watch(budgetNotifierProvider);
    final transactionsAsync = ref.watch(transactionNotifierProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Salut Financera',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // ── Semàfor de Salut ──
            budgetAsync.when(
              data: (statuses) {
                double totalBudget = 0;
                double totalSpent = 0;

                for (final s in statuses) {
                  if (s.category.type == TransactionType.expense) {
                    totalBudget += s.total;
                    totalSpent += s.spent;
                  }
                }

                final now = DateTime.now();
                final totalDays = activeCycle.endDate
                        .difference(activeCycle.startDate)
                        .inDays +
                    1;
                final daysPassed = now.difference(activeCycle.startDate).inDays;
                final clampedDays = daysPassed.clamp(0, totalDays);
                final timePercent = (clampedDays / totalDays).clamp(0.0, 1.0);
                final moneyPercent = totalBudget > 0
                    ? (totalSpent / totalBudget).clamp(0.0, 1.0)
                    : 0.0;

                Color statusColor;
                String statusEmoji;
                String statusText;
                if (moneyPercent > timePercent + 0.05) {
                  statusColor = Colors.red;
                  statusEmoji = '🔴';
                  statusText = 'Gastes massa ràpid!';
                } else if (moneyPercent > timePercent - 0.05) {
                  statusColor = Colors.orange;
                  statusEmoji = '🟡';
                  statusText = 'Al límit, vigila!';
                } else {
                  statusColor = Colors.green;
                  statusEmoji = '🟢';
                  statusText = 'Vas bé, bon ritme!';
                }

                return Column(
                  children: [
                    // Status row
                    Row(
                      children: [
                        Text(statusEmoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Dia $clampedDays/$totalDays · Gastat ${(moneyPercent * 100).toStringAsFixed(0)}% del pressupost',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress bars
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: moneyPercent,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(statusColor),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: timePercent,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          Colors.blueGrey[300],
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pressupost',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          'Temps',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e'),
            ),

            const Divider(height: 28),

            // ── Batec del Mes (Gràfic diari) ──
            Text(
              'Batec del Mes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 12),
            transactionsAsync.when(
              data: (transactions) {
                return _DailyBarChart(
                  transactions: transactions,
                  startDate: activeCycle.startDate,
                  endDate: activeCycle.endDate,
                );
              },
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const Divider(height: 28),

            // ── Últims 3 Moviments ──
            Text(
              'Últims moviments',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            transactionsAsync.when(
              data: (transactions) {
                // Filter to active cycle and sort by date desc
                final cycleTransactions = transactions
                    .where((t) =>
                        t.date.isAfter(
                          activeCycle.startDate.subtract(
                            const Duration(seconds: 1),
                          ),
                        ) &&
                        t.date.isBefore(
                          activeCycle.endDate.add(const Duration(days: 1)),
                        ))
                    .toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                final recent = cycleTransactions.take(3).toList();

                if (recent.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Cap moviment encara aquest cicle',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                final fmt = NumberFormat('#,##0.00', 'ca_ES');
                final dateFmt = DateFormat('dd MMM', 'ca_ES');

                return Column(
                  children: recent.map((t) {
                    final isExpense = !t.isIncome;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: (isExpense ? Colors.red : Colors.green)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isExpense
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 16,
                              color: isExpense
                                  ? Colors.red[400]
                                  : Colors.green[400],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.concept,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${t.categoryName} · ${dateFmt.format(t.date)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isExpense ? "-" : "+"}${fmt.format(t.amount)}€',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isExpense
                                  ? Colors.red[600]
                                  : Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gràfic de barres apilades per dia del mes
class _DailyBarChart extends StatelessWidget {
  final List<model.Transaction> transactions;
  final DateTime startDate;
  final DateTime endDate;

  const _DailyBarChart({
    required this.transactions,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = endDate.difference(startDate).inDays + 1;

    // Aggregate per day
    final dailyIncome = <int, double>{};
    final dailyExpense = <int, double>{};

    for (final t in transactions) {
      if (t.date.isBefore(startDate) ||
          t.date.isAfter(endDate.add(const Duration(days: 1)))) {
        continue;
      }
      final dayIndex = t.date.difference(startDate).inDays;
      if (dayIndex < 0 || dayIndex >= totalDays) continue;

      if (t.isIncome) {
        dailyIncome[dayIndex] = (dailyIncome[dayIndex] ?? 0) + t.amount;
      } else {
        dailyExpense[dayIndex] = (dailyExpense[dayIndex] ?? 0) + t.amount;
      }
    }

    // Find max for Y axis
    double maxY = 0;
    for (int i = 0; i < totalDays; i++) {
      final dayTotal = (dailyIncome[i] ?? 0) + (dailyExpense[i] ?? 0);
      if (dayTotal > maxY) maxY = dayTotal;
    }
    if (maxY == 0) maxY = 100; // Fallback

    // Round up maxY to a nice number
    maxY = (maxY / 50).ceil() * 50.0;

    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          groupsSpace: 4,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final income = dailyIncome[group.x] ?? 0;
                final expense = dailyExpense[group.x] ?? 0;
                final dateOfDay = startDate.add(Duration(days: group.x));
                final dateFmt = DateFormat('dd MMM', 'ca_ES');
                return BarTooltipItem(
                  '${dateFmt.format(dateOfDay)}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  children: [
                    if (income > 0)
                      TextSpan(
                        text: '+${income.toStringAsFixed(0)}€ ',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 10,
                        ),
                      ),
                    if (expense > 0)
                      TextSpan(
                        text: '-${expense.toStringAsFixed(0)}€',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt() + 1;
                  // Show every 5th day + first and last
                  if (day == 1 || day % 5 == 0 || day == totalDays) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(totalDays, (i) {
            final income = dailyIncome[i] ?? 0;
            final expense = dailyExpense[i] ?? 0;

            // Mark today
            final isToday = i == DateTime.now().difference(startDate).inDays;

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: income + expense,
                  width: totalDays >= 30 ? 4 : 5,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                  ),
                  rodStackItems: [
                    BarChartRodStackItem(
                      0,
                      expense,
                      isToday
                          ? Colors.red[400]!
                          : Colors.red[300]!.withValues(alpha: 0.7),
                    ),
                    BarChartRodStackItem(
                      expense,
                      expense + income,
                      isToday
                          ? Colors.green[400]!
                          : Colors.green[300]!.withValues(alpha: 0.7),
                    ),
                  ],
                  color: Colors.transparent,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
