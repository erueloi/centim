// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_cycle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentCycleHash() => r'1916768d41a10f62c2e6c2bcde822ed9034aacc3';

/// See also [currentCycle].
@ProviderFor(currentCycle)
final currentCycleProvider = AutoDisposeProvider<BillingCycle>.internal(
  currentCycle,
  name: r'currentCycleProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentCycleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentCycleRef = AutoDisposeProviderRef<BillingCycle>;
String _$activeCycleHash() => r'bac69a3d744e64c9d7dc6d5fbbccf19ecfb52b36';

/// See also [activeCycle].
@ProviderFor(activeCycle)
final activeCycleProvider = AutoDisposeProvider<BillingCycle>.internal(
  activeCycle,
  name: r'activeCycleProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$activeCycleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveCycleRef = AutoDisposeProviderRef<BillingCycle>;
String _$billingCycleNotifierHash() =>
    r'2c353ecde51cfaacba2c1800b5aac10ba6fc6bef';

/// See also [BillingCycleNotifier].
@ProviderFor(BillingCycleNotifier)
final billingCycleNotifierProvider = AutoDisposeStreamNotifierProvider<
    BillingCycleNotifier, List<BillingCycle>>.internal(
  BillingCycleNotifier.new,
  name: r'billingCycleNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$billingCycleNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BillingCycleNotifier = AutoDisposeStreamNotifier<List<BillingCycle>>;
String _$selectedCycleHash() => r'2107e1a2b5fabe921d851c794fb9457fa896e9fc';

/// See also [SelectedCycle].
@ProviderFor(SelectedCycle)
final selectedCycleProvider =
    AutoDisposeNotifierProvider<SelectedCycle, BillingCycle?>.internal(
  SelectedCycle.new,
  name: r'selectedCycleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedCycleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedCycle = AutoDisposeNotifier<BillingCycle?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
