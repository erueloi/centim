import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/savings_goal.dart';
import '../../providers/savings_goal_provider.dart';

class AddContributionDialog extends ConsumerStatefulWidget {
  final SavingsGoal goal;

  const AddContributionDialog({super.key, required this.goal});

  @override
  ConsumerState<AddContributionDialog> createState() =>
      _AddContributionDialogState();
}

class _AddContributionDialogState extends ConsumerState<AddContributionDialog> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      Navigator.pop(context); // Close dialog first

      try {
        await ref
            .read(savingsGoalNotifierProvider.notifier)
            .addContribution(widget.goal.id, amount);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aportació realitzada correctament!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Aportació a ${widget.goal.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Import (€)',
                border: OutlineInputBorder(),
                prefixText: '€ ',
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Introdueix un import';
                }
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  return 'Import invàlid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Això crearà automàticament una despesa per reduir el saldo disponible.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel·lar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.copper,
            foregroundColor: Colors.white,
          ),
          child: const Text('Aportar'),
        ),
      ],
    );
  }
}
