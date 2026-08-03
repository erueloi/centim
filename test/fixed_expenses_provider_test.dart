import 'package:centim/domain/models/billing_cycle.dart';
import 'package:centim/domain/models/category.dart';
import 'package:centim/domain/models/savings_goal.dart';
import 'package:centim/domain/services/ledger_service.dart';
import 'package:centim/presentation/providers/budget_provider.dart';
import 'package:centim/presentation/providers/fixed_expenses_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cycle = BillingCycle(
    id: 'august',
    groupId: 'group',
    name: 'Agost 2026',
    startDate: DateTime(2026, 7, 30),
    endDate: DateTime(2026, 8, 28),
  );

  test('un fix vençut continua pendent fins que l’import queda cobert', () {
    final statuses = [
      _status([
        _subStatus(
          id: 'mybox',
          budget: 275.36,
          spent: 109.36,
          paymentDay: 1,
        ),
      ]),
    ];

    final items = calculateFixedExpenseItems(
      statuses: statuses,
      ledger: LedgerSummary(),
      goals: const [],
      cycle: cycle,
      today: DateTime(2026, 8, 7),
    );

    expect(items, hasLength(1));
    expect(items.single.remaining, closeTo(166, 0.001));
    expect(items.single.covered, closeTo(109.36, 0.001));
    expect(items.single.isOverdue, isTrue);
    expect(items.single.scheduledDate, DateTime(2026, 8, 1));
  });

  test('un pagament complet elimina l’obligació encara que sigui anticipat',
      () {
    final items = calculateFixedExpenseItems(
      statuses: [
        _status([
          _subStatus(
            id: 'paid',
            budget: 100,
            spent: 100,
            paymentDay: 20,
          ),
        ]),
      ],
      ledger: LedgerSummary(),
      goals: const [],
      cycle: cycle,
      today: DateTime(2026, 8, 3),
    );

    expect(items, isEmpty);
  });

  test('ignora residus inferiors a max(1 euro, 1% del pressupost)', () {
    final items = calculateFixedExpenseItems(
      statuses: [
        _status([
          _subStatus(
            id: 'visa',
            budget: 145.18,
            spent: 145.16,
            paymentDay: 20,
          ),
        ]),
        _status([
          _subStatus(
            id: 'salary',
            budget: 2600,
            spent: 2599.64,
            paymentDay: 1,
          ),
        ], type: TransactionType.income),
      ],
      ledger: LedgerSummary(),
      goals: const [],
      cycle: cycle,
      today: DateTime(2026, 8, 3),
    );

    expect(items, isEmpty);
  });

  test('manté pendent un import igual al llindar de cobertura', () {
    final items = calculateFixedExpenseItems(
      statuses: [
        _status([
          _subStatus(
            id: 'one-euro',
            budget: 100,
            spent: 99,
            paymentDay: 20,
          ),
          _subStatus(
            id: 'one-percent',
            budget: 2600,
            spent: 2574,
            paymentDay: 20,
          ),
        ]),
      ],
      ledger: LedgerSummary(),
      goals: const [],
      cycle: cycle,
      today: DateTime(2026, 8, 3),
    );

    expect(items, hasLength(2));
    expect(
      items.map((item) => item.remaining),
      containsAll(<double>[1, 26]),
    );
  });

  test('un fix sense data queda classificat com a per venir', () {
    final items = calculateFixedExpenseItems(
      statuses: [
        _status([
          _subStatus(
            id: 'without-date',
            budget: 50,
            spent: 0,
          ),
        ]),
      ],
      ledger: LedgerSummary(),
      goals: const [],
      cycle: cycle,
      today: DateTime(2026, 8, 3),
    );

    expect(items, hasLength(1));
    expect(items.single.scheduledDate, isNull);
    expect(items.single.isOverdue, isFalse);
  });

  test('primer i últim dia hàbil es resolen dins del cicle', () {
    const first = SubCategory(
      id: 'first',
      name: 'Primer',
      monthlyBudget: 1,
      isFixed: true,
      paymentTiming: PaymentTiming.firstBusinessDay,
    );
    const last = SubCategory(
      id: 'last',
      name: 'Últim',
      monthlyBudget: 1,
      isFixed: true,
      paymentTiming: PaymentTiming.lastBusinessDay,
    );

    expect(scheduledPaymentDate(first, cycle), DateTime(2026, 8, 3));
    expect(scheduledPaymentDate(last, cycle), DateTime(2026, 7, 31));
  });

  test('pressupost efectiu zero no crea cap pendent', () {
    final items = calculateFixedExpenseItems(
      statuses: [
        _status([
          _subStatus(
            id: 'zero',
            budget: 0,
            spent: 0,
            paymentDay: 10,
            linkedSavingsGoalId: 'pension',
          ),
        ]),
      ],
      ledger: LedgerSummary(),
      goals: [_goal('pension', isLiquid: false)],
      cycle: cycle,
      today: DateTime(2026, 8, 3),
    );

    expect(items, isEmpty);
  });

  test('només la guardiola no líquida afecta el marge del pot', () {
    final ledger = LedgerSummary()
      ..savedBySubcategory['liquid-sub'] = 20
      ..savedBySubcategory['pension-sub'] = 25;
    final items = calculateFixedExpenseItems(
      statuses: [
        _status([
          _subStatus(
            id: 'liquid-sub',
            budget: 100,
            spent: 0,
            paymentDay: 10,
            linkedSavingsGoalId: 'liquid',
          ),
          _subStatus(
            id: 'pension-sub',
            budget: 100,
            spent: 0,
            paymentDay: 10,
            linkedSavingsGoalId: 'pension',
          ),
        ]),
      ],
      ledger: ledger,
      goals: [
        _goal('liquid', isLiquid: true),
        _goal('pension', isLiquid: false),
      ],
      cycle: cycle,
      today: DateTime(2026, 8, 3),
    );

    final liquid = items.firstWhere(
      (item) => item.subCategory.id == 'liquid-sub',
    );
    final pension = items.firstWhere(
      (item) => item.subCategory.id == 'pension-sub',
    );
    expect(liquid.remaining, 80);
    expect(liquid.affectsPot, isFalse);
    expect(pension.remaining, 75);
    expect(pension.affectsPot, isTrue);
  });
}

