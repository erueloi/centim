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
import '../../sheets/add_transfer_sheet.dart';
import '../../widgets/recurrent_expense_card.dart';
import '../../widgets/cycle_selector.dart';
import '../../providers/billing_cycle_provider.dart';
import '../../providers/transaction_filter_provider.dart';
import '../../providers/category_notifier.dart';
import '../../providers/group_providers.dart';
import '../../widgets/confirm_fixed_expense_dialog.dart';

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

    final hasFilters = filter.categoryIds.isNotEmpty ||
        filter.subCategoryIds.isNotEmpty ||
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
                  ...filter.categoryIds.map((id) => _FilterChip(
                        label: filter.categoryNames[id] ?? 'Categoria',
                        icon: Icons.category,
                        onRemove: () => filterNotifier.toggleCategory(id, ''),
                      )),
                  ...filter.subCategoryIds.map((id) => _FilterChip(
                        label: filter.subCategoryNames[id] ?? 'Subcategoria',
                        icon: Icons.label,
                        onRemove: () =>
                            filterNotifier.toggleSubCategory(id, ''),
                      )),
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
                  if (filter.dateFrom != null || filter.dateTo != null)
                    _FilterChip(
                      label:
                          '${filter.dateFrom != null ? '${filter.dateFrom!.day}/${filter.dateFrom!.month}' : '...'} → ${filter.dateTo != null ? '${filter.dateTo!.day}/${filter.dateTo!.month}' : '...'}',
                      icon: Icons.date_range,
                      onRemove: () => filterNotifier.clearDateRange(),
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
                final tDay =
                    DateTime(t.date.year, t.date.month, t.date.day, 12, 0, 0);
                final startDay = DateTime(
                    activeCycle.startDate.year,
                    activeCycle.startDate.month,
                    activeCycle.startDate.day,
                    12,
                    0,
                    0);
                final endDay = DateTime(
                    activeCycle.endDate.year,
                    activeCycle.endDate.month,
                    activeCycle.endDate.day,
                    12,
                    0,
                    0);

                return (tDay.isAtSameMomentAs(startDay) ||
                        tDay.isAfter(startDay)) &&
                    tDay.isBefore(endDay);
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
              if (filter.categoryIds.isNotEmpty) {
                cycleTransactions = cycleTransactions
                    .where((t) => filter.categoryIds.contains(t.categoryId))
                    .toList();
              }
              if (filter.subCategoryIds.isNotEmpty) {
                cycleTransactions = cycleTransactions
                    .where(
                        (t) => filter.subCategoryIds.contains(t.subCategoryId))
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
              if (filter.dateFrom != null) {
                cycleTransactions = cycleTransactions
                    .where((t) => !t.date.isBefore(filter.dateFrom!))
                    .toList();
              }
              if (filter.dateTo != null) {
                final endOfDay = DateTime(filter.dateTo!.year,
                    filter.dateTo!.month, filter.dateTo!.day, 23, 59, 59);
                cycleTransactions = cycleTransactions
                    .where((t) => !t.date.isAfter(endOfDay))
                    .toList();
              }

              // Get transfers for the active cycle (only if no category filter)
              final transfers = transfersAsync.valueOrNull ?? [];
              final showTransfers = filter.categoryIds.isEmpty &&
                  filter.subCategoryIds.isEmpty &&
                  filter.isIncome == null;

              final cycleTransfers = showTransfers
                  ? transfers.where((t) {
                      final tDay = DateTime(
                          t.date.year, t.date.month, t.date.day, 12, 0, 0);
                      final startDay = DateTime(
                          activeCycle.startDate.year,
                          activeCycle.startDate.month,
                          activeCycle.startDate.day,
                          12,
                          0,
                          0);
                      final endDay = DateTime(
                          activeCycle.endDate.year,
                          activeCycle.endDate.month,
                          activeCycle.endDate.day,
                          12,
                          0,
                          0);

                      return (tDay.isAtSameMomentAs(startDay) ||
                              tDay.isAfter(startDay)) &&
                          tDay.isBefore(endDay);
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
                          return Dismissible(
                            key: Key(transfer.id),
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
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Eliminar traspàs'),
                                  content: const Text(
                                    'Estàs segur que vols eliminar aquest traspàs? Els saldos es restauraran automàticament.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel·lar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) async {
                              try {
                                await ref
                                    .read(transferNotifierProvider.notifier)
                                    .deleteTransfer(transfer.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Traspàs eliminat correctament'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Error esborrant: $e')),
                                  );
                                }
                              }
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
                                    useSafeArea: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => AddTransferSheet(
                                      transferToEdit: transfer,
                                    ),
                                  );
                                },
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.blueGrey.withValues(alpha: 0.1),
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
  Set<String> _selectedCategoryIds = {};
  Map<String, String> _selectedCategoryNames = {};
  Set<String> _selectedSubCategoryIds = {};
  Map<String, String> _selectedSubCategoryNames = {};
  bool? _selectedType;
  String? _selectedPayer;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filter = ref.read(transactionFilterNotifierProvider);
    _selectedCategoryIds = Set.from(filter.categoryIds);
    _selectedCategoryNames = Map.from(filter.categoryNames);
    _selectedSubCategoryIds = Set.from(filter.subCategoryIds);
    _selectedSubCategoryNames = Map.from(filter.subCategoryNames);
    _selectedType = filter.isIncome;
    _selectedPayer = filter.payer;
    _dateFrom = filter.dateFrom;
    _dateTo = filter.dateTo;
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

    // Clear all first, then apply selections
    notifier.clearAll();

    // Apply categories
    for (final id in _selectedCategoryIds) {
      final name = _selectedCategoryNames[id] ?? '';
      notifier.toggleCategory(id, name);
    }

    // Apply subcategories
    for (final id in _selectedSubCategoryIds) {
      final name = _selectedSubCategoryNames[id] ?? '';
      notifier.toggleSubCategory(id, name);
    }

    notifier.setType(_selectedType);
    notifier.setPayer(_selectedPayer);

    final min = double.tryParse(_minController.text);
    final max = double.tryParse(_maxController.text);
    notifier.setAmountRange(min, max);
    notifier.setDateRange(_dateFrom, _dateTo);

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
              'Categories',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: categories.map((c) {
                    final isSelected = _selectedCategoryIds.contains(c.id);
                    return FilterChip(
                      label: Text('${c.icon} ${c.name}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategoryIds.add(c.id);
                            _selectedCategoryNames[c.id] = c.name;
                          } else {
                            _selectedCategoryIds.remove(c.id);
                            _selectedCategoryNames.remove(c.id);
                            for (final sub in c.subcategories) {
                              _selectedSubCategoryIds.remove(sub.id);
                              _selectedSubCategoryNames.remove(sub.id);
                            }
                          }
                        });
                      },
                      selectedColor: AppTheme.copper.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.copper,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              isSelected ? AppTheme.copper : Colors.grey[300]!,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Subcategory filter (for selected categories)
            if (_selectedCategoryIds.isNotEmpty)
              categoriesAsync.when(
                data: (categories) {
                  final selectedCats = categories
                      .where((c) => _selectedCategoryIds.contains(c.id))
                      .toList();
                  final allSubs = <(String, SubCategory)>[];
                  for (final cat in selectedCats) {
                    for (final sub in cat.subcategories) {
                      allSubs.add((cat.name, sub));
                    }
                  }
                  if (allSubs.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subcategories',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: allSubs.map((item) {
                          final catName = item.$1;
                          final sub = item.$2;
                          final isSelected =
                              _selectedSubCategoryIds.contains(sub.id);
                          return FilterChip(
                            label: Text(
                              selectedCats.length > 1
                                  ? '$catName: ${sub.name}'
                                  : sub.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSubCategoryIds.add(sub.id);
                                  _selectedSubCategoryNames[sub.id] = sub.name;
                                } else {
                                  _selectedSubCategoryIds.remove(sub.id);
                                  _selectedSubCategoryNames.remove(sub.id);
                                }
                              });
                            },
                            selectedColor:
                                AppTheme.copper.withValues(alpha: 0.15),
                            checkmarkColor: AppTheme.copper,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? AppTheme.copper
                                    : Colors.grey[300]!,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
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

            // Date range filter
            Text(
              'Rang de dates',
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
                  child: InputChip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _dateFrom != null
                          ? '${_dateFrom!.day}/${_dateFrom!.month}/${_dateFrom!.year}'
                          : 'Des de...',
                    ),
                    selected: _dateFrom != null,
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _dateFrom ??
                            DateTime.now().subtract(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _dateFrom = d);
                    },
                    onDeleted: _dateFrom != null
                        ? () => setState(() => _dateFrom = null)
                        : null,
                    backgroundColor: Colors.grey[50],
                    selectedColor: AppTheme.copper.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InputChip(
                    avatar: const Icon(Icons.event, size: 16),
                    label: Text(
                      _dateTo != null
                          ? '${_dateTo!.day}/${_dateTo!.month}/${_dateTo!.year}'
                          : 'Fins a...',
                    ),
                    selected: _dateTo != null,
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _dateTo ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _dateTo = d);
                    },
                    onDeleted: _dateTo != null
                        ? () => setState(() => _dateTo = null)
                        : null,
                    backgroundColor: Colors.grey[50],
                    selectedColor: AppTheme.copper.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
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
            final result = await showDialog<ConfirmFixedExpenseResult>(
              context: context,
              builder: (ctx) => ConfirmFixedExpenseDialog(
                expenseName: item.subCategory.name,
                amount: item.subCategory.monthlyBudget,
                isIncome: isIncome,
              ),
            );

            if (result == null) return false;

            // Proceed with payment
            final groupId = await ref.read(currentGroupIdProvider.future);
            final userProfile = await ref.read(userProfileProvider.future);
            if (groupId == null || userProfile == null) return false;

            final transaction = Transaction(
              groupId: groupId,
              date: result.date,
              amount: item.subCategory.monthlyBudget,
              concept: 'Pagament ${item.subCategory.name}',
              categoryId: item.category.id,
              subCategoryId: item.subCategory.id,
              categoryName: item.category.name,
              subCategoryName: item.subCategory.name,
              accountId: result.accountId,
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
                    'Pagament registrat el ${DateFormat('dd/MM', 'ca_ES').format(result.date)}: ${item.subCategory.name}',
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
