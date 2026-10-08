// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userProfileHash() => r'9faba67f914dd43b661ed8f49bec39a59f648a6d';

/// Perfil de l'usuari autenticat. Depèn de l'estat d'Auth perquè, en canviar
/// d'usuari (tancar sessió i registrar-ne un altre), no es quedi escoltant
/// el perfil ni l'error de l'usuari anterior.
///
/// Copied from [userProfile].
@ProviderFor(userProfile)
final userProfileProvider = AutoDisposeStreamProvider<UserProfile?>.internal(
  userProfile,
  name: r'userProfileProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserProfileRef = AutoDisposeStreamProviderRef<UserProfile?>;
String _$currentGroupIdHash() => r'12ed676cd93acba360ed561eb464df62d9f4d1b2';

/// See also [currentGroupId].
@ProviderFor(currentGroupId)
final currentGroupIdProvider = AutoDisposeFutureProvider<String?>.internal(
  currentGroupId,
  name: r'currentGroupIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentGroupIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentGroupIdRef = AutoDisposeFutureProviderRef<String?>;
String _$authStateChangesHash() => r'df1a3e091ade897d4ae032ed6eea2402403fefd9';

/// See also [authStateChanges].
@ProviderFor(authStateChanges)
final authStateChangesProvider = AutoDisposeStreamProvider<User?>.internal(
  authStateChanges,
  name: r'authStateChangesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authStateChangesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateChangesRef = AutoDisposeStreamProviderRef<User?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
