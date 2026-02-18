// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionNotifierHash() =>
    r'91226c523b429a993a1cbc196f6bd2d37fd6cfb8';

/// See also [TransactionNotifier].
@ProviderFor(TransactionNotifier)
final transactionNotifierProvider =
    AutoDisposeStreamNotifierProvider<
      TransactionNotifier,
      List<Transaction>
    >.internal(
      TransactionNotifier.new,
      name: r'transactionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$transactionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TransactionNotifier = AutoDisposeStreamNotifier<List<Transaction>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
