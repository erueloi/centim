import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'transaction.freezed.dart';

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    String? id,
    required String groupId,
    required DateTime date,
    required double amount,
    required String concept,
    // Dynamic Category Fields
    required String categoryId,
    required String subCategoryId,
    required String categoryName, // Snapshot
    required String subCategoryName, // Snapshot
    required String payer,
    @Default(false) bool isIncome, // true = income, false = expense
    String?
        savingsGoalId, // Non-null if this transaction is paid FROM savings (or is a withdrawal)
    String? accountId, // Linked bank account / cash asset ID
  }) = _Transaction;

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      groupId: data['groupId'] as String? ?? 'unknown',
      date: (data['date'] as Timestamp).toDate(),
      amount: (data['amount'] as num).toDouble(),
      concept: data['concept'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      subCategoryId: data['subCategoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      subCategoryName: data['subCategoryName'] as String? ?? '',
      payer: data['payer'] as String? ?? '',
      isIncome: data['isIncome'] as bool? ?? false,
      savingsGoalId: data['savingsGoalId'] as String?,
      accountId: data['accountId'] as String?,
    );
  }
}
