import 'package:centim/domain/models/billing_cycle.dart';
import 'package:centim/domain/models/category.dart';
import 'package:centim/presentation/providers/budget_provider.dart';
import 'package:centim/presentation/providers/cycle_spending_margin_provider.dart';
import 'package:centim/presentation/screens/budget/budget_control_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  final cycle = BillingCycle(
    id: 'july',
    groupId: 'group',
    name: 'Juliol 2026',
    startDate: DateTime(2026, 6, 29),
    endDate: DateTime(2026, 7, 30),
  );

  test('projecta pot + ingressos pendents - fixos que encara no han caigut',
      () {
    final statuses = [
      _status(
        type: TransactionType.income,
        subcategories: [
          _subStatus(
            id: 'salary',
            budget: 2500,
            spent: 2000,
          ),
          // Haver ingressat més del previst no crea cap "pendent" negatiu.
          _subStatus(
            id: 'extra-income',
            budget: 100,
            spent: 180,
          ),
        ],
      ),
      _status(
        type: TransactionType.expense,
        subcategories: [
          _subStatus(
            id: 'future-fixed',
            budget: 300,
            spent: 0,
            isFixed: true,
            paymentDay: 20,
          ),
          _subStatus(
            id: 'past-fixed',
            budget: 200,
            spent: 0,
            isFixed: true,
            paymentDay: 10,
          ),
        ],
      ),
    ];

    final result = calculateCycleSpendingMargin(
      availableNow: 100,
      statuses: statuses,
      cycle: cycle,
      today: DateTime(2026, 7, 15),
      hasOpeningBalance: true,
      isCurrentCycle: true,
    );

    expect(result.pendingIncome, 500);
    expect(
      result.pendingIncomeItems.map((item) => item.name),
      ['salary'],
    );
    expect(result.pendingIncomeItems.single.amount, 500);
    expect(result.pendingFixedExpenses, 300);
    expect(
      result.pendingFixedExpenseItems.map((item) => item.name),
      ['future-fixed'],
    );
    expect(result.pendingFixedExpenseItems.single.amount, 300);
    expect(result.margin, 300);
    expect(result.daysRemaining, 15);
    expect(result.perDay, 20);
  });

  test('ordena els conceptes pendents de més gran a més petit', () {
    final statuses = [
      _status(
        type: TransactionType.income,
        subcategories: [
          _subStatus(id: 'petit', budget: 10, spent: 0),
          _subStatus(id: 'gran', budget: 40, spent: 0),
          _subStatus(id: 'mitjà', budget: 25, spent: 0),
          _subStatus(id: 'quart', budget: 15, spent: 0),
        ],
      ),
    ];

    final result = calculateCycleSpendingMargin(
      availableNow: 0,
      statuses: statuses,
      cycle: cycle,
      today: DateTime(2026, 7, 15),
      hasOpeningBalance: true,
      isCurrentCycle: true,
    );

    expect(
      result.pendingIncomeItems.map((item) => item.name),
      ['gran', 'mitjà', 'quart', 'petit'],
    );
  });

  test('un fix pagat abans del venciment no es reserva dues vegades', () {
    final result = calculateCycleSpendingMargin(
      availableNow: 80,
      statuses: [
        _status(
          type: TransactionType.expense,
          subcategories: [
            _subStatus(
              id: 'paid-early',
              budget: 50,
              spent: 50,
              isFixed: true,
              paymentDay: 25,
            ),
          ],
        ),
      ],
      cycle: cycle,
      today: DateTime(2026, 7, 15),
      hasOpeningBalance: true,
      isCurrentCycle: true,
    );

    expect(result.pendingFixedExpenses, 0);
    expect(result.margin, 80);
  });

  test('les guardioles no inflen ingressos pendents ni fixos ni desviació', () {
    final result = calculateCycleSpendingMargin(
      availableNow: 25,
      statuses: [
        _status(
          type: TransactionType.income,
          subcategories: [
            _subStatus(
              id: 'withdrawal',
              budget: 600,
              spent: 0,
              linkedSavingsGoalId: 'goal',
            ),
          ],
        ),
        _status(
          type: TransactionType.expense,
          subcategories: [
            _subStatus(
              id: 'saving',
              budget: 200,
              spent: 0,
              isFixed: true,
              paymentDay: 25,
              linkedSavingsGoalId: 'goal',
            ),
          ],
        ),
      ],
      cycle: cycle,
      today: DateTime(2026, 7, 15),
      hasOpeningBalance: false,
      isCurrentCycle: true,
    );

    expect(result.pendingIncome, 0);
    expect(result.pendingFixedExpenses, 0);
    expect(result.budgetDeviation, 0);
    expect(result.margin, 25);
    expect(result.hasOpeningBalance, isFalse);
  });

  test('respecta primer i últim dia laborable del mes pressupostari', () {
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

    expect(scheduledPaymentDate(first, cycle), DateTime(2026, 7, 1));
    expect(scheduledPaymentDate(last, cycle), DateTime(2026, 7, 31));
  });

  test('clampa el dia 31 al darrer dia del mes', () {
    final februaryCycle = BillingCycle(
      id: 'february',
      groupId: 'group',
      name: 'Febrer 2026',
      startDate: DateTime(2026, 1, 29),
      endDate: DateTime(2026, 2, 28),
    );
    const sub = SubCategory(
      id: 'fixed',
      name: 'Fix',
      monthlyBudget: 1,
      isFixed: true,
      paymentDay: 31,
    );

    expect(
      scheduledPaymentDate(sub, februaryCycle),
      DateTime(2026, 2, 28),
    );
  });

  test('el resum compacte usa singular i plural correctament', () {
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€');

    expect(
      remainingDaysSummary(1, -58.15, currency),
      startsWith('1 dia restant · '),
    );
    expect(
      remainingDaysSummary(2, -29.075, currency),
      startsWith('2 dies restants · '),
    );
    expect(
      remainingDaysSummary(0, null, currency),
      'Últim dia del cicle',
    );
  });
}

BudgetStatus _status({
  required TransactionType type,
  required List<SubcategoryBudgetStatus> subcategories,
}) {
  final budget =
      subcategories.fold(0.0, (sum, subcategory) => sum + subcategory.budget);
  final spent =
      subcategories.fold(0.0, (sum, subcategory) => sum + subcategory.spent);
  return BudgetStatus(
    category: Category(
      id: type.name,
      name: type.name,
      icon: '',
      type: type,
      subcategories: subcategories.map((status) => status.subcategory).toList(),
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
  bool isFixed = false,
  int? paymentDay,
  String? linkedSavingsGoalId,
}) {
  return SubcategoryBudgetStatus(
    subcategory: SubCategory(
      id: id,
      name: id,
      monthlyBudget: budget,
      isFixed: isFixed,
      paymentDay: paymentDay,
      linkedSavingsGoalId: linkedSavingsGoalId,
    ),
    spent: spent,
    budget: budget,
    percentage: budget == 0 ? 0 : spent / budget,
  );
}
