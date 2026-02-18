import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transfer.dart';
import '../../../domain/models/category.dart';
import '../../providers/transaction_notifier.dart';
import '../../providers/transfer_provider.dart';
import '../../providers/fixed_expenses_provider.dart';
import '../../providers/auth_providers.dart';
import '../../sheets/add_transaction_sheet.dart';
import '../../widgets/recurrent_expense_card.dart';
import '../../widgets/cycle_selector.dart';
import '../../providers/billing_cycle_provider.dart';

import '../../../domain/services/import_service.dart';
import '../import/import_transactions_screen.dart';

class MovimentsScreen extends ConsumerWidget {
  const MovimentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Moviments'),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_upload),
              tooltip: 'Importar CSV (CaixaBank)',
              onPressed: () async {
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final service = ref.read(importServiceProvider);
                  final transactions = await service.pickAndParseCsv();

                  // Close loading
                  if (context.mounted) Navigator.pop(context);

                  if (transactions.isNotEmpty) {
                    if (context.mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImportTransactionsScreen(
                            transactions: transactions,
                          ),
                        ),
                      );
                      // If result is true, refresh? (Streams update automatically)
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No s\'han trobat moviments o s\'ha cancel·lat la selecció',
                          ),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // Close loading if error
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error important: $e')),
                    );
                  }
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tots'),
              Tab(text: 'Fixes'),
            ],
            indicatorColor: AppTheme.copper,
            labelColor: AppTheme.anthracite,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: Column(
          children: [
            const CycleSelector(),
            const Expanded(
              child: TabBarView(
                children: [_AllMovementsView(), _RecurringExpensesView()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllMovementsView extends ConsumerWidget {
  const _AllMovementsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final transfersAsync = ref.watch(transferNotifierProvider);
    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final dateFormat = DateFormat('dd MMM yyyy', 'ca_ES');

    return transactionsAsync.when(
      data: (transactions) {
        final activeCycle = ref.watch(activeCycleProvider);

        // Filter transactions by active cycle
        final cycleTransactions = transactions.where((t) {
          return t.date.isAfter(
                activeCycle.startDate.subtract(const Duration(seconds: 1)),
              ) &&
              t.date.isBefore(
                activeCycle.endDate.add(const Duration(seconds: 1)),
              );
        }).toList();

        // Get transfers for the active cycle
        final transfers = transfersAsync.valueOrNull ?? [];
        final cycleTransfers = transfers.where((t) {
          return t.date.isAfter(
                activeCycle.startDate.subtract(const Duration(seconds: 1)),
              ) &&
              t.date.isBefore(
                activeCycle.endDate.add(const Duration(seconds: 1)),
              );
        }).toList();

        // Build unified list of movement items
        final List<_MovementItem> items = [];
        for (final t in cycleTransactions) {
          items.add(_MovementItem(date: t.date, transaction: t));
        }
        for (final t in cycleTransfers) {
          items.add(_MovementItem(date: t.date, transfer: t));
        }
        items.sort((a, b) => b.date.compareTo(a.date));

        if (items.isEmpty) {
          return const Center(
            child: Text('No hi ha moviments en aquest cicle'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            // --- Transfer tile ---
            if (item.transfer != null) {
              final transfer = item.transfer!;
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.swap_horiz,
                      color: Colors.blueGrey[600],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '${transfer.sourceAssetName} → ${transfer.destinationName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${dateFormat.format(transfer.date)}${transfer.note != null ? ' • ${transfer.note}' : ''}',
                  ),
                  trailing: Text(
                    currencyFormat.format(transfer.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueGrey[700],
                    ),
                  ),
                ),
              );
            }

            // --- Transaction tile ---
            final transaction = item.transaction!;
            final isIncome = transaction.isIncome;

            return Dismissible(
              key: Key(transaction.id ?? index.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Esborrar moviment?'),
                    content: const Text('Aquesta acció no es pot desfer.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel·lar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Esborrar'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                ref
                    .read(transactionNotifierProvider.notifier)
                    .deleteTransaction(transaction);
              },
              child: Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          AddTransactionSheet(transactionToEdit: transaction),
                    );
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isIncome
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isIncome ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    transaction.concept,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${dateFormat.format(transaction.date)} • ${transaction.categoryName}',
                  ),
                  trailing: Text(
                    '${isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _RecurringExpensesView extends ConsumerWidget {
  const _RecurringExpensesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixedExpenses = ref.watch(fixedExpensesProvider);

    if (fixedExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Totes les despeses fixes pagades!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquest mes ja ho tens tot al dia.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: fixedExpenses.length,
      itemBuilder: (context, index) {
        final item = fixedExpenses[index];
        final isIncome = item.category.type == TransactionType.income;
        return RecurrentExpenseCard(
          subCategory: item.subCategory,
          categoryIcon: item.category.icon,
          isIncome: isIncome,
          confirmDismiss: (direction) async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              helpText: 'Seleciona la data del pagament',
            );

            if (selectedDate == null) return false;

            // Proceed with payment
            final groupId = await ref.read(currentGroupIdProvider.future);
            final userProfile = await ref.read(userProfileProvider.future);
            if (groupId == null || userProfile == null) return false;

            final transaction = Transaction(
              groupId: groupId,
              date: selectedDate,
              amount: item.subCategory.monthlyBudget,
              concept: 'Pagament ${item.subCategory.name}',
              categoryId: item.category.id,
              subCategoryId: item.subCategory.id,
              categoryName: item.category.name,
              subCategoryName: item.subCategory.name,
              payer: userProfile.uid,
              isIncome: item.category.type == TransactionType.income,
            );

            await ref
                .read(transactionNotifierProvider.notifier)
                .addTransaction(transaction);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pagament registrat el ${DateFormat('dd/MM', 'ca_ES').format(selectedDate)}: ${item.subCategory.name}',
                  ),
                ),
              );
            }
            return true;
          },
          onPay: () {
            // Logic moved to confirmDismiss to ensure date is selected first
          },
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddTransactionSheet(
                initialCategory: item.category,
                initialSubCategory: item.subCategory,
                initialAmount: item.subCategory.monthlyBudget,
                initialConcept: 'Pagament ${item.subCategory.name}',
              ),
            );
          },
        );
      },
    );
  }
}

/// Helper class to unify transactions and transfers in one sorted list.
class _MovementItem {
  final DateTime date;
  final Transaction? transaction;
  final Transfer? transfer;

  _MovementItem({required this.date, this.transaction, this.transfer});
}
