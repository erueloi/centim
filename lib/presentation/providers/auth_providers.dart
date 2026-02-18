import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/providers/repository_providers.dart';
import '../../domain/models/user_profile.dart';

part 'auth_providers.g.dart';

@riverpod
Stream<UserProfile?> userProfile(Ref ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getUserProfileStream();
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
