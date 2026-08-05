import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/services/ledger_service.dart';

import 'package:centim/presentation/providers/transaction_notifier.dart';
import 'package:centim/presentation/providers/category_notifier.dart';

class CategoryDrillDownSheet extends ConsumerWidget {
  final Category category;
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final Set<String> categoryIds;

  CategoryDrillDownSheet({
    super.key,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    Set<String>? categoryIds,
  }) : categoryIds = categoryIds ?? {category.id};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);

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
                return categoriesAsync.when(
                  data: (categories) => _TransactionList(
                    transactions: transactions,
                    categories: categories,
                    categoryIds: categoryIds,
                    startDate: startDate,
                    endDate: endDate,
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Text('Error carregant les categories: $err'),
                  ),
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

class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final Set<String> categoryIds;
  final DateTime startDate;
  final DateTime endDate;

  const _TransactionList({
    required this.transactions,
    required this.categories,
    required this.categoryIds,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final lookups = LedgerLookups.from(categories);
    final currentSubcategoryNames = <String, String>{
      for (final category in categories)
        for (final subcategory in category.subcategories)
          '${category.id}:${subcategory.id}': subcategory.name,
    };
    final entries = <_DrillDownEntry>[];

    for (final transaction in transactions) {
      if (!categoryIds.contains(transaction.categoryId) ||
          transaction.date.isBefore(startDate) ||
          transaction.date.isAfter(endDate)) {
        continue;
      }
      final classification = classifyTransaction(transaction, lookups);
      if (classification.bucket != LedgerBucket.expense) continue;
      entries.add(
        _DrillDownEntry(transaction, classification.delta),
      );
    }
    entries.sort((a, b) => b.transaction.date.compareTo(a.transaction.date));

    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Cap moviment comptabilitzat.')),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: entries.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final transaction = entry.transaction;
        final currentSubcategory = currentSubcategoryNames[
            '${transaction.categoryId}:${transaction.subCategoryId}'];
        final detail = [
          DateFormat.yMMMd('ca_ES').format(transaction.date),
          if (currentSubcategory != null) currentSubcategory,
        ].join(' · ');
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          title: Text(
            transaction.concept,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            detail,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          trailing: Text(
            '${entry.delta.toStringAsFixed(2).replaceAll('.', ',')} €',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: entry.delta < 0 ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }
}

class _DrillDownEntry {
  final Transaction transaction;
  final double delta;

  const _DrillDownEntry(this.transaction, this.delta);
}
