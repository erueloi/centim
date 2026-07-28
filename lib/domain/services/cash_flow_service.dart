import '../models/asset.dart';
import '../models/billing_cycle.dart';
import '../models/savings_goal.dart';
import '../models/transfer.dart';

/// Estat de CAIXA d'un cicle: "en quin moment estic", separat de "on gasto"
/// (això últim és el pressupost / el donut).
///
/// FILOSOFIA: els comptes són UN SOL POT. El pot són els actius líquids més les
/// guardioles, perquè les guardioles són comptes bancaris reals, no etiquetes.
///
///   Pot = Σ assets(bankAccount, cash).amount + Σ savings_goals.currentAmount
///
/// D'aquí surt què mou el pot i què no:
///   · ingressos i despeses reals   → SÍ, són diners que entren o surten
///   · aportar/retirar d'una guardiola → NO, és un traspàs intern
///     (el `ledger_service` ja els aparta als cistells saved/withdrawn)
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

  /// Suma dels comptes registrats: actius líquids + guardioles.
  ///
  /// ATENCIÓ: NO és el saldo real de CaixaBank. `Asset.amount` és un saldo
  /// corrent que manté la pròpia app aplicant deltes, i cap sincronització
  /// n'escriu el balance real. És, doncs, el mateix llibre comptabilitzat per
  /// una altra via (la de `accountId`), i per això serveix per detectar fuites
  /// —moviments sense compte assignat— però no per verificar-se contra el banc.
  /// Detall que compon [registeredAccountsTotal]. Les dues llistes es mantenen
  /// separades perquè la UI pugui distingir els comptes de les guardioles.
  final List<RegisteredAccountBalance> liquidAccounts;
  final List<RegisteredAccountBalance> savingsAccounts;

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
    required this.liquidAccounts,
    required this.savingsAccounts,
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
      : openingBalance! + income - expense + transfersNet;

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

/// Suma el pot: actius líquids + guardioles.
///
/// Sumar totes dues coses és correcte perquè no se solapen: les guardioles
/// viuen només a `savings_goals` i cap actiu líquid en representa una. Si algun
/// dia una guardiola es registrés també com a `Asset`, es comptaria dos cops.
double totalPot(List<Asset> assets, List<SavingsGoal> goals) {
  final liquid = assets.where(isLiquidAsset).fold(0.0, (s, a) => s + a.amount);
  final saved = goals.fold(0.0, (s, g) => s + g.currentAmount);
  return liquid + saved;
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
  required bool isActiveCycle,
}) {
  final inCycle = transfers.where((t) => isWithinCycle(t.date, cycle));
  final liquidAccounts = assets
      .where(isLiquidAsset)
      .map(
        (asset) => RegisteredAccountBalance(
          id: asset.id,
          name: asset.name,
          amount: asset.amount,
        ),
      )
      .toList();
  final savingsAccounts = goals
      .map(
        (goal) => RegisteredAccountBalance(
          id: goal.id,
          name: goal.name,
          amount: goal.currentAmount,
        ),
      )
      .toList();

  return CashFlowStatus(
    openingBalance: cycle.openingBalance,
    openingBalanceSource: cycle.openingBalanceSource,
    income: income,
    expense: expense,
    transfersNet: transfersEffectOnPot(inCycle),
    liquidAccounts: liquidAccounts,
    savingsAccounts: savingsAccounts,
    comparable: isActiveCycle,
  );
}
