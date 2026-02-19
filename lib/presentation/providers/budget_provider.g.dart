// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentMonthBudgetEntriesHash() =>
    r'5ec2b54822ec6a49989f302c1aa4117652c26d8f';

/// See also [currentMonthBudgetEntries].
@ProviderFor(currentMonthBudgetEntries)
final currentMonthBudgetEntriesProvider =
    AutoDisposeStreamProvider<List<BudgetEntry>>.internal(
      currentMonthBudgetEntries,
      name: r'currentMonthBudgetEntriesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentMonthBudgetEntriesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentMonthBudgetEntriesRef =
    AutoDisposeStreamProviderRef<List<BudgetEntry>>;
String _$zeroBudgetBalanceHash() => r'2b5006c7a7f947b24698fa78f9ab8bd0b314717c';

/// See also [zeroBudgetBalance].
@ProviderFor(zeroBudgetBalance)
final zeroBudgetBalanceProvider =
    AutoDisposeFutureProvider<ZeroBudgetSummary>.internal(
      zeroBudgetBalance,
      name: r'zeroBudgetBalanceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$zeroBudgetBalanceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ZeroBudgetBalanceRef = AutoDisposeFutureProviderRef<ZeroBudgetSummary>;
String _$budgetNotifierHash() => r'd73cfc7f29e8ee53d5e44777d612e7a3721647d7';

/// See also [BudgetNotifier].
@ProviderFor(BudgetNotifier)
final budgetNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      BudgetNotifier,
      List<BudgetStatus>
    >.internal(
      BudgetNotifier.new,
      name: r'budgetNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$budgetNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BudgetNotifier = AutoDisposeAsyncNotifier<List<BudgetStatus>>;
String _$dashboardBudgetNotifierHash() =>
    r'd1416b33484abbdeb45f14415f6222da58e177e9';

/// See also [DashboardBudgetNotifier].
@ProviderFor(DashboardBudgetNotifier)
final dashboardBudgetNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      DashboardBudgetNotifier,
      List<BudgetStatus>
    >.internal(
      DashboardBudgetNotifier.new,
      name: r'dashboardBudgetNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dashboardBudgetNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DashboardBudgetNotifier =
    AutoDisposeAsyncNotifier<List<BudgetStatus>>;
String _$budgetContextNotifierHash() =>
    r'35113d303e4f6b7b836f53507c813fc7bccf2a08';

/// Holds the selected budget context. null = "Pressupost Estàndard" (base).
///
/// Copied from [BudgetContextNotifier].
@ProviderFor(BudgetContextNotifier)
final budgetContextNotifierProvider =
    AutoDisposeNotifierProvider<BudgetContextNotifier, BillingCycle?>.internal(
      BudgetContextNotifier.new,
      name: r'budgetContextNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$budgetContextNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BudgetContextNotifier = AutoDisposeNotifier<BillingCycle?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
