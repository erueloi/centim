import 'package:flutter_test/flutter_test.dart';

import 'package:centim/data/services/category_seeder_service.dart';
import 'package:centim/domain/models/category.dart';

Category _existing(String name, TransactionType type, {bool archived = false}) =>
    Category(id: name, name: name, icon: '📂', type: type, archived: archived);

List<String> _names(List<Category> categories) =>
    categories.map((c) => c.name).toList();

void main() {
  group('categories per defecte', () {
    test('els ingressos són genèrics: sense noms de persones', () {
      final income = defaultIncomeCategories();
      final allNames = [
        for (final c in income) ...[c.name, ...c.subcategories.map((s) => s.name)],
      ];
      expect(allNames, isNot(contains('Eloi')));
      expect(allNames, isNot(contains('Jose')));
      expect(income.every((c) => c.type == TransactionType.income), isTrue);
    });

    test('la categoria Nòmina es manté (l\'informe anual la detecta pel nom)', () {
      final nomina = defaultIncomeCategories().firstWhere((c) => c.name == 'Nòmina');
      expect(nomina.subcategories.single.name, 'Nòmina');
      expect(nomina.subcategories.single.isFixed, isTrue);
    });

    test('les despeses són les transversals acordades, totes de tipus despesa', () {
      final expense = defaultExpenseCategories();
      expect(_names(expense), [
        'Habitatge',
        'Subministraments',
        'Alimentació',
        'Transport',
        'Salut',
        'Oci',
        'Roba i cura personal',
        'Educació',
        'Subscripcions',
        'Impostos i comissions',
        'Altres',
      ]);
      expect(expense.every((c) => c.type == TransactionType.expense), isTrue);
      expect(expense.every((c) => c.subcategories.isNotEmpty), isTrue);
    });

    test('cada crida genera ids nous i únics', () {
      final ids = [
        for (final c in [...defaultExpenseCategories(), ...defaultExpenseCategories()]) ...[
          c.id,
          ...c.subcategories.map((s) => s.id),
        ],
      ];
      expect(ids.toSet().length, ids.length);
    });
  });

  group('categoriesToSeed', () {
    test('en un grup buit es creen totes', () {
      final defaults = defaultExpenseCategories();
      expect(categoriesToSeed(defaults, const []), hasLength(defaults.length));
    });

    test('es salten les que ja existeixen, sense distingir majúscules ni accents', () {
      final result = categoriesToSeed(defaultExpenseCategories(), [
        _existing('habitatge', TransactionType.expense),
        _existing('ALIMENTACIO', TransactionType.expense),
        _existing('  Oci ', TransactionType.expense),
      ]);
      final names = _names(result);
      expect(names, isNot(contains('Habitatge')));
      expect(names, isNot(contains('Alimentació')));
      expect(names, isNot(contains('Oci')));
      expect(names, contains('Salut'));
    });

    test('generar dues vegades no duplica res', () {
      final first = categoriesToSeed(defaultIncomeCategories(), const []);
      expect(categoriesToSeed(defaultIncomeCategories(), first), isEmpty);
    });

    test('les arxivades també compten com a existents', () {
      final result = categoriesToSeed(defaultExpenseCategories(), [
        _existing('Transport', TransactionType.expense, archived: true),
      ]);
      expect(_names(result), isNot(contains('Transport')));
    });

    test('el mateix nom amb un altre tipus no bloqueja la creació', () {
      // "Habitatge" com a ingrés no és la categoria de despesa.
      final result = categoriesToSeed(defaultExpenseCategories(), [
        _existing('Habitatge', TransactionType.income),
      ]);
      expect(_names(result), contains('Habitatge'));
    });
  });
}
