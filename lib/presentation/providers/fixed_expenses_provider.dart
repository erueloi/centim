import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/billing_cycle.dart';
import '../../domain/models/category.dart';
import '../../domain/models/savings_goal.dart';
import '../../domain/services/ledger_service.dart';
import 'billing_cycle_provider.dart';
import 'budget_provider.dart';
import 'savings_goal_provider.dart';

part 'fixed_expenses_provider.g.dart';

/// Font compartida entre la pestanya Fixes i la projecció de marge.
/// `null` vol dir que encara falten dades; una llista buida vol dir que tot
/// està realment cobert.
final fixedExpenseObligationsProvider =
    Provider.autoDispose<List<FixedExpenseItem>?>((ref) {
  final statuses = ref.watch(budgetNotifierProvider).valueOrNull;
  final ledger = ref.watch(activeCycleLedgerSummaryProvider).valueOrNull;
  final goals = ref.watch(savingsGoalNotifierProvider).valueOrNull;
  if (statuses == null || ledger == null || goals == null) return null;

  return calculateFixedExpenseItems(
    statuses: statuses,
    ledger: ledger,
    goals: goals,
    cycle: ref.watch(activeCycleProvider),
    today: DateTime.now(),
  );
});

@riverpod
List<FixedExpenseItem> fixedExpenses(Ref ref) {
  return ref.watch(fixedExpenseObligationsProvider) ?? const [];
}

class FixedExpenseItem {
  final SubCategory subCategory;
  final Category category;
  final double budget;
  final double executed;
  final double remaining;
  final DateTime? scheduledDate;
  final bool isOverdue;
  final bool affectsPot;

  const FixedExpenseItem({
    required this.subCategory,
    required this.category,
    required this.budget,
    required this.executed,
    required this.remaining,
    required this.scheduledDate,
    required this.isOverdue,
    required this.affectsPot,
  });

  double get covered => executed.clamp(0.0, budget);
}

/// Calcula només obligacions amb import pendent. La data classifica l'estat,
/// però mai fa desaparèixer un fix no cobert.
List<FixedExpenseItem> calculateFixedExpenseItems({
  required List<BudgetStatus> statuses,
  required LedgerSummary ledger,
  required List<SavingsGoal> goals,
  required BillingCycle cycle,
  required DateTime today,
}) {
  const zeroTolerance = 0.005;
  final goalById = {for (final goal in goals) goal.id: goal};
  final todayDay = _dateOnly(today);
  final result = <FixedExpenseItem>[];

  for (final status in statuses) {
    for (final subStatus in status.subcategoryStatuses) {
      final subcategory = subStatus.subcategory;
      if (!subcategory.isFixed || subStatus.budget <= zeroTolerance) continue;

      final goalId = subcategory.linkedSavingsGoalId;
      final isSavings = goalId != null;
      final executed = isSavings
          ? status.category.type == TransactionType.income
              ? ledger.withdrawnBySubcategory[subcategory.id] ?? 0
              : ledger.savedBySubcategory[subcategory.id] ?? 0
          : subStatus.spent;
      final remaining =
          (subStatus.budget - executed).clamp(0.0, double.infinity);
      final coverageTolerance =
          subStatus.budget * 0.01 > 1.0 ? subStatus.budget * 0.01 : 1.0;
      if (remaining < coverageTolerance) continue;

      final scheduledDate = scheduledPaymentDate(subcategory, cycle);
      final isOverdue =
          scheduledDate != null && scheduledDate.isBefore(todayDay);
      final savingsGoal = goalId == null ? null : goalById[goalId];
      final affectsPot = status.category.type == TransactionType.expense &&
          (!isSavings || savingsGoal?.isLiquid == false);

      result.add(
        FixedExpenseItem(
          subCategory: subcategory,
          category: status.category,
          budget: subStatus.budget,
          executed: executed,
          remaining: remaining,
          scheduledDate: scheduledDate,
          isOverdue: isOverdue,
          affectsPot: affectsPot,
        ),
      );
    }
  }

  result.sort((a, b) {
    if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
    final aDate = a.scheduledDate;
    final bDate = b.scheduledDate;
    if (aDate == null && bDate != null) return 1;
    if (aDate != null && bDate == null) return -1;
    if (aDate != null && bDate != null) {
      final byDate = aDate.compareTo(bDate);
      if (byDate != 0) return byDate;
    }
    return b.remaining.compareTo(a.remaining);
  });
  return List.unmodifiable(result);
}

/// Resol l'ocurrència de pagament que pertany al cicle. Es parteix del mes
/// pressupostari (`cycle.endDate`) i, si cau fora, es prova el mes adjacent.
DateTime? scheduledPaymentDate(
  SubCategory subcategory,
  BillingCycle cycle,
) {
  final budgetMonth = budgetMonthForCycle(cycle);
  final start = _dateOnly(cycle.startDate);
  final end = _dateOnly(cycle.endDate);
  final primary = _scheduledDateForMonth(subcategory, budgetMonth);
  if (primary == null) return null;
  if (_isWithin(primary, start, end)) return primary;

  final adjacentMonth = primary.isAfter(end)
      ? DateTime(budgetMonth.year, budgetMonth.month - 1)
      : DateTime(budgetMonth.year, budgetMonth.month + 1);
  final adjacent = _scheduledDateForMonth(subcategory, adjacentMonth);
  return adjacent != null && _isWithin(adjacent, start, end) ? adjacent : null;
}

DateTime? _scheduledDateForMonth(
  SubCategory subcategory,
  DateTime month,
) {
  final firstDay = DateTime(month.year, month.month, 1);
  final lastDay = DateTime(month.year, month.month + 1, 0);

  switch (subcategory.paymentTiming) {
    case PaymentTiming.specificDay:
      final paymentDay = subcategory.paymentDay;
      if (paymentDay == null) return null;
      return DateTime(
        month.year,
        month.month,
        paymentDay.clamp(1, lastDay.day),
      );
    case PaymentTiming.firstBusinessDay:
      var day = firstDay;
      while (_isWeekend(day)) {
        day = day.add(const Duration(days: 1));
      }
      return day;
    case PaymentTiming.lastBusinessDay:
      var day = lastDay;
      while (_isWeekend(day)) {
        day = day.subtract(const Duration(days: 1));
      }
      return day;
  }
}

bool _isWithin(DateTime value, DateTime start, DateTime end) =>
    !value.isBefore(start) && !value.isAfter(end);

bool _isWeekend(DateTime value) =>
    value.weekday == DateTime.saturday || value.weekday == DateTime.sunday;

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
