import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/models/household_group.dart';
import 'dart:math';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');

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

    // No es comprova la unicitat del codi: les regles no deixen llistar grups.
    // Amb 36^6 combinacions la col·lisió és molt improbable, i si passa,
    // joinGroupWithCode la detecta i no uneix ningú a l'atzar.

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

  /// Unir-se a una llar amb el codi d'invitació. Les regles de Firestore no
  /// deixen llistar grups ni afegir-se a `memberIds`: ho fa la Cloud Function
  /// `joinGroupWithCode`, que també deixa aquest grup com a `currentGroupId`.
  /// Llança [FirebaseFunctionsException] amb un missatge en català si el codi
  /// no és vàlid o no existeix.
  Future<String> joinGroup(String inviteCode) async {
    final result = await _functions
        .httpsCallable('joinGroupWithCode')
        .call<Map<String, dynamic>>({'code': inviteCode});
    return result.data['groupId'] as String;
  }

  Future<HouseholdGroup?> getGroup(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (!doc.exists) return null;
    return HouseholdGroup.fromJson(doc.data()!);
  }

  /// Grup en viu. Si l'usuari deixa de ser-ne membre (l'owner el treu), el
  /// listener falla amb `permission-denied`: vegeu GroupAccessGuard.
  Stream<HouseholdGroup?> watchGroup(String groupId) {
    return _firestore.collection('groups').doc(groupId).snapshots().map(
          (doc) => doc.exists ? HouseholdGroup.fromJson(doc.data()!) : null,
        );
  }

  // --- Administració de membres. Les regles només ho permeten a l'owner,
  // excepte sortir del grup, que ho pot fer qualsevol membre que no sigui
  // l'owner.

  Future<void> removeMember(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> transferOwnership(String groupId, String newOwnerId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'ownerId': newOwnerId,
    });
  }

  /// El codi anterior deixa de servir immediatament.
  Future<String> regenerateInviteCode(String groupId) async {
    final inviteCode = _generateInviteCode();
    await _firestore.collection('groups').doc(groupId).update({
      'inviteCode': inviteCode,
    });
    return inviteCode;
  }

  /// Surt del grup i, en el mateix lot, buida el grup actual del perfil
  /// perquè l'app torni a la pantalla de crear o unir-se a un grup.
  Future<void> leaveGroup(String groupId, String userId) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('groups').doc(groupId), {
      'memberIds': FieldValue.arrayRemove([userId]),
    });
    batch.update(_firestore.collection('users').doc(userId), {
      'currentGroupId': null,
    });
    await batch.commit();
  }

  Future<void> updateGroup(HouseholdGroup group) async {
    await _firestore.collection('groups').doc(group.id).update(group.toJson());
  }
}
