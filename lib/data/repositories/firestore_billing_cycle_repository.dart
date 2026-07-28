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
  Future<String> addBillingCycle(BillingCycle cycle) async {
    final doc = await _firestore.collection(_collectionName).add(_toMap(cycle));
    return doc.id;
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

  @override
  Future<void> setOpeningBalance(
    String cycleId,
    double amount,
    String source,
  ) async {
    // Escriptura QUIRÚRGICA: només els tres camps del saldo. Mai passa per
    // _toMap, que no els coneix (vegeu la nota d'allà).
    await _firestore.collection(_collectionName).doc(cycleId).update({
      'openingBalance': amount,
      'openingBalanceAt': Timestamp.fromDate(DateTime.now()),
      'openingBalanceSource': source,
    });
  }

  @override
  Future<void> clearOpeningBalance(String cycleId) async {
    await _firestore.collection(_collectionName).doc(cycleId).update({
      'openingBalance': FieldValue.delete(),
      'openingBalanceAt': FieldValue.delete(),
      'openingBalanceSource': FieldValue.delete(),
    });
  }

  @override
  Future<void> setEndDateForOverlapRepair(
    String cycleId,
    DateTime endDate,
  ) async {
    // Escriptura deliberadament limitada: no passa per _toMap i no pot tocar
    // ni l'inici del cicle següent ni cap snapshot de saldo.
    await _firestore.collection(_collectionName).doc(cycleId).update({
      'endDate': Timestamp.fromDate(endDate),
    });
  }

  /// NOMÉS els camps de calendari. Els de saldo (`openingBalance`…) queden
  /// deliberadament FORA: `update()` només toca les claus presents al mapa, i
  /// `configureAnnualSchedule` reescriu tots els cicles futurs de cop. Si
  /// s'afegissin aquí, aquella reescriptura els posaria a null i esborraria
  /// snapshots ja segellats. Per escriure'ls hi ha `setOpeningBalance`.
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
      openingBalance: (data['openingBalance'] as num?)?.toDouble(),
      openingBalanceAt: (data['openingBalanceAt'] as Timestamp?)?.toDate(),
      openingBalanceSource: data['openingBalanceSource'] as String?,
    );
  }
}
