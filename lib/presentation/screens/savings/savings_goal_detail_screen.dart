import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/savings_goal.dart';
import '../../../../domain/models/transaction.dart';
import '../../sheets/add_savings_goal_sheet.dart';
import '../../providers/transaction_notifier.dart';
import '../../providers/auth_providers.dart';

class SavingsGoalDetailScreen extends ConsumerWidget {
  final SavingsGoal goal;

  const SavingsGoalDetailScreen({super.key, required this.goal});

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirar estalvis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aquests fons es mouran a la teva cartera principal com a ingrés.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Import a retirar (€)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val != null && val > 0) Navigator.pop(context, val);
            },
            child: const Text('Retirar'),
          ),
        ],
      ),
    );

    if (amount == null) return;

    // Check if enough funds
    if (amount > goal.currentAmount) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tens prous fons a la guardiola.')),
        );
      }
      return;
    }

    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;

    final transaction = Transaction(
      groupId: groupId,
      date: DateTime.now(),
      amount: amount,
      concept: 'Retirada de ${goal.name}',
      categoryId: 'income_savings', // Placeholder or generic 'Other'
      subCategoryId: 'withdrawal',
      categoryName: 'Estalvi',
      subCategoryName: 'Retirada',
      payer: 'User',
      isIncome: true, // It's an income for the main budget
      savingsGoalId: goal.id, // Linked to this goal (will trigger reduction)
    );

    await ref
        .read(transactionNotifierProvider.notifier)
        .addTransaction(transaction);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retirats ${amount.toStringAsFixed(2)}€ correctament.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
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
              if (value == 'withdraw') {
                _withdraw(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'withdraw',
                child: Row(
                  children: [
                    Icon(Icons.output, color: AppTheme.copper),
                    SizedBox(width: 8),
                    Text('Retirar Fons'),
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
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Encara no hi ha moviments.'),
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
                              entry.note.isNotEmpty ? entry.note : 'Aportació',
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

    // We need to calculate running total for the chart
    double runningTotal = 0;
    List<FlSpot> spots = [];

    // Start with 0 at the beginning? Or just the first entry?
    // Let's assume start at 0 before first entry if we want.
    // simpler: just map index to amount.

    for (int i = 0; i < entries.length; i++) {
      runningTotal += entries[i].amount; // Logic: history tracks contributions
      // To prevent showing just contributions, we accumulate them.
      // Wait, `history` in `SavingsGoal` tracks contributions (date, amount).
      // `currentAmount` is the sum.
      // The chart should show the accumulated total over time.

      spots.add(FlSpot(i.toDouble(), runningTotal));
    }

    return spots;
  }
}
