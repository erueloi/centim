// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_reports_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cycleReportNotifierHash() =>
    r'3a4cc2cbfde053254485226cf1e1f0bf5dc7a051';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$CycleReportNotifier
    extends BuildlessAutoDisposeAsyncNotifier<CycleReport?> {
  late final String cycleId;

  FutureOr<CycleReport?> build(
    String cycleId,
  );
}

/// See also [CycleReportNotifier].
@ProviderFor(CycleReportNotifier)
const cycleReportNotifierProvider = CycleReportNotifierFamily();

/// See also [CycleReportNotifier].
class CycleReportNotifierFamily extends Family<AsyncValue<CycleReport?>> {
  /// See also [CycleReportNotifier].
  const CycleReportNotifierFamily();

  /// See also [CycleReportNotifier].
  CycleReportNotifierProvider call(
    String cycleId,
  ) {
    return CycleReportNotifierProvider(
      cycleId,
    );
  }

  @override
  CycleReportNotifierProvider getProviderOverride(
    covariant CycleReportNotifierProvider provider,
  ) {
    return call(
      provider.cycleId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'cycleReportNotifierProvider';
}

/// See also [CycleReportNotifier].
class CycleReportNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    CycleReportNotifier, CycleReport?> {
  /// See also [CycleReportNotifier].
  CycleReportNotifierProvider(
    String cycleId,
  ) : this._internal(
          () => CycleReportNotifier()..cycleId = cycleId,
          from: cycleReportNotifierProvider,
          name: r'cycleReportNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$cycleReportNotifierHash,
          dependencies: CycleReportNotifierFamily._dependencies,
          allTransitiveDependencies:
              CycleReportNotifierFamily._allTransitiveDependencies,
          cycleId: cycleId,
        );

  CycleReportNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.cycleId,
  }) : super.internal();

  final String cycleId;

  @override
  FutureOr<CycleReport?> runNotifierBuild(
    covariant CycleReportNotifier notifier,
  ) {
    return notifier.build(
      cycleId,
    );
  }

  @override
  Override overrideWith(CycleReportNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: CycleReportNotifierProvider._internal(
        () => create()..cycleId = cycleId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        cycleId: cycleId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<CycleReportNotifier, CycleReport?>
      createElement() {
    return _CycleReportNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CycleReportNotifierProvider && other.cycleId == cycleId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, cycleId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CycleReportNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<CycleReport?> {
  /// The parameter `cycleId` of this provider.
  String get cycleId;
}

class _CycleReportNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<CycleReportNotifier,
        CycleReport?> with CycleReportNotifierRef {
  _CycleReportNotifierProviderElement(super.provider);

  @override
  String get cycleId => (origin as CycleReportNotifierProvider).cycleId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