BudgetStatus _status(
  List<SubcategoryBudgetStatus> subcategories, {
  TransactionType type = TransactionType.expense,
}) {
  final budget = subcategories.fold(0.0, (sum, item) => sum + item.budget);
  final spent = subcategories.fold(0.0, (sum, item) => sum + item.spent);
  return BudgetStatus(
    category: Category(
      id: type.name,
      name: type.name,
      icon: '',
      type: type,
      subcategories: subcategories.map((item) => item.subcategory).toList(),
    ),
    spent: spent,
    total: budget,
    percentage: budget == 0 ? 0 : spent / budget,
    isOverBudget: spent > budget,
    subcategoryStatuses: subcategories,
  );
}

SubcategoryBudgetStatus _subStatus({
  required String id,
  required double budget,
  required double spent,
  int? paymentDay,
  String? linkedSavingsGoalId,
}) =>
    SubcategoryBudgetStatus(
      subcategory: SubCategory(
        id: id,
        name: id,
        monthlyBudget: budget,
        isFixed: true,
        paymentDay: paymentDay,
        linkedSavingsGoalId: linkedSavingsGoalId,
      ),
      spent: spent,
      budget: budget,
      percentage: budget == 0 ? 0 : spent / budget,
    );

SavingsGoal _goal(String id, {required bool isLiquid}) => SavingsGoal(
      id: id,
      groupId: 'group',
      name: id,
      icon: '',
      currentAmount: 0,
      color: 0,
      history: const [],
      isLiquid: isLiquid,
    );
