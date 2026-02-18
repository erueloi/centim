import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/debt_account.dart';
import '../../../../domain/models/asset.dart';
import '../../providers/debt_provider.dart';
import '../../providers/asset_provider.dart';

import 'package:intl/intl.dart';
import '../../sheets/wealth_sheet.dart';
import '../../providers/savings_goal_provider.dart';
import '../../widgets/savings/savings_goal_card.dart';
import '../../sheets/add_savings_goal_sheet.dart';

enum PatrimoniView { assets, debts, goals }

final patrimoniViewProvider = StateProvider<PatrimoniView>(
  (ref) => PatrimoniView.assets,
);

class PatrimoniScreen extends ConsumerWidget {
  const PatrimoniScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(patrimoniViewProvider);
    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');

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
                  icon: Icon(Icons.account_balance),
                ),
                ButtonSegment(
                  value: PatrimoniView.debts,
                  label: Text('DEUTES'),
                  icon: Icon(Icons.credit_card),
                ),
                ButtonSegment(
                  value: PatrimoniView.goals,
                  label: Text('OBJECTIUS'),
                  icon: Icon(Icons.savings),
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
      body: switch (view) {
        PatrimoniView.assets => _AssetsView(currencyFormat: currencyFormat),
        PatrimoniView.debts => _DebtsView(currencyFormat: currencyFormat),
        PatrimoniView.goals => const _SavingsGoalsView(),
      },
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
                      subtitle: asset.bankName != null
                          ? Text(asset.bankName!)
                          : null,
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

class _DebtsView extends ConsumerWidget {
  final NumberFormat currencyFormat;

  const _DebtsView({required this.currencyFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtNotifierProvider);

    return debtsAsync.when(
      data: (debts) {
        if (debts.isEmpty) {
          return const Center(child: Text('No hi ha deutes registrats.'));
        }

        // Sort by Avalanche (Highest Interest Rate First)
        final sortedDebts = List<DebtAccount>.from(debts)
          ..sort((a, b) => b.interestRate.compareTo(a.interestRate));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDebts.length,
          itemBuilder: (context, index) {
            final debt = sortedDebts[index];
            final isHighInterest = debt.interestRate > 10;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  padding: const EdgeInsets.only(top: 4),
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
                                    : Colors
                                          .green[700], // Green for low interest
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    showDragHandle: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) =>
                                        WealthSheet(initialDebt: debt),
                                  );
                                } else if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Eliminar Deute?'),
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
                                        .read(debtNotifierProvider.notifier)
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
                                    style: TextStyle(color: Colors.red),
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
                          value:
                              ((debt.originalAmount - debt.currentBalance) /
                                      debt.originalAmount)
                                  .clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[200],
                          color: isHighInterest
                              ? AppTheme.copper
                              : Colors
                                    .green[600], // Color logic: fast pay vs relaxed
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pendent',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              currencyFormat.format(debt.currentBalance),
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
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Inicial',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                currencyFormat.format(debt.originalAmount),
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
                  ],
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
} // End of PatrimoniScreen

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
