// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trends_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$trendsFilterNotifierHash() =>
    r'59f3319258ad08c650dd0dbc90d21305c475daef';

/// See also [TrendsFilterNotifier].
@ProviderFor(TrendsFilterNotifier)
final trendsFilterNotifierProvider = AutoDisposeNotifierProvider<
    TrendsFilterNotifier, TrendsTimeFilter>.internal(
  TrendsFilterNotifier.new,
  name: r'trendsFilterNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trendsFilterNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TrendsFilterNotifier = AutoDisposeNotifier<TrendsTimeFilter>;
String _$trendsNotifierHash() => r'6fd2b71954a8e7060e34e28911a4809f8fed0fbb';

/// See also [TrendsNotifier].
@ProviderFor(TrendsNotifier)
final trendsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<TrendsNotifier, TrendsData>.internal(
  TrendsNotifier.new,
  name: r'trendsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trendsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TrendsNotifier = AutoDisposeAsyncNotifier<TrendsData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
