import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/format_utils.dart';
import '../../../domain/models/category.dart';
import '../../../domain/services/subcategory_move_service.dart';

import '../providers/category_notifier.dart';
import '../providers/transaction_notifier.dart';
import '../providers/group_providers.dart';
import '../providers/savings_goal_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/auth_providers.dart';
import '../screens/budget/annual_budget_screen.dart'; // Keep for navigation
import '../../../domain/models/billing_cycle.dart';
import '../../../domain/models/budget_entry.dart';
import '../../../data/providers/repository_providers.dart';
import '../providers/budget_provider.dart';

class SubCategoryEditorSheet extends ConsumerStatefulWidget {
  final Category category;
  final SubCategory? subCategory;
  final BillingCycle? selectedCycle; // null = base budget

  const SubCategoryEditorSheet({
    super.key,
    required this.category,
    this.subCategory,
    this.selectedCycle,
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
  late bool _isWatched;
  late bool _archived;
  late PaymentTiming _paymentTiming;
  int _paymentDay = 1;
  String? _selectedPayerId;
  String? _linkedSavingsGoalId;
  String? _linkedDebtId;
  bool _isLinkedToSavings = false;
  double _fallbackBudget = 0.0; // Pressupost del cicle anterior (fallback)
  late String _targetParentId; // Categoria pare (pot canviar: mou la subcat)

  @override
  void initState() {
    super.initState();
    _targetParentId = widget.category.id;
    _nameController = TextEditingController(
      text: widget.subCategory?.name ?? '',
    );
    _amountController = TextEditingController(
      text: widget.subCategory != null
          ? editableAmountText(widget.subCategory!.monthlyBudget)
          : '0',
    );
    _isFixed = widget.subCategory?.isFixed ?? false;
    _isWatched = widget.subCategory?.isWatched ?? false;
    _archived = widget.subCategory?.archived ?? false;
    _paymentTiming =
        widget.subCategory?.paymentTiming ?? PaymentTiming.specificDay;
    _paymentDay = widget.subCategory?.paymentDay ?? 1;
    _selectedPayerId = widget.subCategory?.defaultPayerId;
    _linkedSavingsGoalId = widget.subCategory?.linkedSavingsGoalId;
    _linkedDebtId = widget.subCategory?.linkedDebtId;
    _isLinkedToSavings = _linkedSavingsGoalId != null || _linkedDebtId != null;

    // Load existing month-specific override if editing a specific cycle
    if (widget.selectedCycle != null && widget.subCategory != null) {
      _loadMonthOverride();
    }

    // Precarregar el pressupost del cicle anterior (per fallback de la vareta)
    if (widget.subCategory != null) {
      _loadPreviousBudget();
    }
  }

  Future<void> _loadPreviousBudget() async {
    final groupId = ref.read(currentGroupIdProvider).valueOrNull;
    if (groupId == null) return;

    final prevMonth =
        DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
    final repo = ref.read(budgetEntryRepositoryProvider);
    try {
      final entries = await repo
          .watchEntriesForMonth(groupId, prevMonth.year, prevMonth.month)
          .first;
      final match =
          entries.where((e) => e.subCategoryId == widget.subCategory!.id);
      if (match.isNotEmpty && match.first.amount > 0 && mounted) {
        setState(() {
          _fallbackBudget = match.first.amount;
        });
      }
    } catch (_) {
      // Sense pressupost anterior disponible
    }
  }

  Future<void> _loadMonthOverride() async {
    final groupId = ref.read(currentGroupIdProvider).valueOrNull;
    if (groupId == null) return;
    final cycle = widget.selectedCycle!;
    final repo = ref.read(budgetEntryRepositoryProvider);
    final entryId =
        '${widget.subCategory!.id}_${cycle.endDate.year}_${cycle.endDate.month}';
    try {
      final entry = await repo.getEntry(groupId, entryId);
      if (entry != null && mounted) {
        setState(() {
          _amountController.text = editableAmountText(entry.amount);
        });
      }
    } catch (_) {
      // No override exists, keep base amount
    }
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

    if (_archived && (_linkedSavingsGoalId != null || _linkedDebtId != null)) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Arxivar subcategoria enllaçada'),
          content: const Text(
            'Aquesta subcategoria té un deute o guardiola vinculada. Es mantindrà l\'enllaç però s\'ocultarà del pressupost i selectors actius. Vols continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel·lar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, arxivar'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final amount = parseEditableAmount(_amountController.text) ?? 0.0;

    // When editing a specific month, save as BudgetEntry override
    // and keep the base monthlyBudget unchanged
    final baseAmount = widget.selectedCycle != null
        ? (widget.subCategory?.monthlyBudget ?? 0.0)
        : amount;

    final newSub = widget.subCategory?.copyWith(
          name: _nameController.text.trim(),
          monthlyBudget: baseAmount,
          isFixed: _isFixed,
          isWatched: _isWatched,
          archived: _archived,
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
          monthlyBudget: baseAmount,
          isFixed: _isFixed,
          isWatched: _isWatched,
          archived: _archived,
          paymentTiming: _paymentTiming,
          paymentDay: (_isFixed && _paymentTiming == PaymentTiming.specificDay)
              ? _paymentDay
              : null,
          defaultPayerId: payerId,
          linkedSavingsGoalId: _isLinkedToSavings ? _linkedSavingsGoalId : null,
          linkedDebtId: _isLinkedToSavings ? _linkedDebtId : null,
        );

    // ── CANVI DE CATEGORIA PARE ──
    // Si s'ha triat un pare diferent, el desat passa pel camí de moviment:
    // dry-run → confirmació → moviment atòmic + reescriptura de l'històric.
    if (widget.subCategory != null && _targetParentId != widget.category.id) {
      final ok = await _handleParentMove(newSub);
      if (!ok) return; // cancel·lat o error: no continuem
    } else {
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
    }

    // Save month-specific budget override if a cycle is selected
    if (widget.selectedCycle != null) {
      final groupId = ref.read(currentGroupIdProvider).valueOrNull;
      if (groupId != null) {
        final cycle = widget.selectedCycle!;
        final repo = ref.read(budgetEntryRepositoryProvider);
        final entryId =
            '${newSub.id}_${cycle.endDate.year}_${cycle.endDate.month}';

        if (amount == newSub.monthlyBudget) {
          // Same as base → remove override
          await repo.deleteEntry(groupId, entryId);
        } else {
          final entry = BudgetEntry(
            id: entryId,
            subCategoryId: newSub.id,
            year: cycle.endDate.year,
            month: cycle.endDate.month,
            amount: amount,
          );
          await repo.setEntry(groupId, entry);
        }
      }
      // Force refresh of the balance footer
      ref.invalidate(zeroBudgetBalanceProvider);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final sub = widget.subCategory;
    if (sub == null) return;

    final groupId = ref.read(currentGroupIdProvider).valueOrNull;
    if (groupId == null) return;

    // Check if used in transactions
    final repo = ref.read(transactionRepositoryProvider);
    final count = await repo.countBySubCategory(groupId, sub.id);

    if (!mounted) return;

    if (count > 0) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No es pot eliminar'),
          content: Text(
            'Aquesta subcategoria té $count moviments associats. Elimina els moviments primer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('D\'acord'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar subcategoria?'),
        content: Text(
          'Estàs segur que vols eliminar "${sub.name}"? Aquesta acció no es pot desfer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Remove from category
      final updatedSubcategories = List<SubCategory>.from(
        widget.category.subcategories,
      );
      updatedSubcategories.removeWhere((s) => s.id == sub.id);

      final updatedCategory = widget.category.copyWith(
        subcategories: updatedSubcategories,
      );

      await ref
          .read(categoryNotifierProvider.notifier)
          .updateCategory(updatedCategory);

      if (mounted) Navigator.pop(context);
    }
  }

  /// Executa el canvi de pare: dry-run → confirmació informada → moviment
  /// atòmic + reescriptura de l'històric amb progrés bloquejant.
  /// Retorna true si s'ha completat.
  Future<bool> _handleParentMove(SubCategory newSub) async {
    final categories = await ref.read(categoryNotifierProvider.future);
    if (!mounted) return false;

    final from = categories.firstWhere((c) => c.id == widget.category.id,
        orElse: () => widget.category);
    final toList = categories.where((c) => c.id == _targetParentId).toList();
    if (toList.isEmpty) return false;
    final to = toList.first;

    // Bloqueig dur: mai entre tipus diferents (canviaria la semàntica de tots
    // els moviments i generaria incoherències massives).
    if (to.type != from.type) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No es pot moure entre categories d\'ingrés i de despesa.'),
          ),
        );
      }
      return false;
    }

    final service = ref.read(subcategoryMoveServiceProvider);
    final report = await service.dryRun(
      from: from,
      to: to,
      sub: newSub,
    );
    if (!mounted) return false;

    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final df = DateFormat('dd/MM/yyyy');

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Moure de categoria'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('«${report.subCategoryName}» passarà de '
                  '«${report.fromName}» a «${report.toName}».'),
              const SizedBox(height: 12),
              if (report.transactionCount == 0)
                const Text('No hi ha moviments històrics a reclassificar.')
              else
                Text(
                  '${report.transactionCount} moviment'
                  '${report.transactionCount == 1 ? '' : 's'} · '
                  '${currency.format(report.totalAmount)} es reclassificaran'
                  '${report.firstDate != null ? '\n(${df.format(report.firstDate!)} – ${df.format(report.lastDate!)})' : ''}.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (report.hasLinks) ...[
                const SizedBox(height: 12),
                _warn(
                  report.linkedDebtId != null
                      ? 'Aquesta subcategoria està enllaçada a un DEUTE. '
                          'Moure-la NO desfà l\'enllaç: seguirà amortitzant-lo. '
                          'Si ja no és un deute, desvincula\'l a part.'
                      : 'Aquesta subcategoria està enllaçada a una GUARDIOLA. '
                          'Moure-la NO desfà l\'enllaç.',
                ),
              ],
              if (report.nameCollision) ...[
                const SizedBox(height: 12),
                _warn(
                  'Ja hi ha una subcategoria amb aquest nom a '
                  '«${report.toName}». Funcionarà (els ids són únics) però pot '
                  'confondre visualment.',
                ),
              ],
              if (report.staleReportCycles.isNotEmpty) ...[
                const SizedBox(height: 12),
                _warn(
                  '${report.staleReportCycles.length} informe'
                  '${report.staleReportCycles.length == 1 ? '' : 's'} de cicle '
                  'quedarà${report.staleReportCycles.length == 1 ? '' : 'n'} '
                  'obsolet${report.staleReportCycles.length == 1 ? '' : 's'} '
                  '(${report.staleReportCycles.join(', ')}). '
                  'Regenera\'ls quan acabi.',
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Moure'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    // Progrés BLOQUEJANT: la finestra en què les transaccions encara apunten al
    // pare vell ha de ser curta i no navegable.
    final progress = ValueNotifier<String>('Movent la subcategoria…');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: progress,
                  builder: (_, v, __) => Text(v),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await service.move(
        from: from,
        to: to,
        sub: newSub,
        onProgress: (done, total) {
          if (total > 0) {
            progress.value = 'Reclassificant moviments… $done/$total';
          }
        },
      );
      if (mounted) Navigator.pop(context); // tanca el progrés
      return true;
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error movent la subcategoria: $e')),
        );
      }
      return false;
    } finally {
      progress.dispose();
    }
  }

  Widget _warn(String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      );

  /// Selector de categoria pare. Només ofereix categories del MATEIX tipus
  /// (moure entre expense/income canviaria la semàntica de tots els moviments)
  /// i no arxivades. Canviar-lo mou la subcategoria conservant-ne l'id.
  Widget _buildParentSelector() {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    return categoriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (categories) {
        final options = categories
            .where((c) =>
                c.type == widget.category.type &&
                (!c.archived || c.id == widget.category.id))
            .toList();
        if (options.length < 2) return const SizedBox.shrink();

        final changed = _targetParentId != widget.category.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _targetParentId,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.drive_file_move_outline),
                  labelText: 'Categoria pare',
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
                items: options
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.icon} ${c.name}'),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _targetParentId = v ?? widget.category.id),
              ),
              if (changed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'En desar es reclassificaran els moviments històrics '
                          'd\'aquesta subcategoria.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(groupMembersProvider);
    final transactionsAsync = ref.watch(transactionNotifierProvider);

    double calculatedAverage = 0.0;
    if (widget.subCategory != null) {
      transactionsAsync.whenData((transactions) {
        final now = DateTime.now();

        // Recollim la despesa dels últims 3 mesos naturals (cicles tancats)
        final monthlySpending = <double>[];
        for (int i = 1; i <= 3; i++) {
          final monthStart = DateTime(now.year, now.month - i, 1);
          final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);

          final monthSum = transactions
              .where((t) =>
                  t.subCategoryId == widget.subCategory!.id &&
                  !t.isIncome &&
                  !t.date.isBefore(monthStart) &&
                  !t.date.isAfter(monthEnd))
              .fold<double>(0, (prev, t) => prev + t.amount);

          monthlySpending.add(monthSum);
        }

        // Filtre: ignora mesos amb despesa 0
        final nonZeroMonths = monthlySpending.where((s) => s > 0).toList();

        if (nonZeroMonths.isNotEmpty) {
          // Divisor dinàmic: només divideix pels mesos amb dades
          final sum = nonZeroMonths.fold<double>(0, (a, b) => a + b);
          calculatedAverage = sum / nonZeroMonths.length;
        } else {
          // Fallback: utilitza el pressupost del cicle anterior
          calculatedAverage = _fallbackBudget;
        }
      });
      // Si les transaccions encara no s'han carregat, fallback
      if (calculatedAverage == 0.0) {
        calculatedAverage = _fallbackBudget;
      }
      // Cas zero: si no hi ha ni historial ni pressupost previ, queda 0.0
    }

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
            if (widget.subCategory != null) _buildParentSelector(),
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
            if (widget.selectedCycle != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editant pressupost per ${widget.selectedCycle!.name}',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Center(
              child: Text(
                widget.selectedCycle != null
                    ? 'Pressupost per ${widget.selectedCycle!.name}'
                    : 'Pressupost Mensual Base',
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
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (widget.subCategory != null && calculatedAverage > 0) ...[
              const SizedBox(height: 12),
              Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _amountController.text =
                            calculatedAverage.toStringAsFixed(0);
                      });
                    },
                    icon: const Icon(Icons.auto_awesome,
                        size: 16, color: Colors.purple),
                    label: Text(
                        'Mitjana: ${calculatedAverage.toStringAsFixed(0)} €',
                        style: const TextStyle(
                            color: Colors.purple, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.purple),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if ((parseEditableAmount(_amountController.text) ?? 0) <
                          calculatedAverage * 0.75 &&
                      (parseEditableAmount(_amountController.text) ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Compte, la teva mitjana és bastant superior',
                        style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ],
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
                  if (widget.subCategory != null) ...[
                    SwitchListTile(
                      title: const Text(
                        '📦 Arxivar Subcategoria',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'S\'amagarà de l\'editor de pressupost i selectors actius, conservant la història.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _archived,
                      onChanged: (val) => setState(() => _archived = val),
                      activeTrackColor: Colors.orange,
                    ),
                    const Divider(),
                  ],
                  SwitchListTile(
                    title: const Text(
                      '👁 Vigilar al Dashboard',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Mostrar la barra de progrés a la pantalla Inici',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _isWatched,
                    onChanged: (val) => setState(() => _isWatched = val),
                    activeTrackColor: Colors.orange,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(
                      widget.category.type == TransactionType.income
                          ? 'És un ingrés fix?'
                          : 'És una despesa fixa?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      widget.category.type == TransactionType.income
                          ? 'Nòmina, Lloguer cobrat, Subscripcions...'
                          : 'Lloguer, Gimnàs, Subscripcions...',
                      style: const TextStyle(fontSize: 12),
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
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  SwitchListTile(
                    title: Text(
                      widget.category.type == TransactionType.income
                          ? 'Vincular a una guardiola'
                          : 'Vincular pagament a...',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      widget.category.type == TransactionType.income
                          ? 'L\'ingrés es restarà automàticament de la guardiola'
                          : 'En pagar, aporta a guardiola o paga deute',
                      style: const TextStyle(fontSize: 12),
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

                        // Only show debts for expense categories
                        if (widget.category.type != TransactionType.income) {
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
                        }

                        // Compute current value from state
                        String? currentValue;
                        if (_linkedSavingsGoalId != null) {
                          currentValue = 'goal:$_linkedSavingsGoalId';
                        } else if (_linkedDebtId != null) {
                          currentValue = 'debt:$_linkedDebtId';
                        }

                        // Validate the value exists in items
                        if (currentValue != null &&
                            !items.any((i) => i.value == currentValue)) {
                          currentValue = null;
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: currentValue,
                          decoration: InputDecoration(
                            labelText:
                                widget.category.type == TransactionType.income
                                    ? 'Selecciona Guardiola'
                                    : 'Destí del pagament',
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
                    decoration: const BoxDecoration(
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
            if (widget.subCategory != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Eliminar Subcategoria',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
