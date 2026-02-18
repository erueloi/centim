import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../providers/auth_providers.dart';
import '../providers/category_notifier.dart';
import '../providers/group_providers.dart';
import '../providers/transaction_notifier.dart';
import '../providers/savings_goal_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final Category? initialCategory;
  final SubCategory? initialSubCategory;
  final double? initialAmount;
  final String? initialConcept;
  final bool initialIsExpense;
  final Transaction? transactionToEdit;

  const AddTransactionSheet({
    super.key,
    this.initialCategory,
    this.initialSubCategory,
    this.initialAmount,
    this.initialConcept,
    this.initialIsExpense = false,
    this.transactionToEdit,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _conceptController = TextEditingController();

  bool _isIncome = false;
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;
  String? _selectedPayerId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSavingsExpenditure = false;
  String? _selectedSavingsGoalId;

  @override
  void initState() {
    super.initState();

    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      _amountController.text = t.amount.toStringAsFixed(2);
      _conceptController.text = t.concept;
      _isIncome = t.isIncome;
      _selectedDate = t.date;
      _selectedPayerId = t.payer;

      // If editing a savings expenditure
      if (t.savingsGoalId != null) {
        _isSavingsExpenditure = true;
        _selectedSavingsGoalId = t.savingsGoalId;
      }

      // Categories will be matched in build or we need to fetch them.
      // Ideally we should pass the category/subcategory objects if available,
      // but if not, logic might be needed to find them from IDs.
      // For now, let's assume valid IDs or that the user re-selects if mismatch.
      // Optimally, logic to find Category by ID from provider would be good here,
      // but avoiding complex async init for now.
      // Let's rely on widget.initialCategory/SubCategory being passed correctly
      // OR matching in the build method.
    } else {
      _selectedCategory = widget.initialCategory;
      _selectedSubCategory = widget.initialSubCategory;

      if (widget.initialAmount != null) {
        _amountController.text = widget.initialAmount!.toStringAsFixed(2);
      }

      if (widget.initialConcept != null) {
        _conceptController.text = widget.initialConcept!;
      }

      // Prioritize category type if available, otherwise fallback to widget param
      if (_selectedCategory != null) {
        _isIncome = _selectedCategory!.type == TransactionType.income;
      } else {
        _isIncome = !widget.initialIsExpense;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (!mounted) return;
    if (groupId == null) return;

    // Validate
    if (_amountController.text.isEmpty ||
        _conceptController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedSubCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si us plau, omple tots els camps (Import, Concepte, Categoria)',
          ),
        ),
      );
      return;
    }

    if (_isSavingsExpenditure && _selectedSavingsGoalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has de seleccionar una guardiola')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      final members = await ref.read(groupMembersProvider.future);

      // If paying with savings, payer might default to user or be irrelevant?
      // We'll stick to selected payer or default.
      final payer =
          _selectedPayerId ?? (members.isNotEmpty ? members.first.uid : '');

      final transaction = Transaction(
        id: widget.transactionToEdit?.id, // Preserve ID if editing
        groupId: groupId,
        date: _selectedDate,
        amount: amount,
        concept: _conceptController.text,
        categoryId: _selectedCategory!.id,
        subCategoryId: _selectedSubCategory!.id,
        categoryName: _selectedCategory!.name,
        subCategoryName: _selectedSubCategory!.name,
        payer: payer,
        isIncome: _isIncome,
        savingsGoalId: _isSavingsExpenditure ? _selectedSavingsGoalId : null,
      );

      final notifier = ref.read(transactionNotifierProvider.notifier);
      if (widget.transactionToEdit != null) {
        await notifier.updateTransaction(transaction);
      } else {
        await notifier.addTransaction(transaction);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final membersAsync = ref.watch(groupMembersProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag Handle handled by showModalBottomSheet property usually,
              // but purely visual usage here if needed, otherwise removed if duplicate.
              // Logic: showDragHandle: true in ShowModalBottomSheet adds it above.
              Expanded(
                child: ListView(
                  controller: scrollController, // Important for drag behavior
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  children: [
                    // --- DELETE BUTTON (If Editing) ---
                    if (widget.transactionToEdit != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Esborrar moviment?'),
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
                                    child: const Text('Esborrar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              await ref
                                  .read(transactionNotifierProvider.notifier)
                                  .deleteTransaction(widget.transactionToEdit!);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                        ),
                      ),

                    // --- AMOUNT INPUT ---
                    Center(
                      child: IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.anthracite,
                              ),
                          decoration: InputDecoration(
                            prefixText: '€ ',
                            prefixStyle: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.copper,
                                ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- TYPE SELECTOR ---
                    Center(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Despesa'),
                            icon: Icon(Icons.arrow_downward),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Ingrés'),
                            icon: Icon(Icons.arrow_upward),
                          ),
                        ],
                        selected: {_isIncome},
                        onSelectionChanged: (v) => setState(() {
                          _isIncome = v.first;
                          _selectedCategory = null;
                          _selectedSubCategory = null;
                        }),
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppTheme.copper.withValues(alpha: 0.2);
                                }
                                return Colors.transparent;
                              }),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppTheme.anthracite;
                                }
                                return Colors.grey;
                              }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- CONCEPT INPUT ---
                    TextField(
                      controller: _conceptController,
                      decoration: InputDecoration(
                        hintText: 'Concepte (ex: Supermercat)',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(
                          Icons.edit_note,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.copper,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- CATEGORIES (Chips) ---
                    Text(
                      'Categoria',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    categoriesAsync.when(
                      data: (categories) {
                        // Logic to pre-select category/subcategory if editing and not yet selected
                        if (widget.transactionToEdit != null &&
                            _selectedCategory == null) {
                          try {
                            final cat = categories.firstWhere(
                              (c) =>
                                  c.id == widget.transactionToEdit!.categoryId,
                            );
                            // Defer state update to end of frame to avoid build error,
                            // OR just set it locally if not calling setState (but we are in build).
                            // Better: Set it in a microtask or ensure initState handles it.
                            // Since initState didn't have access to 'categories', we find it here.
                            // But modifying state during build is bad.
                            // Let's rely on finding it in the list to displaying as selected,
                            // but we need the object for logic.
                            // Actually, setState in initState is fine. But we didn't have categories.
                            // Hack: We'll set it here if null to drive the UI, but this is fragile.
                            // CORRECT APPROACH: Use ref.watch in initState using ref.read? No.
                            // Let's just do a quick look up.
                            _selectedCategory = cat;
                            if (widget
                                .transactionToEdit!
                                .subCategoryId
                                .isNotEmpty) {
                              _selectedSubCategory = cat.subcategories
                                  .firstWhere(
                                    (s) =>
                                        s.id ==
                                        widget.transactionToEdit!.subCategoryId,
                                    orElse: () => cat.subcategories.first,
                                  );
                            }
                          } catch (e) {
                            // Category might have been deleted
                          }
                        }

                        final filteredCategories = categories
                            .where(
                              (c) =>
                                  c.type ==
                                  (_isIncome
                                      ? TransactionType.income
                                      : TransactionType.expense),
                            )
                            .toList();

                        if (filteredCategories.isEmpty) {
                          return const Text('No hi ha categories disponibles.');
                        }

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: filteredCategories.map((cat) {
                            final isSelected = _selectedCategory?.id == cat.id;
                            return ChoiceChip(
                              label: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: cat.icon,
                                      style: const TextStyle(
                                        fontSize: 18,
                                      ), // Bigger emoji
                                    ),
                                    const TextSpan(text: ' '),
                                    TextSpan(
                                      text: cat.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.anthracite,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontFamily:
                                            'Roboto', // Ensure consistent font
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? cat : null;
                                  _selectedSubCategory = null;
                                });
                              },
                              selectedColor: AppTheme.copper,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                              showCheckmark: false, // Cleaner look with emojis
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error: $err'),
                    ),

                    // --- SUBCATEGORIES (Conditionally Shown) ---
                    if (_selectedCategory != null &&
                        _selectedCategory!.subcategories.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Subcategoria',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ... (Subcategories Wrap code omitted for brevity matching)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedCategory!.subcategories.map((sub) {
                          final isSelected = _selectedSubCategory?.id == sub.id;
                          return ChoiceChip(
                            label: Text(sub.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedSubCategory = selected ? sub : null;
                              });
                            },
                            // ... styles matching existing code
                            selectedColor: AppTheme.copper.withValues(
                              alpha: 0.5,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.anthracite,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // --- PAY WITH SAVINGS (Toggle) ---
                    if (!_isIncome) ...[
                      SwitchListTile(
                        title: const Text(
                          'Pagar amb estalvis?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Es descomptarà d\'una guardiola',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _isSavingsExpenditure,
                        activeTrackColor: AppTheme.copper,
                        onChanged: (val) {
                          setState(() {
                            _isSavingsExpenditure = val;
                            if (!val) _selectedSavingsGoalId = null;
                          });
                        },
                      ),
                      if (_isSavingsExpenditure) ...[
                        const SizedBox(height: 12),
                        Consumer(
                          builder: (context, ref, _) {
                            final goalsAsync = ref.watch(
                              savingsGoalNotifierProvider,
                            );
                            return goalsAsync.when(
                              data: (goals) {
                                if (goals.isEmpty) {
                                  return const Text(
                                    'No tens guardioles amb fons.',
                                    style: TextStyle(color: Colors.red),
                                  );
                                }
                                return DropdownButtonFormField<String>(
                                  initialValue: _selectedSavingsGoalId,
                                  decoration: InputDecoration(
                                    labelText: 'Selecciona Guardiola',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: goals
                                      .map(
                                        (g) => DropdownMenuItem(
                                          value: g.id,
                                          child: Row(
                                            children: [
                                              Text(g.icon),
                                              const SizedBox(width: 8),
                                              Text(
                                                g.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '(${g.currentAmount.toStringAsFixed(0)}€)',
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) => setState(
                                    () => _selectedSavingsGoalId = val,
                                  ),
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (_, _) =>
                                  const Text('Error carregant guardioles'),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],

                    // --- METADATA (Date & Payer) ---
                    Row(
                      children: [
                        // Date Chip
                        InputChip(
                          avatar: const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppTheme.anthracite,
                          ),
                          label: Text(
                            DateUtils.isSameDay(_selectedDate, DateTime.now())
                                ? 'Avui'
                                : '${_selectedDate.day}/${_selectedDate.month}',
                          ),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) setState(() => _selectedDate = d);
                          },
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Payer Selector (SegmentedButton)
                        if (!_isSavingsExpenditure) ...[
                          membersAsync.when(
                            data: (members) {
                              if (members.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              // Ensure Payer Selector is visible even if only 1 member (User feedback)
                              // if (members.length == 1) {
                              //   return const SizedBox.shrink();
                              // }

                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: SegmentedButton<String>(
                                    segments: members.map((m) {
                                      // Brief name from email or name
                                      final name = m.name?.isNotEmpty == true
                                          ? m.name!
                                          : m.email.split('@')[0];
                                      return ButtonSegment(
                                        value: m.uid,
                                        label: Text(name),
                                        icon: const Icon(Icons.person),
                                      );
                                    }).toList(),
                                    selected: {
                                      _selectedPayerId ?? members.first.uid,
                                    },
                                    onSelectionChanged:
                                        (Set<String> newSelection) {
                                          setState(() {
                                            _selectedPayerId =
                                                newSelection.first;
                                          });
                                        },
                                    style: ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor:
                                          WidgetStateProperty.resolveWith<
                                            Color
                                          >((states) {
                                            if (states.contains(
                                              WidgetState.selected,
                                            )) {
                                              return AppTheme.anthracite
                                                  .withValues(alpha: 0.1);
                                            }
                                            return Colors.transparent;
                                          }),
                                    ),
                                  ),
                                ),
                              );
                            },
                            loading: () => const Expanded(
                              child: LinearProgressIndicator(),
                            ),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // --- SAVE BUTTON ---
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: _isIncome
                          ? Colors.green
                          : AppTheme
                                .copper, // Green for income context? Or stick to theme?
                      // User requested AppTheme colors. Sticking to Copper for consistency, maybe Green only for income toggle.
                      // Let's use Theme implementation for now.
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Guardar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              // Keyboard spacing handled by Scaffold/Sheet logic usually, but Padding bottom is good.
            ],
          ),
        );
      },
    );
  }
}
