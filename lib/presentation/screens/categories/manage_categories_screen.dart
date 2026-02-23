import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/category_notifier.dart';

import '../../providers/auth_providers.dart';
import '../../../domain/models/category.dart';
import '../../../data/services/category_seeder_service.dart';
import '../../../data/repositories/category_repository.dart';
import '../../widgets/responsive_center.dart';
import '../../sheets/category_editor_sheet.dart';
import '../../sheets/subcategory_editor_sheet.dart';
import '../../providers/budget_provider.dart';
import '../../providers/billing_cycle_provider.dart';
import '../../../domain/models/billing_cycle.dart';
import '../../../domain/models/budget_entry.dart';
import '../../../data/providers/repository_providers.dart';

// Predefined emoji icons for categories

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState
    extends ConsumerState<ManageCategoriesScreen> {
  TransactionType _selectedType = TransactionType.expense;
  final ScrollController _chipScrollController = ScrollController();

  @override
  void dispose() {
    _chipScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    final cycles = ref.watch(billingCycleNotifierProvider).valueOrNull ?? [];
    final selectedCycle = ref.watch(budgetContextNotifierProvider);
    final balanceAsync = ref.watch(zeroBudgetBalanceProvider);

    // Sort cycles ascending (Febrer, Març, …)
    final sortedCycles = List<BillingCycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Pressupost'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import') {
                _showImportDialog(context, ref);
              } else if (value == 'seed_income') {
                _seedIncomeCategories(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.playlist_add),
                    SizedBox(width: 8),
                    Text('Importar des de text'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'seed_income',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome),
                    SizedBox(width: 8),
                    Text('Generar Ingressos Defecte'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            // ── Context Selector (Choice Chips) ──
            Container(
              height: 50,
              margin: const EdgeInsets.only(top: 4),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView.separated(
                  controller: _chipScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount:
                      sortedCycles.length + 2, // +1 for base, +1 for divider
                  separatorBuilder: (_, i) {
                    if (i == 0) {
                      // Divider between base and cycles
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Center(
                          child: Container(
                            width: 1,
                            height: 24,
                            color: Colors.grey[300],
                          ),
                        ),
                      );
                    }
                    return const SizedBox(width: 6);
                  },
                  itemBuilder: (_, index) {
                    if (index == 0) {
                      // Base / Estàndard chip
                      final isSelected = selectedCycle == null;
                      return ChoiceChip(
                        label: const Text('🛠️ Estàndard'),
                        selected: isSelected,
                        onSelected: (_) {
                          ref
                              .read(budgetContextNotifierProvider.notifier)
                              .select(null);
                        },
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }
                    // Cycle chips (index -1 because of base chip)
                    final cycleIndex = index - 1;
                    if (cycleIndex >= sortedCycles.length) {
                      return const SizedBox.shrink();
                    }
                    final cycle = sortedCycles[cycleIndex];
                    final isSelected = selectedCycle?.id == cycle.id;
                    // Short label: "Feb 26", "Mar 26"
                    final shortLabel =
                        '${cycle.name.length > 5 ? cycle.name.substring(0, 3) : cycle.name}'
                        ' ${cycle.startDate.year.toString().substring(2)}';
                    return ChoiceChip(
                      label: Text(shortLabel),
                      selected: isSelected,
                      onSelected: (_) {
                        ref
                            .read(budgetContextNotifierProvider.notifier)
                            .select(cycle);
                        // Auto-scroll to center selected chip
                        final targetOffset = (index * 80.0) -
                            (MediaQuery.of(context).size.width / 2) +
                            40;
                        _chipScrollController.animateTo(
                          targetOffset.clamp(
                            0,
                            _chipScrollController.position.maxScrollExtent,
                          ),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      selectedColor: Colors.green.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.green.shade900 : null,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  },
                ),
              ),
            ),
            // ── Income / Expense Tabs ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Despeses'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Ingressos'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),
            ),
            // ── Category List with AnimatedSwitcher ──
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey('${selectedCycle?.id}_$_selectedType'),
                  child: categoriesAsync.when(
                    data: (categories) {
                      final filteredCategories = categories
                          .where((c) => c.type == _selectedType)
                          .toList();

                      if (filteredCategories.isEmpty) {
                        return Center(
                          key: ValueKey('empty_$_selectedType'),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hi ha categories de ${_selectedType == TransactionType.expense ? "despesa" : "ingrés"}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Afegeix-ne una per començar',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        );
                      }
                      return ReorderableListView.builder(
                        key: ValueKey(
                          'list_${selectedCycle?.id}_$_selectedType',
                        ),
                        buildDefaultDragHandles: false,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = filteredCategories[index];
                          return Container(
                            key: ValueKey(category.id),
                            child: _CategoryTile(
                              category: category,
                              index: index,
                            ),
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          if (oldIndex < newIndex) newIndex -= 1;
                          final item = filteredCategories.removeAt(oldIndex);
                          filteredCategories.insert(newIndex, item);

                          final offset = _selectedType == TransactionType.income
                              ? 10000
                              : 0;
                          final updatedCategories = <Category>[];
                          for (int i = 0; i < filteredCategories.length; i++) {
                            updatedCategories.add(
                              filteredCategories[i].copyWith(order: offset + i),
                            );
                          }
                          ref
                              .read(categoryNotifierProvider.notifier)
                              .updateCategoriesOrder(updatedCategories);
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  ),
                ),
              ),
            ),
            // ── Sticky Balance Footer ──
            _BalanceFooter(balanceAsync: balanceAsync),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'categories_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            backgroundColor: Colors.white,
            builder: (_) => CategoryEditorSheet(initialType: _selectedType),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BalanceFooter extends ConsumerWidget {
  final AsyncValue<ZeroBudgetSummary> balanceAsync;
  const _BalanceFooter({required this.balanceAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return balanceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        final remainder = summary.remainder;
        final isDeficit = remainder < -0.01;
        final isSurplus = remainder > 0.01;

        final Color bgColor;
        final Color textColor;
        final IconData icon;
        final String label;

        if (isDeficit) {
          bgColor = Colors.red.shade50;
          textColor = Colors.red.shade700;
          icon = Icons.warning_amber_rounded;
          label = 'Et passes de ${remainder.abs().toStringAsFixed(2)} €!';
        } else if (isSurplus) {
          bgColor = Colors.green.shade50;
          textColor = Colors.green.shade700;
          icon = Icons.check_circle_outline;
          label = 'Et queden ${remainder.toStringAsFixed(2)} € per assignar';
        } else {
          bgColor = Colors.blue.shade50;
          textColor = Colors.blue.shade700;
          icon = Icons.balance;
          label = 'Pressupost Perfecte (0 €)';
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(color: textColor.withValues(alpha: 0.3)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Income / Expense summary row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '📈 ${summary.totalIncome.toStringAsFixed(2)} €',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '📉 ${summary.totalExpenses.toStringAsFixed(2)} €',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Balance label row
                Row(
                  children: [
                    Icon(icon, color: textColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isSurplus)
                      TextButton.icon(
                        onPressed: () => _showAssignSurplusSheet(
                          context,
                          ref,
                          summary.remainder,
                        ),
                        icon: const Icon(Icons.savings_outlined, size: 18),
                        label: const Text('Estalvi'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAssignSurplusSheet(
    BuildContext context,
    WidgetRef ref,
    double surplus,
  ) {
    final categories = ref.read(categoryNotifierProvider).valueOrNull ?? [];
    final expenseCategories =
        categories.where((c) => c.type == TransactionType.expense).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.savings, color: AppTheme.copper),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Assignar ${surplus.toStringAsFixed(2)} € a:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: expenseCategories.length,
                itemBuilder: (_, catIndex) {
                  final cat = expenseCategories[catIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          '${cat.icon} ${cat.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                      ...cat.subcategories.map(
                        (sub) => ListTile(
                          dense: true,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.copper.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                            ),
                          ),
                          title: Text(sub.name),
                          subtitle: Text(
                            'Actual: ${sub.monthlyBudget.toStringAsFixed(2)} € → ${(sub.monthlyBudget + surplus).toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _assignSurplus(ref, cat, sub, surplus);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${surplus.toStringAsFixed(2)} € assignats a ${sub.name}',
                                  ),
                                  backgroundColor: AppTheme.copper,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignSurplus(
    WidgetRef ref,
    Category category,
    SubCategory subcategory,
    double surplus,
  ) async {
    final cycle = ref.read(budgetContextNotifierProvider);

    if (cycle == null) {
      // Base context: update the subcategory's monthlyBudget directly
      final updatedSub = subcategory.copyWith(
        monthlyBudget: subcategory.monthlyBudget + surplus,
      );
      final updatedSubs = category.subcategories.map((s) {
        return s.id == subcategory.id ? updatedSub : s;
      }).toList();
      final updatedCat = category.copyWith(subcategories: updatedSubs);
      await ref
          .read(categoryNotifierProvider.notifier)
          .updateCategory(updatedCat);
    } else {
      // Cycle context: create/update a BudgetEntry
      final groupId = await ref.read(currentGroupIdProvider.future);
      if (groupId == null) return;

      final repo = ref.read(budgetEntryRepositoryProvider);
      final year = cycle.startDate.year;
      final month = cycle.startDate.month;

      // Check if an entry already exists
      final existing =
          await repo.watchEntriesForMonth(groupId, year, month).first;
      final match = existing.cast<BudgetEntry?>().firstWhere(
            (e) => e!.subCategoryId == subcategory.id,
            orElse: () => null,
          );

      final currentAmount = match?.amount ?? subcategory.monthlyBudget;
      final entryId = match?.id ?? 'be_${subcategory.id}_${year}_$month';

      await repo.setEntry(
        groupId,
        BudgetEntry(
          id: entryId,
          subCategoryId: subcategory.id,
          year: year,
          month: month,
          amount: currentAmount + surplus,
        ),
      );
    }

    // Invalidate to refresh the balance
    ref.invalidate(zeroBudgetBalanceProvider);
  }
}

class _CategoryTile extends ConsumerWidget {
  final Category category;
  final int index;
  const _CategoryTile({required this.category, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCycle = ref.watch(budgetContextNotifierProvider);
    final groupId = ref.watch(currentGroupIdProvider).valueOrNull;

    // If a cycle is selected, watch entries for that month
    final entriesStream = (selectedCycle != null && groupId != null)
        ? ref.watch(budgetEntryRepositoryProvider).watchEntriesForMonth(
              groupId,
              selectedCycle.endDate.year,
              selectedCycle.endDate.month,
            )
        : null;

    return StreamBuilder<List<BudgetEntry>>(
      stream: entriesStream,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];

        // Helper to get effective budget for a subcategory
        double effectiveBudget(SubCategory sub) {
          if (selectedCycle == null) return sub.monthlyBudget;
          final entry = entries.cast<BudgetEntry?>().firstWhere(
                (e) => e!.subCategoryId == sub.id,
                orElse: () => null,
              );
          return entry?.amount ?? sub.monthlyBudget;
        }

        final totalBudget = category.subcategories.fold<double>(
          0,
          (sum, s) => sum + effectiveBudget(s),
        );

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: ExpansionTile(
            shape: const Border(), // Remove expanded border
            collapsedShape: const Border(), // Remove collapsed border
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.copper.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Total: ${totalBudget.toStringAsFixed(2)} €',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<String>(
                  icon:
                      Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36),
                  onSelected: (value) {
                    if (value == 'edit') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        backgroundColor: Colors.white,
                        builder: (_) => CategoryEditorSheet(category: category),
                      );
                    } else if (value == 'delete') {
                      _deleteCategory(context, ref, category);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle, color: Colors.grey),
                ),
              ],
            ),
            children: [
              ...category.subcategories.map((sub) {
                String fixText = "Variable";
                if (sub.isFixed) {
                  switch (sub.paymentTiming) {
                    case PaymentTiming.specificDay:
                      fixText = sub.paymentDay != null
                          ? "Dia ${sub.paymentDay}"
                          : "Dia Específic";
                      break;
                    case PaymentTiming.firstBusinessDay:
                      fixText = "Primer dia hàbil";
                      break;
                    case PaymentTiming.lastBusinessDay:
                      fixText = "Últim dia hàbil";
                      break;
                  }
                }

                final subBudget = effectiveBudget(sub);
                final isOverride =
                    selectedCycle != null && subBudget != sub.monthlyBudget;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        backgroundColor: Colors.white,
                        builder: (_) => SubCategoryEditorSheet(
                          category: category,
                          subCategory: sub,
                          selectedCycle: ref.read(
                            budgetContextNotifierProvider,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isOverride
                            ? Colors.orange.shade50
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isOverride ? AppTheme.copper : Colors.grey[200]!,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pressupost: ${subBudget.toStringAsFixed(2)} €${isOverride ? ' (base: ${sub.monthlyBudget.toStringAsFixed(0)}€)' : ''} | $fixText',
                                  style: TextStyle(
                                    color: isOverride
                                        ? AppTheme.copper
                                        : Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 4,
                  bottom: 16,
                ),
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      backgroundColor: Colors.white,
                      builder: (_) => SubCategoryEditorSheet(
                        category: category,
                        selectedCycle: ref.read(budgetContextNotifierProvider),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.copper.withAlpha(50),
                        style: BorderStyle.solid,
                      ),
                      color: AppTheme.copper.withAlpha(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: AppTheme.copper, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Afegir subcategoria',
                          style: TextStyle(
                            color: AppTheme.copper,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ); // Card
      }, // StreamBuilder builder
    ); // StreamBuilder
  }
}

Future<void> _seedIncomeCategories(BuildContext context, WidgetRef ref) async {
  try {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) throw Exception('No group selected');

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generant categories...')));
    }

    final repository = CategoryRepository();
    final seeder = CategorySeederService(repository);
    final count = await seeder.seedIncomeCategories(groupId);

    ref.invalidate(categoryNotifierProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count categories d\'ingrés afegides!'),
          backgroundColor: AppTheme.copper,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
  final textController = TextEditingController();
  bool isLoading = false;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Importar Categories'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enganxa el text del teu Excel. Les línies en MAJÚSCULES seran categories, les altres seran subcategories.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText:
                      'LLAR\nllum\naigua\ngas\nCOTXE\nassegurança\ngasolina',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    if (textController.text.trim().isEmpty) return;
                    setState(() => isLoading = true);

                    try {
                      final groupId = await ref.read(
                        currentGroupIdProvider.future,
                      );
                      if (groupId == null) {
                        throw Exception('No group selected');
                      }

                      final repository = CategoryRepository();
                      final seeder = CategorySeederService(repository);
                      final count = await seeder.seedFromText(
                        groupId,
                        textController.text,
                      );

                      // Refresh categories
                      ref.invalidate(categoryNotifierProvider);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$count categories importades!'),
                            backgroundColor: AppTheme.copper,
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() => isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.copper,
              foregroundColor: Colors.white,
            ),
            child: const Text('Processar'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _deleteCategory(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Eliminar Categoria'),
      content: Text('Estàs segur que vols eliminar "${category.name}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel·lar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await ref
        .read(categoryNotifierProvider.notifier)
        .deleteCategory(category.id);
  }
}
