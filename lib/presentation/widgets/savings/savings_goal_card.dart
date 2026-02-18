import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/savings_goal.dart';
import 'add_contribution_dialog.dart';

import '../../screens/savings/savings_goal_detail_screen.dart';

class SavingsGoalCard extends ConsumerWidget {
  final SavingsGoal goal;

  const SavingsGoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final progress = goal.targetAmount != null
        ? (goal.currentAmount / goal.targetAmount!).clamp(0.0, 1.0)
        : 0.0;
    final goalColor = Color(goal.color);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SavingsGoalDetailScreen(goal: goal),
            ),
          );
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AddContributionDialog(goal: goal),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                goalColor.withValues(alpha: 0.10),
                goalColor.withValues(alpha: 0.03),
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: icon + name
              Row(
                children: [
                  Text(goal.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      goal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              if (goal.targetAmount != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    color: goalColor,
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              // Amount
              Text(
                goal.targetAmount != null
                    ? '${currencyFormat.format(goal.currentAmount)} / ${currencyFormat.format(goal.targetAmount)}'
                    : currencyFormat.format(goal.currentAmount),
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
