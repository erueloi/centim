import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/models/category.dart';
import 'package:centim/domain/models/savings_goal.dart';
import 'package:centim/domain/models/transaction.dart';
import 'package:centim/domain/services/internal_transfer_migration_service.dart';

void main() {
  const savingsSubcategoryId = '801d4ee8-dea0-43fc-a8c6-813abfb5adac';
  const bizumsSubcategoryId = '28018cc9-d6fa-4809-ace5-84d42d61dff6';
  const joseGoalId = 'nvXLyoZiZWNS0jcKe1WC';

  Transaction tx({
    required String id,
    required double amount,
    required bool income,
    required DateTime date,
    required String subcategory,
    String? concept,
    String? savingsGoalId,
  }) {
    return Transaction(
      id: id,
      groupId: 'g',
      date: date,
      amount: amount,
      concept: concept ?? id,
      categoryId: income ? 'income' : 'other',
      subCategoryId: subcategory,
      categoryName: income ? 'Ingressos' : 'Altres',
      subCategoryName: income ? 'Ingrés Guardiola Jose' : 'Bizums',
      payer: 'p',
      isIncome: income,
      accountId: 'cc-jose',
      savingsGoalId: savingsGoalId,
    );
  }

  List<Category> categories({
    String? expenseLinkedGoalId,
    String? incomeLinkedGoalId = joseGoalId,
  }) {
    return [
      Category(
        id: 'other',
        name: 'Altres',
        icon: '',
        subcategories: [
          SubCategory(
            id: bizumsSubcategoryId,
            name: 'Bizums',
            monthlyBudget: 0,
            linkedSavingsGoalId: expenseLinkedGoalId,
          ),
        ],
      ),
      Category(
        id: 'income',
        name: 'Ingressos',
        icon: '',
        type: TransactionType.income,
        subcategories: [
          SubCategory(
            id: savingsSubcategoryId,
            name: 'Ingrés Guardiola Jose',
            monthlyBudget: 0,
            linkedSavingsGoalId: incomeLinkedGoalId,
          ),
        ],
      ),
    ];
  }

  SavingsGoal joseGoal([double balance = 0]) => SavingsGoal(
        id: joseGoalId,
        groupId: 'g',
        name: 'Guardiola Estabilitat Jose',
        icon: '',
        currentAmount: balance,
        color: 0,
        history: const [],
      );

  test('proposa el mirall amb import igual, signe oposat i ±3 dies', () {
    final items = findInternalTransferCandidates([
      tx(
        id: 'expense',
        amount: 70,
        income: false,
        date: DateTime(2026, 7, 10),
        subcategory: bizumsSubcategoryId,
      ),
      tx(
        id: 'income',
        amount: 70,
        income: true,
        date: DateTime(2026, 7, 12),
        subcategory: savingsSubcategoryId,
      ),
    ]);

    expect(items, hasLength(1));
    expect(items.single.expense.id, 'expense');
    expect(items.single.income.id, 'income');
  });

  test('no proposa imports diferents ni dates fora de finestra', () {
    final items = findInternalTransferCandidates([
      tx(
        id: 'expense',
        amount: 70,
        income: false,
        date: DateTime(2026, 7, 10),
        subcategory: bizumsSubcategoryId,
      ),
      tx(
        id: 'wrong-amount',
        amount: 71,
        income: true,
        date: DateTime(2026, 7, 10),
        subcategory: savingsSubcategoryId,
      ),
      tx(
        id: 'wrong-date',
        amount: 70,
        income: true,
        date: DateTime(2026, 7, 14),
        subcategory: savingsSubcategoryId,
      ),
    ]);

    expect(items, isEmpty);
  });

  test('conserva la retirada i manté el saldo de guardiola abans → després',
      () {
    final candidate = findInternalTransferCandidates([
      tx(
        id: 'expense',
        amount: 70,
        income: false,
        date: DateTime(2026, 7, 17),
        subcategory: bizumsSubcategoryId,
        concept: 'Compres Rubí',
      ),
      tx(
        id: 'income',
        amount: 70,
        income: true,
        date: DateTime(2026, 7, 17),
        subcategory: savingsSubcategoryId,
        concept: 'Compres',
      ),
    ]).single;

    final plan = buildInternalTransferMigrationPlans(
      candidates: [candidate],
      categories: categories(),
      goals: [joseGoal()],
    ).single;

    expect(plan.canConvert, isTrue);
    expect(plan.savingsTransaction?.id, 'income');
    expect(plan.expenseToReplace?.id, 'expense');
    expect(plan.savingsGoalName, 'Guardiola Estabilitat Jose');
    expect(plan.savingsBalanceBefore, 0);
    expect(plan.savingsBalanceAfter, 0);
  });

  test('bloqueja estrictament una parella sense cap pota de guardiola', () {
    final candidate = findInternalTransferCandidates([
      tx(
        id: 'expense',
        amount: 15,
        income: false,
        date: DateTime(2026, 7, 16),
        subcategory: bizumsSubcategoryId,
      ),
      tx(
        id: 'income',
        amount: 15,
        income: true,
        date: DateTime(2026, 7, 16),
        subcategory: savingsSubcategoryId,
      ),
    ]).single;

    final plan = buildInternalTransferMigrationPlans(
      candidates: [candidate],
      categories: categories(incomeLinkedGoalId: null),
      goals: [joseGoal()],
    ).single;

    expect(plan.canConvert, isFalse);
    expect(plan.blockedReason, contains('cap de les dues potes'));
  });

  test('bloqueja estrictament una parella amb dues potes de guardiola', () {
    final candidate = findInternalTransferCandidates([
      tx(
        id: 'expense',
        amount: 9,
        income: false,
        date: DateTime(2026, 7, 23),
        subcategory: bizumsSubcategoryId,
      ),
      tx(
        id: 'income',
        amount: 9,
        income: true,
        date: DateTime(2026, 7, 23),
        subcategory: savingsSubcategoryId,
      ),
    ]).single;

    final plan = buildInternalTransferMigrationPlans(
      candidates: [candidate],
      categories: categories(expenseLinkedGoalId: joseGoalId),
      goals: [joseGoal()],
    ).single;

    expect(plan.canConvert, isFalse);
    expect(plan.blockedReason, contains('dues potes'));
  });

  test(
    'els quatre conceptes reals de juliol formen tres conversions '
    'sense moure la guardiola del Jose',
    () {
      final realTransactions = [
        tx(
          id: 'expense-70',
          amount: 70,
          income: false,
          date: DateTime.utc(2026, 7, 17, 22),
          subcategory: bizumsSubcategoryId,
          concept: 'Compres Rubí',
        ),
        tx(
          id: 'income-70',
          amount: 70,
          income: true,
          date: DateTime.utc(2026, 7, 17, 22),
          subcategory: savingsSubcategoryId,
          concept: 'Compres',
        ),
        tx(
          id: 'expense-15',
          amount: 15,
          income: false,
          date: DateTime.utc(2026, 7, 16, 22),
          subcategory: bizumsSubcategoryId,
          concept: 'Dinar Alba',
        ),
        tx(
          id: 'income-15',
          amount: 15,
          income: true,
          date: DateTime.utc(2026, 7, 16, 22),
          subcategory: savingsSubcategoryId,
          concept: 'Dinar Alba',
        ),
        tx(
          id: 'expense-9',
          amount: 9,
          income: false,
          date: DateTime.utc(2026, 7, 23, 18, 10),
          subcategory: bizumsSubcategoryId,
          concept: 'Bizum Jose a Eloi',
        ),
        tx(
          id: 'income-9',
          amount: 9,
          income: true,
          date: DateTime.utc(2026, 7, 23, 18, 9),
          subcategory: savingsSubcategoryId,
          concept: 'Altres',
        ),
      ];

      final plans = buildInternalTransferMigrationPlans(
        candidates: findInternalTransferCandidates(realTransactions),
        categories: categories(),
        goals: [joseGoal()],
      );

      expect(plans, hasLength(3));
      expect(plans.every((plan) => plan.canConvert), isTrue);
      expect(
        plans.map((plan) => plan.expenseToReplace!.concept),
        containsAll(
            <String>['Compres Rubí', 'Dinar Alba', 'Bizum Jose a Eloi']),
      );
      expect(
        plans.every(
          (plan) =>
              plan.savingsGoalId == joseGoalId &&
              plan.savingsBalanceBefore == 0 &&
              plan.savingsBalanceAfter == 0,
        ),
        isTrue,
      );
    },
  );
}
