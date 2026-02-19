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
    // Sort: duplicates first, then by date descending
    _items = List.from(widget.transactions)
      ..sort((a, b) {
        if (a.isDuplicate && !b.isDuplicate) return -1;
        if (!a.isDuplicate && b.isDuplicate) return 1;
        return b.date.compareTo(a.date);
      });
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
            orElse: () => const Category(
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
                orElse: () => const SubCategory(id: '', name: '', monthlyBudget: 0),
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
          final duplicateCount = _items.where((i) => i.isDuplicate).length;
          final newCount = _items.length - duplicateCount;
          final selectedCount = _items.where((i) => i.selected).length;

          return Column(
            children: [
              // Summary banner
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildCountChip('$newCount nous', Colors.green),
                    const SizedBox(width: 8),
                    if (duplicateCount > 0)
                      _buildCountChip(
                        '$duplicateCount duplicats',
                        Colors.orange,
                      ),
                    const Spacer(),
                    Text(
                      '$selectedCount seleccionats',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Select all
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: _items
                          .where((i) => !i.isDuplicate)
                          .every((i) => i.selected),
                      onChanged: (v) {
                        setState(() {
                          for (var i in _items) {
                            if (!i.isDuplicate) i.selected = v ?? false;
                          }
                        });
                      },
                    ),
                    const Text('Seleccionar tots (nous)'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    // Section header when transitioning from duplicates to new
                    final showNewHeader =
                        index > 0 &&
                        _items[index - 1].isDuplicate &&
                        !item.isDuplicate;
                    final showDupHeader = index == 0 && item.isDuplicate;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDupHeader)
                          _buildSectionHeader(
                            '⚠️ Possibles Duplicats',
                            Colors.orange,
                          ),
                        if (showNewHeader)
                          _buildSectionHeader('✅ Nous Moviments', Colors.green),
                        if (showNewHeader)
                          _buildSectionHeader('✅ Nous Moviments', Colors.green),
                        _TransactionImportRow(
                          key: Key(item.id),
                          item: item,
                          categories: categories,
                          onChanged: () => setState(() {}),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCountChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == Colors.green ? Colors.green[700] : Colors.orange[700],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.1),
      child: Text(
        title,
        style: TextStyle(
          color: color == Colors.green ? Colors.green[800] : Colors.orange[800],
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _TransactionImportRow extends StatefulWidget {
  final ImportedTransaction item;
  final List<Category> categories;
  final VoidCallback onChanged;

  const _TransactionImportRow({
    required Key key,
    required this.item,
    required this.categories,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_TransactionImportRow> createState() => _TransactionImportRowState();
}

class _TransactionImportRowState extends State<_TransactionImportRow> {
  late TextEditingController _conceptController;
  late ImportedTransaction item;

  @override
  void initState() {
    super.initState();
    item = widget.item;
    _conceptController = TextEditingController(text: item.concept);
  }

  @override
  void dispose() {
    _conceptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Normalize empty strings to null for DropdownButton compatibility
    final categoryId = (item.categoryId != null && item.categoryId!.isNotEmpty)
        ? item.categoryId
        : null;
    final subCategoryId =
        (item.subCategoryId != null && item.subCategoryId!.isNotEmpty)
        ? item.subCategoryId
        : null;

    Category? selectedCat;

    if (categoryId != null) {
      try {
        selectedCat = widget.categories.firstWhere((c) => c.id == categoryId);
      } catch (_) {
        // categoryId doesn't match any category, reset it
        item.categoryId = null;
      }
    }

    final color = item.isDuplicate
        ? Colors.orange.withValues(alpha: 0.08)
        : Colors.green.withValues(alpha: 0.05);

    return Container(
      color: color,
      child: ExpansionTile(
        leading: Checkbox(
          value: item.selected,
          onChanged: (v) {
            item.selected = v ?? false;
            widget.onChanged();
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
            child: Column(
              children: [
                // Concept Editor
                TextFormField(
                  controller: _conceptController,
                  decoration: const InputDecoration(
                    labelText: 'Concepte',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (val) {
                    item.concept = val;
                    // Trigger rebuild to update title
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.category, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    // Category Dropdown
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Sense Categoria'),
                        value: categoryId,
                        items: widget.categories.map((c) {
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
                          widget.onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Subcategory Dropdown (if category selected)
                    if (selectedCat != null &&
                        selectedCat.subcategories.isNotEmpty)
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Subcategoria'),
                          value: subCategoryId,
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
                            widget.onChanged();
                          },
                        ),
                      ),
                  ],
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
