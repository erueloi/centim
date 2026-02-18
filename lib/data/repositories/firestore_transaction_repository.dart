import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/transaction.dart' as dom;

import '../../domain/repositories/transaction_repository.dart';

class FirestoreTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'transactions';

  @override
  Stream<List<dom.Transaction>> getAllTransactions(String groupId) {
    return _firestore
        .collection(_collectionName)
        .where('groupId', isEqualTo: groupId)
        // Order by date descending by default
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return _fromMap(data, doc.id);
          }).toList();
        });
  }

  @override
  Future<void> addTransaction(dom.Transaction transaction) async {
    final data = _toMap(transaction);
    await _firestore.collection(_collectionName).add(data);
  }

  @override
  Future<void> updateTransaction(dom.Transaction transaction) async {
    if (transaction.id == null) {
      throw Exception('Transaction ID is null. Cannot update.');
    }
    final data = _toMap(transaction);
    await _firestore
        .collection(_collectionName)
        .doc(transaction.id)
        .update(data);
  }

  @override
  Future<void> deleteTransaction(dom.Transaction transaction) async {
    if (transaction.id == null) {
      throw Exception('Transaction ID is null. Cannot delete.');
    }
    await _firestore.collection(_collectionName).doc(transaction.id).delete();
  }

  Map<String, dynamic> _toMap(dom.Transaction transaction) {
    return {
      'groupId': transaction.groupId,
      'date': Timestamp.fromDate(transaction.date),
      'amount': transaction.amount,
      'concept': transaction.concept,
      // New Dynamic Fields
      'categoryId': transaction.categoryId,
      'subCategoryId': transaction.subCategoryId,
      'categoryName': transaction.categoryName,
      'subCategoryName': transaction.subCategoryName,
      'payer': transaction.payer,
      'isIncome': transaction.isIncome,
    };
  }

  dom.Transaction _fromMap(Map<String, dynamic> data, String id) {
    return dom.Transaction(
      id: id,
      groupId: data['groupId'] as String? ?? 'unknown',
      date: (data['date'] as Timestamp).toDate(),
      amount: (data['amount'] as num).toDouble(),
      concept: data['concept'] as String? ?? '',
      // Map new fields with fallbacks for old data
      categoryId: data['categoryId'] as String? ?? 'legacy_cat',
      subCategoryId: data['subCategoryId'] as String? ?? 'legacy_sub',
      categoryName:
          data['categoryName'] as String? ??
          (data['category'] as String? ?? 'Unknown'),
      subCategoryName: data['subCategoryName'] as String? ?? 'General',
      payer:
          data['payer'] as String? ??
          'unknown', // Handle potentially missing payer in v1 docs
      isIncome: data['isIncome'] as bool? ?? false,
    );
  }
}
