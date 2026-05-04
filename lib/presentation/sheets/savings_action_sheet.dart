import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:centim/l10n/app_localizations.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/asset.dart';
import '../../domain/models/savings_goal.dart';
import '../../domain/models/transaction.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_providers.dart';
import '../providers/category_notifier.dart';

import '../providers/transaction_notifier.dart';
import '../providers/savings_goal_provider.dart';

enum SavingsActionType { contribute, withdraw, adjust }

class SavingsActionSheet extends ConsumerStatefulWidget {
  final SavingsGoal goal;
  final SavingsActionType actionType;

  const SavingsActionSheet({
    super.key,
    required this.goal,
    required this.actionType,
  });

  @override
  ConsumerState<SavingsActionSheet> createState() => _SavingsActionSheetState();
}

class _SavingsActionSheetState extends ConsumerState<SavingsActionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedAccountId;
  bool _isLoading = false;

  bool get _isContribute => widget.actionType == SavingsActionType.contribute;
  bool get _isWithdraw => widget.actionType == SavingsActionType.withdraw;
  bool get _isAdjust => widget.actionType == SavingsActionType.adjust;

  @override
  void initState() {
    super.initState();
    if (_isAdjust) {
      _amountController.text =
          widget.goal.currentAmount.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.'));

    if (amount == null || (_isAdjust ? amount < 0 : amount <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nameRequired)),
      );
      return;
    }

    if (_isWithdraw && amount > widget.goal.currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.insufficientFunds),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isAdjust) {
        await _doAdjust(amount);
      } else {
        await _doContributeOrWithdraw(amount);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _doAdjust(double newAmount) async {
    await ref
        .read(savingsGoalNotifierProvider.notifier)
        .adjustBalance(widget.goal.id, newAmount);
  }

  Future<void> _doContributeOrWithdraw(double amount) async {
    final l10n = AppLocalizations.of(context)!;
    final categories = await ref.read(categoryNotifierProvider.future);
    final userProfile = ref.read(userProfileProvider).valueOrNull;
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;

    // Resolve linked category/subcategory
    String resolvedCategoryId = _isContribute ? 'expense_savings' : 'income_savings';
    String resolvedSubCategoryId = _isContribute ? 'contribution' : 'withdrawal';
    String resolvedCategoryName = 'Estalvi';
    String resolvedSubCategoryName = _isContribute ? l10n.contributionLabel : l10n.withdrawFunds;

    for (var cat in categories) {
      for (var sub in cat.subcategories) {
        if (sub.linkedSavingsGoalId == widget.goal.id) {
          resolvedCategoryId = cat.id;
          resolvedSubCategoryId = sub.id;
          resolvedCategoryName = cat.name;
          resolvedSubCategoryName = sub.name;
          break;
        }
      }
    }

    final payer =
        userProfile?.name ?? userProfile?.email.split('@').first ?? 'User';

    final concept = _noteController.text.isNotEmpty
        ? _noteController.text
        : _isContribute
            ? '${l10n.contributionLabel} a ${widget.goal.name}'
            : '${l10n.withdrawFunds} de ${widget.goal.name}';

    final transaction = Transaction(
      groupId: groupId,
      date: _selectedDate,
      amount: amount,
      concept: concept,
      categoryId: resolvedCategoryId,
      subCategoryId: resolvedSubCategoryId,
      categoryName: resolvedCategoryName,
      subCategoryName: resolvedSubCategoryName,
      payer: payer,
      isIncome: _isWithdraw,
      savingsGoalId: null,
      accountId: _selectedAccountId,
    );

    await ref
        .read(transactionNotifierProvider.notifier)
        .addTransaction(transaction);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goalColor = Color(widget.goal.color);

    String title;
    IconData titleIcon;
    Color accentColor;

    if (_isContribute) {
      title = l10n.contributeTitle;
      titleIcon = Icons.add_circle_outline;
      accentColor = goalColor;
    } else if (_isWithdraw) {
      title = l10n.withdrawTitle;
      titleIcon = Icons.output;
      accentColor = AppTheme.copper;
    } else {
      title = l10n.adjustBalance;
      titleIcon = Icons.balance;
      accentColor = AppTheme.copper;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                  children: [
                    // --- HEADER ---
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(titleIcon, color: accentColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${widget.goal.icon} ${widget.goal.name}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isAdjust)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: goalColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.goal.currentAmount.toStringAsFixed(2)} €',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: goalColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- AMOUNT INPUT ---
                    Center(
                      child: IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                          textAlign: TextAlign.center,
                          autofocus: true,
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
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
                                  color: accentColor,
                                ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: '0,00',
                            hintStyle: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                          ),
                        ),
                      ),
                    ),

                    if (_isAdjust)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            l10n.adjustBalanceHint,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // --- NOTE (not for adjust) ---
                    if (!_isAdjust) ...[
                      TextField(
                        controller: _noteController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: l10n.savingsNotePlaceholder,
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
                            borderSide: BorderSide(
                              color: accentColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- DATE PICKER ---
                      ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: const Icon(
                          Icons.calendar_today,
                          color: AppTheme.anthracite,
                        ),
                        title: Text(
                          DateUtils.isSameDay(_selectedDate, DateTime.now())
                              ? l10n.today
                              : DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() => _selectedDate = d);
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- ACCOUNT SELECTOR (withdraw only) ---
                      if (_isWithdraw) ...[
                        Text(
                          l10n.accountLabel,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Consumer(
                          builder: (context, ref, _) {
                            final assetsAsync =
                                ref.watch(assetNotifierProvider);
                            return assetsAsync.when(
                              data: (assets) {
                                final liquidAssets = assets
                                    .where((a) =>
                                        a.type == AssetType.bankAccount ||
                                        a.type == AssetType.cash)
                                    .toList();
                                if (liquidAssets.isEmpty) {
                                  return Text(
                                    l10n.noAccountsAvailable,
                                    style: const TextStyle(color: Colors.grey),
                                  );
                                }
                                return DropdownButtonFormField<String>(
                                  initialValue: _selectedAccountId,
                                  decoration: InputDecoration(
                                    hintText: l10n.selectAccount,
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: const Icon(
                                      Icons.account_balance,
                                      color: Colors.grey,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(l10n.noAccount,
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                    ),
                                    ...liquidAssets.map((a) => DropdownMenuItem(
                                          value: a.id,
                                          child: Text(
                                            '${a.name} (${a.amount.toStringAsFixed(2)} €)'),
                                        )),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _selectedAccountId = v),
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) =>
                                  const Text('Error carregant comptes'),
                            );
                          },
                        ),
                      ],
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
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isAdjust
                                ? l10n.saveButton
                                : _isContribute
                                    ? l10n.contributeButton
                                    : l10n.withdrawFunds,
                            style: const TextStyle(
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
