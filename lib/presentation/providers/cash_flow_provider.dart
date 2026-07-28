import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/billing_cycle.dart';
import '../../domain/models/transaction.dart';
import '../../domain/services/cash_flow_service.dart';
import '../../domain/services/cycle_integrity_service.dart';
import 'asset_provider.dart';
import 'billing_cycle_provider.dart';
import 'financial_summary_provider.dart';
import 'savings_goal_provider.dart';
import 'transaction_notifier.dart';
import 'transfer_provider.dart';

/// Estat de caixa del cicle seleccionat. `null` mentre falti alguna dada.
///
/// Es llegeix tot de providers ja carregats a memòria (`valueOrNull`): cap
/// consulta nova, cap lectura facturada. I es fa amb un `Provider` síncron, no
/// amb `.future`, perquè alguns notifiers emeten `Stream.empty()` mentre
/// carreguen i esperar-ne el futur deixaria la targeta penjada per sempre.
final cashFlowStatusProvider = Provider<CashFlowStatus?>((ref) {
  final cycle = ref.watch(activeCycleProvider);
  final summary = ref.watch(financialSummaryNotifierProvider).valueOrNull;
  if (summary == null) return null;

  final transfers = ref.watch(transferNotifierProvider).valueOrNull ?? const [];
  final assets = ref.watch(assetNotifierProvider).valueOrNull ?? const [];
  final goals = ref.watch(savingsGoalNotifierProvider).valueOrNull ?? const [];

  // La comparació contra els comptes només val al cicle en curs: els saldos
  // dels actius i de les guardioles són l'estat d'ARA.
  final isActive = cycle.id == ref.watch(currentCycleProvider).id;

  return buildCashFlowStatus(
    cycle: cycle,
    income: summary.monthlyIncome,
    expense: summary.monthlyExpenses,
    transfers: transfers,
    assets: assets,
    goals: goals,
    isActiveCycle: isActive,
  );
});

/// El pot ARA mateix (actius líquids + guardioles). El fa servir el diàleg de
/// tancament per proposar el saldo inicial del cicle següent.
final currentPotProvider = Provider<double?>((ref) {
  final assets = ref.watch(assetNotifierProvider).valueOrNull;
  final goals = ref.watch(savingsGoalNotifierProvider).valueOrNull;
  if (assets == null || goals == null) return null;
  return totalPot(assets, goals);
});

/// Solapaments i buits a la graella de cicles. NOMÉS LECTURA: dos cicles que
/// comparteixen dia fan que els moviments d'aquell dia comptin dues vegades, i
/// això trenca la cadena de saldos inicials. Cal corregir-ho a mà, editant les
/// dates del cicle.
final cycleGridProblemsProvider = Provider<List<CycleGridProblem>>((ref) {
  final cycles = ref.watch(billingCycleNotifierProvider).valueOrNull ?? const [];
  return findCycleGridProblems(cycles);
});

/// Moviments que mouen diners reals però no tenen cap compte assignat.
///
/// Sense `accountId` el saldo de l'actiu no es mou, i el pot queda descuadrat
/// exactament per aquest import. És la fuita que fa que la targeta de caixa
/// marqui ⚠️.
///
/// ÀMBIT PER DEFECTE: el cicle actiu. La importació d'Excel no ha assignat mai
/// `accountId` (només ho fan el sync bancari i l'alta manual), així que sobre
/// tot l'històric la llista seria de centenars d'entrades i el senyal es
/// perdria entre el soroll.
final movementsWithoutAccountProvider =
    Provider.family<List<Transaction>, BillingCycle?>((ref, cycle) {
  final txs = ref.watch(transactionNotifierProvider).valueOrNull ?? const [];

  final filtered = txs.where((t) {
    if (t.accountId != null) return false;
    if (cycle == null) return true; // tot l'històric
    return isWithinCycle(t.date, cycle);
  }).toList();

  filtered.sort((a, b) => b.date.compareTo(a.date));
  return filtered;
});

/// Comptador per al badge: només el cicle actiu.
final movementsWithoutAccountCountProvider = Provider<int>((ref) {
  final cycle = ref.watch(activeCycleProvider);
  return ref.watch(movementsWithoutAccountProvider(cycle)).length;
});
