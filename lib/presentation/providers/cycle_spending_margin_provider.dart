import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/billing_cycle.dart';
import '../../domain/models/category.dart';
import 'billing_cycle_provider.dart';
import 'budget_provider.dart';
import 'cash_flow_provider.dart';

/// Projecció de caixa fins al final del cicle.
///
/// No classifica ni suma transaccions: consumeix els [BudgetStatus] que ja ha
/// calculat `budget_provider` amb el ledger canònic, i el pot líquid que
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

  const CyclePendingItem({
    required this.name,
    required this.amount,
  });
}

final cycleSpendingMarginProvider = Provider<CycleSpendingMargin?>((ref) {
  final statuses = ref.watch(budgetNotifierProvider).valueOrNull;
  final cashFlow = ref.watch(cashFlowStatusProvider);
  final currentPot = ref.watch(currentPotProvider);
  if (statuses == null || cashFlow == null || currentPot == null) return null;

  final cycle = ref.watch(activeCycleProvider);
  final currentCycle = ref.watch(currentCycleProvider);

  return calculateCycleSpendingMargin(
    availableNow: currentPot,
    statuses: statuses,
    cycle: cycle,
    today: DateTime.now(),
    hasOpeningBalance: cashFlow.openingBalance != null,
    isCurrentCycle: cycle.id == currentCycle.id,
  );
});

CycleSpendingMargin calculateCycleSpendingMargin({
  required double availableNow,
  required List<BudgetStatus> statuses,
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

      if (!sub.isFixed) continue;
      final paymentDate = scheduledPaymentDate(sub, cycle);
      if (paymentDate == null ||
          !paymentDate.isAfter(todayDay) ||
          paymentDate.isAfter(cycleEnd)) {
        continue;
      }

      // Si ja s'ha pagat abans del dia previst, no el reservem dues vegades.
      final pending =
          (subStatus.budget - subStatus.spent).clamp(0.0, double.infinity);
      pendingFixedExpenses += pending;
      if (pending > 0) {
        pendingFixedExpenseItems.add(
          CyclePendingItem(name: sub.name, amount: pending),
        );
      }
    }
  }

  pendingIncomeItems.sort((a, b) => b.amount.compareTo(a.amount));
  pendingFixedExpenseItems.sort((a, b) => b.amount.compareTo(a.amount));

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

/// Data prevista dins del mes pressupostari del cicle.
///
/// Respecta també els dos modes de dia laborable que ja ofereix l'editor de
/// subcategories. Un dia 31 en un mes més curt es clampa al darrer dia.
DateTime? scheduledPaymentDate(
  SubCategory subcategory,
  BillingCycle cycle,
) {
  final budgetMonth = budgetMonthForCycle(cycle);
  final firstDay = DateTime(budgetMonth.year, budgetMonth.month, 1);
  final lastDay = DateTime(budgetMonth.year, budgetMonth.month + 1, 0);

  switch (subcategory.paymentTiming) {
    case PaymentTiming.specificDay:
      final paymentDay = subcategory.paymentDay;
      if (paymentDay == null) return null;
      final clampedDay = paymentDay.clamp(1, lastDay.day);
      return DateTime(budgetMonth.year, budgetMonth.month, clampedDay);
    case PaymentTiming.firstBusinessDay:
      var day = firstDay;
      while (
          day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        day = day.add(const Duration(days: 1));
      }
      return day;
    case PaymentTiming.lastBusinessDay:
      var day = lastDay;
      while (
          day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        day = day.subtract(const Duration(days: 1));
      }
      return day;
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
