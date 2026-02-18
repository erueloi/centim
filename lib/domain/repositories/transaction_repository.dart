import 'package:centim/domain/models/transaction.dart';

abstract class TransactionRepository {
  Future<void> addTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Stream<List<Transaction>> getAllTransactions(String groupId);
  Future<void> deleteTransaction(Transaction transaction);
}
