import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/billing_cycle.dart';
import '../../domain/services/cycle_integrity_service.dart';
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

  /// Repara UN solapament detectat escurçant només el final del primer cicle.
  ///
  /// Es torna a validar contra les dades més recents abans d'escriure perquè
  /// una targeta antiga no pugui aplicar una reparació que ja no correspon.
  /// Retorna els solapaments que quedarien després del canvi.
  Future<List<CycleGridProblem>> repairOverlap(
    CycleGridProblem staleProblem,
  ) async {
    if (staleProblem.type != CycleGridProblemType.overlap) {
      throw ArgumentError('Aquesta acció només resol solapaments.');
    }

    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) throw StateError('No hi ha cap grup actiu.');

    final repo = ref.read(billingCycleRepositoryProvider);
    final cycles = await repo.watchBillingCycles(groupId).first;
    final currentProblems = findCycleGridProblems(cycles);

    final problem = currentProblems.where((p) {
      return p.type == CycleGridProblemType.overlap &&
          p.first.id == staleProblem.first.id &&
          p.second.id == staleProblem.second.id;
    }).firstOrNull;

    if (problem == null) {
      throw StateError('Aquest solapament ja no existeix.');
    }

    final proposedEnd = proposedEndDateForOverlap(problem);
    if (proposedEnd.isBefore(problem.first.startDate)) {
      throw StateError(
        'La reparació deixaria el primer cicle amb dates invàlides.',
      );
    }

    // Verificació pura sobre tota la graella abans de persistir.
    final repairedCycles = cycles.map((cycle) {
      return cycle.id == problem.first.id
          ? cycle.copyWith(endDate: proposedEnd)
          : cycle;
    }).toList();
    final remainingOverlaps = findCycleGridProblems(repairedCycles)
        .where((p) => p.type == CycleGridProblemType.overlap)
        .toList();

    await repo.setEndDateForOverlapRepair(problem.first.id, proposedEnd);
    return remainingOverlaps;
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

  /// Tanca el cicle actual i comença el següent el dia de cobrament.
  ///
  /// 1. [activeCycle.endDate] = dia anterior a [payday].
  /// 2. El cicle següent comença a [payday], que és el seu DIA 1.
  /// 3. Si es passa [openingBalanceForNext], el segella com a saldo inicial del
  ///    cicle següent. Sempre ve d'una confirmació explícita de l'usuari: un
  ///    saldo inicial equivocat contamina tots els cicles posteriors, així que
  ///    mai s'escriu sol.
  Future<void> closeCurrentAndStartNextCycle(
    BillingCycle activeCycle, {
    required DateTime payday,
    double? openingBalanceForNext,
  }) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;

    final repo = ref.read(billingCycleRepositoryProvider);
    final cycles = await repo.watchBillingCycles(groupId).first;
    final currentCycle =
        cycles.where((c) => c.id == activeCycle.id).firstOrNull;
    if (currentCycle == null) {
      throw StateError('El cicle que es vol tancar ja no existeix.');
    }

    final boundary = cycleCloseBoundaryForPayday(payday);
    final activeStart = DateTime(
      currentCycle.startDate.year,
      currentCycle.startDate.month,
      currentCycle.startDate.day,
      12,
    );
    if (boundary.currentEndDate.isBefore(activeStart)) {
      throw ArgumentError.value(
        payday,
        'payday',
        'La data de cobrament ha de ser posterior a l’inici del cicle actual.',
      );
    }

    final nextStart = boundary.nextStartDate;
    final sortedCycles = List<BillingCycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final currentIndex = sortedCycles.indexWhere((c) => c.id == activeCycle.id);
    final nextCycle =
        currentIndex != -1 && currentIndex + 1 < sortedCycles.length
            ? sortedCycles[currentIndex + 1]
            : null;

    // Validar-ho TOT abans de la primera escriptura: una data invàlida no pot
    // deixar només el cicle vell retallat.
    if (nextCycle != null) {
      final nextEnd = DateTime(
        nextCycle.endDate.year,
        nextCycle.endDate.month,
        nextCycle.endDate.day,
        12,
      );
      if (nextStart.isAfter(nextEnd)) {
        throw ArgumentError.value(
          payday,
          'payday',
          'La data de cobrament queda després del final del cicle següent.',
        );
      }
    }

    // 1. El cicle vell acaba el dia anterior al cobrament. `endDate` és
    // inclusiu, així que aquest és l'únic tall que posa la nòmina al cicle nou
    // sense compartir cap dia.
    final closingCycle =
        currentCycle.copyWith(endDate: boundary.currentEndDate);
    await repo.updateBillingCycle(closingCycle);

    String? nextCycleId;

    if (nextCycle != null) {
      // 2. El cicle següent comença el mateix dia del cobrament.
      final updatedNext = nextCycle.copyWith(
        startDate: nextStart,
      );
      await repo.updateBillingCycle(updatedNext);
      nextCycleId = nextCycle.id;
    } else {
      // Si encara no existeix, el nom correspon al mes central del nou cicle.
      final targetDate = nextStart.add(
        const Duration(days: 15),
      );
      final targetMonth = targetDate.month;
      final targetYear = targetDate.year;

      final name = '${_getMonthName(targetMonth)} $targetYear';

      // Final provisional: el pròxim cobrament el tornarà a ajustar.
      final nextMonthTarget = nextStart.add(const Duration(days: 30));
      final newEndDate = DateTime(nextMonthTarget.year, nextMonthTarget.month,
          nextMonthTarget.day, 12, 0, 0);

      final newCycle = BillingCycle(
        id: '',
        groupId: groupId,
        name: name,
        startDate: nextStart,
        endDate: newEndDate,
      );

      nextCycleId = await repo.addBillingCycle(newCycle);
    }

    // 3. Segellar el saldo inicial del cicle nou, si l'usuari l'ha confirmat.
    if (openingBalanceForNext != null) {
      await repo.setOpeningBalance(
        nextCycleId,
        openingBalanceForNext,
        'auto-tancament',
      );
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
