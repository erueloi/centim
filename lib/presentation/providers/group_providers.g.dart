// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentGroupHash() => r'f623e24ae31c5b6ab7e1cb55280ddf20d0bd4546';

/// En viu: els canvis de membres, owner o codi es veuen a l'instant, i si
/// l'usuari deixa de ser membre el stream falla amb `permission-denied`.
///
/// Copied from [currentGroup].
@ProviderFor(currentGroup)
final currentGroupProvider =
    AutoDisposeStreamProvider<HouseholdGroup?>.internal(
  currentGroup,
  name: r'currentGroupProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentGroupHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentGroupRef = AutoDisposeStreamProviderRef<HouseholdGroup?>;
String _$groupMembersHash() => r'7ac1fce7cfbdfb1caf1f4a898cce5972ebedb29c';

/// See also [groupMembers].
@ProviderFor(groupMembers)
final groupMembersProvider =
    AutoDisposeFutureProvider<List<UserProfile>>.internal(
  groupMembers,
  name: r'groupMembersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$groupMembersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupMembersRef = AutoDisposeFutureProviderRef<List<UserProfile>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
