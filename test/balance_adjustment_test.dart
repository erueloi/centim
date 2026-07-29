import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/models/balance_adjustment.dart';
import 'package:centim/domain/models/billing_cycle.dart';
import 'package:centim/domain/services/cash_flow_service.dart';

void main() {
  BalanceAdjustment adjustment({
    required String id,
    required double amount,
    required bool affectsPot,
    BalanceAdjustmentType type = BalanceAdjustmentType.adjustment,
    String? reverses,
    DateTime? date,
  }) =>
      BalanceAdjustment(
        id: id,
        groupId: 'group',
        savingsGoalId: 'goal',
        savingsGoalName: 'Guardiola',
        date: date ?? DateTime(2026, 7, 10),
        amount: amount,
        reason: 'Reconciliació',
        affectsPot: affectsPot,
        type: type,
        reversesAdjustmentId: reverses,
      );

  test('adjustment plus reversal nets to zero and counts as no real adjustment',
      () {
    final items = [
      adjustment(id: 'a1', amount: 25, affectsPot: true),
      adjustment(
        id: 'r1',
        amount: -25,
        affectsPot: true,
        type: BalanceAdjustmentType.reversal,
        reverses: 'a1',
      ),
    ];

    expect(
      effectiveAdjustmentCount(
        items,
        since: DateTime(2026, 1, 1),
        savingsGoalId: 'goal',
      ),
      0,
    );
  });

  test('only liquid-at-adjustment entries affect the cash equation', () {
    final status = buildCashFlowStatus(
      cycle: BillingCycle(
        id: 'cycle',
        groupId: 'group',
        name: 'Juliol',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        openingBalance: 100,
      ),
      income: 0,
      expense: 0,
      transfers: const [],
      assets: const [],
      goals: const [],
      savedByGoal: const {},
      withdrawnByGoal: const {},
      isActiveCycle: true,
      balanceAdjustments: [
        adjustment(id: 'liquid', amount: 10, affectsPot: true),
        adjustment(id: 'non-liquid', amount: 40, affectsPot: false),
      ],
    );

    expect(status.balanceAdjustmentsNet, 10);
    expect(status.balanceAdjustments, hasLength(1));
    expect(status.balanceAdjustments.single.name, 'Guardiola');
    expect(status.closingBalance, 110);
  });
}
