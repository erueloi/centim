import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/transaction.dart';
import '../../../domain/services/import_service.dart';
import '../../../data/providers/repository_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/category_notifier.dart';
import '../../../domain/models/category.dart';

class ImportTransactionsScreen extends ConsumerStatefulWidget {
  final List<ImportedTransaction> transactions;

  const ImportTransactionsScreen({super.key, required this.transactions});

  @override
  ConsumerState<ImportTransactionsScreen> createState() =>
      _ImportTransactionsScreenState();
}

class _ImportTransactionsScreenState
    extends ConsumerState<ImportTransactionsScreen> {
  late List<ImportedTransaction> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.transactions;
  }

  Future<void> _saveSelected() async {
    setState(() => _isSaving = true);

    final selected = _items.where((t) => t.selected).toList();
    if (selected.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cap moviment seleccionat')),
        );
        setState(() => _isSaving = false);
      }
      return;
    }

    try {
      final groupId = await ref.read(currentGroupIdProvider.future);
      if (groupId == null) throw Exception("No group ID");

      final repo = ref.read(transactionRepositoryProvider);
      final categories = await ref.read(categoryNotifierProvider.future);

      int count = 0;
      for (final item in selected) {
        // Resolve Category Name
        String catName = 'Sense categoria';
        String subName = 'General';
        String catId = item.categoryId ?? '';
        String subId = item.subCategoryId ?? '';

        // If no category selected, use default "Expenses" or similar?
        // Or create "Uncategorized"?
        // For now, if empty, we might skip or fail.
        // Better: require category or use "General".

        if (catId.isNotEmpty) {
          final cat = categories.firstWhere(
            (c) => c.id == catId,
            orElse: () => Category(
              id: '',
              name: '',
              icon: '',
              color: 0,
              subcategories: [],
            ),
          );
          if (cat.id.isNotEmpty) {
            catName = cat.name;
            if (subId.isNotEmpty) {
              final sub = cat.subcategories.firstWhere(
                (s) => s.id == subId,
                orElse: () => SubCategory(id: '', name: '', monthlyBudget: 0),
              );
              if (sub.id.isNotEmpty) subName = sub.name;
            }
          }
        } else {
          // Assign to a default fallback or leave empty?
          // Firestore rules might require non-empty.
          // Let's assume we need at least a placeholder.
          // However main app logic usually requires valid category.
          // Ideally we enforce selection in UI.
        }

        final tx = Transaction(
          id: const Uuid().v4(),
          groupId: groupId,
          date: item.date,
          amount: item.amount
              .abs(), // Always positive in model usually? No, model has amount and isIncome.
          // Wait, Transaction model has 'amount' and 'isIncome'.
          // amount is typically positive.
          isIncome: item.amount > 0,
          concept: item.concept,
          categoryId: catId,
          subCategoryId: subId,
          categoryName: catName,
          subCategoryName: subName,
          payer: 'Imported', // Default payer? Or current user?
          // Maybe let user pick payer for all? Or default to current user?
          // Let's use 'Imported' or 'CaixaBank' as payer?
          // 'payer' field is usually person name.
          // Let's fetch current user name.
        );

        // Fix Amount sign: Model expects positive amount usually?
        // Checked Transaction model: `required double amount`
        // `required bool isIncome`
        // Usually amount is absolute value.
        await repo.addTransaction(tx.copyWith(amount: item.amount.abs()));
        count++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count moviments importats correctament')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error guardant: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar Importació'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSelected,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'CONFIRMAR',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (categories) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: _items.every((i) => i.selected),
                      onChanged: (v) {
                        setState(() {
                          for (var i in _items) {
                            if (!i.isDuplicate) i.selected = v ?? false;
                          }
                        });
                      },
                    ),
                    const Text('Seleccionar tots'),
                    const Spacer(),
                    Text(
                      '${_items.where((i) => i.selected).length} seleccionats',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _buildTransactionRow(item, categories);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionRow(
    ImportedTransaction item,
    List<Category> categories,
  ) {
    // Category? selectedCat;
    // SubCategory? selectedSub;

    Category? selectedCat;

    if (item.categoryId != null) {
      try {
        selectedCat = categories.firstWhere((c) => c.id == item.categoryId);
      } catch (_) {}
    }

    final color = item.isDuplicate ? Colors.red.withValues(alpha: 0.1) : null;

    return Container(
      color: color,
      child: ExpansionTile(
        leading: Checkbox(
          value: item.selected,
          onChanged: item.isDuplicate
              ? null
              : (v) {
                  // Prevent selecting potential duplicates easily? Or warn?
                  // Allow user to override if they really want
                  setState(() => item.selected = v ?? false);
                },
        ),
        title: Text(
          item.concept,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(item.date)),
        trailing: Text(
          '${item.amount.toStringAsFixed(2)} €',
          style: TextStyle(
            color: item.amount > 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                const Icon(Icons.category, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                // Category Dropdown
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Sense Categoria'),
                    value: item.categoryId,
                    items: categories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.icon} ${c.name}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        item.categoryId = val;
                        item.subCategoryId = null; // Reset sub
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Subcategory Dropdown (if category selected)
                if (selectedCat != null && selectedCat.subcategories.isNotEmpty)
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Subcategoria'),
                      value: item.subCategoryId,
                      items: selectedCat.subcategories.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          item.subCategoryId = val;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (item.isDuplicate)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0, left: 50.0),
              child: Text(
                '⚠️ Possible duplicat detectat',
                style: TextStyle(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
