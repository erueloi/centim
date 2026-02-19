import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/budget_entry.dart';
import '../../../domain/models/category.dart';
import '../../providers/auth_providers.dart';
import '../../../data/providers/repository_providers.dart';
import '../../widgets/responsive_center.dart';

class AnnualBudgetScreen extends ConsumerStatefulWidget {
  final SubCategory subCategory;

  const AnnualBudgetScreen({super.key, required this.subCategory});

  @override
  ConsumerState<AnnualBudgetScreen> createState() => _AnnualBudgetScreenState();
}

class _AnnualBudgetScreenState extends ConsumerState<AnnualBudgetScreen> {
  late int _currentYear;

  @override
  void initState() {
    super.initState();
    _currentYear = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final groupIdAsync = ref.watch(currentGroupIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Planificació: ${widget.subCategory.name}'),
        actions: [
          groupIdAsync.when(
            data: (groupId) {
              if (groupId == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.cleaning_services),
                tooltip: "Aplicar valor Base a tot l'any",
                onPressed: () => _resetToDefault(groupId),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: groupIdAsync.when(
        data: (groupId) {
          if (groupId == null) {
            return const Center(child: Text('Error: No active group'));
          }
          return ResponsiveCenter(maxWidth: 1000, child: _buildBody(groupId));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBody(String groupId) {
    final repo = ref.watch(budgetEntryRepositoryProvider);

    return StreamBuilder<List<BudgetEntry>>(
      stream: repo.watchEntriesForSubCategory(
        groupId,
        widget.subCategory.id,
        _currentYear,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data!;
        return Column(
          children: [
            // Year Selector (Simple for now)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _currentYear--),
                  ),
                  Text(
                    '$_currentYear',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() => _currentYear++),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxisCount = 2;
                  double childAspectRatio = 0.85;

                  if (width >= 600 && width < 900) {
                    crossAxisCount = 3;
                    childAspectRatio = 0.8; // Standard
                  } else if (width >= 900) {
                    crossAxisCount = 4;
                    childAspectRatio = 1.0; // Widescreen
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final month = index + 1;
                      final entry = entries.firstWhere(
                        (e) => e.month == month,
                        orElse: () => const BudgetEntry(
                          id: '',
                          subCategoryId: '',
                          year: 0,
                          month: 0,
                          amount: -1,
                        ),
                      );

                      final isException = entry.amount >= 0;
                      final currentAmount = isException
                          ? entry.amount
                          : widget.subCategory.monthlyBudget;

                      return _MonthCard(
                        month: month,
                        year: _currentYear,
                        amount: currentAmount,
                        isException: isException,
                        baseAmount: widget.subCategory.monthlyBudget,
                        onChanged: (newAmount) {
                          _updateEntry(groupId, month, newAmount);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateEntry(String groupId, int month, double amount) async {
    final repo = ref.read(budgetEntryRepositoryProvider);
    final isBase = amount == widget.subCategory.monthlyBudget;

    // Find existing to get ID if needed, or query again?
    // Actually we can just query directly or use the one from stream logic if we passed it down.
    // Simpler: Fetch the list again or just rely on ID generation/query.
    // Since we don't have the ID handy in the callback efficiently without passing it, let's just query to find the ID to delete/update.
    // Or we can generate a deterministic ID: "subcatId_year_month".
    // Let's use deterministic ID for simplicity and atomicity.

    // Wait, better practice is to look it up. But for now, let's use query.
    // Actually `setEntry` overwrites. We just need a consistent ID.
    // Let's assume ID = "${widget.subCategory.id}_${_currentYear}_$month".
    final entryId = '${widget.subCategory.id}_${_currentYear}_$month';

    if (isBase) {
      // If matches base, delete the entry
      await repo.deleteEntry(groupId, entryId);
    } else {
      // Create/Update entry
      final entry = BudgetEntry(
        id: entryId,
        subCategoryId: widget.subCategory.id,
        year: _currentYear,
        month: month,
        amount: amount,
      );
      await repo.setEntry(groupId, entry);
    }
  }

  Future<void> _resetToDefault(String groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restablir valors'),
        content: const Text(
          "Això esborrarà totes les excepcions d'aquest any i aplicarà el valor base a tots els mesos. Estàs segur?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restablir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(budgetEntryRepositoryProvider);
      await repo.deleteEntriesForSubCategory(
        groupId,
        widget.subCategory.id,
        _currentYear,
      );
    }
  }
}

class _MonthCard extends StatefulWidget {
  final int month;
  final int year;
  final double amount;
  final bool isException;
  final double baseAmount;
  final ValueChanged<double> onChanged;

  const _MonthCard({
    required this.month,
    required this.year,
    required this.amount,
    required this.isException,
    required this.baseAmount,
    required this.onChanged,
  });

  @override
  State<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<_MonthCard> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.amount.toStringAsFixed(0));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _submit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _MonthCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount != oldWidget.amount && !_focusNode.hasFocus) {
      _controller.text = widget.amount.toStringAsFixed(0);
    }
  }

  void _submit() {
    final val = double.tryParse(_controller.text);
    if (val != null && val != widget.amount) {
      widget.onChanged(val);
    } else {
      // Reset if invalid or unchanged
      if (!_focusNode.hasFocus) {
        _controller.text = widget.amount.toStringAsFixed(0);
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Gener',
      'Febrer',
      'Març',
      'Abril',
      'Maig',
      'Juny',
      'Juliol',
      'Agost',
      'Setembre',
      'Octubre',
      'Novembre',
      'Desembre',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: widget.isException
            ? const BorderSide(color: AppTheme.copper, width: 2)
            : BorderSide.none,
      ),
      color: widget.isException ? Colors.orange[50] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getMonthName(widget.month),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder(),
                suffixText: '€',
              ),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isException ? AppTheme.copper : Colors.grey[600],
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (widget.isException)
              Text(
                'Base: ${widget.baseAmount.toStringAsFixed(0)}€',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              )
            else
              Text(
                '(Base)',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
    );
  }
}
