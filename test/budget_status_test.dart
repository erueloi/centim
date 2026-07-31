import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/models/billing_cycle.dart';
import 'package:centim/domain/models/category.dart';
import 'package:centim/domain/models/transaction.dart';
import 'package:centim/domain/services/ledger_service.dart';
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
    String? savingsGoalId,
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
        savingsGoalId: savingsGoalId,
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

  test(
      'la projecció d’estalvi mostra el net del ledger sense canviar les despeses',
      () {
    const goalId = 'fons-masia';
    final savings = Category(
      id: 'sav',
      name: 'Estalvi Menusal',
      icon: '🐷',
      subcategories: const [
        SubCategory(
          id: 'sav-masia',
          name: 'Aportació Fons Masia',
          monthlyBudget: 100,
          linkedSavingsGoalId: goalId,
        ),
      ],
    );
    final savingsIncome = Category(
      id: 'sav-income',
      name: 'Ingressos',
      icon: '💰',
      type: TransactionType.income,
      subcategories: const [
        SubCategory(
          id: 'withdraw-masia',
          name: 'Ingrés Fons Masia',
          monthlyBudget: 0,
          linkedSavingsGoalId: goalId,
        ),
      ],
    );
    final categories = [savings, savingsIncome];
    final transactions = [
      tx(
        amount: 100,
        isIncome: false,
        catId: 'sav',
        subId: 'sav-masia',
      ),
      tx(
        amount: 35,
        isIncome: true,
        catId: 'sav-income',
        subId: 'withdraw-masia',
      ),
    ];

    final budgetStatus = calculateBudgetStatus(
      categories,
      transactions,
      const [],
      cycle,
    ).firstWhere((status) => status.category.id == 'sav');
    final ledger = summarizeLedger(
      transactionsInBillingCycle(transactions, cycle),
      LedgerLookups.from(categories),
    );
    final categoryProgress = SavingsBudgetProgress.forCycle(ledger);
    final subcategoryProgress = SavingsBudgetProgress.forSubcategory(
      savings.subcategories.single,
      ledger,
    );

    expect(isSavingsBudgetCategory(savings), isTrue);
    expect(budgetStatus.spent, 0); // continua fora del total de despeses
    expect(budgetStatus.subcategoryStatuses.single.spent, 0);
    expect(categoryProgress.saved, 100);
    expect(categoryProgress.withdrawn, 35);
    expect(categoryProgress.net, 65);
    expect(subcategoryProgress.net, 65);
    expect(ledger.netSavedForGoal(goalId), 65);
  });

  test('l’editor actiu continua excloent categories i subcategories arxivades',
      () {
    final archivedCategory = Category(
      id: 'archived',
      name: 'Arxivada',
      icon: '',
      archived: true,
      subcategories: const [
        SubCategory(id: 'old', name: 'Antiga', monthlyBudget: 100),
      ],
    );
    final categoryWithArchivedSub = Category(
      id: 'mixed',
      name: 'Mixta',
      icon: '',
      subcategories: const [
        SubCategory(id: 'active', name: 'Activa', monthlyBudget: 100),
        SubCategory(
          id: 'archived-sub',
          name: 'Antiga',
          monthlyBudget: 50,
          archived: true,
        ),
      ],
    );

    final statuses = calculateBudgetStatus(
      [archivedCategory, categoryWithArchivedSub],
      const [],
      const [],
      cycle,
    );

    expect(statuses.map((item) => item.category.id), ['mixed']);
    expect(statuses.single.total, 100);
    expect(
      statuses.single.subcategoryStatuses.map((item) => item.subcategory.id),
      ['active'],
    );
  });
}
