import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:centim/l10n/app_localizations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/savings_goal.dart';
import '../../../../domain/models/balance_adjustment.dart';
import '../../sheets/add_savings_goal_sheet.dart';
import '../../sheets/savings_action_sheet.dart';
import '../../providers/savings_goal_provider.dart';
import '../../providers/balance_adjustment_provider.dart';
import '../../../../data/providers/repository_providers.dart';

class SavingsGoalDetailScreen extends ConsumerWidget {
  final SavingsGoal goal;

  const SavingsGoalDetailScreen({super.key, required this.goal});

  void _openActionSheet(BuildContext context, SavingsActionType actionType) {
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
    final liveGoals =
        ref.watch(savingsGoalNotifierProvider).valueOrNull ?? const [];
    final matches = liveGoals.where((item) => item.id == goal.id);
    final currentGoal = matches.isEmpty ? goal : matches.first;
    final adjustments =
        ref.watch(balanceAdjustmentsForGoalProvider(currentGoal.id));
    final reversedIds = reversedAdjustmentIds(adjustments);
    final adjustmentsById = {
      for (final adjustment in adjustments) adjustment.id: adjustment,
    };
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 183));
    final recentAdjustmentCount = effectiveAdjustmentCount(
      adjustments,
      since: sixMonthsAgo,
      savingsGoalId: currentGoal.id,
    );
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(
      locale: 'ca_ES',
      symbol: '€',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd MMM yyyy', 'ca_ES');

    // Sort history by date descending for the list
    final sortedHistory = List<SavingsEntry>.from(currentGoal.history)
      ..removeWhere((entry) => entry.type == SavingsEntryType.reversal)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Sort by date ascending for the chart
    final chartData = List<SavingsEntry>.from(currentGoal.history)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(currentGoal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => AddSavingsGoalSheet(goal: currentGoal),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'adjust') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SavingsActionSheet(
                    goal: currentGoal,
                    actionType: SavingsActionType.adjust,
                  ),
                );
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
              color: Color(currentGoal.color).withValues(alpha: 0.1),
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
                      currentGoal.icon,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currencyFormat.format(currentGoal.currentAmount),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(currentGoal.color),
                    ),
                  ),
                  if (currentGoal.targetAmount != null)
                    Text(
                      'de ${currencyFormat.format(currentGoal.targetAmount)}',
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
                          backgroundColor: Color(currentGoal.color),
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
                        color: Color(currentGoal.color),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color:
                              Color(currentGoal.color).withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.copper.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$recentAdjustmentCount ajust${recentAdjustmentCount == 1 ? '' : 'os'} '
                  'els últims 6 mesos',
                  style: const TextStyle(
                    color: AppTheme.anthracite,
                    fontWeight: FontWeight.w600,
                  ),
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
                        final adjustment = entry.adjustmentId == null
                            ? null
                            : adjustmentsById[entry.adjustmentId];
                        final isAdjustment =
                            entry.type == SavingsEntryType.adjustment;
                        final isReverted = adjustment != null &&
                            reversedIds.contains(adjustment.id);
                        final reversalMatches = adjustment == null
                            ? const <BalanceAdjustment>[]
                            : adjustments
                                .where(
                                  (item) =>
                                      item.reversesAdjustmentId ==
                                      adjustment.id,
                                )
                                .toList(growable: false);
                        final reversal = reversalMatches.isEmpty
                            ? null
                            : reversalMatches.first;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(
                                currentGoal.color,
                              ).withValues(alpha: 0.1),
                              child: Icon(
                                isAdjustment
                                    ? Icons.balance
                                    : entry.amount >= 0
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                color: Color(currentGoal.color),
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dateFormat.format(entry.date)),
                                if (isReverted && reversal != null)
                                  Text(
                                    'Revertit el ${dateFormat.format(reversal.date)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isReverted
                                      ? currencyFormat.format(0)
                                      : '${entry.amount >= 0 ? '+' : '−'}'
                                          '${currencyFormat.format(entry.amount.abs())}',
                                  style: TextStyle(
                                    color: isReverted
                                        ? Colors.grey
                                        : entry.amount >= 0
                                            ? Colors.green
                                            : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (adjustment != null && !isReverted)
                                  PopupMenuButton<String>(
                                    tooltip: 'Opcions de l’ajust',
                                    onSelected: (value) {
                                      if (value == 'reverse') {
                                        _reverseAdjustment(
                                          context,
                                          ref,
                                          adjustment,
                                        );
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'reverse',
                                        child: Text('Revertir l’ajust'),
                                      ),
                                    ],
                                  ),
                              ],
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

  Future<void> _reverseAdjustment(
    BuildContext context,
    WidgetRef ref,
    BalanceAdjustment adjustment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revertir aquest ajust?'),
        content: const Text(
          'Es crearà una reversió auditable. La parella quedarà agrupada i '
          'no comptarà com un ajust real al detector de fuites.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Revertir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(balanceAdjustmentRepositoryProvider)
          .reverseAdjustment(adjustment);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No s’ha pogut revertir: $error')),
      );
    }
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
