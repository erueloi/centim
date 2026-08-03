import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/billing_cycle.dart';
import '../../domain/models/category.dart';
import 'billing_cycle_provider.dart';
import 'budget_provider.dart';
import 'cash_flow_provider.dart';
import 'fixed_expenses_provider.dart';

/// Projecció de caixa fins al final del cicle.
///
/// No classifica ni suma transaccions: consumeix els [BudgetStatus], les
/// obligacions fixes ja resoltes per import i el pot líquid que
/// `cash_flow_service` exposa a través de [currentPotProvider].
class CycleSpendingMargin {
  final double availableNow;
  final double pendingIncome;
  final List<CyclePendingItem> pendingIncomeItems;
  final double pendingFixedExpenses;
  final List<CyclePendingItem> pendingFixedExpenseItems;
  final double margin;
  final double budgetDeviation;
  final int daysRemaining;
  final bool hasOpeningBalance;
  final bool isCurrentCycle;

  const CycleSpendingMargin({
    required this.availableNow,
    required this.pendingIncome,
    required this.pendingIncomeItems,
    required this.pendingFixedExpenses,
    required this.pendingFixedExpenseItems,
    required this.margin,
    required this.budgetDeviation,
    required this.daysRemaining,
    required this.hasOpeningBalance,
    required this.isCurrentCycle,
  });

  double? get perDay => daysRemaining > 0 ? margin / daysRemaining : null;
}

class CyclePendingItem {
  final String name;
  final double amount;
  final bool isOverdue;

  const CyclePendingItem({
    required this.name,
    required this.amount,
    this.isOverdue = false,
  });
}

final cycleSpendingMarginProvider = Provider<CycleSpendingMargin?>((ref) {
  final statuses = ref.watch(budgetNotifierProvider).valueOrNull;
  final cashFlow = ref.watch(cashFlowStatusProvider);
  final currentPot = ref.watch(currentPotProvider);
  final fixedExpenses = ref.watch(fixedExpenseObligationsProvider);
  if (statuses == null ||
      cashFlow == null ||
      currentPot == null ||
      fixedExpenses == null) {
    return null;
  }

  final cycle = ref.watch(activeCycleProvider);
  final currentCycle = ref.watch(currentCycleProvider);

  return calculateCycleSpendingMargin(
    availableNow: currentPot,
    statuses: statuses,
    fixedExpenses: fixedExpenses,
    cycle: cycle,
    today: DateTime.now(),
    hasOpeningBalance: cashFlow.openingBalance != null,
    isCurrentCycle: cycle.id == currentCycle.id,
  );
});

CycleSpendingMargin calculateCycleSpendingMargin({
  required double availableNow,
  required List<BudgetStatus> statuses,
  required List<FixedExpenseItem> fixedExpenses,
  required BillingCycle cycle,
  required DateTime today,
  required bool hasOpeningBalance,
  required bool isCurrentCycle,
}) {
  var pendingIncome = 0.0;
  var pendingFixedExpenses = 0.0;
  final pendingIncomeItems = <CyclePendingItem>[];
  final pendingFixedExpenseItems = <CyclePendingItem>[];
  var expenseBudget = 0.0;
  var expenseSpent = 0.0;

  final todayDay = _dateOnly(today);
  final cycleEnd = _dateOnly(cycle.endDate);

  for (final status in statuses) {
    for (final subStatus in status.subcategoryStatuses) {
      final sub = subStatus.subcategory;

      // Els moviments de guardiola no són ingrés/despesa del pot. El ledger
      // ja els exclou de l'executat; també els excloem de la projecció perquè
      // un pressupost de retirada no sembli caixa externa pendent.
      if (sub.linkedSavingsGoalId != null) continue;

      if (status.category.type == TransactionType.income) {
        final pending =
            (subStatus.budget - subStatus.spent).clamp(0.0, double.infinity);
        pendingIncome += pending;
        if (pending > 0) {
          pendingIncomeItems.add(
            CyclePendingItem(name: sub.name, amount: pending),
          );
        }
        continue;
      }

      expenseBudget += subStatus.budget;
      expenseSpent += subStatus.spent;
    }
  }

  // La data només etiqueta vençut/per venir. L'import pendent prové de la
  // mateixa obligació que consumeix la pestanya Fixes i no desapareix fins que
  // queda cobert. Les guardioles líquides i els ingressos no afecten el pot.
  for (final item in fixedExpenses.where((item) => item.affectsPot)) {
    pendingFixedExpenses += item.remaining;
    pendingFixedExpenseItems.add(
      CyclePendingItem(
        name: item.subCategory.name,
        amount: item.remaining,
        isOverdue: item.isOverdue,
      ),
    );
  }

  pendingIncomeItems.sort((a, b) => b.amount.compareTo(a.amount));
  pendingFixedExpenseItems.sort((a, b) {
    if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
    return b.amount.compareTo(a.amount);
  });

  final daysRemaining =
      cycleEnd.isAfter(todayDay) ? cycleEnd.difference(todayDay).inDays : 0;
  final margin = availableNow + pendingIncome - pendingFixedExpenses;

  return CycleSpendingMargin(
    availableNow: availableNow,
    pendingIncome: pendingIncome,
    pendingIncomeItems: List.unmodifiable(pendingIncomeItems),
    pendingFixedExpenses: pendingFixedExpenses,
    pendingFixedExpenseItems: List.unmodifiable(pendingFixedExpenseItems),
    margin: margin,
    budgetDeviation: expenseSpent - expenseBudget,
    daysRemaining: daysRemaining,
    hasOpeningBalance: hasOpeningBalance,
    isCurrentCycle: isCurrentCycle,
  );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
