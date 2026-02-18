import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/household_group.dart';
import 'dart:math';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<String> createGroup(String name, String ownerId) async {
    final docRef = _firestore.collection('groups').doc(); // Auto-ID
    final inviteCode = _generateInviteCode();

    // In a real app, we should check for uniqueness of inviteCode here
    // checking if a doc with this code already exists. For now, skipping for simplicity.

    final group = HouseholdGroup(
      id: docRef.id,
      name: name,
      memberIds: [ownerId],
      ownerId: ownerId,
      inviteCode: inviteCode,
    );
    await docRef.set(group.toJson());
    return docRef.id;
  }

  Future<void> joinGroup(String inviteCode, String userId) async {
    // Find group by invite code
    final query = await _firestore
        .collection('groups')
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Invalid invite code');
    }

    final docRef = query.docs.first.reference;

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Group not found');
      }

      final data = snapshot.data()!;
      final currentMembers = List<String>.from(data['memberIds'] as List);

      if (!currentMembers.contains(userId)) {
        currentMembers.add(userId);
        transaction.update(docRef, {'memberIds': currentMembers});
      }
    });
  }

  Future<HouseholdGroup?> getGroup(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (!doc.exists) return null;
    return HouseholdGroup.fromJson(doc.data()!);
  }

  Future<void> updateGroup(HouseholdGroup group) async {
    await _firestore.collection('groups').doc(group.id).update(group.toJson());
  }
}
