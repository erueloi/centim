import '../models/asset.dart';
import '../models/billing_cycle.dart';
import '../models/savings_goal.dart';
import '../models/transfer.dart';
import '../models/balance_adjustment.dart';

/// Estat de CAIXA d'un cicle: "en quin moment estic", separat de "on gasto"
/// (això últim és el pressupost / el donut).
///
/// FILOSOFIA: els comptes són UN SOL POT. El pot són els actius líquids més les
/// guardioles disponibles immediatament.
///
///   Pot = Σ assets(bankAccount, cash).amount
///       + Σ savings_goals(isLiquid=true).currentAmount
///
/// D'aquí surt què mou el pot i què no:
///   · ingressos i despeses reals   → SÍ, són diners que entren o surten
///   · guardiola líquida → traspàs intern, no mou el pot
///   · guardiola no líquida → aportar treu diners del pot; retirar-ne n'entra
///   · traspàs entre dos actius registrats → NO, és intern
///   · traspàs d'un actiu a un deute → SÍ, els diners surten del pot
///
/// L'equació del cicle és:
///   Saldo final = Saldo inicial + Ingressos − Despeses ± Traspassos
///
/// Els ingressos i les despeses NO es tornen a sumar aquí: arriben ja calculats
/// pel `ledger_service`, que és l'única font de veritat.

/// Actius que compten com a caixa. `realEstate` i `other` no són diners
/// disponibles; formen part del patrimoni, que és una altra pregunta.
bool isLiquidAsset(Asset a) =>
    a.type == AssetType.bankAccount || a.type == AssetType.cash;

bool isLiquidSavingsGoal(SavingsGoal goal) => goal.isLiquid;

/// Tolerància del quadrament, per arrodoniments de cèntim.
const double kCashFlowTolerance = 0.01;

class RegisteredAccountBalance {
  final String id;
  final String name;
  final double amount;

  const RegisteredAccountBalance({
    required this.id,
    required this.name,
    required this.amount,
  });
}

class CashPotBreakdown {
  final List<RegisteredAccountBalance> liquidAccounts;
  final List<RegisteredAccountBalance> liquidSavings;
  final List<RegisteredAccountBalance> nonLiquidSavings;

  const CashPotBreakdown({
    required this.liquidAccounts,
    required this.liquidSavings,
    required this.nonLiquidSavings,
  });

  double get total => [
        ...liquidAccounts,
        ...liquidSavings,
      ].fold(0.0, (sum, account) => sum + account.amount);
}

class CashFlowStatus {
  /// Pot amb què obre el cicle. `null` = no registrat (mode degradat).
  final double? openingBalance;
  final String? openingBalanceSource;

  final double income;
  final double expense;

  /// Efecte net dels traspassos sobre el pot (negatiu = en surten diners).
  /// Avui l'alimenten els traspassos a deute; els traspassos entre actius
  /// registrats són interns i valen 0.
  final double transfersNet;

  /// Ajustos manuals de reconciliació que afectaven el pot en el moment de
  /// registrar-los. Les reversions també hi entren: el net continua sent
  /// comptablement correcte, encara que no comptin com a ajustos "reals".
  final double balanceAdjustmentsNet;
  final List<RegisteredAccountBalance> balanceAdjustments;

  /// Suma dels comptes registrats: actius líquids + guardioles líquides.
  ///
  /// ATENCIÓ: NO és el saldo real de CaixaBank. `Asset.amount` és un saldo
  /// corrent que manté la pròpia app aplicant deltes, i cap sincronització
  /// n'escriu el balance real. És, doncs, el mateix llibre comptabilitzat per
  /// una altra via (la de `accountId`), i per això serveix per detectar fuites
  /// —moviments sense compte assignat— però no per verificar-se contra el banc.
  /// Detall que compon [registeredAccountsTotal]. Les dues llistes es mantenen
  /// separades perquè la UI pugui distingir comptes, guardioles líquides i
  /// guardioles no disponibles immediatament.
  final List<RegisteredAccountBalance> liquidAccounts;
  final List<RegisteredAccountBalance> savingsAccounts;
  final List<RegisteredAccountBalance> nonLiquidSavingsAccounts;

  /// Si la comparació contra els comptes registrats té sentit. Només al cicle
  /// ACTIU: `Asset.amount` i `currentAmount` són l'estat d'ARA, no el d'un
  /// cicle passat, i comparar-los amb un tancament antic no vol dir res.
  final bool comparable;

  const CashFlowStatus({
    required this.openingBalance,
    required this.openingBalanceSource,
    required this.income,
    required this.expense,
    required this.transfersNet,
    required this.balanceAdjustmentsNet,
    required this.balanceAdjustments,
    required this.liquidAccounts,
    required this.savingsAccounts,
    required this.nonLiquidSavingsAccounts,
    required this.comparable,
  });

  double get registeredAccountsTotal => [
        ...liquidAccounts,
        ...savingsAccounts,
      ].fold(0.0, (sum, account) => sum + account.amount);

  /// Net del cicle: el que ha entrat menys el que ha sortit. No és caixa.
  double get netOfCycle => income - expense;

  /// Saldo final previst. `null` si no hi ha saldo inicial registrat: sense
  /// punt de partida no hi ha punt d'arribada, i no ens l'inventem.
  double? get closingBalance => openingBalance == null
      ? null
      : openingBalance! +
          income -
          expense +
          transfersNet +
          balanceAdjustmentsNet;

  /// Diferència entre el saldo final previst i els comptes registrats.
  double? get difference => (closingBalance == null || !comparable)
      ? null
      : closingBalance! - registeredAccountsTotal;

  /// `null` quan no es pot avaluar (sense saldo inicial, o cicle no actiu).
  bool? get reconciles {
    final d = difference;
    return d == null ? null : d.abs() <= kCashFlowTolerance;
  }
}

