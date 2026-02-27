import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/billing_cycle.dart';
import '../../data/providers/repository_providers.dart';
import 'auth_providers.dart';

part 'billing_cycle_provider.g.dart';

@riverpod
class BillingCycleNotifier extends _$BillingCycleNotifier {
  @override
  Stream<List<BillingCycle>> build() {
    return _watchCycles();
  }

  Stream<List<BillingCycle>> _watchCycles() async* {
    final groupId = await ref.watch(currentGroupIdProvider.future);
    if (groupId == null) {
      yield [];
      return;
    }
    final repo = ref.watch(billingCycleRepositoryProvider);
    yield* repo.watchBillingCycles(groupId);
  }

  Future<void> addBillingCycle(BillingCycle cycle) async {
    final repo = ref.read(billingCycleRepositoryProvider);
    await repo.addBillingCycle(cycle);
  }

  Future<void> updateBillingCycle(BillingCycle cycle) async {
    final repo = ref.read(billingCycleRepositoryProvider);
    await repo.updateBillingCycle(cycle);
  }

  Future<void> deleteBillingCycle(String cycleId) async {
    final repo = ref.read(billingCycleRepositoryProvider);
    await repo.deleteBillingCycle(cycleId);
  }

  Future<void> deleteAllCycles() async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;

    final repo = ref.read(billingCycleRepositoryProvider);
    final cycles = await repo.watchBillingCycles(groupId).first;

    if (cycles.isNotEmpty) {
      final ids = cycles.map((c) => c.id).toList();
      await repo.deleteBatchBillingCycles(ids);
    }
  }

  /// Configures the schedule for the next 12 months.
  /// 1. Updates ALL existing future cycles to start on [anchorDay] of the PREVIOUS month.
  ///    e.g. Month = "February", Start = Jan 28, End = Feb 27.
  /// 2. Generates missing cycles for the next 12 months using the same logic.
  Future<void> configureAnnualSchedule(int anchorDay) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;

    final repo = ref.read(billingCycleRepositoryProvider);
    final cycles = await repo.watchBillingCycles(groupId).first;
    final now = DateTime.now();

    // 1. UPDATE EXISTING FUTURE CYCLES
    // Filter future cycles (start date is after today)
    final futureCycles = cycles.where((c) => c.startDate.isAfter(now)).toList();

    // Track covered months (year * 100 + month) to know what to skip generation for
    // Uses the "End Date" month as the "Target Month"
    final coveredMonths = <int>{};

    for (final cycle in futureCycles) {
      // Use existing END DATE to determine the "Target Month"
      // e.g. If cycle ends in Feb, it's the Feb cycle.
      final targetDate = cycle.endDate;
      final targetYear = targetDate.year;
      final targetMonth = targetDate.month;

      coveredMonths.add(targetYear * 100 + targetMonth);

      // Start Date: Previous Month, Anchor Day
      // Handle Dec -> Jan transition for Previous Month
      var startMonth = targetMonth - 1;
      var startYear = targetYear;
      if (startMonth < 1) {
        startMonth = 12;
        startYear--;
      }

      final daysInStartMonth = DateTime(startYear, startMonth + 1, 0).day;
      final startDay =
          anchorDay > daysInStartMonth ? daysInStartMonth : anchorDay;
      final newStartDate = DateTime(startYear, startMonth, startDay, 12, 0, 0);

      // End Date: Target Month, Anchor Day, exact noon.
      final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
      final endDay =
          anchorDay > daysInTargetMonth ? daysInTargetMonth : anchorDay;
      final newEndDate = DateTime(targetYear, targetMonth, endDay, 12, 0, 0);

      final updatedCycle = cycle.copyWith(
        startDate: newStartDate,
        endDate: newEndDate,
      );

      await repo.updateBillingCycle(updatedCycle);
    }

    // 2. GENERATE MISSING CYCLES FOR NEXT 12 MONTHS
    // We want to ensure we have cycles "ending" in the next 12 months.

    var currentYear = now.year;
    var currentMonth = now.month;

    // We'll iterate to cover target months
    for (int i = 0; i < 12; i++) {
      // Calculate TARGET month/year (The month the cycle ends in)
      var targetMonth = currentMonth + i;
      var targetYear = currentYear;

      while (targetMonth > 12) {
        targetMonth -= 12;
        targetYear++;
      }

      // Skip if covered
      if (coveredMonths.contains(targetYear * 100 + targetMonth)) {
        continue;
      }

      // Check name (safety)
      final name = '${_getMonthName(targetMonth)} $targetYear';
      if (cycles.any((c) => c.name == name)) {
        continue;
      }

      // Calculate Start Date (Previous Month)
      var startMonth = targetMonth - 1;
      var startYear = targetYear;
      if (startMonth < 1) {
        startMonth = 12;
        startYear--;
      }

      final daysInStartMonth = DateTime(startYear, startMonth + 1, 0).day;
      final sDay = anchorDay > daysInStartMonth ? daysInStartMonth : anchorDay;
      final startDate = DateTime(startYear, startMonth, sDay, 12, 0, 0);

      // Calculate End Date
      final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
      final eDay =
          anchorDay > daysInTargetMonth ? daysInTargetMonth : anchorDay;
      final endDate = DateTime(targetYear, targetMonth, eDay, 12, 0, 0);

      await repo.addBillingCycle(
        BillingCycle(
          id: '',
          groupId: groupId,
          name: name,
          startDate: startDate,
          endDate: endDate,
        ),
      );
    }
  }

  /// Closes the current cycle and starts the next one immediately (e.g., Payday).
  /// 1. Sets [activeCycle.endDate] to NOW.
  /// 2. Finds or creates the next cycle and sets its [startDate] to NOW.
  Future<void> closeCurrentAndStartNextCycle(BillingCycle activeCycle) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;

    final repo = ref.read(billingCycleRepositoryProvider);
    final cycles = await repo.watchBillingCycles(groupId).first;
    final now = DateTime.now();

    // 1. Close current cycle using exact date and 12:00:00
    final nowNormalized = DateTime(now.year, now.month, now.day, 12, 0, 0);
    final closingCycle = activeCycle.copyWith(endDate: nowNormalized);
    await repo.updateBillingCycle(closingCycle);

    // 2. Determine Next Cycle
    // Logic: Look for a cycle that starts right after the *original* end date of the active cycle
    // OR just look for the chronological next month.

    // Let's rely on the chronological "Next Month".
    // Wait, if we just shortened the endDate to NOW, we should look for the cycle that WAS supposed to be next.
    // It's safer to identify the next expected month based on the original end date.
    // But since we receive `activeCycle` which might be stale in UI but correct in ID,
    // let's grab the freshest version of it first? No, local object is fine for logic.

    // Actually better: Find the cycle physically starting after this one in the list.
    final sortedCycles = List<BillingCycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final currentIndex = sortedCycles.indexWhere((c) => c.id == activeCycle.id);
    BillingCycle? nextCycle;

    if (currentIndex != -1 && currentIndex + 1 < sortedCycles.length) {
      nextCycle = sortedCycles[currentIndex + 1];
    }

    if (nextCycle != null) {
      // Update existing next cycle to start NOW (normalized)
      final updatedNext = nextCycle.copyWith(
        startDate: nowNormalized,
      );
      await repo.updateBillingCycle(updatedNext);
    } else {
      // Create new next cycle
      // Guess the month: Active Month + 1
      // We need a robust way to name/date it.
      // Fallback: If active was "Feb 2026", next is "Mar 2026"
      // Let's use the date logic from `configureAnnualSchedule`
      // Target Month is (active end month + 1)

      final targetDate = activeCycle.endDate.add(
        const Duration(days: 15),
      ); // Jump to middle of next month to be safe
      final targetMonth = targetDate.month;
      final targetYear = targetDate.year;

      final name = '${_getMonthName(targetMonth)} $targetYear';

      // End date for new cycle -> +30 days approx
      final nextMonthTarget = nowNormalized.add(const Duration(days: 30));
      final newEndDate = DateTime(nextMonthTarget.year, nextMonthTarget.month,
          nextMonthTarget.day, 12, 0, 0);

      final newCycle = BillingCycle(
        id: '',
        groupId: groupId,
        name: name,
        startDate: nowNormalized,
        endDate: newEndDate,
      );

      await repo.addBillingCycle(newCycle);
    }
  }
}

