import '../models/billing_cycle.dart';

/// Tall de calendari quan arriba una nòmina.
///
/// La data de cobrament és el DIA 1 del cicle nou. Com que `endDate` és
/// inclusiu, el cicle vell acaba el dia natural anterior.
class CycleCloseBoundary {
  final DateTime currentEndDate;
  final DateTime nextStartDate;

  const CycleCloseBoundary({
    required this.currentEndDate,
    required this.nextStartDate,
  });
}

CycleCloseBoundary cycleCloseBoundaryForPayday(DateTime payday) {
  final nextStart = DateTime(
    payday.year,
    payday.month,
    payday.day,
    12,
  );
  final currentEnd = DateTime(
    nextStart.year,
    nextStart.month,
    nextStart.day - 1,
    12,
  );
  return CycleCloseBoundary(
    currentEndDate: currentEnd,
    nextStartDate: nextStart,
  );
}

/// Validació de la graella de cicles.
///
/// CONVENCIÓ: `endDate` és INCLUSIU. Juliol acaba el 30/07 i Agost comença el
/// 31/07. Per tant els filtres de cicle són `data >= inici && data <= final`,
/// i la responsabilitat de no comptar un dia dues vegades recau sobre les DATES
/// dels cicles, no sobre el filtre.
///
/// Si dos cicles comparteixen dia, els moviments d'aquell dia sumen als dos
/// alhora: els totals quadren per separat però la cadena de saldos inicials
/// (final del cicle N = inicial del cicle N+1) es trenca. Per això és una
/// comprovació de només lectura que s'ha de resoldre a mà.

enum CycleGridProblemType {
  /// Dos cicles cobreixen el mateix dia → moviments comptats dues vegades.
  overlap,

  /// Hi ha dies entre dos cicles que no pertanyen a cap → moviments perduts.
  gap,
}

class CycleGridProblem {
  final CycleGridProblemType type;
  final BillingCycle first;
  final BillingCycle second;

  /// Dies afectats: solapats (overlap) o orfes (gap). Sempre >= 1.
  final int days;

  const CycleGridProblem({
    required this.type,
    required this.first,
    required this.second,
    required this.days,
  });

  String get message => switch (type) {
        CycleGridProblemType.overlap => days == 1
            ? '«${first.name}» i «${second.name}» comparteixen 1 dia. '
                'Els moviments d\'aquell dia compten als dos cicles.'
            : '«${first.name}» i «${second.name}» se solapen $days dies. '
                'Els moviments d\'aquests dies compten als dos cicles.',
        CycleGridProblemType.gap => days == 1
            ? 'Entre «${first.name}» i «${second.name}» hi ha 1 dia que no '
                'pertany a cap cicle.'
            : 'Entre «${first.name}» i «${second.name}» hi ha $days dies que no '
                'pertanyen a cap cicle.',
      };
}

// UTC evita que un canvi d'horari d'estiu converteixi dos dies consecutius en
// 23 hores (`difference.inDays == 0`) i generi un fals solapament.
DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Cerca solapaments i buits a la graella de cicles. NOMÉS LECTURA.
///
/// Compara cicles consecutius un cop ordenats per data d'inici, que és on es
/// produeixen els problemes reals (un cicle mal datat contra el seu veí).
List<CycleGridProblem> findCycleGridProblems(List<BillingCycle> cycles) {
  final sorted = List<BillingCycle>.from(cycles)
    ..sort((a, b) => a.startDate.compareTo(b.startDate));

  final problems = <CycleGridProblem>[];

  for (var i = 0; i + 1 < sorted.length; i++) {
    final current = sorted[i];
    final next = sorted[i + 1];

    final currentEnd = _day(current.endDate);
    final nextStart = _day(next.startDate);

    // Amb final INCLUSIU, el següent cicle ha de començar l'endemà exacte.
    final diff = nextStart.difference(currentEnd).inDays;

    if (diff <= 0) {
      // nextStart == currentEnd → 1 dia compartit; nextStart < currentEnd → més.
      problems.add(CycleGridProblem(
        type: CycleGridProblemType.overlap,
        first: current,
        second: next,
        days: 1 - diff,
      ));
    } else if (diff > 1) {
      problems.add(CycleGridProblem(
        type: CycleGridProblemType.gap,
        first: current,
        second: next,
        days: diff - 1,
      ));
    }
  }

  return problems;
}

/// Data final que resol un [problem] de solapament sense tocar l'inici del
/// segon cicle.
///
/// Com que `endDate` és inclusiu, el primer cicle ha d'acabar exactament el dia
/// anterior a l'inici del segon. Restar un dia conserva l'hora i la zona de la
/// data original (p. ex. 2026-03-30T10:00:00Z → 2026-03-29T10:00:00Z).
DateTime proposedEndDateForOverlap(CycleGridProblem problem) {
  if (problem.type != CycleGridProblemType.overlap) {
    throw ArgumentError.value(
      problem.type,
      'problem.type',
      'Només es poden reparar solapaments.',
    );
  }
  return problem.second.startDate.subtract(const Duration(days: 1));
}
