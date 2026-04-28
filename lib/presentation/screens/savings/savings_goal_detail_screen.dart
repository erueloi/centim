import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:centim/l10n/app_localizations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/savings_goal.dart';
import '../../sheets/add_savings_goal_sheet.dart';
import '../../sheets/savings_action_sheet.dart';

class SavingsGoalDetailScreen extends ConsumerWidget {
  final SavingsGoal goal;

  const SavingsGoalDetailScreen({super.key, required this.goal});

  void _openActionSheet(
      BuildContext context, SavingsActionType actionType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SavingsActionSheet(
        goal: goal,
        actionType: actionType,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(
      locale: 'ca_ES',
      symbol: '€',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd MMM yyyy', 'ca_ES');

    // Sort history by date descending for the list
    final sortedHistory = List<SavingsEntry>.from(goal.history)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Sort by date ascending for the chart
    final chartData = List<SavingsEntry>.from(goal.history)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => AddSavingsGoalSheet(goal: goal),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'adjust') {
                _openActionSheet(context, SavingsActionType.adjust);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'adjust',
                child: Row(
                  children: [
                    const Icon(Icons.balance, color: AppTheme.copper),
                    const SizedBox(width: 8),
                    Text(l10n.adjustBalance),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              color: Color(goal.color).withValues(alpha: 0.1),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      goal.icon,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currencyFormat.format(goal.currentAmount),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(goal.color),
                    ),
                  ),
                  if (goal.targetAmount != null)
                    Text(
                      'de ${currencyFormat.format(goal.targetAmount)}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _openActionSheet(
                            context, SavingsActionType.contribute),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.contributeButton),
                        style: FilledButton.styleFrom(
                          backgroundColor: Color(goal.color),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _openActionSheet(
                            context, SavingsActionType.withdraw),
                        icon: const Icon(Icons.output, size: 18),
                        label: Text(l10n.withdrawFunds),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.anthracite,
                          side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chart
            if (chartData.isNotEmpty)
              Container(
                height: 250,
                padding: const EdgeInsets.all(24),
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              currencyFormat.format(spot.y),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _generateSpots(chartData),
                        isCurved: true,
                        color: Color(goal.color),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Color(goal.color).withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // History List
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: sortedHistory.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(l10n.noMovementsYet),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedHistory.length,
                      itemBuilder: (context, index) {
                        final entry = sortedHistory[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(
                                goal.color,
                              ).withValues(alpha: 0.1),
                              child: Icon(
                                Icons.arrow_upward,
                                color: Color(goal.color),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              entry.note.isNotEmpty
                                  ? entry.note
                                  : l10n.contributionLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(dateFormat.format(entry.date)),
                            trailing: Text(
                              '+${currencyFormat.format(entry.amount)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots(List<SavingsEntry> entries) {
    if (entries.isEmpty) return [];

    double runningTotal = 0;
    List<FlSpot> spots = [];

    for (int i = 0; i < entries.length; i++) {
      runningTotal += entries[i].amount;
      spots.add(FlSpot(i.toDouble(), runningTotal));
    }

    return spots;
  }
}
