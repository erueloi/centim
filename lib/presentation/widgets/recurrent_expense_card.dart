import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/category.dart';
import '../../../core/theme/app_theme.dart';

class RecurrentExpenseCard extends StatelessWidget {
  final SubCategory subCategory;
  final String categoryIcon; // Emoji or IconData string
  final bool isIncome;
  final double budget;
  final double remaining;
  final DateTime? scheduledDate;
  final bool isOverdue;
  final Future<bool?> Function(DismissDirection)? confirmDismiss;
  final VoidCallback onPay;
  final VoidCallback onTap;

  const RecurrentExpenseCard({
    super.key,
    required this.subCategory,
    required this.categoryIcon,
    required this.isIncome,
    required this.budget,
    required this.remaining,
    required this.scheduledDate,
    required this.isOverdue,
    this.confirmDismiss,
    required this.onPay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final covered = (budget - remaining).clamp(0.0, budget);
    final hasPartialPayment = covered > 0.005;
    final amountLabel = hasPartialPayment
        ? 'Falten ${currencyFormat.format(remaining)} de '
            '${currencyFormat.format(budget)}'
        : 'Pendent ${currencyFormat.format(remaining)}';
    final dateLabel = scheduledDate == null
        ? 'sense data prevista'
        : isOverdue
            ? 'vençut el ${DateFormat('dd/MM', 'ca_ES').format(scheduledDate!)}'
            : 'previst el ${DateFormat('dd/MM', 'ca_ES').format(scheduledDate!)}';

    return Dismissible(
      key: Key(subCategory.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: confirmDismiss,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.green,
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 30),
            SizedBox(width: 10),
            Text(
              'Confirmar Pagament',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        onPay();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.copper.withAlpha(30), // 0.12 * 255
              shape: BoxShape.circle,
            ),
            // Use the passed category icon (emoji)
            child: Text(categoryIcon, style: const TextStyle(fontSize: 24)),
          ),
          title: Text(
            subCategory.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '$amountLabel · $dateLabel',
            style: TextStyle(
              color: isOverdue ? Colors.red[700] : Colors.grey[600],
            ),
          ),
          trailing: Text(
            '${isIncome ? '+' : '-'}${currencyFormat.format(remaining)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}
