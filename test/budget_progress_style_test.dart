import 'package:centim/presentation/widgets/budget_progress_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('els trams de consum coincideixen amb Despeses per Vigilar', () {
    expect(budgetConsumptionColor(0.79), Colors.green);
    expect(budgetConsumptionColor(0.80), Colors.orange);
    expect(budgetConsumptionColor(1.00), Colors.red);
  });

  test('ingressos i estalvi inverteixen el significat del percentatge', () {
    expect(budgetAchievementColor(0.79), Colors.red);
    expect(budgetAchievementColor(0.80), Colors.orange);
    expect(budgetAchievementColor(1.00), Colors.green);
  });
}