@riverpod
class SelectedCycle extends _$SelectedCycle {
  @override
  BillingCycle? build() {
    // Default to null, will be populated by current cycle if not set
    return null;
  }

  void select(BillingCycle cycle) {
    state = cycle;
  }

  void reset() {
    state = null;
  }
}

@riverpod
BillingCycle currentCycle(Ref ref) {
  final cycles = ref.watch(billingCycleNotifierProvider).valueOrNull ?? [];
  final now = DateTime.now();

  // 1. Sort by Start Date
  final sortedCycles = List<BillingCycle>.from(cycles)
    ..sort((a, b) => a.startDate.compareTo(b.startDate));

  // 2. Find the cycle that covers 'now'
  // Logic: transaction.date >= cycleX.startDate AND transaction.date < cycleY.startDate

  for (int i = 0; i < sortedCycles.length; i++) {
    final current = sortedCycles[i];
    final next = (i + 1 < sortedCycles.length) ? sortedCycles[i + 1] : null;

    if (now.isAtSameMomentAs(current.startDate) ||
        now.isAfter(current.startDate)) {
      if (next == null || now.isBefore(next.startDate)) {
        return current;
      }
    }
  }

  // 3. Fallback: Natural Month
  final startOfMonth = DateTime(now.year, now.month, 1, 12, 0, 0);

  var nextMonth = now.month + 1;
  var nextYear = now.year;
  if (nextMonth > 12) {
    nextMonth = 1;
    nextYear++;
  }
  final endOfMonth = DateTime(nextYear, nextMonth, 1, 12, 0, 0);

  return BillingCycle(
    id: 'virtual_natural_month',
    groupId: '',
    name: _getMonthName(now.month),
    startDate: startOfMonth,
    endDate: endOfMonth,
  );
}

@riverpod
BillingCycle activeCycle(Ref ref) {
  // Returns selected cycle OR current cycle if none selected
  final selected = ref.watch(selectedCycleProvider);
  if (selected != null) return selected;

  return ref.watch(currentCycleProvider);
}

// Helper for month names (should use localization in real app)
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
