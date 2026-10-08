import 'package:flutter_test/flutter_test.dart';

import 'package:centim/domain/models/asset.dart';
import 'package:centim/domain/models/savings_goal.dart';
import 'package:centim/presentation/providers/financial_summary_provider.dart';

Asset _asset(String name, double amount, AssetType type) =>
    Asset(id: name, name: name, amount: amount, type: type);

SavingsGoal _goal(String name, double currentAmount) => SavingsGoal(
      id: name,
      groupId: 'g',
      name: name,
      icon: '🐷',
      currentAmount: currentAmount,
      color: 0,
      history: const [],
    );

void main() {
  test('un grup nou sense actius ni guardioles té 0 € d\'actiu', () {
    expect(totalAssetsOf(const [], const []), 0);
  });

  test('l\'actiu és la suma d\'actius registrats i guardioles', () {
    final assets = [
      _asset('CC Principal', 31.39, AssetType.bankAccount),
      _asset('CC Jose', -162.22, AssetType.bankAccount),
      _asset('Compte Comú', -0.18, AssetType.bankAccount),
      _asset('Terreny Camp', 15000, AssetType.realEstate),
      _asset('Hort', 5000, AssetType.realEstate),
      _asset('Masia', 80000, AssetType.realEstate),
    ];
    final goals = [
      _goal('Pla Jubilació Jose', 76.66),
      _goal('Fons Masia', 0.05),
      _goal('Guardiola Estabilitat Eloi', 140.02),
      _goal('Guardiola Estabilitat Jose', 0),
    ];

    // 99.868,99 d'actius + 216,73 de guardioles
    expect(totalAssetsOf(assets, goals), closeTo(100085.72, 0.001));
  });

  test('només guardioles, sense actius registrats', () {
    expect(totalAssetsOf(const [], [_goal('Viatge', 250)]), 250);
  });
}
