import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/services/ledger_service.dart';
import '../../../domain/services/subcategory_movement_grouping_service.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_notifier.dart';
import '../../providers/cycle_spending_margin_provider.dart';

import '../../providers/date_provider.dart';
import '../../../domain/models/category.dart';
import '../categories/manage_categories_screen.dart';
import '../../widgets/responsive_center.dart';
import 'package:centim/l10n/app_localizations.dart';
import '../../providers/auth_providers.dart';
import '../../../data/providers/repository_providers.dart';
import '../../providers/transaction_notifier.dart';
import '../../providers/billing_cycle_provider.dart';
import '../../../domain/models/budget_entry.dart';
import '../../widgets/cycle_selector.dart';
import '../../widgets/budget_progress_style.dart';
import '../../widgets/trends_tab.dart'; // Import TrendsTab
import '../../providers/transaction_filter_provider.dart';
import '../../widgets/main_scaffold.dart';
import '../dashboard/panoramic_heatmap_screen.dart';

class BudgetControlScreen extends ConsumerStatefulWidget {
  final bool isReadOnly;
  const BudgetControlScreen({super.key, this.isReadOnly = false});

  @override
  ConsumerState<BudgetControlScreen> createState() =>
      _BudgetControlScreenState();
}

class _BudgetControlScreenState extends ConsumerState<BudgetControlScreen> {
  TransactionType _selectedType = TransactionType.expense;
  final _marginCardKey = GlobalKey<_CycleSpendingMarginCardState>();
  final Map<String, _CachedMovementGrouping> _movementGroupingCache = {};
  String? _movementGroupingCacheCycleId;

  @override
  Widget build(BuildContext context) {
    final budgetStatusAsync = ref.watch(budgetNotifierProvider);
    final ledgerSummary =
        ref.watch(activeCycleLedgerSummaryProvider).valueOrNull;
    final activeCycleId = ref.watch(activeCycleProvider).id;
    final l10n = AppLocalizations.of(context)!;
    if (_movementGroupingCacheCycleId != activeCycleId) {
      _movementGroupingCache.clear();
      _movementGroupingCacheCycleId = activeCycleId;
    }

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
          actions: [
            IconButton(
              icon: const Icon(Icons.grid_on_rounded),
              tooltip: l10n.panoramicTitle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PanoramicHeatmapScreen(),
                  ),
                );
              },
            ),
            if (!widget.isReadOnly)
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

                        return Column(
                          children: [
                            Expanded(
                              child: filteredStatuses.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No hi ha dades de ${_selectedType == TransactionType.expense ? "despesa" : "ingrés"}',
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                    )
                                  : NotificationListener<
                                      UserScrollNotification>(
                                      onNotification: (notification) {
                                        if (notification.direction !=
                                            ScrollDirection.idle) {
                                          _marginCardKey.currentState
                                              ?.collapse();
                                        }
                                        return false;
                                      },
                                      child: ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          0,
                                          16,
                                          16,
                                        ),
                                        itemCount: filteredStatuses.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final status =
                                              filteredStatuses[index];
                                          return _BudgetCard(
                                            status: status,
                                            type: _selectedType,
                                            isReadOnly: widget.isReadOnly,
                                            ledgerSummary: ledgerSummary,
                                            movementGroupingCache:
                                                _movementGroupingCache,
                                          );
                                        },
                                      ),
                                    ),
                            ),
                            _CycleSpendingMarginCard(key: _marginCardKey),
                          ],
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
  final LedgerSummary? ledgerSummary;
  final Map<String, _CachedMovementGrouping> movementGroupingCache;

  const _BudgetCard({
    required this.status,
    required this.type,
    required this.isReadOnly,
    required this.ledgerSummary,
    required this.movementGroupingCache,
  });

  Color _getProgressColor(double percentage, {required bool isSavings}) {
    if (status.category.color != null) {
      return Color(status.category.color!);
    }
    if (type == TransactionType.expense && !isSavings) {
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
    final isSavings = isSavingsBudgetCategory(status.category);
    final savingsProgress = ledgerSummary == null
        ? null
        : SavingsBudgetProgress.forCycle(ledgerSummary!);
    final displayedAmount = isSavings ? savingsProgress?.net : status.spent;
    final percentage = displayedAmount == null
        ? 0.0
        : status.total > 0
            ? displayedAmount / status.total
            : displayedAmount > 0
                ? 1.0
                : 0.0;
    final progressColor = _getProgressColor(
      percentage,
      isSavings: isSavings,
    );
    final percentageColor = isSavings || type == TransactionType.income
        ? budgetAchievementColor(percentage)
        : budgetConsumptionColor(percentage);
    final isDisplayedZero = displayedAmount == null || displayedAmount == 0;
    final isTotalZero = status.total == 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        maintainState: true,
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
        title: InkWell(
          onTap: () {
            ref
                .read(transactionFilterNotifierProvider.notifier)
                .setCategory(status.category.id, status.category.name);
            ref.read(selectedIndexProvider.notifier).state = 2;
          },
          child: Text(
            status.category.name.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.anthracite,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.copper,
              decorationStyle: TextDecorationStyle.dotted,
            ),
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
                          ? (isDisplayedZero ? 0 : 1)
                          : percentage.clamp(0.0, 1.0),
                      backgroundColor: AppTheme.anthracite.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isSavings)
                      Text(
                        'Aportat net',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text:
                              '${displayedAmount == null ? '…' : _formatBudgetAmount(displayedAmount)}€ / ${_formatBudgetAmount(status.total)}€',
                          children: [
                            if (displayedAmount != null && status.total > 0)
                              TextSpan(
                                text:
                                    ' · ${(percentage * 100).toStringAsFixed(0)}%',
                                style: TextStyle(color: percentageColor),
                              ),
                          ],
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: !isSavings && status.isOverBudget
                              ? Colors.red
                              : AppTheme.anthracite,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!isSavings && status.isOverBudget && status.total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${(status.spent - status.total).toStringAsFixed(2).replaceAll('.', ',')}€ sobrepassat',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                key: ValueKey(subStatus.subcategory.id),
                subStatus: subStatus,
                category: status.category,
                type: type, // Pass type
                isReadOnly: isReadOnly,
                cycleId: ref.watch(activeCycleProvider).id,
                isSavingsCategory: isSavings,
                ledgerSummary: ledgerSummary,
                groupingCache: movementGroupingCache,
              );
            }),

          if (status.spent > 0 || status.total > 0) const Divider(height: 24),

          if (status.spent > 0 || status.total > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: _CategoryTrendsCharts(
                categoryId: status.category.id,
                totalBudget: status.total,
                isIncome: type == TransactionType.income,
              ),
            ),
        ],
      ),
    );
  }
}

