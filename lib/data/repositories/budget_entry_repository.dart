import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/budget_entry.dart';

class BudgetEntryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _getCollection(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('budget_entries');
  }

  /// Get entries for a specific month (for Budget Control Screen)
  Stream<List<BudgetEntry>> watchEntriesForMonth(
    String groupId,
    int year,
    int month,
  ) {
    return _getCollection(groupId)
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .snapshots()
        .map(
          (s) => s.docs.map((doc) => BudgetEntry.fromJson(doc.data())).toList(),
        );
  }

  /// Get entries for a specific subcategory (for Matrix Screen)
  Stream<List<BudgetEntry>> watchEntriesForSubCategory(
    String groupId,
    String subCategoryId,
    int year,
  ) {
    return _getCollection(groupId)
        .where('subCategoryId', isEqualTo: subCategoryId)
        .where('year', isEqualTo: year)
        .snapshots()
        .map(
          (s) => s.docs.map((doc) => BudgetEntry.fromJson(doc.data())).toList(),
        );
  }

  Future<void> setEntry(String groupId, BudgetEntry entry) async {
    await _getCollection(groupId).doc(entry.id).set(entry.toJson());
  }

  Future<BudgetEntry?> getEntry(String groupId, String entryId) async {
    final doc = await _getCollection(groupId).doc(entryId).get();
    if (doc.exists && doc.data() != null) {
      return BudgetEntry.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> deleteEntry(String groupId, String entryId) async {
    await _getCollection(groupId).doc(entryId).delete();
  }

  Future<void> deleteEntriesForSubCategory(
    String groupId,
    String subCategoryId,
    int year,
  ) async {
    final batch = _firestore.batch();
    final snapshot = await _getCollection(groupId)
        .where('subCategoryId', isEqualTo: subCategoryId)
        .where('year', isEqualTo: year)
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
