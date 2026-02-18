import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/debt_account.dart';
import '../../domain/models/asset.dart';
import '../../domain/models/savings_goal.dart';
import '../providers/debt_provider.dart';
import '../providers/asset_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../providers/auth_providers.dart';

enum WealthType { asset, debt, goal }

class WealthSheet extends ConsumerStatefulWidget {
  final DebtAccount? initialDebt; // If editing a debt
  final Asset? initialAsset; // If editing an asset
  final WealthType initialType;

  const WealthSheet({
    super.key,
    this.initialDebt,
    this.initialAsset,
    this.initialType = WealthType.asset,
  });

  @override
  ConsumerState<WealthSheet> createState() => _WealthSheetState();
}

class _WealthSheetState extends ConsumerState<WealthSheet> {
  var _selectedType = WealthType.debt;
  final _nameController = TextEditingController();
  bool _isLoading = false;

  // Debt Fields
  final _bankController = TextEditingController();
  final _interestController = TextEditingController();
  final _pendingController =
      TextEditingController(); // Capital Pendent / Current Balance
  final _originalController = TextEditingController(); // Import Inicial
  final _installmentController = TextEditingController();

  DateTime? _maturityDate;

  // Asset Fields
  final _assetValueController = TextEditingController();
  String _assetType = 'Altres'; // 'Immobiliari', 'Compte Bancari', 'Altres'

  String? _selectedBankOption; // 'CaixaBank', 'ING', 'Targeta YOU', 'Altres'

