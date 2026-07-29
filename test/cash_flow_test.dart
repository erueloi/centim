import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/models/asset.dart';
import 'package:centim/domain/models/billing_cycle.dart';
import 'package:centim/domain/models/savings_goal.dart';
import 'package:centim/domain/models/transfer.dart';
import 'package:centim/domain/services/cash_flow_service.dart';

void main() {
  BillingCycle cycleWith({double? opening}) => BillingCycle(
        id: 'c1',
        groupId: 'g',
        name: 'Juliol 2026',
        startDate: DateTime(2026, 6, 29),
        endDate: DateTime(2026, 7, 30),
        openingBalance: opening,
        openingBalanceSource: opening == null ? null : 'manual',
      );

  Asset asset(String id, double amount,
          [AssetType type = AssetType.bankAccount]) =>
      Asset(id: id, name: id, amount: amount, type: type);

  SavingsGoal goal(String id, double amount, {bool isLiquid = true}) =>
      SavingsGoal(
        id: id,
        groupId: 'g',
        name: id,
        icon: '🏦',
        currentAmount: amount,
        color: 0,
        history: const [],
        isLiquid: isLiquid,
      );

  Transfer transfer({
    required double amount,
    required TransferDestinationType to,
    DateTime? date,
  }) =>
      Transfer(
        id: 't',
        groupId: 'g',
        date: date ?? DateTime(2026, 7, 10),
        amount: amount,
        sourceAssetId: 'cc',
        sourceAssetName: 'CC',
        destinationType: to,
        destinationId: 'd',
        destinationName: 'D',
      );

  CashFlowStatus build({
    double? opening,
    double income = 0,
    double expense = 0,
    List<Transfer> transfers = const [],
    List<Asset> assets = const [],
    List<SavingsGoal> goals = const [],
    Map<String, double> savedByGoal = const {},
    Map<String, double> withdrawnByGoal = const {},
    bool isActive = true,
  }) =>
      buildCashFlowStatus(
        cycle: cycleWith(opening: opening),
        income: income,
        expense: expense,
        transfers: transfers,
        assets: assets,
        goals: goals,
        savedByGoal: savedByGoal,
        withdrawnByGoal: withdrawnByGoal,
        isActiveCycle: isActive,
      );

  group('equació del cicle', () {
    test('saldo final = inicial + ingressos − despeses', () {
      final s = build(opening: 1000, income: 3668, expense: 2500);
      expect(s.closingBalance, 2168);
      expect(s.netOfCycle, 1168);
    });

    test('sense saldo inicial no hi ha saldo final (mode degradat)', () {
      final s = build(income: 3668, expense: 2500);
      expect(s.openingBalance, isNull);
      expect(s.closingBalance, isNull);
      expect(s.difference, isNull);
      expect(s.reconciles, isNull);
      // El flux sí que es pot ensenyar.
      expect(s.netOfCycle, 1168);
    });
  });

  group('el pot', () {
    test('inclou les guardioles i exclou el que no és caixa', () {
      final s = build(
        assets: [
          asset('cc', 1000),
          asset('efectiu', 50, AssetType.cash),
          asset('pis', 200000, AssetType.realEstate),
          asset('altres', 999, AssetType.other),
        ],
        goals: [goal('mybox', 275.36), goal('viatge', 100)],
      );
      expect(s.registeredAccountsTotal, closeTo(1425.36, 0.001));
      expect(s.liquidAccounts.map((a) => a.id), ['cc', 'efectiu']);
      expect(s.savingsAccounts.map((a) => a.id), ['mybox', 'viatge']);
      expect(
        [...s.liquidAccounts, ...s.savingsAccounts]
            .fold(0.0, (sum, account) => sum + account.amount),
        closeTo(s.registeredAccountsTotal, 0.001),
      );
    });

    test('exclou una guardiola no líquida del pot: 8,52 → −65,41', () {
      final s = build(
        assets: [asset('comptes', -65.41)],
        goals: [goal('pla-jubilacio', 73.93, isLiquid: false)],
      );
      expect(s.registeredAccountsTotal, closeTo(-65.41, 0.001));
      expect(s.savingsAccounts, isEmpty);
      expect(s.nonLiquidSavingsAccounts.single.id, 'pla-jubilacio');
      expect(
          totalPot(
            [asset('comptes', -65.41)],
            [goal('pla-jubilacio', 73.93, isLiquid: false)],
          ),
          closeTo(-65.41, 0.001));
    });
  });

  group('traspassos', () {
    test('actiu→actiu és intern: no mou el pot', () {
      final s = build(
        opening: 1000,
        transfers: [
          transfer(amount: 400, to: TransferDestinationType.asset),
        ],
      );
      expect(s.transfersNet, 0);
      expect(s.closingBalance, 1000);
    });

    test('actiu→deute treu diners del pot', () {
      final s = build(
        opening: 1000,
        transfers: [transfer(amount: 400, to: TransferDestinationType.debt)],
      );
      expect(s.transfersNet, -400);
      expect(s.closingBalance, 600);
    });

    test('aportar a guardiola no líquida surt per Traspassos', () {
      final s = build(
        opening: 1000,
        assets: [asset('cc', 870)],
        goals: [goal('pensions', 130, isLiquid: false)],
        savedByGoal: const {'pensions': 130},
      );
      expect(s.transfersNet, -130);
      expect(s.closingBalance, 870);
      expect(s.registeredAccountsTotal, 870);
      expect(s.reconciles, isTrue);
    });

    test('retirar de guardiola no líquida entra per Traspassos', () {
      final s = build(
        opening: 870,
        assets: [asset('cc', 1000)],
        goals: [goal('pensions', 0, isLiquid: false)],
        withdrawnByGoal: const {'pensions': 130},
      );
      expect(s.transfersNet, 130);
      expect(s.closingBalance, 1000);
      expect(s.reconciles, isTrue);
    });

    test('els traspassos de fora del cicle no compten', () {
      final s = build(
        opening: 1000,
        transfers: [
          transfer(
            amount: 400,
            to: TransferDestinationType.debt,
            date: DateTime(2026, 8, 15),
          ),
        ],
      );
      expect(s.transfersNet, 0);
    });

    test('el darrer dia del cicle compta (endDate és INCLUSIU)', () {
      final s = build(
        opening: 1000,
        transfers: [
          transfer(
            amount: 400,
            to: TransferDestinationType.debt,
            date: DateTime(2026, 7, 30, 23, 59),
          ),
        ],
      );
      expect(s.transfersNet, -400);
    });
  });

  group('quadrament', () {
    test('quadra quan el saldo previst i els comptes coincideixen', () {
      final s = build(
        opening: 1000,
        income: 500,
        expense: 200,
        assets: [asset('cc', 1300)],
      );
      expect(s.difference, closeTo(0, 0.001));
      expect(s.reconciles, isTrue);
    });

    test('una aportació a guardiola amb compte no mou el pot', () {
      // El moviment surt del compte (−130) i entra a la guardiola (+130).
      // El ledger l'exclou dels totals, i el pot queda igual → quadra.
      final s = build(
        opening: 1000,
        assets: [asset('cc', 870)],
        goals: [goal('mybox', 130)],
      );
      expect(s.reconciles, isTrue);
    });

    test('REGRESSIÓ: una aportació SENSE compte descuadra pel seu import', () {
      // Només s'aplica el +130 a la guardiola; el compte no baixa.
      // El pot creix del no-res i el descuadre delata l'import exacte.
      final s = build(
        opening: 1000,
        assets: [asset('cc', 1000)],
        goals: [goal('mybox', 130)],
      );
      expect(s.reconciles, isFalse);
      expect(s.difference, closeTo(-130, 0.001));
    });

    test('tolera un cèntim d\'arrodoniment', () {
      final s = build(opening: 1000, assets: [asset('cc', 1000.01)]);
      expect(s.reconciles, isTrue);
    });

    test('un cicle NO actiu no es compara amb els comptes d\'avui', () {
      final s = build(
        opening: 1000,
        assets: [asset('cc', 999999)],
        isActive: false,
      );
      expect(s.closingBalance, 1000); // l'equació sí que es calcula
      expect(s.difference, isNull); // la comparació no
      expect(s.reconciles, isNull);
    });
  });
}
