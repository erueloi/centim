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

              // Cash-flow chart
              Text(
                'Flux de caixa',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (data.monthlyFlow.isEmpty)
                const SizedBox(
                  height: 150,
                  child: Center(
                    child: Text('No hi ha mesos complets amb moviments.'),
                  ),
                )
              else
                AspectRatio(
                  aspectRatio: 1.5,
                  child: _CashFlowChart(data: data.monthlyFlow),
                ),
              if (data.currentMonthExcludedFromFlow) ...[
                const SizedBox(height: 8),
                Text(
                  'El mes en curs no s’inclou perquè encara és incomplet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
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
    final level = savingsRateLevel(rate);
    final color = switch (level) {
      SavingsRateLevel.veryTight => Colors.red,
      SavingsRateLevel.improvable => Colors.orange,
      SavingsRateLevel.good => Colors.blue,
      SavingsRateLevel.veryGood => Colors.green,
    };
    final message = savingsRateMessage(rate);

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Taxa d’estalvi del període",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  RichText(
                    text: TextSpan(
                      text: '${(rate * 100).toStringAsFixed(1)}% ',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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
    maxY = maxY > 0 ? maxY * 1.1 : 1;
    final yInterval = maxY / 4;

    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _ChartLegendDot(color: Colors.green, label: 'Ingressos'),
            SizedBox(width: 16),
            _ChartLegendDot(color: Colors.red, label: 'Despeses'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.18),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        // Show every 2nd or 3rd month if simpler?
                        // Or show first letter of month.
                        final date = data[index].month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            data[index].isIncomplete
                                ? '${DateFormat.MMM('ca_ES').format(date).toUpperCase()}\nEN CURS'
                                : DateFormat.MMM(
                                    'ca_ES',
                                  ).format(date).toUpperCase(),
                            style: TextStyle(
                              fontSize: data[index].isIncomplete ? 9 : 10,
                              color: data[index].isIncomplete
                                  ? Colors.orange[800]
                                  : null,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const Text('');
                    },
                    interval: 1, // Only some labels?
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        _formatAxisAmount(value),
                        style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: data.length > 1 ? (data.length - 1).toDouble() : 1,
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                // Income Line
                LineChartBarData(
                  spots: data.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.income);
                  }).toList(),
                  isCurved: false,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                ),
                // Expense Line
                LineChartBarData(
                  spots: data.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.expense);
                  }).toList(),
                  isCurved: false,
                  color: Colors.red,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
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
                              color: isIncome
                                  ? Colors.green[300]
                                  : Colors.red[300],
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
          ),
        ),
      ],
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

String _formatAxisAmount(double value) {
  if (value.abs() >= 1000) {
    final thousands = value / 1000;
    return '${thousands.toStringAsFixed(thousands % 1 == 0 ? 0 : 1)}k €';
  }
  return '${value.toStringAsFixed(0)} €';
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
                            categoryIds: c.categoryIds,
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
        // Legend with subcategories
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.categories.asMap().entries.expand((entry) {
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

                return [
                  InkWell(
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
                            categoryIds: c.categoryIds,
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
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
                                fontWeight: isTouched
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Subcategories (shown when touched)
                  if (isTouched && c.subcategories.isNotEmpty)
                    ...c.subcategories.map((sub) => Padding(
                          padding: const EdgeInsets.only(
                              left: 24, right: 4, top: 2, bottom: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  sub.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${sub.totalAmount.toStringAsFixed(0)}€',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )),
                ];
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
