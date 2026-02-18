import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/debt_account.dart';

class DebtRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<DebtAccount>> getDebtsStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('debt_accounts')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DebtAccount.fromJson(doc.data()))
              .toList();
        });
  }

  Future<void> addDebt(String groupId, DebtAccount debt) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('debt_accounts')
        .doc(debt.id)
        .set(debt.toJson());
  }

  Future<void> updateDebt(String groupId, DebtAccount debt) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('debt_accounts')
        .doc(debt.id)
        .update(debt.toJson());
  }

  Future<void> deleteDebt(String groupId, String debtId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('debt_accounts')
        .doc(debtId)
        .delete();
  }
}
