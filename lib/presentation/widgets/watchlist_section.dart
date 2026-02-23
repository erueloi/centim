import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/budget_entry.dart';
import '../providers/category_notifier.dart';
import '../providers/transaction_notifier.dart';
import '../providers/billing_cycle_provider.dart';
import '../providers/auth_providers.dart';
import '../providers/transaction_filter_provider.dart';
import '../widgets/main_scaffold.dart';
import '../../data/providers/repository_providers.dart';

class WatchlistSection extends ConsumerWidget {
  const WatchlistSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final cycle = ref.watch(activeCycleProvider);
    final groupIdAsync = ref.watch(currentGroupIdProvider);

    return categoriesAsync.when(
      data: (categories) {
        return transactionsAsync.when(
          data: (transactions) {
            return groupIdAsync.when(
              data: (groupId) {
                if (groupId == null) return const SizedBox.shrink();

                // Buscar BudgetEntries pel cicle actual
                final budgetEntriesStream = ref.watch(
                  _watchlistBudgetEntriesProvider(
                    (
                      groupId: groupId,
                      year: cycle.endDate.year,
                      month: cycle.endDate.month
                    ),
                  ),
                );

                return budgetEntriesStream.when(
                  data: (budgetEntries) {
                    // Filtrar transaccions del cicle actiu
                    final currentTransactions = transactions.where((t) {
                      return t.date.isAfter(
                            cycle.startDate
                                .subtract(const Duration(seconds: 1)),
                          ) &&
                          t.date.isBefore(
                            cycle.endDate.add(const Duration(seconds: 1)),
                          );
                    }).toList();

                    // Calculem despeses per cada subcategoria
                    final spendBySubcat = <String, double>{};
                    for (var t in currentTransactions) {
                      if (!t.isIncome) {
                        spendBySubcat[t.subCategoryId] =
                            (spendBySubcat[t.subCategoryId] ?? 0) + t.amount;
                      }
                    }

                    // Identificar subcategories marcades com a "vigilar"
                    final List<_WatchlistItemData> alerts = [];

                    for (var category in categories) {
                      if (category.type == TransactionType.income) continue;

                      for (var sub in category.subcategories) {
                        if (!sub.isWatched) continue;

                        // Resolem el pressupost efectiu (override mensual > base)
                        final entry =
                            budgetEntries.cast<BudgetEntry?>().firstWhere(
                                  (e) => e!.subCategoryId == sub.id,
                                  orElse: () => null,
                                );
                        final effectiveBudget =
                            entry != null ? entry.amount : sub.monthlyBudget;

                        final spend = spendBySubcat[sub.id] ?? 0.0;
                        final ratio = effectiveBudget > 0
                            ? spend / effectiveBudget
                            : (spend > 0 ? 1.0 : 0.0);

                        alerts.add(
                          _WatchlistItemData(
                            categoryId: category.id,
                            categoryName: category.name,
                            categoryIcon: category.icon,
                            categoryColor: category.color != null
                                ? Color(category.color!)
                                : Colors.grey,
                            subCategory: sub,
                            spent: spend,
                            budget: effectiveBudget,
                            ratio: ratio,
                          ),
                        );
                      }
                    }

                    if (alerts.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    // Ordenar de pitjor a millor estat
                    alerts.sort((a, b) => b.ratio.compareTo(a.ratio));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.visibility,
                                color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Despeses per Vigilar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.anthracite,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...alerts.map((item) => _buildAlertRow(item, ref)),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAlertRow(_WatchlistItemData item, WidgetRef ref) {
    final fmt = NumberFormat('#,##0.00', 'ca_ES');
    bool isOver = item.ratio >= 1.0;
    Color indicatorColor = isOver
        ? Colors.red
        : (item.ratio >= 0.8 ? Colors.orange : Colors.green);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        ref.read(transactionFilterNotifierProvider.notifier).clearAll();
        ref.read(transactionFilterNotifierProvider.notifier).setSubCategory(
              item.categoryId,
              item.categoryName,
              item.subCategory.id,
              item.subCategory.name,
            );
        ref.read(selectedIndexProvider.notifier).state = 2;
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: item.categoryColor.withValues(alpha: 0.1),
              child: Text(item.categoryIcon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.categoryName} - ${item.subCategory.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.ratio.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[200],
                      color: indicatorColor,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.budget > 0
                      ? '${fmt.format(item.spent)}€ / ${fmt.format(item.budget)}€'
                      : '${fmt.format(item.spent)}€',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: indicatorColor,
                    fontSize: 13,
                  ),
                ),
                if (item.budget > 0)
                  Text(
                    '${(item.ratio * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
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

// Provider intern per carregar BudgetEntries del cicle actiu
final _watchlistBudgetEntriesProvider = StreamProvider.autoDispose
    .family<List<BudgetEntry>, ({String groupId, int year, int month})>(
  (ref, params) {
    final repo = ref.watch(budgetEntryRepositoryProvider);
    return repo.watchEntriesForMonth(params.groupId, params.year, params.month);
  },
);

class _WatchlistItemData {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final Color categoryColor;
  final SubCategory subCategory;
  final double spent;
  final double budget;
  final double ratio;

  _WatchlistItemData({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.subCategory,
    required this.spent,
    required this.budget,
    required this.ratio,
  });
}
