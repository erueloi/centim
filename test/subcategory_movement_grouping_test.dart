import 'package:centim/domain/models/category.dart';
import 'package:centim/domain/models/transaction.dart';
import 'package:centim/domain/services/concept_normalizer.dart';
import 'package:centim/domain/services/subcategory_movement_grouping_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const market = SubCategory(
    id: 'market',
    name: 'Mercat / Supermercat',
    monthlyBudget: 600,
  );
  const category = Category(
    id: 'food',
    name: 'Menjar',
    icon: '🛒',
    type: TransactionType.expense,
    subcategories: [market],
  );

  test('la identitat compartida uneix variants reals de comerç', () {
    expect(
      conceptKeysRepresentSameMerchant(
        transactionConceptKey('CONSUM RUBI CALD.'),
        transactionConceptKey('CONSUM'),
      ),
      isTrue,
    );
    expect(
      conceptKeysRepresentSameMerchant(
        transactionConceptKey('PLUS FRESC BALAGUER'),
        transactionConceptKey('PLUS FRESC B4'),
      ),
      isTrue,
    );
    expect(
      conceptKeysRepresentSameMerchant(
        transactionConceptKey('PLUS FRESC'),
        transactionConceptKey('LOS JIJONENCOS'),
      ),
      isFalse,
    );
  });

  test('l’autoaprenentatge difús es bloqueja si el destí és ambigu', () {
    final candidates = {
      transactionConceptKey('ISIDRE AYMERICH — Ajuda Eloi'): 'bizum',
      transactionConceptKey('ISIDRE AYMERICH — Pagament Eloi'): 'ingres',
    };

    expect(
      unambiguousMerchantCandidate(
        key: transactionConceptKey('ISIDRE AYMERICH OLIVEDA'),
        candidates: candidates,
        targetKey: (target) => target,
      ),
      isNull,
    );

    expect(
      unambiguousMerchantCandidate(
        key: transactionConceptKey('PLUS FRESC'),
        candidates: {
          transactionConceptKey('PLUS FRESC BALAGUER'): 'supermercat',
          transactionConceptKey('PLUS FRESC B4'): 'supermercat',
        },
        targetKey: (target) => target,
      ),
      'supermercat',
    );
  });

  test('agrupa amb deltes del ledger, refunds i Altres per cua petita', () {
    final transactions = [
      _tx('PLUS FRESC', 100),
      _tx('PLUS FRESC B4', 50),
      _tx('PLUS FRESC BALAGUER', 20, isIncome: true),
      _tx('CONSUM', 100),
      _tx('CONSUM RUBI CALD.', 50),
      _tx('DERMATOLEG', 220),
      _tx('LOS JIJONENCOS', 60),
      _tx('ALFA', 9),
      _tx('BRAVO', 8),
      _tx('CIGNE', 7),
      _tx('DELTA', 6),
      _tx('EROSI', 5),
      _tx('FORMA', 4),
      _tx('GLAÇ', 3),
      _tx('HOTEL', 2),
      _tx('DEVOLUCIÓ BOTIGA', 10, isIncome: true),
    ];

    final result = groupSubcategoryMovements(
      cycleTransactions: transactions,
      categories: const [category],
      category: category,
      subcategoryId: market.id,
      expectedTotal: 594,
    );

    expect(result.matchesExpectedTotal, isTrue);
    expect(result.total, 594);
    expect(
      result.groups.fold<double>(0, (sum, group) => sum + group.amount),
      594,
    );
    expect(
      result.groups.fold<int>(
        0,
        (sum, group) => sum + group.displayPercentage,
      ),
      100,
    );

    final plus = result.groups.singleWhere(
      (group) => group.name == 'PLUS FRESC',
    );
    expect(plus.amount, 130);
    expect(plus.movementCount, 3);

    final consum = result.groups.singleWhere(
      (group) => group.name == 'CONSUM',
    );
    expect(consum.amount, 150);
    expect(consum.movementCount, 2);

    // Un moviment únic però material no queda amagat.
    expect(
      result.groups.singleWhere((group) => group.name == 'DERMATOLEG').amount,
      220,
    );

    // Un grup negatiu per refund continua visible.
    expect(
      result.groups.singleWhere((group) => group.name == 'BOTIGA').amount,
      -10,
    );

    final other = result.groups.singleWhere((group) => group.isOther);
    expect(other.name, 'Altres');
    expect(other.amount, 44);
    expect(other.movementCount, 8);
    expect(other.children, hasLength(8));
  });

  test('una subcategoria de guardiola queda exclosa estructuralment', () {
    const savingsSubcategory = SubCategory(
      id: 'savings',
      name: 'Guardiola',
      monthlyBudget: 100,
      linkedSavingsGoalId: 'goal',
    );
    const savingsCategory = Category(
      id: 'saving-category',
      name: 'Estalvi',
      icon: '🐷',
      type: TransactionType.expense,
      subcategories: [savingsSubcategory],
    );

    final result = groupSubcategoryMovements(
      cycleTransactions: [
        _tx(
          'APORTACIÓ',
          100,
          categoryId: savingsCategory.id,
          subcategoryId: savingsSubcategory.id,
        ),
      ],
      categories: const [savingsCategory],
      category: savingsCategory,
      subcategoryId: savingsSubcategory.id,
      expectedTotal: 0,
    );

    expect(result.groups, isEmpty);
    expect(result.matchesExpectedTotal, isTrue);
  });

  test('Invariant de suma: suma(grups) == total i suma(displayPercentage) == 100 amb fills d’Altres', () {
    final transactions = [
      _tx('ALFA RESTAURANT', 50),
      _tx('BRAVO CAFE', 45),
      _tx('CHARLIE FORN', 40),
      _tx('DELTA PASTISSERIA', 35),
      _tx('ECHO SUPER', 30),
      _tx('FOXTROT CARNISSERIA', 25),
      _tx('GOLF PEIXATERIA', 20),
      _tx('HOTEL MENJAR', 15),
      _tx('INDIA FRUITA', 14),
      _tx('JULIETT GELATS', 13),
      _tx('KILO BAR', 12),
      _tx('LIMA TAPES', 11),
      _tx('MIKE XURRERIA', 10),
      _tx('NOVEMBER LOCAL', 5),
      _tx('OSCAR LOCAL', 4),
      _tx('PAPA LOCAL', 3),
      _tx('QUEBEC LOCAL', 2),
    ];
    final totalExpected = transactions.fold(0.0, (sum, tx) => sum + tx.amount); // 334 €

    final result = groupSubcategoryMovements(
      cycleTransactions: transactions,
      categories: const [category],
      category: category,
      subcategoryId: market.id,
      expectedTotal: totalExpected,
      maxVisiblePositiveGroups: 10,
      minimumShare: 0.01,
      minimumAmount: 10.0,
    );

    expect(result.matchesExpectedTotal, isTrue);
    expect(result.total, totalExpected);

    // Suma d'imports dels grups principals == totalExpected
    final groupsSum = result.groups.fold<double>(0, (sum, g) => sum + g.amount);
    expect((groupsSum - totalExpected).abs() < 0.001, isTrue);

    // Suma de percentatges == 100
    final pctSum = result.groups.fold<int>(0, (sum, g) => sum + g.displayPercentage);
    expect(pctSum, 100);

    // Comprovar que Altres conté els subgrups fills i que la seva suma coincideix amb Altres.amount
    final otherGroup = result.groups.firstWhere((g) => g.isOther);
    expect(otherGroup.children, isNotEmpty);
    final childrenSum = otherGroup.children.fold<double>(0, (sum, c) => sum + c.amount);
    expect((childrenSum - otherGroup.amount).abs() < 0.001, isTrue);
  });
}

Transaction _tx(
  String concept,
  double amount, {
  bool isIncome = false,
  String categoryId = 'food',
  String subcategoryId = 'market',
}) {
  return Transaction(
    id: '$concept-$amount-$isIncome',
    groupId: 'group',
    date: DateTime(2026, 7, 15),
    amount: amount,
    concept: concept,
    categoryId: categoryId,
    subCategoryId: subcategoryId,
    categoryName: categoryId,
    subCategoryName: subcategoryId,
    payer: 'Eloi',
    isIncome: isIncome,
  );
}
