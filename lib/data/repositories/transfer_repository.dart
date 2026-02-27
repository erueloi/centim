import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/transfer.dart';

class TransferRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Transfer>> getTransfersStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('transfers')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Transfer.fromJson(doc.data())).toList();
    });
  }

  Future<void> addTransfer(String groupId, Transfer transfer) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('transfers')
        .doc(transfer.id)
        .set(transfer.toJson());
  }

  Future<void> updateTransfer(String groupId, Transfer transfer) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('transfers')
        .doc(transfer.id)
        .update(transfer.toJson());
  }

  Future<void> deleteTransfer(String groupId, String transferId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('transfers')
        .doc(transferId)
        .delete();
  }
}
