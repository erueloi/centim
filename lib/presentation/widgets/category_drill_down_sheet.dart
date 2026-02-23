import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/category.dart';

import 'package:centim/presentation/providers/transaction_notifier.dart';

class CategoryDrillDownSheet extends ConsumerWidget {
  final Category category;
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;

  const CategoryDrillDownSheet({
    super.key,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionNotifierProvider);

    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header (Category Info)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: category.color != null
                        ? Color(category.color!).withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      category.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.anthracite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Import total de ${DateFormat.MMMd('ca_ES').format(startDate)} a ${DateFormat.MMMd('ca_ES').format(endDate)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${totalAmount.toStringAsFixed(2).replaceAll('.', ',')} €',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: category.type == TransactionType.income
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),

          // Transaction List
          Flexible(
            child: transactionsAsync.when(
              data: (transactions) {
                // Filter transactions for this specific category and date range
                final filtered = transactions.where((t) {
                  return t.categoryId == category.id &&
                      t.date.isAfter(
                          startDate.subtract(const Duration(days: 1))) &&
                      t.date.isBefore(endDate.add(const Duration(days: 1)));
                }).toList();

                // Sort newest first
                filtered.sort((a, b) => b.date.compareTo(a.date));

                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('Cap moviment trobat.'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = filtered[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 4),
                      title: Text(
                        t.concept,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat.yMMMd('ca_ES').format(t.date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      trailing: Text(
                        '${t.amount.toStringAsFixed(2).replaceAll('.', ',')} €',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: t.isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error carregant els moviments: $err'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
