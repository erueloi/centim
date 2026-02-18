import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/billing_cycle_provider.dart';
import '../providers/budget_provider.dart';
import '../../domain/models/category.dart'; // TransactionType enum

class FinancialHealthIndicator extends ConsumerWidget {
  const FinancialHealthIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCycle = ref.watch(activeCycleProvider);
    final budgetAsync = ref.watch(budgetNotifierProvider);

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
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            budgetAsync.when(
              data: (statuses) {
                // Calculate Totals
                double totalBudget = 0;
                double totalSpent = 0;

                for (final s in statuses) {
                  // Only count expense categories
                  if (s.category.type == TransactionType.expense) {
                    totalBudget += s.total;
                    totalSpent += s.spent;
                  }
                }

                // Time Logic
                final now = DateTime.now();
                // Ensure we don't go out of bounds if cycle is future/past
                // If cycle is future: 0%. If past: 100%.
                // But activeCycle is usually current.
                // Let's assume current or relevant.
                final totalDays =
                    activeCycle.endDate
                        .difference(activeCycle.startDate)
                        .inDays +
                    1;
                final daysPassed = now.difference(activeCycle.startDate).inDays;

                // Clamp daysPassed between 0 and totalDays
                final clampedDays = daysPassed.clamp(0, totalDays);
                final timePercent = (clampedDays / totalDays).clamp(0.0, 1.0);

                // Money Logic
                final moneyPercent = totalBudget > 0
                    ? (totalSpent / totalBudget).clamp(0.0, 1.0)
                    : 0.0;

                // Color Logic
                Color statusColor;
                if (moneyPercent > timePercent + 0.05) {
                  statusColor = Colors.red; // Overspending relative to time
                } else if (moneyPercent > timePercent - 0.05) {
                  statusColor = Colors.orange; // Close to limit
                } else {
                  statusColor = Colors.green; // Saving relative to time
                }

                return Column(
                  children: [
                    // Text Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dia $clampedDays/$totalDays (${(timePercent * 100).toStringAsFixed(0)}%)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Gastat ${(moneyPercent * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Visual Indicator
                    SizedBox(
                      height: 12,
                      child: Stack(
                        children: [
                          // Background
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          // Time Bar (Bottom/Background layer context)
                          // Visualizing Time as a marker or a bar?
                          // User requested "Double linear progress bar (one over another or parallel)".
                          // Parallel is clearer.
                          // But space is tight. Let's do stacked or parallel thick lines.
                          // Let's do parallel: Top heavy for Money, Bottom thin for Time.
                        ],
                      ),
                    ),
                    // Actually, let's use LinearProgressIndicator for simplicity but robustly.
                    // Or separate bars.
                    // "Double linear progress bar"
                    Column(
                      children: [
                        // Money Bar
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
                        // Time Bar (Reference)
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
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
              error: (e, _) => Text('Error loading stats: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
