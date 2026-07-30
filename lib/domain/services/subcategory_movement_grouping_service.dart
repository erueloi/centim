import '../models/category.dart';
import '../models/transaction.dart';
import 'concept_normalizer.dart';
import 'ledger_service.dart';

class GroupedMovement {
  final Transaction transaction;
  final double ledgerDelta;

  const GroupedMovement({
    required this.transaction,
    required this.ledgerDelta,
  });
}

class MovementConceptGroup {
  final String name;
  final double amount;
  final double percentage;
  final int displayPercentage;
  final List<GroupedMovement> movements;
  final List<MovementConceptGroup> children;
  final bool isOther;

  const MovementConceptGroup({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.displayPercentage,
    required this.movements,
    this.children = const [],
    this.isOther = false,
  });

  int get movementCount => movements.length;

  MovementConceptGroup withPercentages({
    required double percentage,
    required int displayPercentage,
  }) {
    return MovementConceptGroup(
      name: name,
      amount: amount,
      percentage: percentage,
      displayPercentage: displayPercentage,
      movements: movements,
      children: children,
      isOther: isOther,
    );
  }
}

class SubcategoryMovementGrouping {
  final List<MovementConceptGroup> groups;
  final double total;
  final double expectedTotal;

  const SubcategoryMovementGrouping({
    required this.groups,
    required this.total,
    required this.expectedTotal,
  });

  bool get matchesExpectedTotal => (total - expectedTotal).abs() < 0.005;
}

/// Agrupa moviments JA filtrats al cicle amb els deltes canònics del ledger.
///
/// No llegeix dades ni interpreta signes pel seu compte: [classifyTransaction]
/// decideix exclusions, refunds i cistell. [expectedTotal] és el `spent` que ja
/// mostra `calculateBudgetStatus` i serveix d'invariant de quadrament.
SubcategoryMovementGrouping groupSubcategoryMovements({
  required Iterable<Transaction> cycleTransactions,
  required List<Category> categories,
  required Category category,
  required String subcategoryId,
  required double expectedTotal,
  int maxVisiblePositiveGroups = 7,
  double minimumShare = 0.05,
  double minimumAmount = 10,
}) {
  final lookups = LedgerLookups.from(categories);
  final relevantBucket = category.type == TransactionType.income
      ? LedgerBucket.income
      : LedgerBucket.expense;
  final mutableGroups = <_MutableMovementGroup>[];

  for (final transaction in cycleTransactions) {
    if (transaction.categoryId != category.id ||
        transaction.subCategoryId != subcategoryId) {
      continue;
    }

    final classification = classifyTransaction(transaction, lookups);
    if (classification.bucket != relevantBucket) continue;

    final key = transactionConceptKey(transaction.concept);
    final matchingGroups = mutableGroups
        .where(
          (group) => group.keys.any(
            (existing) => conceptKeysRepresentSameMerchant(existing, key),
          ),
        )
        .toList();

    final target =
        matchingGroups.isEmpty ? _MutableMovementGroup() : matchingGroups.first;
    if (matchingGroups.isEmpty) mutableGroups.add(target);
    for (final duplicate in matchingGroups.skip(1)) {
      target.merge(duplicate);
      mutableGroups.remove(duplicate);
    }

    target.keys.add(key);
    target.amount += classification.delta;
    target.movements.add(
      GroupedMovement(
        transaction: transaction,
        ledgerDelta: classification.delta,
      ),
    );
  }

  final rawGroups = mutableGroups
      .map(
        (group) => MovementConceptGroup(
          name: commonMerchantLabel(group.keys),
          amount: group.amount,
          percentage: 0,
          displayPercentage: 0,
          movements: List.unmodifiable(
            group.movements
              ..sort(
                (a, b) => b.transaction.date.compareTo(a.transaction.date),
              ),
          ),
        ),
      )
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final total = rawGroups.fold(0.0, (sum, group) => sum + group.amount);
  final detailedGroups = _assignPercentages(rawGroups, expectedTotal);
  final threshold = (expectedTotal.abs() * minimumShare)
      .clamp(minimumAmount, double.infinity);
  final visible = <MovementConceptGroup>[];
  final otherChildren = <MovementConceptGroup>[];
  var visiblePositiveCount = 0;

  for (final group in detailedGroups) {
    // Els grups a zero o negatius són senyal útil de refunds: no s'amaguen.
    if (group.amount <= 0) {
      visible.add(group);
      continue;
    }

    if (visiblePositiveCount < maxVisiblePositiveGroups &&
        group.amount >= threshold) {
      visible.add(group);
      visiblePositiveCount++;
    } else {
      otherChildren.add(group);
    }
  }

  if (otherChildren.isNotEmpty) {
    visible.add(
      MovementConceptGroup(
        name: 'Altres',
        amount: otherChildren.fold(0.0, (sum, group) => sum + group.amount),
        percentage: 0,
        displayPercentage: 0,
        movements: List.unmodifiable(
          otherChildren.expand((group) => group.movements).toList()
            ..sort(
              (a, b) => b.transaction.date.compareTo(a.transaction.date),
            ),
        ),
        children: List.unmodifiable(otherChildren),
        isOther: true,
      ),
    );
  }

  final groupsWithPercentages = _assignPercentages(visible, expectedTotal);

  return SubcategoryMovementGrouping(
    groups: List.unmodifiable(groupsWithPercentages),
    total: total,
    expectedTotal: expectedTotal,
  );
}

List<MovementConceptGroup> _assignPercentages(
  List<MovementConceptGroup> groups,
  double total,
) {
  if (groups.isEmpty) return const [];

  final denominator = total.abs() >= 0.005
      ? total
      : groups.fold(0.0, (sum, group) => sum + group.amount.abs());
  if (denominator == 0) {
    return groups
        .map(
          (group) => group.withPercentages(
            percentage: 0,
            displayPercentage: 0,
          ),
        )
        .toList();
  }

  final exact = groups
      .map(
        (group) => total.abs() >= 0.005
            ? group.amount / denominator * 100
            : group.amount.abs() / denominator * 100,
      )
      .toList();
  final rounded = exact.map((value) => value.round()).toList();
  var difference = 100 - rounded.fold(0, (sum, value) => sum + value);

  final indexes = List<int>.generate(groups.length, (index) => index);
  indexes.sort((a, b) {
    final residualA = exact[a] - rounded[a];
    final residualB = exact[b] - rounded[b];
    return difference >= 0
        ? residualB.compareTo(residualA)
        : residualA.compareTo(residualB);
  });

  var cursor = 0;
  while (difference != 0 && indexes.isNotEmpty) {
    final index = indexes[cursor % indexes.length];
    final step = difference > 0 ? 1 : -1;
    rounded[index] += step;
    difference -= step;
    cursor++;
  }

  return [
    for (var index = 0; index < groups.length; index++)
      groups[index].withPercentages(
        percentage: exact[index],
        displayPercentage: rounded[index],
      ),
  ];
}

class _MutableMovementGroup {
  final Set<String> keys = {};
  final List<GroupedMovement> movements = [];
  double amount = 0;

  void merge(_MutableMovementGroup other) {
    keys.addAll(other.keys);
    movements.addAll(other.movements);
    amount += other.amount;
  }
}
