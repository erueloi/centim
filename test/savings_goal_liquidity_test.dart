import 'package:centim/data/repositories/firestore_savings_goal_repository.dart';
import 'package:centim/domain/models/savings_goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SavingsGoal goal({required bool isLiquid}) => SavingsGoal(
        id: 'pensions',
        groupId: 'g',
        name: 'Pla Jubilació Jose',
        icon: '🏦',
        currentAmount: 73.93,
        color: 0,
        history: const [],
        isLiquid: isLiquid,
      );

  test('isLiquid persisteix en el round-trip de Firestore', () {
    final restored = savingsGoalFromFirestoreMap(
      savingsGoalToFirestoreMap(goal(isLiquid: false)),
      'pensions',
    );
    expect(restored.isLiquid, isFalse);
  });

  test('documents antics sense isLiquid continuen sent líquids', () {
    final legacy = savingsGoalToFirestoreMap(goal(isLiquid: true))
      ..remove('isLiquid');
    expect(savingsGoalFromFirestoreMap(legacy, 'pensions').isLiquid, isTrue);
  });
}
