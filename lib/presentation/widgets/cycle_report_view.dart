import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../domain/models/billing_cycle.dart';
import '../providers/cycle_reports_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/category_notifier.dart';
import '../providers/transaction_filter_provider.dart';
import 'main_scaffold.dart';

class CycleReportView extends ConsumerWidget {
  final BillingCycle cycle;

  const CycleReportView({super.key, required this.cycle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(cycleReportNotifierProvider(cycle.id));

    return reportAsync.when(
      data: (report) {
        if (report == null) {
          return _buildEmptyState(context, ref);
        }
        return _buildReportContent(context, report, ref);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.copper.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 64,
                color: AppTheme.copper,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Informe no generat",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.anthracite,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Demana a Cèntim Coach que analitzi aquest mes i et prepari un resum detallat amb les teves mètriques i desviacions.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(cycleReportNotifierProvider(cycle.id).notifier)
                    .generateReportForCycle(cycle);
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Generar Informe d'aquest Cicle"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.copper,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(
      BuildContext context, dynamic report, WidgetRef ref) {
    // report is CycleReport
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700), // tablet friendly
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAiVerdict(report.aiVerdict, ref),
            const SizedBox(height: 24),
            _buildMetricsRow(
              income: report.totalIncome,
              expense: report.totalExpense,
              savingsPercent: report.savingsPercentage,
            ),
            const SizedBox(height: 24),
            const Text(
              "Flux d'Efectiu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildWaterfallChart(
              income: report.totalIncome,
              expense: report.totalExpense,
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDeviationsList(
                    context: context,
                    ref: ref,
                    title: "Desviacions",
                    icon: Icons.trending_up,
                    color: Colors.red,
                    items: report.topOverspent,
                    isSavedText: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDeviationsList(
                    context: context,
                    ref: ref,
                    title: "Estalvis",
                    icon: Icons.trending_down,
                    color: Colors.green,
                    items: report.topSaved,
                    isSavedText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildAiVerdict(String verdict, WidgetRef ref) {
    return Card(
      elevation: 0,
      color: AppTheme.sand.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.smart_toy_rounded, color: AppTheme.copper),
                    SizedBox(width: 8),
                    Text(
                      "El veredicte de Cèntim",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome,
                      color: AppTheme.copper, size: 20),
                  tooltip: "Tornar a generar l'informe",
                  onPressed: () {
                    ref
                        .read(cycleReportNotifierProvider(cycle.id).notifier)
                        .generateReportForCycle(cycle);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              verdict,
              style: const TextStyle(height: 1.4, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow({
    required double income,
    required double expense,
    required double savingsPercent,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard("Ingressat", income, Colors.green),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard("Gastat", expense, Colors.red),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard("Estalvi", savingsPercent, AppTheme.copper,
              isPercent: true),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, double value, Color color,
      {bool isPercent = false}) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              isPercent
                  ? "${value.toStringAsFixed(0)}%"
                  : "${value.toStringAsFixed(2)}€",
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterfallChart({
    required double income,
    required double expense,
  }) {
    final savings = income - expense > 0 ? income - expense : 0.0;

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: income * 1.1,
          minY: 0,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text('Ingressos',
                          style: TextStyle(fontSize: 10));
                    case 1:
                      return const Text('Despeses',
                          style: TextStyle(fontSize: 10));
                    case 2:
                      return const Text('Estalvi',
                          style: TextStyle(fontSize: 10));
                    default:
                      return const Text('');
                  }
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
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: income,
                  fromY: 0,
                  color: Colors.green,
                  width: 40,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: income,
                  fromY: savings,
                  color: Colors.red,
                  width: 40,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: savings,
                  fromY: 0,
                  color: AppTheme.copper,
                  width: 40,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviationsList({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required IconData icon,
    required Color color,
    required List<dynamic> items,
    required bool isSavedText,
  }) {
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSavedText ? "Cap estalvi destacat." : "Sense desviacions greus.",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          final amount = isSavedText ? item['estalvi'] : item['desviacio'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final categories =
                    await ref.read(categoryNotifierProvider.future);
                try {
                  final cat =
                      categories.firstWhere((c) => c.name == item['categoria']);
                  ref
                      .read(transactionFilterNotifierProvider.notifier)
                      .clearAll();
                  ref
                      .read(transactionFilterNotifierProvider.notifier)
                      .setCategory(cat.id, cat.name);
                  ref
                      .read(transactionFilterNotifierProvider.notifier)
                      .setDateRange(cycle.startDate, cycle.endDate);
                  ref.read(selectedIndexProvider.notifier).state =
                      2; // Transactions tab
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                } catch (e) {
                  // Ignore if category is not found
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['categoria'],
                        style: const TextStyle(
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "${item['despesa']?.toStringAsFixed(2) ?? '0.00'}€ (${isSavedText ? '-' : '+'}${amount.toStringAsFixed(2)}€)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