CashPotBreakdown buildCashPotBreakdown(
  List<Asset> assets,
  List<SavingsGoal> goals,
) {
  RegisteredAccountBalance assetBalance(Asset asset) =>
      RegisteredAccountBalance(
        id: asset.id,
        name: asset.name,
        amount: asset.amount,
      );
  RegisteredAccountBalance goalBalance(SavingsGoal goal) =>
      RegisteredAccountBalance(
        id: goal.id,
        name: goal.name,
        amount: goal.currentAmount,
      );

  return CashPotBreakdown(
    liquidAccounts:
        assets.where(isLiquidAsset).map(assetBalance).toList(growable: false),
    liquidSavings: goals
        .where(isLiquidSavingsGoal)
        .map(goalBalance)
        .toList(growable: false),
    nonLiquidSavings: goals
        .where((goal) => !isLiquidSavingsGoal(goal))
        .map(goalBalance)
        .toList(growable: false),
  );
}

/// Suma el pot: actius líquids + guardioles líquides.
///
/// Sumar totes dues coses és correcte perquè no se solapen: les guardioles
/// viuen només a `savings_goals` i cap actiu líquid en representa una. Si algun
/// dia una guardiola es registrés també com a `Asset`, es comptaria dos cops.
double totalPot(List<Asset> assets, List<SavingsGoal> goals) {
  return buildCashPotBreakdown(assets, goals).total;
}

/// Efecte net sobre el pot dels traspassos d'una finestra.
///
/// Actiu → actiu: els diners es queden dins del pot, no compta.
/// Actiu → deute: els diners surten a pagar deute, resta.
double transfersEffectOnPot(Iterable<Transfer> transfersInCycle) {
  var net = 0.0;
  for (final t in transfersInCycle) {
    if (t.destinationType == TransferDestinationType.debt) net -= t.amount;
  }
  return net;
}

/// Aportar a una guardiola no líquida és una sortida del pot; retirar-ne és
/// una entrada. Els imports provenen del ledger, agregats per guardiola.
double nonLiquidSavingsEffectOnPot({
  required Iterable<SavingsGoal> goals,
  required Map<String, double> savedByGoal,
  required Map<String, double> withdrawnByGoal,
}) {
  var net = 0.0;
  for (final goal in goals.where((goal) => !goal.isLiquid)) {
    net -= savedByGoal[goal.id] ?? 0;
    net += withdrawnByGoal[goal.id] ?? 0;
  }
  return net;
}

/// Filtra per la finestra del cicle. `endDate` és INCLUSIU (vegeu
/// `cycle_integrity_service.dart`), i la comparació és a nivell de DIA perquè
/// els documents no tenen una hora consistent.
bool isWithinCycle(DateTime date, BillingCycle cycle) {
  final d = DateTime(date.year, date.month, date.day);
  final start = DateTime(
      cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
  final end =
      DateTime(cycle.endDate.year, cycle.endDate.month, cycle.endDate.day);
  return !d.isBefore(start) && !d.isAfter(end);
}

/// Munta l'estat de caixa. Funció PURA: els ingressos i les despeses ja venen
/// calculats pel `ledger_service`; aquí no es torna a classificar res.
CashFlowStatus buildCashFlowStatus({
  required BillingCycle cycle,
  required double income,
  required double expense,
  required List<Transfer> transfers,
  required List<Asset> assets,
  required List<SavingsGoal> goals,
  required Map<String, double> savedByGoal,
  required Map<String, double> withdrawnByGoal,
  required bool isActiveCycle,
  List<BalanceAdjustment> balanceAdjustments = const [],
}) {
  final inCycle = transfers.where((t) => isWithinCycle(t.date, cycle));
  final pot = buildCashPotBreakdown(assets, goals);
  final nonLiquidSavingsNet = nonLiquidSavingsEffectOnPot(
    goals: goals,
    savedByGoal: savedByGoal,
    withdrawnByGoal: withdrawnByGoal,
  );
  final adjustmentsInCycle = balanceAdjustments
      .where(
        (adjustment) =>
            adjustment.affectsPot && isWithinCycle(adjustment.date, cycle),
      )
      .toList(growable: false);
  final adjustmentAmountsByGoal = <String, double>{};
  final adjustmentNamesByGoal = <String, String>{};
  for (final adjustment in adjustmentsInCycle) {
    adjustmentAmountsByGoal[adjustment.savingsGoalId] =
        (adjustmentAmountsByGoal[adjustment.savingsGoalId] ?? 0) +
            adjustment.amount;
    adjustmentNamesByGoal[adjustment.savingsGoalId] =
        adjustment.savingsGoalName;
  }
  final adjustmentBreakdown = adjustmentAmountsByGoal.entries
      .map(
        (entry) => RegisteredAccountBalance(
          id: entry.key,
          name: adjustmentNamesByGoal[entry.key] ?? 'Guardiola',
          amount: entry.value,
        ),
      )
      .toList(growable: false);
  final balanceAdjustmentsNet = adjustmentBreakdown.fold(
    0.0,
    (sum, adjustment) => sum + adjustment.amount,
  );

  return CashFlowStatus(
    openingBalance: cycle.openingBalance,
    openingBalanceSource: cycle.openingBalanceSource,
    income: income,
    expense: expense,
    transfersNet: transfersEffectOnPot(inCycle) + nonLiquidSavingsNet,
    balanceAdjustmentsNet: balanceAdjustmentsNet,
    balanceAdjustments: adjustmentBreakdown,
    liquidAccounts: pot.liquidAccounts,
    savingsAccounts: pot.liquidSavings,
    nonLiquidSavingsAccounts: pot.nonLiquidSavings,
    comparable: isActiveCycle,
  );
}
