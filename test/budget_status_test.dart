import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/models/billing_cycle.dart';
import 'package:centim/domain/models/category.dart';
import 'package:centim/domain/models/transaction.dart';
import 'package:centim/presentation/providers/budget_provider.dart';

void main() {
  final cycle = BillingCycle(
    id: 'c1',
    groupId: 'g',
    name: 'Juliol 2026',
    startDate: DateTime(2026, 6, 29),
    endDate: DateTime(2026, 7, 30),
  );

  final nomina = Category(
    id: 'inc',
    name: 'NÒMINA',
    icon: '💰',
    type: TransactionType.income,
    subcategories: const [
      SubCategory(id: 'inc_eloi', name: 'Eloi', monthlyBudget: 2600),
      SubCategory(id: 'inc_jose', name: 'Jose', monthlyBudget: 1068),
    ],
  );

  final menjar = Category(
    id: 'exp',
    name: 'Menjar',
    icon: '🍎',
    type: TransactionType.expense,
    subcategories: const [
      SubCategory(id: 'exp_super', name: 'Super', monthlyBudget: 400),
    ],
  );

  Transaction tx({
    required double amount,
    required bool isIncome,
    required String catId,
    required String subId,
    DateTime? date,
  }) =>
      Transaction(
        id: 'x',
        groupId: 'g',
        date: date ?? DateTime(2026, 7, 10),
        amount: amount,
        concept: 'c',
        categoryId: catId,
        subCategoryId: subId,
        categoryName: '',
        subCategoryName: '',
        payer: 'p',
        isIncome: isIncome,
      );

  BudgetStatus statusOf(List<Transaction> txs, String catId) =>
      calculateBudgetStatus([nomina, menjar], txs, const [], cycle)
          .firstWhere((s) => s.category.id == catId);

  test('REGRESSIÓ: una categoria d\'INGRÉS compta els ingressos rebuts', () {
    final s = statusOf([
      tx(amount: 2600, isIncome: true, catId: 'inc', subId: 'inc_eloi'),
      tx(amount: 1068, isIncome: true, catId: 'inc', subId: 'inc_jose'),
    ], 'inc');

    // El bug deixava això a 0 perquè només mirava el cistell de despesa.
    expect(s.spent, 3668);
    expect(s.total, 3668);

    final eloi =
        s.subcategoryStatuses.firstWhere((x) => x.subcategory.id == 'inc_eloi');
    expect(eloi.spent, 2600);
    expect(eloi.budget, 2600);
  });

  test('una categoria de DESPESA segueix comptant les despeses', () {
    final s = statusOf([
      tx(amount: 50, isIncome: false, catId: 'exp', subId: 'exp_super'),
    ], 'exp');
    expect(s.spent, 50);
  });

  test('els moviments de signe contrari resten del seu cistell', () {
    // Refund dins d'una categoria de despesa.
    final e = statusOf([
      tx(amount: 50, isIncome: false, catId: 'exp', subId: 'exp_super'),
      tx(amount: 20, isIncome: true, catId: 'exp', subId: 'exp_super'),
    ], 'exp');
    expect(e.spent, 30);

    // Devolució d'un ingrés dins d'una categoria d'ingrés.
    final i = statusOf([
      tx(amount: 2600, isIncome: true, catId: 'inc', subId: 'inc_eloi'),
      tx(amount: 100, isIncome: false, catId: 'inc', subId: 'inc_eloi'),
    ], 'inc');
    expect(i.spent, 2600); // la de signe contrari no suma com a ingrés
  });

  test('els moviments fora del cicle no compten', () {
    final s = statusOf([
      tx(
        amount: 2600,
        isIncome: true,
        catId: 'inc',
        subId: 'inc_eloi',
        date: DateTime(2026, 8, 15), // fora del cicle
      ),
    ], 'inc');
    expect(s.spent, 0);
  });
}
