import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/budget_provider.dart';

import '../../providers/date_provider.dart';
import '../../../domain/models/category.dart';
import '../categories/manage_categories_screen.dart';
import '../../widgets/responsive_center.dart';
import 'package:centim/l10n/app_localizations.dart';
import '../../providers/auth_providers.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../domain/models/budget_entry.dart';
import '../../widgets/cycle_selector.dart';
import '../../widgets/trends_tab.dart'; // Import TrendsTab

class BudgetControlScreen extends ConsumerStatefulWidget {
  final bool isReadOnly;
  const BudgetControlScreen({super.key, this.isReadOnly = false});

  @override
  ConsumerState<BudgetControlScreen> createState() =>
      _BudgetControlScreenState();
}

class _BudgetControlScreenState extends ConsumerState<BudgetControlScreen> {
  TransactionType _selectedType = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final budgetStatusAsync = ref.watch(budgetNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isReadOnly ? 'Detall estat' : l10n.budgetScreenTitle,
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mensual'),
              Tab(text: 'Tendències'),
            ],
          ),
          actions: widget.isReadOnly
              ? []
              : [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageCategoriesScreen(),
                        ),
                      );
                    },
                  ),
                ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Mensual (Existing content)
            ResponsiveCenter(
              child: Column(
                children: [
                  // Cycle Selector
                  const CycleSelector(),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
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
                  Expanded(
                    child: budgetStatusAsync.when(
                      data: (statuses) {
                        final filteredStatuses = statuses
                            .where((s) => s.category.type == _selectedType)
                            .toList();

                        if (filteredStatuses.isEmpty) {
                          return Center(
                            child: Text(
                              'No hi ha dades de ${_selectedType == TransactionType.expense ? "despesa" : "ingrés"}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filteredStatuses.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final status = filteredStatuses[index];
                            return _BudgetCard(
                              status: status,
                              type: _selectedType, // Pass type for color logic
                              isReadOnly: widget.isReadOnly,
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) =>
                          Center(child: Text(l10n.errorText(e.toString()))),
                    ),
                  ),
                ],
              ),
            ),
            // Tab 2: Tendències (New content)
            const ResponsiveCenter(child: TrendsTab()),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final BudgetStatus status;
  final TransactionType type;
  final bool isReadOnly;

  const _BudgetCard({
    required this.status,
    required this.type,
    required this.isReadOnly,
  });

  Color _getProgressColor(double percentage) {
    if (status.category.color != null) {
      return Color(status.category.color!);
    }
    if (type == TransactionType.expense) {
      // Expense: Green -> Red (Bad if high)
      if (percentage >= 1.0) return Colors.red;
      if (percentage >= 0.75) return AppTheme.copper;
      return Colors.green[700]!;
    } else {
      // Income: Red -> Green (Good if high)
      if (percentage >= 1.0) return Colors.green[700]!;
      if (percentage >= 0.75) return AppTheme.copper;
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressColor = _getProgressColor(status.percentage);
    final isSpentZero = status.spent == 0;
    final isTotalZero = status.total == 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.copper.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              status.category.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          status.category.name.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.anthracite,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: isTotalZero
                          ? (isSpentZero ? 0 : 1)
                          : (status.spent / status.total).clamp(0.0, 1.0),
                      backgroundColor: AppTheme.anthracite.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${status.spent.toStringAsFixed(0)}€ / ${status.total.toStringAsFixed(0)}€',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: status.isOverBudget
                        ? Colors.red
                        : AppTheme.anthracite,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          // Subcategory details
          if (status.subcategoryStatuses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Cap subcategoria definida',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            )
          else
            ...status.subcategoryStatuses.map((subStatus) {
              return _SubcategoryRow(
                subStatus: subStatus,
                category: status.category,
                type: type, // Pass type
                isReadOnly: isReadOnly,
              );
            }),
        ],
      ),
    );
  }
}

class _SubcategoryRow extends ConsumerWidget {
  final SubcategoryBudgetStatus subStatus;
  final Category category;
  final TransactionType type;
  final bool isReadOnly;

  const _SubcategoryRow({
    required this.subStatus,
    required this.category,
    required this.type,
    required this.isReadOnly,
  });

  Color _getProgressColor(double percentage) {
    if (category.color != null) {
      return Color(category.color!);
    }
    if (type == TransactionType.expense) {
      // Expense: Green -> Red
      if (percentage >= 1.0) return Colors.red;
      if (percentage >= 0.75) return AppTheme.copper;
      return Colors.green[700]!;
    } else {
      // Income: Red -> Green
      if (percentage >= 1.0) return Colors.green[700]!;
      if (percentage >= 0.75) return AppTheme.copper;
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressColor = _getProgressColor(subStatus.percentage);
    final isBudgetZero = subStatus.budget == 0;
    final isSpentZero = subStatus.spent == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Subcategory name
          Expanded(
            flex: 3,
            child: Text(
              subStatus.subcategory.name,
              style: const TextStyle(fontSize: 13, color: AppTheme.anthracite),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Progress bar
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: isBudgetZero
                    ? (isSpentZero ? 0 : 1)
                    : (subStatus.spent / subStatus.budget).clamp(0.0, 1.0),
                backgroundColor: AppTheme.anthracite.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Amount display
          SizedBox(
            width: 85,
            child: Text(
              '${subStatus.spent.toStringAsFixed(0)}€/${subStatus.budget.toStringAsFixed(0)}€',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.right,
            ),
          ),
          // Edit button
          if (!isReadOnly)
            SizedBox(
              width: 32,
              child: IconButton(
                icon: Icon(Icons.edit, size: 16, color: Colors.grey[500]),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showQuickBudgetDialog(context, ref),
              ),
            )
          else
            const SizedBox(width: 32), // Placeholder to keep alignment
        ],
      ),
    );
  }

  Future<void> _showQuickBudgetDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final budgetController = TextEditingController(
      text: subStatus.budget.toStringAsFixed(0),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Editar Pressupost', style: const TextStyle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subStatus.subcategory.name,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: budgetController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Objectiu Mensual (€)',
                suffixText: '€',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBudget = double.tryParse(budgetController.text) ?? 0.0;
              final selectedDate = ref.read(selectedDateProvider);
              final groupId = ref.read(currentGroupIdProvider).valueOrNull;

              if (groupId == null) {
                if (context.mounted) Navigator.pop(context);
                return;
              }

              final repo = ref.read(budgetEntryRepositoryProvider);
              final entryId =
                  '${subStatus.subcategory.id}_${selectedDate.year}_${selectedDate.month}';

              // If new budget matches the base budget, remove the exception
              if (newBudget == subStatus.subcategory.monthlyBudget) {
                await repo.deleteEntry(groupId, entryId);
              } else {
                // Otherwise set/update the exception
                final entry = BudgetEntry(
                  id: entryId,
                  subCategoryId: subStatus.subcategory.id,
                  year: selectedDate.year,
                  month: selectedDate.month,
                  amount: newBudget,
                );
                await repo.setEntry(groupId, entry);
              }

              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.copper,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
