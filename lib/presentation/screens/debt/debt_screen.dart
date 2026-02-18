import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/debt_provider.dart';
import '../../../domain/models/debt_account.dart';
import '../../widgets/responsive_center.dart';
import '../../sheets/wealth_sheet.dart';
import 'widgets/amortization_dialog.dart';

class DebtScreen extends ConsumerWidget {
  const DebtScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Passiu')),
      body: ResponsiveCenter(
        child: debtsAsync.when(
          data: (debts) {
            final totalDebt = debts.fold(
              0.0,
              (sum, d) => sum + d.currentBalance,
            );
            final totalMonthly = debts.fold(
              0.0,
              (sum, d) => sum + d.monthlyInstallment,
            );

            return Column(
              children: [
                _DebtSummaryHeader(
                  totalDebt: totalDebt,
                  totalMonthly: totalMonthly,
                ),
                Expanded(
                  child: debts.isEmpty
                      ? const Center(
                          child: Text('No tens cap deute registrat.'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: debts.length,
                          itemBuilder: (context, index) =>
                              _DebtCard(debt: debts[index]),
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'debt_screen_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const WealthSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DebtSummaryHeader extends StatelessWidget {
  final double totalDebt;
  final double totalMonthly;

  const _DebtSummaryHeader({
    required this.totalDebt,
    required this.totalMonthly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.anthracite,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'DEUTE TOTAL',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 1.5,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${totalDebt.toStringAsFixed(0)} €',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppTheme.copper,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quota Total: ${totalMonthly.toStringAsFixed(0)} € / mes',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends ConsumerWidget {
  final DebtAccount debt;

  const _DebtCard({required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calculate progress
    final paidAmount = debt.originalAmount - debt.currentBalance;
    final progress = debt.originalAmount > 0
        ? (paidAmount / debt.originalAmount).clamp(0.0, 1.0)
        : 0.0;
    final isGoodProgress = progress > 0.5;
    final isHighInterest = debt.interestRate > 10.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: AppTheme.anthracite,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.anthracite,
                        ),
                      ),
                      if (debt.bankName != null)
                        Text(
                          debt.bankName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isHighInterest
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${debt.interestRate}% TAE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isHighInterest ? Colors.red : Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => WealthSheet(initialDebt: debt),
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
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel·lar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
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
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
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
            const SizedBox(height: 20),

            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pagat: ${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isGoodProgress
                        ? Colors.green[700]
                        : AppTheme.copper, // Orange-ish
                  ),
                ),
                Text(
                  '${debt.currentBalance.toStringAsFixed(0)} € pendents',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isGoodProgress
                      ? Colors.green[700]!
                      : AppTheme.copper, // Orange
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Footer Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (debt.endDate != null)
                  Row(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Lliure el: ${_formatDate(debt.endDate!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  )
                else
                  const SizedBox(),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AmortizationDialog(
                        debt: debt,
                        onApply: (extraAmount) {
                          // In a real app we might apply this to DB
                          // For now, it's just a simulation dialog
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.calculate, size: 16),
                  label: const Text('Simular Amortització'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.copper,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
}

// _showDebtDialog moved to dialogs/debt_dialog.dart
