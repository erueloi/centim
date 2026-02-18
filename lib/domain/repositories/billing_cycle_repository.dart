import '../models/billing_cycle.dart';

abstract class BillingCycleRepository {
  Stream<List<BillingCycle>> watchBillingCycles(String groupId);
  Future<void> addBillingCycle(BillingCycle cycle);
  Future<void> updateBillingCycle(BillingCycle cycle);
  Future<void> deleteBillingCycle(String cycleId);
  Future<void> addBatchBillingCycles(List<BillingCycle> cycles);
  Future<void> deleteBatchBillingCycles(List<String> cycleIds);
}
