import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/category.dart';

import '../providers/category_notifier.dart';
import '../providers/group_providers.dart';
import '../providers/savings_goal_provider.dart';
import '../providers/debt_provider.dart';
import '../screens/budget/annual_budget_screen.dart'; // Keep for navigation

class SubCategoryEditorSheet extends ConsumerStatefulWidget {
  final Category category;
  final SubCategory? subCategory;

  const SubCategoryEditorSheet({
    super.key,
    required this.category,
    this.subCategory,
  });

  @override
  ConsumerState<SubCategoryEditorSheet> createState() =>
      _SubCategoryEditorSheetState();
}

class _SubCategoryEditorSheetState
    extends ConsumerState<SubCategoryEditorSheet> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late bool _isFixed;
  late PaymentTiming _paymentTiming;
  int _paymentDay = 1;
  String? _selectedPayerId;
  String? _linkedSavingsGoalId;
  String? _linkedDebtId;
  bool _isLinkedToSavings = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.subCategory?.name ?? '',
    );
    _amountController = TextEditingController(
      text: widget.subCategory?.monthlyBudget.toStringAsFixed(0) ?? '0',
    );
    _isFixed = widget.subCategory?.isFixed ?? false;
    _paymentTiming =
        widget.subCategory?.paymentTiming ?? PaymentTiming.specificDay;
    _paymentDay = widget.subCategory?.paymentDay ?? 1;
    _selectedPayerId = widget.subCategory?.defaultPayerId;
    _linkedSavingsGoalId = widget.subCategory?.linkedSavingsGoalId;
    _linkedDebtId = widget.subCategory?.linkedDebtId;
    _isLinkedToSavings = _linkedSavingsGoalId != null || _linkedDebtId != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final members = await ref.read(groupMembersProvider.future);
    if (!mounted) return;
    final payerId =
        _selectedPayerId ?? (members.isNotEmpty ? members.first.uid : null);

    if (payerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has de seleccionar un pagador')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    final newSub =
        widget.subCategory?.copyWith(
          name: _nameController.text.trim(),
          monthlyBudget: amount,
          isFixed: _isFixed,
          paymentTiming: _paymentTiming,
          paymentDay: (_isFixed && _paymentTiming == PaymentTiming.specificDay)
              ? _paymentDay
              : null,
          defaultPayerId: payerId,
          linkedSavingsGoalId: _isLinkedToSavings ? _linkedSavingsGoalId : null,
          linkedDebtId: _isLinkedToSavings ? _linkedDebtId : null,
        ) ??
        SubCategory(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          monthlyBudget: amount,
          isFixed: _isFixed,
          paymentTiming: _paymentTiming,
          paymentDay: (_isFixed && _paymentTiming == PaymentTiming.specificDay)
              ? _paymentDay
              : null,
          defaultPayerId: payerId,
          linkedSavingsGoalId: _isLinkedToSavings ? _linkedSavingsGoalId : null,
          linkedDebtId: _isLinkedToSavings ? _linkedDebtId : null,
        );

    List<SubCategory> updatedSubcategories = List.from(
      widget.category.subcategories,
    );

    if (widget.subCategory == null) {
      updatedSubcategories.add(newSub);
    } else {
      final index = updatedSubcategories.indexWhere(
        (s) => s.id == widget.subCategory!.id,
      );
      if (index != -1) {
        updatedSubcategories[index] = newSub;
      }
    }

    final updatedCategory = widget.category.copyWith(
      subcategories: updatedSubcategories,
    );

    await ref
        .read(categoryNotifierProvider.notifier)
        .updateCategory(updatedCategory);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(groupMembersProvider);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Title
            Center(
              child: Text(
                widget.subCategory == null
                    ? 'Nova Subcategoria'
                    : 'Editar Subcategoria',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.anthracite,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- Block 1: Identity ---
            Text(
              'Identitat',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.label_outline),
                labelText: 'Nom de la categoria',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            membersAsync.when(
              data: (members) {
                if (members.isEmpty) return const SizedBox.shrink();

                // Unify logic with AddTransactionSheet:
                // Default to first member if none selected (for display)
                final effectiveSelectedId =
                    _selectedPayerId ?? members.first.uid;

                // Also update state if null so save logic works without validation error
                if (_selectedPayerId == null) {
                  // Schedule state update to avoid build error?
                  // Or just rely on effectiveId for display and let user select?
                  // AddTransactionSheet implies selection.
                  // Better: set it in a post-frame callback or just use effectiveId for visual
                  // and handle validation/save by defaulting there too.
                  // For now, let's just use emptySelectionAllowed: false (default) and provide a set.
                }

                return SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: members.map((m) {
                      // Brief name from email or name (Unified logic)
                      final name = m.name?.isNotEmpty == true
                          ? m.name!
                          : m.email.split('@')[0];
                      return ButtonSegment<String>(
                        value: m.uid,
                        label: Text(name),
                        icon: const Icon(Icons.person_outline),
                      );
                    }).toList(),
                    selected: {effectiveSelectedId},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedPayerId = newSelection.first;
                      });
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.anthracite.withAlpha(25);
                        }
                        return Colors.transparent;
                      }),
                      side: WidgetStateProperty.all(
                        BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),

            // --- Block 2: Money ---
            Center(
              child: Text(
                'Pressupost Mensual Base',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '€',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.copper,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.anthracite,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- Block 3: Behavior ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'És una despesa fixa?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Lloguer, Gimnàs, Subscripcions...',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _isFixed,
                    onChanged: (val) => setState(() => _isFixed = val),
                    activeTrackColor: AppTheme.copper,
                  ),
                  if (_isFixed) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Moment de pagament',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Primer dia hàbil'),
                          selected:
                              _paymentTiming == PaymentTiming.firstBusinessDay,
                          onSelected: (selected) {
                            if (selected) {
                              setState(
                                () => _paymentTiming =
                                    PaymentTiming.firstBusinessDay,
                              );
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Últim dia hàbil'),
                          selected:
                              _paymentTiming == PaymentTiming.lastBusinessDay,
                          onSelected: (selected) {
                            if (selected) {
                              setState(
                                () => _paymentTiming =
                                    PaymentTiming.lastBusinessDay,
                              );
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Dia Específic'),
                          selected: _paymentTiming == PaymentTiming.specificDay,
                          onSelected: (selected) {
                            if (selected) {
                              setState(
                                () =>
                                    _paymentTiming = PaymentTiming.specificDay,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    if (_paymentTiming == PaymentTiming.specificDay) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Dia del mes: '),
                          Expanded(
                            child: Slider(
                              value: _paymentDay.toDouble(),
                              min: 1,
                              max: 31,
                              divisions: 30,
                              label: _paymentDay.toString(),
                              activeColor: AppTheme.copper,
                              onChanged: (val) {
                                setState(() => _paymentDay = val.toInt());
                              },
                            ),
                          ),
                          Text(
                            '$_paymentDay',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Divider(),
                    SwitchListTile(
                      title: const Text(
                        'Vincular pagament a...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'En pagar, aporta a guardiola o paga deute',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _isLinkedToSavings,
                      onChanged: (val) {
                        setState(() {
                          _isLinkedToSavings = val;
                          if (!val) {
                            _linkedSavingsGoalId = null;
                            _linkedDebtId = null;
                          }
                        });
                      },
                      activeTrackColor: AppTheme.copper,
                    ),
                    if (_isLinkedToSavings) ...[
                      const SizedBox(height: 12),
                      Consumer(
                        builder: (context, ref, _) {
                          final goalsAsync = ref.watch(
                            savingsGoalNotifierProvider,
                          );
                          final debtsAsync = ref.watch(debtNotifierProvider);

                          final goals = goalsAsync.valueOrNull ?? [];
                          final debts = debtsAsync.valueOrNull ?? [];

                          if (goals.isEmpty && debts.isEmpty) {
                            return const Text(
                              'No hi ha guardioles ni deutes disponibles.',
                              style: TextStyle(color: Colors.red),
                            );
                          }

                          // Build unified items with composite keys
                          final items = <DropdownMenuItem<String>>[];

                          for (final g in goals) {
                            items.add(
                              DropdownMenuItem(
                                value: 'goal:${g.id}',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      g.icon,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        g.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          for (final d in debts) {
                            items.add(
                              DropdownMenuItem(
                                value: 'debt:${d.id}',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '💳',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        d.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Compute current value from state
                          String? currentValue;
                          if (_linkedSavingsGoalId != null) {
                            currentValue = 'goal:$_linkedSavingsGoalId';
                          } else if (_linkedDebtId != null) {
                            currentValue = 'debt:$_linkedDebtId';
                          }

                          return DropdownButtonFormField<String>(
                            initialValue: currentValue,
                            decoration: InputDecoration(
                              labelText: 'Destí del pagament',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: items,
                            onChanged: (val) {
                              setState(() {
                                if (val != null && val.startsWith('goal:')) {
                                  _linkedSavingsGoalId = val.substring(5);
                                  _linkedDebtId = null;
                                } else if (val != null &&
                                    val.startsWith('debt:')) {
                                  _linkedDebtId = val.substring(5);
                                  _linkedSavingsGoalId = null;
                                }
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Block 4: Advanced Planning ---
            if (widget.subCategory != null)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.copper.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.copper.withAlpha(50)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: AppTheme.copper,
                    ),
                  ),
                  title: const Text(
                    'Planificació Mensual Detallada',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.anthracite,
                    ),
                  ),
                  subtitle: const Text(
                    'Configurar valors específics per mes',
                    style: TextStyle(color: AppTheme.anthracite),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.copper,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnnualBudgetScreen(
                          subCategory: widget.subCategory!,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.copper,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Guardar Subcategoria',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
