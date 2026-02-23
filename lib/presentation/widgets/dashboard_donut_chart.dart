import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/financial_summary.dart';
import '../../../../domain/models/category.dart';
import '../providers/transaction_notifier.dart';
import '../providers/category_notifier.dart';
import '../providers/billing_cycle_provider.dart';
import '../providers/transaction_filter_provider.dart';
import '../widgets/main_scaffold.dart';

class DashboardDonutChart extends ConsumerStatefulWidget {
  final FinancialSummary summary;

  const DashboardDonutChart({super.key, required this.summary});

  @override
  ConsumerState<DashboardDonutChart> createState() =>
      _DashboardDonutChartState();
}

class _DashboardDonutChartState extends ConsumerState<DashboardDonutChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final cycle = ref.watch(activeCycleProvider);

    return transactionsAsync.when(
      data: (transactions) {
        return categoriesAsync.when(
          data: (categories) {
            // Filtrar per mes actiu
            final currentMonthTransactions = transactions.where((t) {
              return t.date.isAfter(
                    cycle.startDate.subtract(const Duration(seconds: 1)),
                  ) &&
                  t.date.isBefore(
                    cycle.endDate.add(const Duration(seconds: 1)),
                  );
            }).toList();

            final expenses = currentMonthTransactions
                .where((t) => !t.isIncome && t.savingsGoalId == null)
                .toList();

            final expenseByCategory = <String, double>{};
            for (var exp in expenses) {
              expenseByCategory[exp.categoryId] =
                  (expenseByCategory[exp.categoryId] ?? 0) + exp.amount;
            }

            final sortedEntries = expenseByCategory.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final totalExpensesNum = widget.summary.monthlyExpenses > 0
                ? widget.summary.monthlyExpenses
                : 1.0;

            String centerTitle = 'Disponible';
            double centerAmount = widget.summary.availableToSpend;
            String centerSubtitle =
                'de ${currencyFormat.format(widget.summary.monthlyIncome)}';
            Color centerColor = widget.summary.availableToSpend < 0
                ? Colors.red
                : AppTheme.anthracite;

            if (touchedIndex != -1 && touchedIndex < sortedEntries.length) {
              // S'ha tocat una categoria particular
              final catId = sortedEntries[touchedIndex].key;
              final amount = sortedEntries[touchedIndex].value;
              final originalCat = categories.cast<Category?>().firstWhere(
                    (c) => c?.id == catId,
                    orElse: () => null,
                  );

              if (originalCat != null) {
                centerTitle = originalCat.name;
                centerAmount = amount;

                final perIncome = widget.summary.monthlyIncome > 0
                    ? ((amount / widget.summary.monthlyIncome) * 100)
                        .toStringAsFixed(1)
                    : '--';
                centerSubtitle = '$perIncome% dels Ingressos';
                centerColor = originalCat.color != null
                    ? Color(originalCat.color!)
                    : AppTheme.anthracite;
              }
            } else if (touchedIndex == sortedEntries.length &&
                widget.summary.monthlyIncome > widget.summary.monthlyExpenses) {
              // S'ha tocat la franja lliure restant grisa
              centerTitle = 'Disponible';
              centerAmount = widget.summary.availableToSpend;
              centerSubtitle = 'pressupost lliure';
            }

            List<PieChartSectionData> sections = [];

            for (int i = 0; i < sortedEntries.length; i++) {
              final catId = sortedEntries[i].key;
              final amount = sortedEntries[i].value;

              final originalCat = categories.cast<Category?>().firstWhere(
                    (c) => c?.id == catId,
                    orElse: () => null,
                  );

              final rawColor = originalCat?.color;
              final color =
                  rawColor != null ? Color(rawColor) : Colors.grey.shade400;

              final isTouched = i == touchedIndex;
              final radius = isTouched ? 42.0 : 30.0;

              // Percentatge sobre la despesa total per etiquetar-la
              final percentageString =
                  ((amount / totalExpensesNum) * 100).toStringAsFixed(0);

              // Per netedat, ensenyem la dada només si és prou gran l'agrupació, o si se l'hi fa focus
              final title = (isTouched || amount / totalExpensesNum > 0.05)
                  ? '$percentageString%'
                  : '';

              sections.add(
                PieChartSectionData(
                  color: color,
                  value: amount,
                  title: title,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  radius: radius,
                  badgeWidget: isTouched
                      ? CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          radius: 14,
                          child: Text(originalCat?.icon ?? '',
                              style: const TextStyle(fontSize: 14)),
                        )
                      : null,
                  badgePositionPercentageOffset: 1.15,
                ),
              );
            }

            // Zona restant
            if (widget.summary.monthlyIncome > widget.summary.monthlyExpenses) {
              final remaining =
                  widget.summary.monthlyIncome - widget.summary.monthlyExpenses;
              final isTouched = touchedIndex == sortedEntries.length;
              sections.add(
                PieChartSectionData(
                  color: Colors.grey[200]!,
                  value: remaining,
                  title: '',
                  radius: isTouched ? 22.0 : 14.0,
                ),
              );
            }

            if (widget.summary.monthlyExpenses <= 0 && sections.isEmpty) {
              return _buildWithSummaryRow(
                  currencyFormat, const _EmptyDonutChartWrapper());
            }

            // Construir el gràfic amb LayoutBuilder per adaptar el radi
            final chart = LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                // Escriptori: màxim ~100, mòbil: ~70
                final centerRadius = (availableWidth * 0.22).clamp(65.0, 100.0);
                final fontSize = availableWidth < 400 ? 22.0 : 28.0;
                final subFontSize = availableWidth < 400 ? 11.0 : 13.0;

                return AspectRatio(
                  aspectRatio: availableWidth > 500 ? 1.4 : 1.1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            longPressDuration:
                                const Duration(milliseconds: 500),
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                              // Long press: navegar a Moviments filtrats
                              if (event is FlLongPressEnd) {
                                if (touchedIndex >= 0 &&
                                    touchedIndex < sortedEntries.length) {
                                  final catId = sortedEntries[touchedIndex].key;
                                  final originalCat =
                                      categories.cast<Category?>().firstWhere(
                                            (c) => c?.id == catId,
                                            orElse: () => null,
                                          );
                                  if (originalCat != null) {
                                    ref
                                        .read(transactionFilterNotifierProvider
                                            .notifier)
                                        .clearAll();
                                    ref
                                        .read(transactionFilterNotifierProvider
                                            .notifier)
                                        .setCategory(
                                          originalCat.id,
                                          originalCat.name,
                                        );
                                    ref
                                        .read(selectedIndexProvider.notifier)
                                        .state = 2;
                                  }
                                }
                                return;
                              }

                              // Tap normal: seleccionar segment
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                final sectionIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                                if (sectionIndex < 0 ||
                                    sectionIndex >= sections.length) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = sectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 3,
                          centerSpaceRadius: centerRadius,
                          sections: sections,
                        ),
                      ),
                      SizedBox(
                        width: centerRadius * 1.7,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              centerTitle,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currencyFormat.format(centerAmount),
                                style: TextStyle(
                                  color: centerColor,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              centerSubtitle,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: subFontSize,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );

            return _buildWithSummaryRow(currencyFormat, chart);
          },
          loading: () => _buildWithSummaryRow(
            NumberFormat.currency(locale: 'ca_ES', symbol: '€'),
            const _EmptyDonutChartWrapper(),
          ),
          error: (e, s) => _buildWithSummaryRow(
            NumberFormat.currency(locale: 'ca_ES', symbol: '€'),
            const _EmptyDonutChartWrapper(),
          ),
        );
      },
      loading: () => _buildWithSummaryRow(
        NumberFormat.currency(locale: 'ca_ES', symbol: '€'),
        const _EmptyDonutChartWrapper(),
      ),
      error: (e, s) => _buildWithSummaryRow(
        NumberFormat.currency(locale: 'ca_ES', symbol: '€'),
        const _EmptyDonutChartWrapper(),
      ),
    );
  }

  Widget _buildWithSummaryRow(NumberFormat currencyFormat, Widget chartWidget) {
    return Column(
      children: [
        // Fila Ingressos i Despeses
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_downward,
                              color: Colors.green.shade600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Ingressos',
                            style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currencyFormat.format(widget.summary.monthlyIncome),
                          style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_upward,
                              color: Colors.red.shade600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Despeses',
                            style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currencyFormat.format(widget.summary.monthlyExpenses),
                          style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // El gràfic Donut
        chartWidget,
      ],
    );
  }
}

class _EmptyDonutChartWrapper extends StatelessWidget {
  const _EmptyDonutChartWrapper();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {},
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 0,
          centerSpaceRadius: 90,
          sections: [
            PieChartSectionData(
              color: Colors.grey[300]!,
              value: 100,
              title: '',
              radius: 25,
            )
          ],
        ),
      ),
    );
  }
}
