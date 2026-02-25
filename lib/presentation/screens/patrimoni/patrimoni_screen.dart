import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/asset.dart';
import '../../providers/debt_provider.dart';
import '../../providers/asset_provider.dart';

import 'package:intl/intl.dart';
import '../../sheets/wealth_sheet.dart';
import '../../providers/savings_goal_provider.dart';
import '../../widgets/savings/savings_goal_card.dart';
import '../../sheets/add_savings_goal_sheet.dart';
import '../../providers/financial_summary_provider.dart';
import '../../../../domain/models/financial_summary.dart';
import 'package:fl_chart/fl_chart.dart';
import '../debt/widgets/amortization_dialog.dart';

enum PatrimoniView { assets, debts, goals }

final patrimoniViewProvider = StateProvider<PatrimoniView>(
  (ref) => PatrimoniView.assets,
);

class PatrimoniScreen extends ConsumerStatefulWidget {
  const PatrimoniScreen({super.key});

  @override
  ConsumerState<PatrimoniScreen> createState() => _PatrimoniScreenState();
}

class _PatrimoniScreenState extends ConsumerState<PatrimoniScreen> {
  bool _isChartExpanded = false;

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(patrimoniViewProvider);
    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final summaryAsync = ref.watch(financialSummaryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrimoni'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SegmentedButton<PatrimoniView>(
              segments: const [
                ButtonSegment(
                  value: PatrimoniView.assets,
                  label: Text('ACTIUS'),
                ),
                ButtonSegment(
                  value: PatrimoniView.debts,
                  label: Text('DEUTES'),
                ),
                ButtonSegment(
                  value: PatrimoniView.goals,
                  label: Text('OBJECTIUS'),
                ),
              ],
              selected: {view},
              onSelectionChanged: (Set<PatrimoniView> newSelection) {
                ref.read(patrimoniViewProvider.notifier).state =
                    newSelection.first;
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.copper.withValues(alpha: 0.2);
                  }
                  return Colors.transparent;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.anthracite;
                  }
                  return Colors.grey;
                }),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Net Worth Header col·lapsable
          summaryAsync.when(
            data: (summary) => GestureDetector(
              onTap: () => setState(() => _isChartExpanded = !_isChartExpanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: EdgeInsets.all(_isChartExpanded ? 16 : 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    // Fila compacta (sempre visible)
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: AppTheme.copper,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Patrimoni Net',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          currencyFormat.format(summary.totalNetWorth),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.anthracite,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _isChartExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.expand_more,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    // Gràfic expandible
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _NetWorthHeader(
                          summary: summary,
                          currencyFormat: currencyFormat,
                        ),
                      ),
                      crossFadeState: _isChartExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('Error carregant patrimoni: $e')),
            ),
          ),
          // Contingut de la pestanya seleccionada
          Expanded(
            child: switch (view) {
              PatrimoniView.assets =>
                _AssetsView(currencyFormat: currencyFormat),
              PatrimoniView.debts => _DebtsView(currencyFormat: currencyFormat),
              PatrimoniView.goals => const _SavingsGoalsView(),
            },
          ),
        ],
      ),
    );
  }
}

class _AssetsView extends ConsumerWidget {
  final NumberFormat currencyFormat;

  const _AssetsView({required this.currencyFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetNotifierProvider);

    return assetsAsync.when(
      data: (assets) {
        if (assets.isEmpty) {
          return const Center(child: Text('No hi ha actius registrats.'));
        }

        final totalValue = assets.fold(0.0, (sum, a) => sum + a.amount);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Actius',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      currencyFormat.format(totalValue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  IconData icon;
                  switch (asset.type) {
                    case AssetType.realEstate:
                      icon = Icons.home;
                      break;
                    case AssetType.bankAccount:
                      icon = Icons.account_balance;
                      break;
                    case AssetType.cash:
                      icon = Icons.wallet;
                      break;
                    case AssetType.other:
                      icon = Icons.savings;
                      break;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                        child: Icon(icon, color: Colors.green[800]),
                      ),
                      title: Text(
                        asset.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle:
                          asset.bankName != null ? Text(asset.bankName!) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currencyFormat.format(asset.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  showDragHandle: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) =>
                                      WealthSheet(initialAsset: asset),
                                );
                              } else if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar Actiu?'),
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
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref
                                      .read(assetNotifierProvider.notifier)
                                      .removeAsset(asset.id);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
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
    );
  }
}

