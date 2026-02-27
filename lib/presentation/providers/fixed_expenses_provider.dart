import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/category.dart';
import 'category_notifier.dart';
import 'transaction_notifier.dart';
import 'billing_cycle_provider.dart';

part 'fixed_expenses_provider.g.dart';

@riverpod
List<FixedExpenseItem> fixedExpenses(Ref ref) {
  // Watch providers directly to trigger rebuilds on updates
  final categories = ref.watch(categoryNotifierProvider).valueOrNull ?? [];
  final transactions = ref.watch(transactionNotifierProvider).valueOrNull ?? [];

  final fixedItems = <FixedExpenseItem>[];

  // 1. Flatten and find parent
  for (final category in categories) {
    for (final sub in category.subcategories) {
      if (sub.isFixed) {
        fixedItems.add(FixedExpenseItem(sub, category));
      }
    }
  }

  // 2. Determine cycle range
  final cycle = ref.watch(activeCycleProvider);
  final startOfCycle = cycle.startDate;
  final endOfCycle = cycle.endDate;

  // 3. Filter transactions for the current cycle
  final thisMonthTransactions = transactions.where((t) {
    final tDay = DateTime(t.date.year, t.date.month, t.date.day, 12, 0, 0);
    final startDay = DateTime(
        startOfCycle.year, startOfCycle.month, startOfCycle.day, 12, 0, 0);
    final endDay =
        DateTime(endOfCycle.year, endOfCycle.month, endOfCycle.day, 12, 0, 0);

    return (tDay.isAtSameMomentAs(startDay) || tDay.isAfter(startDay)) &&
        tDay.isBefore(endDay);
  }).toList();

  // 4. Filter out subcategories that have already been paid
  final unpaidFixed = fixedItems.where((item) {
    final isPaid = thisMonthTransactions.any(
      (t) => t.subCategoryId == item.subCategory.id,
    );
    return !isPaid;
  }).toList();

  // 5. Sort by payment day (if available) -> Earlier dates first
  unpaidFixed.sort((a, b) {
    final dayA = a.subCategory.paymentDay ?? 31;
    final dayB = b.subCategory.paymentDay ?? 31;
    return dayA.compareTo(dayB);
  });

  return unpaidFixed;
}

class FixedExpenseItem {
  final SubCategory subCategory;
  final Category category;

  FixedExpenseItem(this.subCategory, this.category);
}
