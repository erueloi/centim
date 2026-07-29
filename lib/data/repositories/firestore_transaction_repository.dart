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
        return transactionFromFirestoreMap(data, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addTransaction(dom.Transaction transaction) async {
    final data = transactionToFirestoreMap(transaction);
    if (transaction.id == null) {
      await _firestore.collection(_collectionName).add(data);
    } else {
      await _firestore
          .collection(_collectionName)
          .doc(transaction.id)
          .set(data);
    }
  }

  @override
  Future<void> updateTransaction(dom.Transaction transaction) async {
    if (transaction.id == null) {
      throw Exception('Transaction ID is null. Cannot update.');
    }
    final data = transactionToFirestoreMap(transaction);
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

  @override
  Future<int> countBySubCategory(String groupId, String subCategoryId) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('groupId', isEqualTo: groupId)
        .where('subCategoryId', isEqualTo: subCategoryId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}

/// Serialització pura i testable del document de moviment.
///
/// `savingsGoalId` és informació comptable, no només d'UI: en rellegir un
/// moviment cal saber quina guardiola revertir si s'edita o s'esborra.
Map<String, dynamic> transactionToFirestoreMap(dom.Transaction transaction) {
  return {
    'groupId': transaction.groupId,
    'date': Timestamp.fromDate(transaction.date),
    'amount': transaction.amount,
    'concept': transaction.concept,
    'categoryId': transaction.categoryId,
    'subCategoryId': transaction.subCategoryId,
    'categoryName': transaction.categoryName,
    'subCategoryName': transaction.subCategoryName,
    'payer': transaction.payer,
    'isIncome': transaction.isIncome,
    'savingsGoalId': transaction.savingsGoalId,
    'accountId': transaction.accountId,
    'bankAccountKey': transaction.bankAccountKey,
    'source': transaction.source,
    'bankTxId': transaction.bankTxId,
  };
}

/// Deserialització pura i testable del document de moviment.
dom.Transaction transactionFromFirestoreMap(
  Map<String, dynamic> data,
  String id,
) {
  return dom.Transaction(
    id: id,
    groupId: data['groupId'] as String? ?? 'unknown',
    date: (data['date'] as Timestamp).toDate(),
    amount: (data['amount'] as num).toDouble(),
    concept: data['concept'] as String? ?? '',
    categoryId: data['categoryId'] as String? ?? 'legacy_cat',
    subCategoryId: data['subCategoryId'] as String? ?? 'legacy_sub',
    categoryName: data['categoryName'] as String? ??
        (data['category'] as String? ?? 'Unknown'),
    subCategoryName: data['subCategoryName'] as String? ?? 'General',
    payer: data['payer'] as String? ?? 'unknown',
    isIncome: data['isIncome'] as bool? ?? false,
    savingsGoalId: data['savingsGoalId'] as String?,
    accountId: data['accountId'] as String?,
    bankAccountKey: data['bankAccountKey'] as String?,
    source: data['source'] as String?,
    bankTxId: data['bankTxId'] as String?,
  );
}
