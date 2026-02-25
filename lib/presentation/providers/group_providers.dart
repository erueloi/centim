import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/providers/repository_providers.dart';
import '../../domain/models/household_group.dart';
import '../../domain/models/user_profile.dart'; // Import UserProfile
import 'auth_providers.dart';

part 'group_providers.g.dart';

@riverpod
Future<HouseholdGroup?> currentGroup(Ref ref) async {
  final groupId = await ref.watch(currentGroupIdProvider.future);
  if (groupId == null) return null;

  final repo = ref.watch(groupRepositoryProvider);
  return repo.getGroup(groupId);
}

@riverpod
Future<List<UserProfile>> groupMembers(Ref ref) async {
  final group = await ref.watch(currentGroupProvider.future);
  if (group == null || group.memberIds.isEmpty) return [];

  try {
    // Note: whereIn is limited to 10. For larger groups, need chunking.
    // Assuming small groups for now.
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: group.memberIds.take(10).toList())
        .get();

    final users = <UserProfile>[];
    for (var doc in snapshot.docs) {
      try {
        final data = Map<String, dynamic>.from(doc.data());
        data['uid'] ??= doc
            .id; // Assegurar el camp UID per si no el guardava dins l'objecte
        data['email'] ??=
            'usuari@centim.cat'; // Prevenir que el required hi falte
        users.add(UserProfile.fromJson(data));
      } catch (e) {
        // En cas que l'objecte the Firestore estigui corrupte i falli el serialitzador forcem almenys que el registre existeixi
        debugPrint('Error parsejant usuari ${doc.id}: $e');
        users.add(UserProfile(
          uid: doc.id,
          email: 'usuari_desconegut_${doc.id.substring(0, 4)}@centim.cat',
        ));
      }
    }
    return users;
  } catch (e, stackTrace) {
    debugPrint('ERROR CRÍTIC carregant membres del grup: $e');
    debugPrint('StackTrace: $stackTrace');
    return [];
  }
}