  // Goal Fields
  final _goalIconController = TextEditingController(text: '💰');
  final _goalTargetController = TextEditingController();
  Color _goalColor = Colors.green;
  bool _goalHasTarget = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialDebt != null) {
      _selectedType = WealthType.debt;
      _nameController.text = widget.initialDebt!.name;

      final bank = widget.initialDebt!.bankName;
      if (['CaixaBank', 'ING', 'Targeta YOU'].contains(bank)) {
        _selectedBankOption = bank;
        _bankController.text = bank!;
      } else if (bank != null && bank.isNotEmpty) {
        _selectedBankOption = 'Altres';
        _bankController.text = bank;
      } else {
        _selectedBankOption = null;
      }

      _interestController.text = widget.initialDebt!.interestRate.toString();
      _pendingController.text = widget.initialDebt!.currentBalance.toString();
      _originalController.text = widget.initialDebt!.originalAmount.toString();
      _installmentController.text = widget.initialDebt!.monthlyInstallment
          .toString();
      _maturityDate = widget.initialDebt!.endDate;
    } else if (widget.initialAsset != null) {
      _selectedType = WealthType.asset;
      _nameController.text = widget.initialAsset!.name;
      _assetValueController.text = widget.initialAsset!.amount.toString();

      switch (widget.initialAsset!.type) {
        case AssetType.realEstate:
          _assetType = 'Immobiliari';
          break;
        case AssetType.bankAccount:
          _assetType = 'Compte Bancari';
          break;
        case AssetType.cash:
          _assetType = 'Efectiu';
          break;
        case AssetType.other:
          _assetType = 'Altres';
          break;
      }

      if (widget.initialAsset!.bankName != null) {
        _bankController.text = widget.initialAsset!.bankName!;
      }
    } else {
      _selectedType = widget.initialType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    _interestController.dispose();
    _pendingController.dispose();
    _originalController.dispose();
    _installmentController.dispose();
    _assetValueController.dispose();
    _goalIconController.dispose();
    _goalTargetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El nom és obligatori')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_selectedType == WealthType.debt) {
        await _saveDebt();
      } else if (_selectedType == WealthType.asset) {
        await _saveAsset();
      } else {
        await _saveGoal();
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

  Future<void> _saveDebt() async {
    final currentBalance =
        double.tryParse(_pendingController.text.replaceAll(',', '.')) ?? 0.0;
    final originalAmount =
        double.tryParse(_originalController.text.replaceAll(',', '.')) ?? 0.0;
    final interestRate =
        double.tryParse(_interestController.text.replaceAll(',', '.')) ?? 0.0;
    // Add monthly installment
    final monthlyInstallment =
        double.tryParse(_installmentController.text.replaceAll(',', '.')) ??
        0.0;

    final newDebt =
        widget.initialDebt?.copyWith(
          name: _nameController.text,
          bankName: _bankController.text.isEmpty ? null : _bankController.text,
          currentBalance: currentBalance,
          originalAmount: originalAmount,
          interestRate: interestRate,
          monthlyInstallment: monthlyInstallment,
          endDate: _maturityDate,
        ) ??
        DebtAccount(
          id: const Uuid().v4(),
          name: _nameController.text,
          bankName: _bankController.text.isEmpty ? null : _bankController.text,
          currentBalance: currentBalance,
          originalAmount: originalAmount,
          interestRate: interestRate,
          monthlyInstallment: monthlyInstallment,
          endDate: _maturityDate,
        );

    if (widget.initialDebt == null) {
      await ref.read(debtNotifierProvider.notifier).addDebt(newDebt);
    } else {
      await ref.read(debtNotifierProvider.notifier).updateDebt(newDebt);
    }
  }

  Future<void> _saveAsset() async {
    final amount =
        double.tryParse(_assetValueController.text.replaceAll(',', '.')) ?? 0.0;

    AssetType type = AssetType.other;
    if (_assetType == 'Immobiliari') {
      type = AssetType.realEstate;
    } else if (_assetType == 'Compte Bancari') {
      type = AssetType.bankAccount;
    } else if (_assetType == 'Efectiu') {
      type = AssetType.cash;
    }

    final newAsset =
        widget.initialAsset?.copyWith(
          name: _nameController.text,
          amount: amount,
          type: type,
          bankName:
              type == AssetType.bankAccount && _bankController.text.isNotEmpty
              ? _bankController.text
              : null,
        ) ??
        Asset(
          id: const Uuid().v4(),
          name: _nameController.text,
          amount: amount,
          type: type,
          // If we wanted to store bank name for assets (like bank accounts), we could use _bankController.text
          // But adhering to strict request, keeping it simple.
          // Actually, if type is bankAccount, it might be nice.
          // But let's stick to the generated Asset model which has bankName.
          bankName:
              type == AssetType.bankAccount && _bankController.text.isNotEmpty
              ? _bankController.text
              : null,
        );

    if (widget.initialAsset == null) {
      await ref.read(assetNotifierProvider.notifier).addAsset(newAsset);
    } else {
      await ref.read(assetNotifierProvider.notifier).updateAsset(newAsset);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveGoal() async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;

    final targetAmount = _goalHasTarget
        ? double.tryParse(_goalTargetController.text.replaceAll(',', '.'))
        : null;

    final newGoal = SavingsGoal(
      id: '',
      groupId: groupId,
      name: _nameController.text,
      icon: _goalIconController.text,
      currentAmount: 0.0,
      targetAmount: targetAmount,
      color: _goalColor.toARGB32(),
      history: [],
    );
    await ref
        .read(savingsGoalNotifierProvider.notifier)
        .addSavingsGoal(newGoal);
  }

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // --- SELECTOR ---
                    Center(
                      child: SegmentedButton<WealthType>(
                        segments: const [
                          ButtonSegment(
                            value: WealthType.asset,
                            label: Text('Actiu'),
                            icon: Icon(Icons.account_balance),
                          ),
                          ButtonSegment(
                            value: WealthType.debt,
                            label: Text('Deute'),
                            icon: Icon(Icons.credit_card),
                          ),
                          ButtonSegment(
                            value: WealthType.goal,
                            label: Text('Objectiu'),
                            icon: Icon(Icons.savings),
                          ),
                        ],
                        selected: {_selectedType},
                        onSelectionChanged: (v) =>
                            setState(() => _selectedType = v.first),
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  if (_selectedType == WealthType.asset) {
                                    return Colors.green.withValues(alpha: 0.2);
                                  } else if (_selectedType == WealthType.debt) {
                                    return Colors.red.withValues(alpha: 0.2);
                                  } else {
                                    return AppTheme.copper.withValues(
                                      alpha: 0.2,
                                    );
                                  }
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

                    // --- COMMON NAME ---
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Nom',
                        hintText: _selectedType == WealthType.asset
                            ? 'ex: Masia, Fons Indexat'
                            : _selectedType == WealthType.debt
                            ? 'ex: Hipoteca, Préstec Cotxe'
                            : 'ex: Viatge a Japó, Fons Emergència',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.label_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_selectedType == WealthType.debt) ...[
                      // --- DEBT FIELDS ---
                      // Bank Selector
                      Text(
                        'Entitat Bancària',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: ['CaixaBank', 'ING', 'Targeta YOU', 'Altres']
                            .map((bank) {
                              final isSelected = _selectedBankOption == bank;
                              return ChoiceChip(
                                label: Text(bank),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedBankOption = bank;
                                      if (bank != 'Altres') {
                                        _bankController.text = bank;
                                      } else {
                                        _bankController.text = '';
                                      }
                                    });
                                  }
                                },
                                selectedColor: AppTheme.copper.withValues(
                                  alpha: 0.2,
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppTheme.copper
                                      : AppTheme.anthracite,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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
                            })
                            .toList(),
                      ),
                      const SizedBox(height: 16),

                      if (_selectedBankOption == 'Altres') ...[
                        TextField(
                          controller: _bankController,
                          decoration: InputDecoration(
                            labelText: 'Nom del Banc',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.edit),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Pending & Original Amount
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _originalController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'Import Inicial',
                                suffixText: '€',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _pendingController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'Pendent',
                                suffixText: '€',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Interest & Monthly Quota
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _interestController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'Interès',
                                suffixText: '%',
                                suffixIcon: const Icon(Icons.percent, size: 20),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _installmentController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'Quota Mensual',
                                suffixText: '€',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Maturity Date
                      ListTile(
                        title: Text(
                          _maturityDate == null
                              ? 'Data de Venciment'
                              : 'Venciment: ${_maturityDate!.day}/${_maturityDate!.month}/${_maturityDate!.year}',
                        ),
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: const Icon(
                          Icons.calendar_today,
                          color: AppTheme.anthracite,
                        ),
                        trailing: _maturityDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    setState(() => _maturityDate = null),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate:
                                _maturityDate ??
                                DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2060),
                          );
                          if (d != null) setState(() => _maturityDate = d);
                        },
                      ),
                    ] else if (_selectedType == WealthType.asset) ...[
                      // --- ASSET FIELDS ---
                      // "Valoració actual", "Tipus"
                      TextField(
                        controller: _assetValueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.anthracite,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'Valoració Actual',
                          prefixText: '€ ',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Tipus d\'Actiu',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        children:
                            [
                              'Immobiliari',
                              'Compte Bancari',
                              'Efectiu',
                              'Altres',
                            ].map((type) {
                              final isSelected = _assetType == type;
                              return ChoiceChip(
                                label: Text(type),
                                selected: isSelected,
                                onSelected: (v) =>
                                    setState(() => _assetType = type),
                                selectedColor: Colors.green.withValues(
                                  alpha: 0.2,
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.green[900]
                                      : AppTheme.anthracite,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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
                    if (_selectedType == WealthType.goal) ...[
                      // --- GOAL FIELDS ---
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _goalIconController,
                              decoration: InputDecoration(
                                labelText: 'Icona (Emoji)',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              maxLength: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Tria un color'),
                                  content: SingleChildScrollView(
                                    child: BlockPicker(
                                      pickerColor: _goalColor,
                                      onColorChanged: (color) {
                                        setState(() => _goalColor = color);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _goalColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Té un import objectiu?'),
                        value: _goalHasTarget,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) =>
                            setState(() => _goalHasTarget = value),
                      ),
                      if (_goalHasTarget)
                        TextField(
                          controller: _goalTargetController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Import Objectiu',
                            prefixText: '€ ',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                    ],
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
                      backgroundColor: _selectedType == WealthType.asset
                          ? Colors.green
                          : _selectedType == WealthType.debt
                          ? AppTheme.anthracite
                          : AppTheme.copper,
                      foregroundColor: Colors.white,
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
            ],
          ),
        );
      },
    );
  }
}
