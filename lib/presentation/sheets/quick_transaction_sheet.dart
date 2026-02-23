import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../providers/transaction_notifier.dart';
import '../providers/group_providers.dart';
import '../providers/auth_providers.dart';

class QuickTransactionSheet extends ConsumerStatefulWidget {
  final Category category;

  const QuickTransactionSheet({super.key, required this.category});

  @override
  ConsumerState<QuickTransactionSheet> createState() =>
      _QuickTransactionSheetState();
}

class _QuickTransactionSheetState extends ConsumerState<QuickTransactionSheet> {
  final _amountController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introdueix un import vàlid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final groupId = await ref.read(currentGroupIdProvider.future);
      if (groupId == null) throw Exception("Sense grup actiu");

      final members = await ref.read(groupMembersProvider.future);
      final payer = members.isNotEmpty ? members.first.uid : 'unknown';

      // Assignem una subcategoria per defecte (la primera) per ser una entrada d'un sol tap ràpida
      final defaultSubCat = widget.category.subcategories.isNotEmpty
          ? widget.category.subcategories.first
          : const SubCategory(
              id: 'default',
              name: 'General',
              monthlyBudget: 0.0,
            );

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        isIncome: widget.category.type == TransactionType.income,
        date: DateTime.now(),
        categoryId: widget.category.id,
        categoryName: widget.category.name,
        concept: widget.category.name, // Posem concepte el nom per defecte
        subCategoryId: defaultSubCat.id,
        subCategoryName: defaultSubCat.name,
        payer: payer.toString(),
        groupId: groupId.toString(),
      );

      await ref
          .read(transactionNotifierProvider.notifier)
          .addTransaction(transaction);

      if (mounted) {
        Navigator.pop(context); // Tanca modal the quantitat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.category.type == TransactionType.expense ? 'Despesa' : 'Ingrés'} registrat!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.category.color != null
        ? Color(widget.category.color!)
        : Colors.grey.shade500;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Text(widget.category.icon,
                        style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.category.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.anthracite,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Import (€)',
                  prefixIcon: Icon(
                    widget.category.type == TransactionType.expense
                        ? Icons.money_off
                        : Icons.attach_money,
                    color: widget.category.type == TransactionType.expense
                        ? Colors.red
                        : Colors.green,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                autofocus: true,
                onSubmitted: (_) => _isSaving ? null : _saveTransaction(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text(
                        'Desar Transacció',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
