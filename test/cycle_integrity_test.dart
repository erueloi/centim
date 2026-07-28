import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/models/billing_cycle.dart';
import 'package:centim/domain/services/cycle_integrity_service.dart';

void main() {
  BillingCycle cycle(String name, DateTime start, DateTime end) => BillingCycle(
        id: name,
        groupId: 'g',
        name: name,
        startDate: start,
        endDate: end,
      );

  test('una graella consecutiva correcta no dona cap problema', () {
    // Convenció: Juliol acaba el 30/07 i Agost comença el 31/07.
    final problems = findCycleGridProblems([
      cycle('Juliol', DateTime(2026, 6, 29), DateTime(2026, 7, 30)),
      cycle('Agost', DateTime(2026, 7, 31), DateTime(2026, 8, 30)),
    ]);
    expect(problems, isEmpty);
  });

  test('el cobrament és el dia 1 del cicle nou: Març 29 → Abril 30', () {
    final boundary = cycleCloseBoundaryForPayday(DateTime.utc(2026, 3, 30, 10));
    final marc = cycle(
      'Març',
      DateTime.utc(2026, 2, 28, 10),
      boundary.currentEndDate,
    );
    final abril = cycle(
      'Abril',
      boundary.nextStartDate,
      DateTime.utc(2026, 4, 29, 10),
    );

    expect(boundary.currentEndDate, DateTime(2026, 3, 29, 12));
    expect(boundary.nextStartDate, DateTime(2026, 3, 30, 12));
    expect(findCycleGridProblems([marc, abril]), isEmpty);
  });

  test('REGRESSIÓ: compartir dia és un solapament, no una graella vàlida', () {
    // El cas real de Març→Abril 2026: tots dos amb el 30/03.
    final problems = findCycleGridProblems([
      cycle('Març', DateTime(2026, 2, 28), DateTime(2026, 3, 30)),
      cycle('Abril', DateTime(2026, 3, 30), DateTime(2026, 4, 29)),
    ]);
    expect(problems, hasLength(1));
    expect(problems.first.type, CycleGridProblemType.overlap);
    expect(problems.first.days, 1);
    expect(problems.first.first.name, 'Març');
    expect(problems.first.second.name, 'Abril');
  });

  test('reparar Març→Abril retalla Març i conserva l\'inici d\'Abril', () {
    final febrer = cycle(
      'Febrer',
      DateTime.utc(2026, 1, 30, 10),
      DateTime.utc(2026, 2, 27, 10),
    );
    final marc = cycle(
      'Març',
      DateTime.utc(2026, 2, 28, 10),
      DateTime.utc(2026, 3, 30, 10),
    );
    final abril = cycle(
      'Abril',
      DateTime.utc(2026, 3, 30, 10),
      DateTime.utc(2026, 4, 29, 10),
    );
    final maig = cycle(
      'Maig',
      DateTime.utc(2026, 4, 30, 10),
      DateTime.utc(2026, 5, 29, 10),
    );

    final problem = findCycleGridProblems([febrer, marc, abril, maig]).single;
    final repairedEnd = proposedEndDateForOverlap(problem);
    final repairedMarch = marc.copyWith(endDate: repairedEnd);

    expect(repairedEnd, DateTime.utc(2026, 3, 29, 10));
    expect(abril.startDate, DateTime.utc(2026, 3, 30, 10));
    expect(
      findCycleGridProblems([febrer, repairedMarch, abril, maig])
          .where((p) => p.type == CycleGridProblemType.overlap),
      isEmpty,
    );
  });

  test('un solapament de diversos dies es compta bé', () {
    final problems = findCycleGridProblems([
      cycle('A', DateTime(2026, 1, 1), DateTime(2026, 1, 31)),
      cycle('B', DateTime(2026, 1, 29), DateTime(2026, 2, 28)),
    ]);
    expect(problems.first.type, CycleGridProblemType.overlap);
    expect(problems.first.days, 3); // 29, 30 i 31
  });

  test('un buit entre cicles també es detecta', () {
    final problems = findCycleGridProblems([
      cycle('A', DateTime(2026, 1, 1), DateTime(2026, 1, 30)),
      cycle('B', DateTime(2026, 2, 3), DateTime(2026, 2, 28)),
    ]);
    expect(problems.first.type, CycleGridProblemType.gap);
    expect(problems.first.days, 3); // 31/01, 01/02 i 02/02
  });

  test('l\'ordre d\'entrada no importa', () {
    final problems = findCycleGridProblems([
      cycle('Abril', DateTime(2026, 3, 30), DateTime(2026, 4, 29)),
      cycle('Març', DateTime(2026, 2, 28), DateTime(2026, 3, 30)),
    ]);
    expect(problems, hasLength(1));
    expect(problems.first.first.name, 'Març');
  });

  test('les hores no compten, només el dia', () {
    final problems = findCycleGridProblems([
      cycle('A', DateTime(2026, 1, 1), DateTime(2026, 1, 30, 10)),
      cycle('B', DateTime(2026, 1, 31, 23, 59), DateTime(2026, 2, 28)),
    ]);
    expect(problems, isEmpty);
  });

  test('un sol cicle no pot solapar-se amb res', () {
    expect(
      findCycleGridProblems(
          [cycle('A', DateTime(2026, 1, 1), DateTime(2026, 1, 30))]),
      isEmpty,
    );
    expect(findCycleGridProblems([]), isEmpty);
  });
}
