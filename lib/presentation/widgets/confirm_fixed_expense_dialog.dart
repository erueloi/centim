import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/asset.dart';
import '../providers/asset_provider.dart';

class ConfirmFixedExpenseResult {
  final DateTime date;
  final String? accountId;

  ConfirmFixedExpenseResult(this.date, this.accountId);
}

class ConfirmFixedExpenseDialog extends ConsumerStatefulWidget {
  final String expenseName;
  final double amount;
  final bool isIncome;

  const ConfirmFixedExpenseDialog({
    super.key,
    required this.expenseName,
    required this.amount,
    required this.isIncome,
  });

  @override
  ConsumerState<ConfirmFixedExpenseDialog> createState() =>
      _ConfirmFixedExpenseDialogState();
}

class _ConfirmFixedExpenseDialogState
    extends ConsumerState<ConfirmFixedExpenseDialog> {
  late DateTime _selectedDate;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetNotifierProvider);

    return AlertDialog(
      title: const Text('Confirmar pagament'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estàs a punt de registrar ${widget.isIncome ? "l'ingrés" : "la despesa"} '
              'fixa de ${widget.amount.toStringAsFixed(2)} € per "${widget.expenseName}".',
            ),
            const SizedBox(height: 16),
            // Data
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppTheme.copper),
              title: const Text('Data del pagament'),
              subtitle:
                  Text(DateFormat('dd/MM/yyyy', 'ca_ES').format(_selectedDate)),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  helpText: 'Selecciona la data',
                );
                if (d != null) {
                  setState(() => _selectedDate = d);
                }
              },
            ),
            const SizedBox(height: 16),
            // Compte
            assetsAsync.when(
              data: (assets) {
                final liquidAssets = assets
                    .where((a) =>
                        a.type == AssetType.bankAccount ||
                        a.type == AssetType.cash)
                    .toList();

                if (liquidAssets.isEmpty) return const SizedBox.shrink();

                return DropdownButtonFormField<String?>(
                  initialValue: _selectedAccountId,
                  decoration: InputDecoration(
                    labelText: 'Compte (Opcional)',
                    prefixIcon: const Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.copper,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Cap compte seleccionat'),
                    ),
                    ...liquidAssets.map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(
                            '${a.name} (${NumberFormat.currency(locale: 'ca_ES', symbol: '€').format(a.amount)})'),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel·lar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              ConfirmFixedExpenseResult(_selectedDate, _selectedAccountId),
            );
          },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.copper),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
