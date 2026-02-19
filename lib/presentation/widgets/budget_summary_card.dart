import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/budget_provider.dart';
import '../widgets/main_scaffold.dart';
import '../providers/transaction_filter_provider.dart';

class BudgetSummaryCard extends ConsumerWidget {
  const BudgetSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(dashboardBudgetNotifierProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Despeses Mensuals',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to "Despeses" tab (Index 1)
                    // We need to find the provider for selected index.
                    // It's defined in MainScaffold, so we should import it or move it to a shared location.
                    // For now, let's assume it's available via MainScaffold import or we need to look it up.
                    // Actually, modifying `BudgetSummaryCard` to import `main_scaffold.dart` allows access to `selectedIndexProvider`.
                    ref.read(selectedIndexProvider.notifier).state = 1;
                  },
                  child: const Text('Veure tot'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            budgetAsync.when(
              data: (statuses) {
                // Filter only expenses and take top 5
                final topExpenses = statuses
                    .where(
                      (s) => s.category.type.name == 'expense' && s.spent > 0,
                    )
                    .take(5)
                    .toList();

                if (topExpenses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No hi ha despeses registrades aquest mes',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: topExpenses.map((status) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Filter by category
                          final filterNotifier = ref.read(
                            transactionFilterNotifierProvider.notifier,
                          );
                          filterNotifier.setCategory(
                            status.category.id,
                            status.category.name,
                          );

                          // Reset subcategory (just in case)
                          // The setCategory method usually handles this, but good to be sure if needed.

                          // Navigate to Moviments (Index 2)
                          ref.read(selectedIndexProvider.notifier).state = 2;
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    status.category.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${status.spent.toStringAsFixed(0)}€ / ${status.total.toStringAsFixed(0)}€',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: status.total > 0
                                      ? (status.spent / status.total).clamp(
                                          0.0,
                                          1.0,
                                        )
                                      : 1.0,
                                  backgroundColor: Colors.grey[200],
                                  color: status.isOverBudget
                                      ? Colors.red
                                      : AppTheme.copper,
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
