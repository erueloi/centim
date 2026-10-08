import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/providers/repository_providers.dart';
import '../../domain/models/user_profile.dart';

part 'auth_providers.g.dart';

/// Perfil de l'usuari autenticat. Depèn de l'estat d'Auth perquè, en canviar
/// d'usuari (tancar sessió i registrar-ne un altre), no es quedi escoltant
/// el perfil ni l'error de l'usuari anterior.
@riverpod
Stream<UserProfile?> userProfile(Ref ref) async* {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) {
    yield null;
    return;
  }
  yield* ref.watch(authRepositoryProvider).watchUserProfile(user.uid);
}

@riverpod
Future<String?> currentGroupId(Ref ref) async {
  final userProfile = await ref.watch(userProfileProvider.future);
  return userProfile?.currentGroupId;
}

@riverpod
Stream<User?> authStateChanges(Ref ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
}
