import '../models/billing_cycle.dart';

abstract class BillingCycleRepository {
  Stream<List<BillingCycle>> watchBillingCycles(String groupId);

  /// Retorna l'id del document creat, necessari per poder segellar-hi després
  /// el saldo inicial sense haver de tornar a buscar el cicle.
  Future<String> addBillingCycle(BillingCycle cycle);
  Future<void> updateBillingCycle(BillingCycle cycle);
  Future<void> deleteBillingCycle(String cycleId);
  Future<void> addBatchBillingCycles(List<BillingCycle> cycles);
  Future<void> deleteBatchBillingCycles(List<String> cycleIds);

  /// Escriu NOMÉS el saldo inicial del cicle, sense tocar-ne el calendari.
  /// [source]: 'manual' | 'auto-tancament'.
  Future<void> setOpeningBalance(String cycleId, double amount, String source);

  /// Torna el cicle a "saldo inicial no registrat".
  Future<void> clearOpeningBalance(String cycleId);

  /// Acció de manteniment quirúrgica: canvia NOMÉS la data final d'un cicle
  /// per resoldre un solapament detectat. No obre l'edició general de l'històric.
  Future<void> setEndDateForOverlapRepair(String cycleId, DateTime endDate);
}
