import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/trends_provider.dart';
import 'category_drill_down_sheet.dart';

class TrendsTab extends ConsumerWidget {
  const TrendsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(trendsNotifierProvider);
    final selectedFilter = ref.watch(trendsFilterNotifierProvider);

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
              // Time Filter Selector
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<TrendsTimeFilter>(
                  segments: const [
                    ButtonSegment(
                      value: TrendsTimeFilter.thisMonth,
                      label: Text('Mes', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: TrendsTimeFilter.lastMonth,
                      label: Text('Ant.', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: TrendsTimeFilter.last3Months,
                      label: Text('3m', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: TrendsTimeFilter.thisYear,
                      label: Text('12m', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {selectedFilter},
                  onSelectionChanged: (newSelection) {
                    ref
                        .read(trendsFilterNotifierProvider.notifier)
                        .setFilter(newSelection.first);
                  },
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                child: _CategoryPieChart(
                  categories: data.topCategories,
                  startDate: data.startDate,
                  endDate: data.endDate,
                ),
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
    Color color =
        rate >= 0.2 ? Colors.green : (rate > 0 ? Colors.blue : Colors.red);
    String message =
        rate >= 0.2 ? "Excel·lent!" : (rate > 0 ? "Vas bé" : "Atenció");

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
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
          handleBuiltInTouches: true,
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                const FlLine(
                  color: Colors.blueGrey,
                  strokeWidth: 2,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: barData.color ?? Colors.blueGrey,
                    );
                  },
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.shade800,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isIncome = spot.barIndex == 0;
                // Obtenir el nom del mes pel títol només un cop
                final date = data[spot.x.toInt()].month;
                final monthName = DateFormat.MMMM('ca_ES').format(date);

                return LineTooltipItem(
                  '${monthName.toUpperCase()}\n',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text:
                          '${spot.y.toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: TextStyle(
                        color: isIncome ? Colors.green[300] : Colors.red[300],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryPieChart extends ConsumerStatefulWidget {
  final List<CategoryTrendData> categories;
  final DateTime startDate;
  final DateTime endDate;

  const _CategoryPieChart({
    required this.categories,
    required this.startDate,
    required this.endDate,
  });

  @override
  ConsumerState<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends ConsumerState<_CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const Center(child: Text("Sense despeses significatives"));
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    final index =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                    if (index == -1) {
                      touchedIndex = -1;
                      return;
                    }

                    if (event is FlTapUpEvent) {
                      // Obrim el modal només si hi ha un toc explícit (clic completat)
                      final c = widget.categories[index];
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => DraggableScrollableSheet(
                          initialChildSize: 0.7,
                          minChildSize: 0.5,
                          maxChildSize: 0.95,
                          builder: (_, controller) => CategoryDrillDownSheet(
                            category: c.category,
                            startDate: widget.startDate,
                            endDate: widget.endDate,
                            totalAmount: c.totalAmount,
                          ),
                        ),
                      );
                    }
                    // Mantenim l'efecte hover d'ampliar el pastís
                    touchedIndex = index;
                  });
                },
              ),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: widget.categories.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                final isTouched = i == touchedIndex;
                final radius = isTouched ? 60.0 : 50.0;
                final fontSize = isTouched ? 16.0 : 12.0;

                // Parse color
                Color color = Colors.grey;
                if (c.category.color != null) {
                  color = Color(c.category.color!);
                } else if (c.category.id == 'others') {
                  color = Colors.grey.shade400;
                } else {
                  color = Colors.primaries[
                      c.category.name.hashCode % Colors.primaries.length];
                }

                return PieChartSectionData(
                  color: color,
                  value: c.totalAmount,
                  title: isTouched
                      ? '${c.totalAmount.toStringAsFixed(0)}€\n${(c.percentage * 100).toStringAsFixed(0)}%'
                      : '${(c.percentage * 100).toStringAsFixed(0)}%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 2)
                    ],
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
            children: widget.categories.asMap().entries.map((entry) {
              final i = entry.key;
              final c = entry.value;
              final isTouched = i == touchedIndex;

              Color color = Colors.grey;
              if (c.category.color != null) {
                color = Color(c.category.color!);
              } else if (c.category.id == 'others') {
                color = Colors.grey.shade400;
              } else {
                color = Colors.primaries[
                    c.category.name.hashCode % Colors.primaries.length];
              }

              return InkWell(
                onTap: () {
                  // Obre immediatament al primer clic sobre la llegenda
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DraggableScrollableSheet(
                      initialChildSize: 0.7,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                      builder: (_, controller) => CategoryDrillDownSheet(
                        category: c.category,
                        startDate: widget.startDate,
                        endDate: widget.endDate,
                        totalAmount: c.totalAmount,
                      ),
                    ),
                  );
                  setState(() {
                    touchedIndex = i;
                  });
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: isTouched ? 16 : 12,
                        height: isTouched ? 16 : 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isTouched
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.category.name,
                          style: TextStyle(
                            fontSize: isTouched ? 14 : 12,
                            fontWeight:
                                isTouched ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
