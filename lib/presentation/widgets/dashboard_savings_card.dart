import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:centim/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../providers/financial_summary_provider.dart';

class DashboardSavingsCard extends ConsumerWidget {
  const DashboardSavingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(financialSummaryNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');

    return summaryAsync.when(
      data: (summary) {
        if (summary.savedThisCycle == 0 && summary.withdrawnThisCycle == 0) {
          return const SizedBox.shrink();
        }

        final net = summary.savedThisCycle - summary.withdrawnThisCycle;
        final netColor = net >= 0 ? Colors.green.shade700 : Colors.red.shade700;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.savings_outlined,
                        color: AppTheme.copper, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.savingsTotal,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.anthracite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn(
                      context,
                      l10n.savingsAportat,
                      summary.savedThisCycle,
                      Icons.arrow_downward,
                      Colors.green.shade600,
                      currencyFormat,
                    ),
                    _buildInfoColumn(
                      context,
                      l10n.savingsRescatat,
                      summary.withdrawnThisCycle,
                      Icons.arrow_upward,
                      Colors.orange.shade700,
                      currencyFormat,
                    ),
                    _buildInfoColumn(
                      context,
                      l10n.savingsNet,
                      net,
                      Icons.balance,
                      netColor,
                      currencyFormat,
                      isBold: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildInfoColumn(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color,
    NumberFormat format, {
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          format.format(amount),
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