class _SubcategoryRow extends ConsumerStatefulWidget {
  final SubcategoryBudgetStatus subStatus;
  final Category category;
  final TransactionType type;
  final bool isReadOnly;
  final String cycleId;
  final bool isSavingsCategory;
  final LedgerSummary? ledgerSummary;
  final Map<String, _CachedMovementGrouping> groupingCache;

  const _SubcategoryRow({
    super.key,
    required this.subStatus,
    required this.category,
    required this.type,
    required this.isReadOnly,
    required this.cycleId,
    required this.isSavingsCategory,
    required this.ledgerSummary,
    required this.groupingCache,
  });

  @override
  ConsumerState<_SubcategoryRow> createState() => _SubcategoryRowState();
}

class _SubcategoryRowState extends ConsumerState<_SubcategoryRow> {
  bool _expanded = false;
  bool _loading = false;
  String? _error;
  int _requestId = 0;
  SubcategoryMovementGrouping? _grouping;

  @override
  void didUpdateWidget(covariant _SubcategoryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cycleId != widget.cycleId) {
      _grouping = null;
      if (_expanded && !widget.isSavingsCategory) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadGroups());
      }
    } else if (oldWidget.subStatus.spent != widget.subStatus.spent &&
        _expanded) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadGroups(force: true),
      );
    }
  }

  Color _getProgressColor(double percentage) {
    if (widget.category.color != null) {
      return Color(widget.category.color!);
    }
    if (widget.type == TransactionType.expense) {
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

  Color _getSavingsProgressColor(double percentage) {
    if (widget.category.color != null) {
      return Color(widget.category.color!);
    }
    if (percentage >= 1.0) return Colors.green[700]!;
    if (percentage >= 0.75) return AppTheme.copper;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final savingsProgress = widget.ledgerSummary == null
        ? null
        : SavingsBudgetProgress.forSubcategory(
            widget.subStatus.subcategory,
            widget.ledgerSummary!,
          );
    final displayedAmount = widget.isSavingsCategory
        ? savingsProgress?.net
        : widget.subStatus.spent;
    final percentage = displayedAmount == null
        ? 0.0
        : widget.subStatus.budget > 0
            ? displayedAmount / widget.subStatus.budget
            : displayedAmount > 0
                ? 1.0
                : 0.0;
    final progressColor = widget.isSavingsCategory
        ? _getSavingsProgressColor(percentage)
        : _getProgressColor(widget.subStatus.percentage);
    final percentageColor =
        widget.isSavingsCategory || widget.type == TransactionType.income
            ? budgetAchievementColor(percentage)
            : budgetConsumptionColor(percentage);
    final isBudgetZero = widget.subStatus.budget == 0;
    final isDisplayedZero = displayedAmount == null || displayedAmount == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _expanded
              ? AppTheme.copper.withValues(alpha: 0.045)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: _openSubcategoryMovements,
                        child: Text(
                          widget.subStatus.subcategory.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.anthracite,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.copper,
                            decorationStyle: TextDecorationStyle.dotted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: isBudgetZero
                              ? (isDisplayedZero ? 0 : 1)
                              : percentage.clamp(0.0, 1.0),
                          backgroundColor:
                              AppTheme.anthracite.withValues(alpha: 0.1),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(progressColor),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: widget.isSavingsCategory ? 118 : 110,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (widget.isSavingsCategory)
                            Text(
                              'Aportat net',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[500],
                              ),
                            ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                              TextSpan(
                                text:
                                    '${displayedAmount == null ? '…' : _formatBudgetAmount(displayedAmount)}€/${_formatBudgetAmount(widget.subStatus.budget)}€',
                                children: [
                                  if (displayedAmount != null &&
                                      widget.subStatus.budget > 0)
                                    TextSpan(
                                      text:
                                          ' · ${(percentage * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(color: percentageColor),
                                    ),
                                ],
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isReadOnly)
                      SizedBox(
                        width: 32,
                        child: IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showQuickBudgetDialog(context),
                        ),
                      )
                    else
                      const SizedBox(width: 32),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_expanded
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(10, 2, 4, 8),
                      child: _buildGroupingContent(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupingContent() {
    if (widget.isSavingsCategory) {
      return _buildSavingsContent();
    }

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Agrupant moviments…',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _error!,
          style: TextStyle(fontSize: 12, color: Colors.red[700]),
        ),
      );
    }

    final grouping = _grouping;
    if (grouping == null || grouping.groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Cap moviment comptabilitzat en aquest cicle.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      );
    }

    return _MovementGroupList(
      groups: grouping.groups,
      categoryColor: widget.category.color == null
          ? AppTheme.copper
          : Color(widget.category.color!),
    );
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded && !widget.isSavingsCategory) _loadGroups();
  }

  Widget _buildSavingsContent() {
    final ledger = widget.ledgerSummary;
    if (ledger == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Calculant l’estalvi del cicle…',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    final progress = SavingsBudgetProgress.forSubcategory(
      widget.subStatus.subcategory,
      ledger,
    );
    final String message;
    if (progress.saved == 0 && progress.withdrawn == 0) {
      message = 'Cap aportació ni rescat en aquest cicle · els moviments de '
          'guardiola no compten al pressupost.';
    } else if (progress.withdrawn == 0) {
      message = '${_formatBudgetAmount(progress.saved)} € aportats · els '
          'moviments de guardiola no compten al pressupost.';
    } else {
      message = 'Net ${_formatBudgetAmount(progress.net)} € · '
          '${_formatBudgetAmount(progress.saved)} € aportats − '
          '${_formatBudgetAmount(progress.withdrawn)} € rescatats · els '
          'moviments de guardiola no compten al pressupost.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.savings_outlined,
            size: 16,
            color: Colors.green[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _openSubcategoryMovements() {
    ref.read(transactionFilterNotifierProvider.notifier).setSubCategory(
          widget.category.id,
          widget.category.name,
          widget.subStatus.subcategory.id,
          widget.subStatus.subcategory.name,
        );
    ref.read(selectedIndexProvider.notifier).state = 2;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadGroups({bool force = false}) async {
    if (widget.isSavingsCategory) return;
    final transactions = ref.read(transactionNotifierProvider).valueOrNull;
    final categories = ref.read(categoryNotifierProvider).valueOrNull;
    final cycle = ref.read(activeCycleProvider);
    if (transactions == null || categories == null) {
      setState(() {
        _loading = false;
        _error = 'Els moviments encara no estan disponibles.';
      });
      return;
    }

    final cycleTransactions = transactionsInBillingCycle(transactions, cycle);
    final relevantTransactions = cycleTransactions
        .where(
          (transaction) =>
              transaction.categoryId == widget.category.id &&
              transaction.subCategoryId == widget.subStatus.subcategory.id,
        )
        .toList();
    final fingerprint = Object.hashAll(
      relevantTransactions.map(
        (transaction) => Object.hash(
          transaction.id,
          transaction.date,
          transaction.amount,
          transaction.concept,
          transaction.isIncome,
          transaction.savingsGoalId,
          transaction.categoryId,
          transaction.subCategoryId,
        ),
      ),
    );

    final cacheKey =
        '${cycle.id}\u0000${widget.category.id}\u0000${widget.subStatus.subcategory.id}';
    final cached = widget.groupingCache[cacheKey];
    if (!force && cached?.fingerprint == fingerprint) {
      if (_grouping != cached!.grouping) {
        setState(() {
          _grouping = cached.grouping;
          _error = null;
          _loading = false;
        });
      }
      return;
    }

    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    // Deixa pintar l'estat de càrrega abans del càlcul síncron en memòria.
    await Future<void>.delayed(Duration.zero);

    try {
      final grouping = groupSubcategoryMovements(
        cycleTransactions: cycleTransactions,
        categories: categories,
        category: widget.category,
        subcategoryId: widget.subStatus.subcategory.id,
        expectedTotal: widget.subStatus.spent,
      );
      if (!grouping.matchesExpectedTotal) {
        throw StateError(
          'Els grups (${grouping.total}) no quadren amb el ledger '
          '(${grouping.expectedTotal}).',
        );
      }
      if (!mounted || requestId != _requestId) return;
      widget.groupingCache[cacheKey] = _CachedMovementGrouping(
        fingerprint: fingerprint,
        grouping: grouping,
      );
      setState(() {
        _grouping = grouping;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _error = 'No s’ha pogut quadrar l’agrupació amb el total del ledger.';
      });
    }
  }

  Future<void> _showQuickBudgetDialog(BuildContext context) async {
    final budgetController = TextEditingController(
      text: widget.subStatus.budget.toStringAsFixed(2).replaceAll('.', ','),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Pressupost', style: TextStyle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subStatus.subcategory.name,
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
              final newBudget =
                  double.tryParse(budgetController.text.replaceAll(',', '.')) ??
                      0.0;
              final selectedDate = ref.read(selectedDateProvider);
              final groupId = ref.read(currentGroupIdProvider).valueOrNull;

              if (groupId == null) {
                if (context.mounted) Navigator.pop(context);
                return;
              }

              final repo = ref.read(budgetEntryRepositoryProvider);
              final entryId =
                  '${widget.subStatus.subcategory.id}_${selectedDate.year}_${selectedDate.month}';

              // If new budget matches the base budget, remove the exception
              if (newBudget == widget.subStatus.subcategory.monthlyBudget) {
                await repo.deleteEntry(groupId, entryId);
              } else {
                // Otherwise set/update the exception
                final entry = BudgetEntry(
                  id: entryId,
                  subCategoryId: widget.subStatus.subcategory.id,
                  year: selectedDate.year,
                  month: selectedDate.month,
                  amount: newBudget,
                );
                await repo.setEntry(groupId, entry);
              }

              ref.invalidate(budgetNotifierProvider);
              ref.invalidate(dashboardBudgetNotifierProvider);

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

class _CachedMovementGrouping {
  final int fingerprint;
  final SubcategoryMovementGrouping grouping;

  const _CachedMovementGrouping({
    required this.fingerprint,
    required this.grouping,
  });
}

class _MovementGroupList extends StatefulWidget {
  final List<MovementConceptGroup> groups;
  final Color categoryColor;

  const _MovementGroupList({
    required this.groups,
    required this.categoryColor,
  });

  @override
  State<_MovementGroupList> createState() => _MovementGroupListState();
}

class _MovementGroupListState extends State<_MovementGroupList> {
  final Set<String> _expandedKeys = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final group in widget.groups) _buildGroup(group, prefix: 'top'),
      ],
    );
  }

  Widget _buildGroup(
    MovementConceptGroup group, {
    required String prefix,
    bool nested = false,
  }) {
    final key = '$prefix:${group.name}';
    final expanded = _expandedKeys.contains(key);

    return Column(
      children: [
        _MovementGroupRow(
          group: group,
          expanded: expanded,
          nested: nested,
          categoryColor: widget.categoryColor,
          onTap: () {
            setState(() {
              if (expanded) {
                _expandedKeys.remove(key);
              } else {
                _expandedKeys.add(key);
              }
            });
          },
        ),
        if (expanded)
          Padding(
            padding: EdgeInsets.only(left: nested ? 12 : 16, bottom: 4),
            child: group.isOther
                ? Column(
                    children: [
                      for (final child in group.children)
                        _buildGroup(
                          child,
                          prefix: key,
                          nested: true,
                        ),
                    ],
                  )
                : _MovementRows(movements: group.movements),
          ),
      ],
    );
  }
}

class _MovementGroupRow extends StatelessWidget {
  final MovementConceptGroup group;
  final bool expanded;
  final bool nested;
  final Color categoryColor;
  final VoidCallback onTap;

  const _MovementGroupRow({
    required this.group,
    required this.expanded,
    required this.nested,
    required this.categoryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final progress = (group.percentage / 100).clamp(0.0, 1.0);
    final color = group.amount < 0 ? Colors.teal[700]! : categoryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final movementLabel = wide
            ? ' (${group.movementCount} moviments)'
            : ' (${group.movementCount})';

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Padding(
            padding: EdgeInsets.fromLTRB(nested ? 6 : 0, 5, 0, 5),
            child: Row(
              children: [
                Expanded(
                  flex: wide ? 4 : 3,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: nested ? 11 : 12,
                            fontWeight: group.isOther
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppTheme.anthracite,
                          ),
                        ),
                      ),
                      Text(
                        movementLabel,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: nested ? 10 : 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor:
                          AppTheme.anthracite.withValues(alpha: 0.09),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${group.displayPercentage}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      color: group.amount < 0 ? color : Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: wide ? 86 : 72,
                  child: Text(
                    currency.format(group.amount),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MovementRows extends StatelessWidget {
  final List<GroupedMovement> movements;

  const _MovementRows({required this.movements});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final date = DateFormat('dd/MM');

    return Column(
      children: [
        for (final movement in movements)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Text(
                    date.format(movement.transaction.date),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    movement.transaction.concept,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currency.format(movement.ledgerDelta),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: movement.ledgerDelta < 0
                        ? Colors.teal[700]
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CategoryTrendsCharts extends ConsumerWidget {
  final String categoryId;
  final double totalBudget;
  final bool isIncome;

  const _CategoryTrendsCharts({
    required this.categoryId,
    required this.totalBudget,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCycle = ref.watch(activeCycleProvider);
    final transactionsAsync = ref.watch(transactionNotifierProvider);

    return transactionsAsync.when(
      data: (transactions) {
        // Prepare data for the charts
        final now = DateTime.now();
        final cycleStart = activeCycle.startDate;
        final cycleEnd = activeCycle.endDate;
        final totalDays = cycleEnd.difference(cycleStart).inDays + 1;

        // --- 1. Burn Rate (LineChart) Data ---
        // Accumulate spent amount per day for current cycle
        final dailySpent = <int, double>{};
        var cumulativeSpent = 0.0;

        // Filter current cycle transactions for this category
        final currentCycleTx = transactions
            .where((t) =>
                t.categoryId == categoryId &&
                t.date.isAfter(cycleStart.subtract(const Duration(days: 1))) &&
                t.date.isBefore(cycleEnd.add(const Duration(days: 1))) &&
                t.isIncome == isIncome)
            .toList();

        // Sort by date from older to newer
        currentCycleTx.sort((a, b) => a.date.compareTo(b.date));

        for (int i = 0; i < totalDays; i++) {
          final currentDate = cycleStart.add(Duration(days: i));
          // If the day hasn't happened yet, we stop the actual line
          if (currentDate.isAfter(now)) {
            break;
          }

          final spentThatDay = currentCycleTx
              .where((t) =>
                  t.date.year == currentDate.year &&
                  t.date.month == currentDate.month &&
                  t.date.day == currentDate.day)
              .fold(0.0, (sum, t) => sum + t.amount);

          cumulativeSpent += spentThatDay;
          dailySpent[i] = cumulativeSpent;
        }

        // --- 2. Month-over-Month (BarChart) Data ---
        // Calculate previous cycle dates (rough approx: minus 1 month)
        final prevCycleStart =
            DateTime(cycleStart.year, cycleStart.month - 1, cycleStart.day);
        final prevCycleEnd = cycleStart.subtract(const Duration(days: 1));

        final prevCycleTx = transactions
            .where((t) =>
                t.categoryId == categoryId &&
                t.date.isAfter(
                    prevCycleStart.subtract(const Duration(days: 1))) &&
                t.date.isBefore(prevCycleEnd.add(const Duration(days: 1))) &&
                t.isIncome == isIncome)
            .toList();

        // Cumulative spent for previous cycle (full month, for overlay on burn rate)
        prevCycleTx.sort((a, b) => a.date.compareTo(b.date));
        final prevTotalDays =
            prevCycleEnd.difference(prevCycleStart).inDays + 1;
        final prevDailySpent = <int, double>{};
        var prevCumulativeSpent = 0.0;
        for (int i = 0; i < prevTotalDays && i < totalDays; i++) {
          final prevDate = prevCycleStart.add(Duration(days: i));
          final spentThatDay = prevCycleTx
              .where((t) =>
                  t.date.year == prevDate.year &&
                  t.date.month == prevDate.month &&
                  t.date.day == prevDate.day)
              .fold(0.0, (sum, t) => sum + t.amount);
          prevCumulativeSpent += spentThatDay;
          prevDailySpent[i] = prevCumulativeSpent;
        }

        final totalCurrentStr =
            currentCycleTx.fold(0.0, (sum, t) => sum + t.amount);
        final totalPrevStr = prevCycleTx.fold(0.0, (sum, t) => sum + t.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Burn Rate title
            Text(
              'Ritme de Despesa vs Pressupost',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            // Burn Rate Chart
            SizedBox(
              height: 140,
              child: _buildBurnRateChart(
                  dailySpent, prevDailySpent, totalDays, totalBudget, isIncome),
            ),

            const SizedBox(height: 24),

            // MoM title
            Text(
              'Comparativa (Aquest mes vs Anterior)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            // MoM Chart
            SizedBox(
              height: 120,
              child: _buildMoMChart(totalCurrentStr, totalPrevStr, isIncome),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildBurnRateChart(
      Map<int, double> dailySpent,
      Map<int, double> prevDailySpent,
      int totalDays,
      double totalBudget,
      bool isIncome) {
    if (totalBudget == 0 && dailySpent.isEmpty && prevDailySpent.isEmpty) {
      return const SizedBox();
    }

    final maxY = [
      totalBudget,
      if (dailySpent.isNotEmpty)
        dailySpent.values.reduce((a, b) => a > b ? a : b),
      if (prevDailySpent.isNotEmpty)
        prevDailySpent.values.reduce((a, b) => a > b ? a : b),
    ].reduce((a, b) => a > b ? a : b);

    final finalMaxY = (maxY * 1.2).ceilToDouble(); // Add some padding

    // Determine bar indices for tooltip labeling
    // Order: [0] ideal (if budget>0), [1] prev month (if data), [2] actual (if data)
    int nextBarIndex = 0;
    final int idealBarIndex = totalBudget > 0 ? nextBarIndex++ : -1;
    final int prevBarIndex = prevDailySpent.isNotEmpty ? nextBarIndex++ : -1;
    // ignore: unused_local_variable
    final int actualBarIndex = dailySpent.isNotEmpty ? nextBarIndex++ : -1;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: finalMaxY == 0 ? 10 : finalMaxY,
        minX: 0,
        maxX: (totalDays - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: finalMaxY > 0 ? finalMaxY / 4 : 2.5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey[200]!,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final day = value.toInt() + 1;
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '$day',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == finalMaxY) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${value.toInt()}€',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Ideal Budget Line (Linear)
          if (totalBudget > 0)
            LineChartBarData(
              spots: [
                const FlSpot(0, 0),
                FlSpot((totalDays - 1).toDouble(), totalBudget),
              ],
              isCurved: false,
              color: Colors.grey[400],
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              dashArray: [5, 5],
            ),

          // Previous Month Line (grey, dashed)
          if (prevDailySpent.isNotEmpty)
            LineChartBarData(
              spots: prevDailySpent.entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: Colors.grey[350],
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              dashArray: [6, 4],
            ),

          // Actual Spent Line
          if (dailySpent.isNotEmpty)
            LineChartBarData(
              spots: dailySpent.entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: isIncome ? Colors.green : AppTheme.copper,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: (isIncome ? Colors.green : AppTheme.copper)
                    .withValues(alpha: 0.1),
              ),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                String label = '';
                if (spot.barIndex == idealBarIndex) {
                  label = 'Ideal: ';
                } else if (spot.barIndex == prevBarIndex) {
                  label = 'Ant.: ';
                }
                return LineTooltipItem(
                  '$label${spot.y.toStringAsFixed(0)}€',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMoMChart(double currentMonth, double prevMonth, bool isIncome) {
    if (currentMonth == 0 && prevMonth == 0) return const SizedBox();

    final maxVal = [currentMonth, prevMonth].reduce((a, b) => a > b ? a : b);
    final isHigher = currentMonth > prevMonth;

    // Determine color based on type
    final currentColor = isIncome
        ? Colors.green[600]!
        : (isHigher ? Colors.red[400]! : Colors.green[400]!);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: (maxVal * 1.2).ceilToDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(0)}€',
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final style = TextStyle(
                  color: Colors.grey[700],
                  fontWeight: value == 1 ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                );
                return SideTitleWidget(
                  meta: meta,
                  child: Text(value == 0 ? 'Mes Ant.' : 'Actual', style: style),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          // Previous Month
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: prevMonth,
                color: Colors.grey[400],
                width: 28,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
          // Current Month
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: currentMonth,
                color: currentColor,
                width: 28,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CycleSpendingMarginCard extends ConsumerStatefulWidget {
  const _CycleSpendingMarginCard({super.key});

  @override
  ConsumerState<_CycleSpendingMarginCard> createState() =>
      _CycleSpendingMarginCardState();
}

class _CycleSpendingMarginCardState
    extends ConsumerState<_CycleSpendingMarginCard> {
  static const _expandedPreferenceKey = 'cycle_spending_margin_expanded';

  SharedPreferencesAsync? _preferences;
  bool _expanded = false;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _restoreExpandedState();
  }

  Future<void> _restoreExpandedState() async {
    try {
      final preferences = _preferences ??= SharedPreferencesAsync();
      final expanded = await preferences.getBool(_expandedPreferenceKey);
      if (!mounted || _hasInteracted || expanded == null) return;
      setState(() => _expanded = expanded);
    } catch (_) {
      // És una preferència d'UX no crítica: el fallback segur és col·lapsat.
    }
  }

  Future<void> _toggleExpanded() async {
    await _setExpanded(!_expanded);
  }

  Future<void> collapse() async {
    await _setExpanded(false);
  }

  Future<void> _setExpanded(bool expanded) async {
    _hasInteracted = true;
    if (_expanded != expanded) {
      setState(() => _expanded = expanded);
    }
    try {
      final preferences = _preferences ??= SharedPreferencesAsync();
      await preferences.setBool(_expandedPreferenceKey, expanded);
    } catch (_) {
      // La barra continua funcionant durant la sessió encara que falli el disc.
    }
  }

  @override
  Widget build(BuildContext context) {
    final projection = ref.watch(cycleSpendingMarginProvider);
    if (projection == null) return const SizedBox.shrink();

    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€');

    if (!projection.isCurrentCycle) {
      return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: _marginDecoration(),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 19,
                color: AppTheme.anthracite,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'El marge de caixa només es pot calcular per al cicle actual: '
                  'els saldos dels comptes són l’estat d’ara.',
                  style: TextStyle(
                    color: AppTheme.anthracite,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isNegative = projection.margin < 0;
    final marginColor =
        isNegative ? Colors.red.shade700 : Colors.green.shade700;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: _marginDecoration(
          borderColor: isNegative
              ? Colors.red.withValues(alpha: 0.42)
              : AppTheme.copper.withValues(alpha: 0.28),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: _toggleExpanded,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'MARGE FINS A FI DE CICLE',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.anthracite,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.55,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currency.format(projection.margin),
                            style: TextStyle(
                              color: marginColor,
                              fontSize: 19,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (!projection.hasOpeningBalance) ...[
                            const SizedBox(width: 5),
                            Tooltip(
                              message: 'Falta el saldo inicial del cicle',
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 17,
                                color: AppTheme.copper.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                          const SizedBox(width: 3),
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 23,
                              color: AppTheme.anthracite,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        remainingDaysSummary(
                          projection.daysRemaining,
                          projection.perDay,
                          currency,
                        ),
                        style: TextStyle(
                          color: marginColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: !_expanded
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            _MarginLine(
                              label: 'Disponible ara',
                              value: currency.format(projection.availableNow),
                            ),
                            if (projection.pendingIncome > 0) ...[
                              _MarginLine(
                                label: '+  Ingressos pendents',
                                value:
                                    currency.format(projection.pendingIncome),
                                color: Colors.green.shade700,
                              ),
                              _PendingItemsBreakdown(
                                items: projection.pendingIncomeItems,
                                currency: currency,
                              ),
                            ],
                            if (projection.pendingFixedExpenses > 0) ...[
                              _MarginLine(
                                label: '−  Despeses fixes pendents',
                                value: currency
                                    .format(projection.pendingFixedExpenses),
                                color: Colors.red.shade700,
                              ),
                              _PendingFixedItemsBreakdown(
                                items: projection.pendingFixedExpenseItems,
                                currency: currency,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              'Desviació del pressupost: '
                              '${_signedCurrency(currency, projection.budgetDeviation)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                            if (!projection.hasOpeningBalance) ...[
                              const SizedBox(height: 9),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.copper.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Mode degradat: falta el saldo inicial. El '
                                  'marge usa el pot registrat d’ara, però no es '
                                  'pot validar la cadena de caixa.',
                                  style: TextStyle(
                                    color: AppTheme.anthracite,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String remainingDaysSummary(
  int daysRemaining,
  double? perDay,
  NumberFormat currency,
) {
  if (daysRemaining <= 0) return 'Últim dia del cicle';
  final dayLabel = daysRemaining == 1 ? 'dia restant' : 'dies restants';
  return '$daysRemaining $dayLabel · ${currency.format(perDay)}/dia';
}

class _MarginLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MarginLine({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppTheme.anthracite,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingItemsBreakdown extends StatelessWidget {
  static const _maxVisibleItems = 3;

  final List<CyclePendingItem> items;
  final NumberFormat currency;

  const _PendingItemsBreakdown({
    required this.items,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(_maxVisibleItems).toList();
    final hiddenCount = items.length - visibleItems.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 1, 0, 5),
      child: Column(
        children: [
          for (final item in visibleItems)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    currency.format(item.amount),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (hiddenCount > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+$hiddenCount més',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingFixedItemsBreakdown extends StatelessWidget {
  final List<CyclePendingItem> items;
  final NumberFormat currency;

  const _PendingFixedItemsBreakdown({
    required this.items,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = items.where((item) => item.isOverdue).toList();
    final upcoming = items.where((item) => !item.isOverdue).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 0, 5),
      child: Column(
        children: [
          if (overdue.isNotEmpty)
            _buildGroup(
              label: 'Vençudes',
              items: overdue,
              color: Colors.red.shade700,
            ),
          if (upcoming.isNotEmpty)
            _buildGroup(
              label: 'Per venir',
              items: upcoming,
              color: AppTheme.anthracite,
            ),
        ],
      ),
    );
  }

  Widget _buildGroup({
    required String label,
    required List<CyclePendingItem> items,
    required Color color,
  }) {
    final total = items.fold(0.0, (sum, item) => sum + item.amount);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$label (${items.length})',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                currency.format(total),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          _PendingItemsBreakdown(items: items, currency: currency),
        ],
      ),
    );
  }
}

BoxDecoration _marginDecoration({Color? borderColor}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: borderColor ?? Colors.grey.withValues(alpha: 0.25),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 10,
        offset: const Offset(0, -3),
      ),
    ],
  );
}

String _signedCurrency(NumberFormat currency, double value) {
  if (value > 0) return '+ ${currency.format(value)}';
  if (value < 0) return '− ${currency.format(value.abs())}';
  return currency.format(0);
}

String _formatBudgetAmount(double value) =>
    value.toStringAsFixed(2).replaceAll('.', ',');
