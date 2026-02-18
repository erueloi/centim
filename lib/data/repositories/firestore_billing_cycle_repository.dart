import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/billing_cycle.dart';
import '../../domain/repositories/billing_cycle_repository.dart';

class FirestoreBillingCycleRepository implements BillingCycleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'billing_cycles';

  @override
  Stream<List<BillingCycle>> watchBillingCycles(String groupId) {
    return _firestore
        .collection(_collectionName)
        .where('groupId', isEqualTo: groupId)
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return _fromMap(data, doc.id);
          }).toList();
        });
  }

  @override
  Future<void> addBillingCycle(BillingCycle cycle) async {
    await _firestore.collection(_collectionName).add(_toMap(cycle));
  }

  @override
  Future<void> updateBillingCycle(BillingCycle cycle) async {
    await _firestore
        .collection(_collectionName)
        .doc(cycle.id)
        .update(_toMap(cycle));
  }

  @override
  Future<void> deleteBillingCycle(String cycleId) async {
    await _firestore.collection(_collectionName).doc(cycleId).delete();
  }

  @override
  Future<void> addBatchBillingCycles(List<BillingCycle> cycles) async {
    final batch = _firestore.batch();
    for (final cycle in cycles) {
      final docRef = _firestore.collection(_collectionName).doc();
      batch.set(docRef, _toMap(cycle));
    }
    await batch.commit();
  }

  @override
  Future<void> deleteBatchBillingCycles(List<String> cycleIds) async {
    final batch = _firestore.batch();
    for (final id in cycleIds) {
      final docRef = _firestore.collection(_collectionName).doc(id);
      batch.delete(docRef);
    }
    await batch.commit();
  }

  Map<String, dynamic> _toMap(BillingCycle cycle) {
    return {
      'groupId': cycle.groupId,
      'name': cycle.name,
      'startDate': Timestamp.fromDate(cycle.startDate),
      'endDate': Timestamp.fromDate(cycle.endDate),
    };
  }

  BillingCycle _fromMap(Map<String, dynamic> data, String id) {
    return BillingCycle(
      id: id,
      groupId: data['groupId'] as String? ?? '',
      name: data['name'] as String? ?? 'Unknown',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
    );
  }
}
