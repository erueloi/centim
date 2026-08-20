// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annual_view_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$annualDisplayModeNotifierHash() =>
    r'cc161ebb38c682acfa3ebe37a3e2ff48224420fc';

/// See also [AnnualDisplayModeNotifier].
@ProviderFor(AnnualDisplayModeNotifier)
final annualDisplayModeNotifierProvider = AutoDisposeNotifierProvider<
    AnnualDisplayModeNotifier, AnnualDisplayMode>.internal(
  AnnualDisplayModeNotifier.new,
  name: r'annualDisplayModeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$annualDisplayModeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AnnualDisplayModeNotifier = AutoDisposeNotifier<AnnualDisplayMode>;
String _$annualSelectedYearNotifierHash() =>
    r'8483cdb2e8fe9f7fcebc3c8338f11c4b1f93af68';

/// See also [AnnualSelectedYearNotifier].
@ProviderFor(AnnualSelectedYearNotifier)
final annualSelectedYearNotifierProvider =
    AutoDisposeNotifierProvider<AnnualSelectedYearNotifier, int>.internal(
  AnnualSelectedYearNotifier.new,
  name: r'annualSelectedYearNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$annualSelectedYearNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AnnualSelectedYearNotifier = AutoDisposeNotifier<int>;
String _$annualReportNotifierHash() =>
    r'a8c1ad66545fb2bfce28805136064331904dc4a5';

/// See also [AnnualReportNotifier].
@ProviderFor(AnnualReportNotifier)
final annualReportNotifierProvider = AutoDisposeAsyncNotifierProvider<
    AnnualReportNotifier, AnnualReportData>.internal(
  AnnualReportNotifier.new,
  name: r'annualReportNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$annualReportNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AnnualReportNotifier = AutoDisposeAsyncNotifier<AnnualReportData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