enum DebtSortOption {
  interestDesc,
  interestAsc,
  balanceDesc,
  balanceAsc,
  dateAsc,
  dateDesc,
}

class _DebtsView extends ConsumerStatefulWidget {
  final NumberFormat currencyFormat;

  const _DebtsView({required this.currencyFormat});

  @override
  ConsumerState<_DebtsView> createState() => _DebtsViewState();
}

class _DebtsViewState extends ConsumerState<_DebtsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DebtSortOption _sortOption =
      DebtSortOption.interestDesc; // Avalanche by default

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(debtNotifierProvider);

    return debtsAsync.when(
      data: (debts) {
        if (debts.isEmpty) {
          return const Center(child: Text('No hi ha deutes registrats.'));
        }

        final filteredDebts = debts.where((d) {
          final query = _searchQuery.toLowerCase();
          final nameMatches = d.name.toLowerCase().contains(query);
          final bankMatches =
              d.bankName?.toLowerCase().contains(query) ?? false;
          return nameMatches || bankMatches;
        }).toList();

        // Sort based on selected option
        filteredDebts.sort((a, b) {
          switch (_sortOption) {
            case DebtSortOption.interestDesc:
              return b.interestRate.compareTo(a.interestRate);
            case DebtSortOption.interestAsc:
              return a.interestRate.compareTo(b.interestRate);
            case DebtSortOption.balanceDesc:
              return b.currentBalance.compareTo(a.currentBalance);
            case DebtSortOption.balanceAsc:
              return a.currentBalance.compareTo(b.currentBalance);
            case DebtSortOption.dateAsc:
              if (a.endDate == null && b.endDate == null) return 0;
              if (a.endDate == null) return 1;
              if (b.endDate == null) return -1;
              return a.endDate!.compareTo(b.endDate!);
            case DebtSortOption.dateDesc:
              if (a.endDate == null && b.endDate == null) return 0;
              if (a.endDate == null) return 1;
              if (b.endDate == null) return -1;
              return b.endDate!.compareTo(a.endDate!);
          }
        });

        final totalValue =
            filteredDebts.fold(0.0, (sum, d) => sum + d.currentBalance);

        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Buscar deutes...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<DebtSortOption>(
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Ordenar per',
                    initialValue: _sortOption,
                    onSelected: (option) {
                      setState(() {
                        _sortOption = option;
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: DebtSortOption.interestDesc,
                        child: PopupListTile(
                          icon: Icons.percent,
                          title: 'Més interès',
                          subtitle: 'Mètode Allau',
                        ),
                      ),
                      const PopupMenuItem(
                        value: DebtSortOption.interestAsc,
                        child: PopupListTile(
                          icon: Icons.percent_outlined,
                          title: 'Menys interès',
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: DebtSortOption.balanceDesc,
                        child: PopupListTile(
                          icon: Icons.arrow_downward,
                          title: 'Major deute',
                        ),
                      ),
                      const PopupMenuItem(
                        value: DebtSortOption.balanceAsc,
                        child: PopupListTile(
                          icon: Icons.arrow_upward,
                          title: 'Menor deute',
                          subtitle: 'Mètode Bola de Neu',
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: DebtSortOption.dateAsc,
                        child: PopupListTile(
                          icon: Icons.event,
                          title: 'Venciment proper',
                        ),
                      ),
                      const PopupMenuItem(
                        value: DebtSortOption.dateDesc,
                        child: PopupListTile(
                          icon: Icons.event_busy,
                          title: 'Venciment llunyà',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Deutes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.currencyFormat.format(totalValue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: filteredDebts.isEmpty
                  ? const Center(
                      child: Text('Cap deute coincideix amb la cerca.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filteredDebts.length,
                      itemBuilder: (context, index) {
                        final debt = filteredDebts[index];
                        final isHighInterest = debt.interestRate > 10;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            debt.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (debt.bankName != null &&
                                              debt.bankName!.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                debt.bankName!,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      children: [
                                        if (isHighInterest)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 4),
                                            child: Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.red,
                                              size: 16,
                                            ),
                                          ),
                                        Text(
                                          '${debt.interestRate.toStringAsFixed(2)}%',
                                          style: TextStyle(
                                            color: isHighInterest
                                                ? Colors.red
                                                : Colors.green[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert,
                                              size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                showDragHandle: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                builder: (_) => WealthSheet(
                                                    initialDebt: debt),
                                              );
                                            } else if (value == 'delete') {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Text(
                                                      'Eliminar Deute?'),
                                                  content: const Text(
                                                    'Aquesta acció no es pot desfer.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child: const Text(
                                                          'Cancel·lar'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      style:
                                                          TextButton.styleFrom(
                                                        foregroundColor:
                                                            Colors.red,
                                                      ),
                                                      child: const Text(
                                                          'Eliminar'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                await ref
                                                    .read(debtNotifierProvider
                                                        .notifier)
                                                    .deleteDebt(debt.id);
                                              }
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Editar'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text(
                                                'Eliminar',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Progress Bar
                                if (debt.originalAmount > 0) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      // (Initial - Current) / Initial
                                      value: ((debt.originalAmount -
                                                  debt.currentBalance) /
                                              debt.originalAmount)
                                          .clamp(0.0, 1.0),
                                      backgroundColor: Colors.grey[200],
                                      color: isHighInterest
                                          ? AppTheme.copper
                                          : Colors.green[600],
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pendent',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          widget.currencyFormat
                                              .format(debt.currentBalance),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.anthracite,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Divider and Initial Amount
                                    if (debt.originalAmount > 0) ...[
                                      Container(
                                        height: 30,
                                        width: 1,
                                        color: Colors.grey[300],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Inicial',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            widget.currencyFormat
                                                .format(debt.originalAmount),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else
                                      const SizedBox(), // Spacer
                                  ],
                                ),

                                const SizedBox(height: 12),
                                // Temps restant
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event_available,
                                      size: 16,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        debt.endDate != null
                                            ? 'Lliure el: ${_formatDate(debt.endDate!)} (${debt.remainingTimeText})'
                                            : debt.remainingTimeText,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                // Botó Simular Amortització
                                if (debt.monthlyInstallment > 0 &&
                                    debt.interestRate > 0) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              AmortizationDialog(
                                            debt: debt,
                                            onApply: (_) {},
                                          ),
                                        );
                                      },
                                      icon:
                                          const Icon(Icons.calculate, size: 16),
                                      label: const Text('Simular Amortització'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.copper,
                                        textStyle:
                                            const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Gen',
      'Febr',
      'Març',
      'Abr',
      'Maig',
      'Juny',
      'Jul',
      'Ago',
      'Set',
      'Oct',
      'Nov',
      'Des',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
} // End of _DebtsView

class PopupListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const PopupListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ],
    );
  }
}

class _SavingsGoalsView extends ConsumerWidget {
  const _SavingsGoalsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalNotifierProvider);

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.savings_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No tens cap objectiu d\'estalvi.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddSavingsGoalSheet(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Guardiola'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.copper,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final goal = goals[index];
            return SavingsGoalCard(goal: goal);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _NetWorthHeader extends StatelessWidget {
  final FinancialSummary summary;
  final NumberFormat currencyFormat;

  const _NetWorthHeader({required this.summary, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 180,
                width: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 70,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: AppTheme.copper,
                        value: summary.equityRatio * 100,
                        title: '',
                        radius: 12,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        color: Colors.grey[200]!,
                        value: (1 - summary.equityRatio) * 100,
                        title: '',
                        radius: 12,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'El meu Patrimoni',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(summary.totalNetWorth),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.anthracite,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _AssetLiabilityInfo(
              label: 'Actiu',
              amount: summary.totalAssets,
              color: Colors.green[600]!,
              icon: Icons.trending_up,
              currencyFormat: currencyFormat,
            ),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            _AssetLiabilityInfo(
              label: 'Passiu',
              amount: summary.totalLiabilities,
              color: Colors.red[600]!,
              icon: Icons.trending_down,
              currencyFormat: currencyFormat,
            ),
          ],
        ),
      ],
    );
  }
}

class _AssetLiabilityInfo extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final NumberFormat currencyFormat;

  const _AssetLiabilityInfo({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.anthracite,
          ),
        ),
      ],
    );
  }
}
