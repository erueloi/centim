import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/asset.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transfer.dart';
import '../../../domain/models/category.dart';
import '../../providers/asset_provider.dart';
import '../../providers/transaction_notifier.dart';
import '../../providers/transfer_provider.dart';
import '../../providers/fixed_expenses_provider.dart';
import '../../providers/auth_providers.dart';
import '../../sheets/add_transaction_sheet.dart';
import '../../widgets/recurrent_expense_card.dart';
import '../../widgets/cycle_selector.dart';
import '../../providers/billing_cycle_provider.dart';
import '../../providers/transaction_filter_provider.dart';
import '../../providers/category_notifier.dart';
import '../../providers/group_providers.dart';

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
            // --- MIGRATION BUTTON (TEMPORARY) ---
            IconButton(
              icon: const Icon(Icons.build_circle_outlined),
              tooltip: '🛠️ Migrar Moviments Antics',
              onPressed: () async {
                final groupId = await ref.read(currentGroupIdProvider.future);
                if (groupId == null || !context.mounted) return;

                // Query Firestore for transactions without accountId
                final firestore = FirebaseFirestore.instance;
                final snapshot = await firestore
                    .collection('transactions')
                    .where('groupId', isEqualTo: groupId)
                    .get();

                // Filter locally: accountId == null or field missing
                final orphaned = snapshot.docs.where((doc) {
                  final data = doc.data();
                  return !data.containsKey('accountId') ||
                      data['accountId'] == null;
                }).toList();

                if (!context.mounted) return;

                if (orphaned.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tots els moviments estan actualitzats ✅'),
                    ),
                  );
                  return;
                }

                // Show dialog with account selector
                final assets = await ref.read(assetNotifierProvider.future);
                final liquidAssets = assets
                    .where((a) =>
                        a.type == AssetType.bankAccount ||
                        a.type == AssetType.cash)
                    .toList();

                if (liquidAssets.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No hi ha comptes líquids disponibles'),
                      ),
                    );
                  }
                  return;
                }

                String? selectedId;
                if (!context.mounted) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) {
                    return StatefulBuilder(
                      builder: (ctx, setDialogState) {
                        return AlertDialog(
                          title: const Text('Migrar Moviments Antics'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'S\'han trobat ${orphaned.length} moviments sense compte assignat.\n\nA quin compte els vols vincular?',
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: selectedId,
                                decoration: const InputDecoration(
                                  labelText: 'Compte',
                                  prefixIcon: Icon(Icons.account_balance),
                                ),
                                items: liquidAssets
                                    .map((a) => DropdownMenuItem(
                                          value: a.id,
                                          child: Text(
                                              '${a.name} (${a.amount.toStringAsFixed(2)} €)'),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setDialogState(() => selectedId = v),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel·lar'),
                            ),
                            ElevatedButton(
                              onPressed: selectedId == null
                                  ? null
                                  : () => Navigator.pop(ctx, true),
                              child: const Text('Migrar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );

                if (confirmed != true ||
                    selectedId == null ||
                    !context.mounted) {
                  return;
                }

                // Execute migration with WriteBatch
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final batch = firestore.batch();

                  double totalIncome = 0;
                  double totalExpense = 0;

                  for (final doc in orphaned) {
                    final data = doc.data();
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                    final isIncome = data['isIncome'] as bool? ?? false;

                    if (isIncome) {
                      totalIncome += amount;
                    } else {
                      totalExpense += amount;
                    }

                    batch.update(
                      firestore.collection('transactions').doc(doc.id),
                      {'accountId': selectedId},
                    );
                  }

                  // Calculate net impact and update asset balance
                  final netImpact = totalIncome - totalExpense;
                  final asset =
                      liquidAssets.firstWhere((a) => a.id == selectedId);
                  final assetDoc = firestore
                      .collection('groups')
                      .doc(groupId)
                      .collection('assets')
                      .doc(selectedId);
                  batch.update(assetDoc, {
                    'amount': asset.amount + netImpact,
                  });

                  await batch.commit();

                  if (context.mounted) {
                    Navigator.pop(context); // close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Migració completada amb èxit! ${orphaned.length} moviments actualitzats.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error en la migració: $e')),
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
        body: const Column(
          children: [
            CycleSelector(),
            Expanded(
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

class _AllMovementsView extends ConsumerStatefulWidget {
  const _AllMovementsView();

  @override
  ConsumerState<_AllMovementsView> createState() => _AllMovementsViewState();
}

class _AllMovementsViewState extends ConsumerState<_AllMovementsView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final transfersAsync = ref.watch(transferNotifierProvider);
    final filter = ref.watch(transactionFilterNotifierProvider);
    final filterNotifier = ref.read(transactionFilterNotifierProvider.notifier);
    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final dateFormat = DateFormat('dd MMM yyyy', 'ca_ES');

    final hasFilters = filter.categoryId != null ||
        filter.subCategoryId != null ||
        filter.isIncome != null ||
        filter.payer != null ||
        filter.minAmount != null ||
        filter.maxAmount != null;

    return Column(
      children: [
        // Search bar + filter button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 44,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar moviments...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                filterNotifier.clearSearch();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.copper,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) {
                      filterNotifier.setSearch(value);
                      setState(() {}); // Update suffix icon
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter button
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: hasFilters ? AppTheme.copper : Colors.grey[600],
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: hasFilters
                          ? AppTheme.copper.withValues(alpha: 0.1)
                          : Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        backgroundColor: Colors.white,
                        builder: (_) => const _FilterSheet(),
                      );
                    },
                  ),
                  if (hasFilters)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.copper,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Active filter chips
        if (hasFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (filter.categoryId != null)
                    _FilterChip(
                      label: filter.categoryName ?? 'Categoria',
                      icon: Icons.category,
                      onRemove: () => filterNotifier.clearCategory(),
                    ),
                  if (filter.subCategoryId != null)
                    _FilterChip(
                      label: filter.subCategoryName ?? 'Subcategoria',
                      icon: Icons.label,
                      onRemove: () => filterNotifier.clearSubCategory(),
                    ),
                  if (filter.isIncome != null)
                    _FilterChip(
                      label: filter.isIncome! ? 'Ingressos' : 'Despeses',
                      icon: filter.isIncome!
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      onRemove: () => filterNotifier.clearType(),
                    ),
                  if (filter.payer != null)
                    _FilterChip(
                      label: filter.payer!,
                      icon: Icons.person,
                      onRemove: () => filterNotifier.clearPayer(),
                    ),
                  if (filter.minAmount != null || filter.maxAmount != null)
                    _FilterChip(
                      label:
                          '${filter.minAmount?.toStringAsFixed(0) ?? '0'}€ - ${filter.maxAmount?.toStringAsFixed(0) ?? '∞'}€',
                      icon: Icons.euro,
                      onRemove: () => filterNotifier.clearAmountRange(),
                    ),
                  const SizedBox(width: 4),
                  ActionChip(
                    label: const Text(
                      'Netejar tot',
                      style: TextStyle(fontSize: 12),
                    ),
                    avatar: const Icon(Icons.clear_all, size: 16),
                    onPressed: () {
                      filterNotifier.clearAll();
                      _searchController.clear();
                    },
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: Colors.red.shade50,
                    labelStyle: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 4),

        // Transaction list
        Expanded(
          child: transactionsAsync.when(
            data: (transactions) {
              final activeCycle = ref.watch(activeCycleProvider);

              // Filter by active cycle
              var cycleTransactions = transactions.where((t) {
                return t.date.isAfter(
                      activeCycle.startDate.subtract(
                        const Duration(seconds: 1),
                      ),
                    ) &&
                    t.date.isBefore(
                      activeCycle.endDate.add(const Duration(seconds: 1)),
                    );
              }).toList();

              // Apply filters
              if (filter.searchQuery != null &&
                  filter.searchQuery!.isNotEmpty) {
                final query = filter.searchQuery!.toLowerCase();
                cycleTransactions = cycleTransactions
                    .where(
                      (t) =>
                          t.concept.toLowerCase().contains(query) ||
                          t.categoryName.toLowerCase().contains(query) ||
                          t.subCategoryName.toLowerCase().contains(query),
                    )
                    .toList();
              }
              if (filter.categoryId != null) {
                cycleTransactions = cycleTransactions
                    .where((t) => t.categoryId == filter.categoryId)
                    .toList();
              }
              if (filter.subCategoryId != null) {
                cycleTransactions = cycleTransactions
                    .where((t) => t.subCategoryId == filter.subCategoryId)
                    .toList();
              }
              if (filter.isIncome != null) {
                cycleTransactions = cycleTransactions
                    .where((t) => t.isIncome == filter.isIncome)
                    .toList();
              }
              if (filter.payer != null) {
                cycleTransactions = cycleTransactions
                    .where((t) => t.payer == filter.payer)
                    .toList();
              }
              if (filter.minAmount != null) {
                cycleTransactions = cycleTransactions
                    .where((t) => t.amount >= filter.minAmount!)
                    .toList();
              }
              if (filter.maxAmount != null) {
                cycleTransactions = cycleTransactions
                    .where((t) => t.amount <= filter.maxAmount!)
                    .toList();
              }

              // Get transfers for the active cycle (only if no category filter)
              final transfers = transfersAsync.valueOrNull ?? [];
              final showTransfers = filter.categoryId == null &&
                  filter.subCategoryId == null &&
                  filter.isIncome == null;

              final cycleTransfers = showTransfers
                  ? transfers.where((t) {
                      return t.date.isAfter(
                            activeCycle.startDate.subtract(
                              const Duration(seconds: 1),
                            ),
                          ) &&
                          t.date.isBefore(
                            activeCycle.endDate.add(const Duration(seconds: 1)),
                          );
                    }).toList()
                  : <Transfer>[];

              // Build unified list
              final List<_MovementItem> items = [];
              for (final t in cycleTransactions) {
                items.add(_MovementItem(date: t.date, transaction: t));
              }
              for (final t in cycleTransfers) {
                items.add(_MovementItem(date: t.date, transfer: t));
              }
              items.sort((a, b) => b.date.compareTo(a.date));

              // Compute totals for active filters
              double totalIncome = 0;
              double totalExpense = 0;
              if (hasFilters || filter.searchQuery != null) {
                for (final t in cycleTransactions) {
                  if (t.isIncome) {
                    totalIncome += t.amount;
                  } else {
                    totalExpense += t.amount;
                  }
                }
              }

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        hasFilters || filter.searchQuery != null
                            ? 'Cap moviment coincideix amb els filtres'
                            : 'No hi ha moviments en aquest cicle',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // Results count
              return Column(
                children: [
                  if (hasFilters || filter.searchQuery != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            '${items.length} resultat${items.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hasFilters || filter.searchQuery != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ingressos',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '+${currencyFormat.format(totalIncome)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.grey.shade200,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Despeses',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '-${currencyFormat.format(totalExpense)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
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
                              side: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Esborrar moviment?'),
                                content: const Text(
                                  'Aquesta acció no es pot desfer.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel·lar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
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
                              side: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            child: ListTile(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  showDragHandle: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => AddTransactionSheet(
                                    transactionToEdit: transaction,
                                  ),
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
                                  isIncome
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: isIncome ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                transaction.concept,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${dateFormat.format(transaction.date)} • ${transaction.categoryName}${transaction.subCategoryName.isNotEmpty && transaction.subCategoryName != 'General' ? ' > ${transaction.subCategoryName}' : ''}',
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
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        avatar: Icon(icon, size: 14, color: AppTheme.copper),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onRemove,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: AppTheme.copper.withValues(alpha: 0.08),
        side: BorderSide(color: AppTheme.copper.withValues(alpha: 0.24)),
        labelPadding: const EdgeInsets.only(left: 2),
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  bool? _selectedType;
  String? _selectedPayer;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filter = ref.read(transactionFilterNotifierProvider);
    _selectedCategoryId = filter.categoryId;
    _selectedSubCategoryId = filter.subCategoryId;
    _selectedType = filter.isIncome;
    _selectedPayer = filter.payer;
    _minController.text = filter.minAmount?.toStringAsFixed(0) ?? '';
    _maxController.text = filter.maxAmount?.toStringAsFixed(0) ?? '';
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    final notifier = ref.read(transactionFilterNotifierProvider.notifier);
    final categories = ref.read(categoryNotifierProvider).valueOrNull ?? [];

    if (_selectedCategoryId != null) {
      final cat = categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => categories.first,
      );
      if (_selectedSubCategoryId != null) {
        final sub = cat.subcategories.firstWhere(
          (s) => s.id == _selectedSubCategoryId,
          orElse: () => cat.subcategories.first,
        );
        notifier.setSubCategory(cat.id, cat.name, sub.id, sub.name);
      } else {
        notifier.setCategory(cat.id, cat.name);
      }
    } else {
      notifier.clearCategory();
    }

    notifier.setType(_selectedType);
    notifier.setPayer(_selectedPayer);

    final min = double.tryParse(_minController.text);
    final max = double.tryParse(_maxController.text);
    notifier.setAmountRange(min, max);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final membersAsync = ref.watch(groupMembersProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Filtres Avançats',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.anthracite,
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // Type filter
            Text(
              'Tipus',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool?>(
              segments: const [
                ButtonSegment(value: null, label: Text('Tots')),
                ButtonSegment(
                  value: false,
                  label: Text('Despeses'),
                  icon: Icon(Icons.arrow_downward, size: 16),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Ingressos'),
                  icon: Icon(Icons.arrow_upward, size: 16),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (v) =>
                  setState(() => _selectedType = v.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.anthracite.withAlpha(25);
                  }
                  return Colors.transparent;
                }),
                side: WidgetStateProperty.all(
                  BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category filter
            Text(
              'Categoria',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) {
                return DropdownButtonFormField<String?>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    hintText: 'Totes les categories',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Totes')),
                    ...categories.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.icon} ${c.name}'),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedCategoryId = v;
                      _selectedSubCategoryId = null;
                    });
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Subcategory filter (only if category selected)
            if (_selectedCategoryId != null)
              categoriesAsync.when(
                data: (categories) {
                  final cat = categories.firstWhere(
                    (c) => c.id == _selectedCategoryId,
                    orElse: () => categories.first,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subcategoria',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedSubCategoryId,
                        decoration: InputDecoration(
                          hintText: 'Totes les subcategories',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Totes'),
                          ),
                          ...cat.subcategories.map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedSubCategoryId = v),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

            // Payer filter
            membersAsync.when(
              data: (members) {
                if (members.length <= 1) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagador',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedPayer,
                      decoration: InputDecoration(
                        hintText: 'Tots',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tots'),
                        ),
                        ...members.map(
                          (m) => DropdownMenuItem(
                            value: m.uid,
                            child: Text(m.name ?? m.email.split('@').first),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedPayer = v),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Amount range
            Text(
              'Rang d\'import',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Mínim',
                      suffixText: '€',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('—', style: TextStyle(color: Colors.grey[500])),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Màxim',
                      suffixText: '€',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref
                          .read(transactionFilterNotifierProvider.notifier)
                          .clearAll();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Netejar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.copper,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Aplicar Filtres'),
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
