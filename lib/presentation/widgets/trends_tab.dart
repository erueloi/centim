import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/trends_provider.dart';

class TrendsTab extends ConsumerWidget {
  const TrendsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(trendsNotifierProvider);

    return trendsAsync.when(
      data: (data) {
        if (data.monthlyFlow.isEmpty) {
          return const Center(child: Text("No hi ha dades suficients."));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Card
              _SavingsRateCard(rate: data.savingsRate),
              const SizedBox(height: 24),

              // Line Chart
              Text(
                'Flux de Caixa (12 mesos)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1.5,
                child: _CashFlowChart(data: data.monthlyFlow),
              ),
              const SizedBox(height: 32),

              // Pie Chart
              Text(
                'On van els diners?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1.3,
                child: _CategoryPieChart(categories: data.topCategories),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _SavingsRateCard extends StatelessWidget {
  final double rate;
  const _SavingsRateCard({required this.rate});

  @override
  Widget build(BuildContext context) {
    // Determine color/message
    // > 20% Great, > 10% Good, > 0% OK, < 0% Bad
    Color color = rate >= 0.2
        ? Colors.green
        : (rate > 0 ? Colors.blue : Colors.red);
    String message = rate >= 0.2
        ? "Excel·lent!"
        : (rate > 0 ? "Vas bé" : "Atenció");

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.savings, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Taxa d'Estalvi Mitjana",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                RichText(
                  text: TextSpan(
                    text: '${(rate * 100).toStringAsFixed(1)}% ',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    children: [
                      TextSpan(
                        text: message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CashFlowChart extends StatelessWidget {
  final List<MonthlyTrendData> data;
  const _CashFlowChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // Find Max Y for scaling
    double maxY = 0;
    for (var m in data) {
      if (m.income > maxY) {
        maxY = m.income;
      }
      if (m.expense > maxY) {
        maxY = m.expense;
      }
    }
    maxY = maxY * 1.1; // Add padding

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < data.length) {
                  // Show every 2nd or 3rd month if simpler?
                  // Or show first letter of month.
                  final date = data[index].month;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat.MMM('ca_ES').format(date).toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              interval: 1, // Only some labels?
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          // Income Line
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.income);
            }).toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.1),
            ),
          ),
          // Expense Line
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.expense);
            }).toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isIncome = spot.barIndex == 0;
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(0)} €',
                  TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final List<CategoryTrendData> categories;
  const _CategoryPieChart({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text("Sense despeses significatives"));
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: categories.map((c) {
                // Parse color
                Color color = Colors.grey;
                if (c.category.color != null) {
                  color = Color(c.category.color!);
                } else if (c.category.id == 'others') {
                  color = Colors.grey.shade400;
                } else {
                  // Fallback random or hash
                  color =
                      Colors.primaries[c.category.name.hashCode %
                          Colors.primaries.length];
                }

                return PieChartSectionData(
                  color: color,
                  value: c.totalAmount,
                  title: '${(c.percentage * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Legend
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories.map((c) {
              Color color = Colors.grey;
              if (c.category.color != null) {
                color = Color(c.category.color!);
              } else if (c.category.id == 'others') {
                color = Colors.grey.shade400;
              } else {
                color =
                    Colors.primaries[c.category.name.hashCode %
                        Colors.primaries.length];
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.category.name,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
