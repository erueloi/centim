// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Transfer _$TransferFromJson(Map<String, dynamic> json) {
  return _Transfer.fromJson(json);
}

/// @nodoc
mixin _$Transfer {
  String get id => throw _privateConstructorUsedError;
  String get groupId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get sourceAssetId => throw _privateConstructorUsedError;
  String get sourceAssetName => throw _privateConstructorUsedError; // Snapshot
  TransferDestinationType get destinationType =>
      throw _privateConstructorUsedError;
  String get destinationId => throw _privateConstructorUsedError;
  String get destinationName => throw _privateConstructorUsedError; // Snapshot
  String? get note => throw _privateConstructorUsedError;
  String? get concept => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  List<BankTransferLeg> get bankLegs => throw _privateConstructorUsedError;
  bool get awaitsBankCounterpart => throw _privateConstructorUsedError;
  int get schemaVersion => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get migratedTransactionSnapshots =>
      throw _privateConstructorUsedError;

  /// Serializes this Transfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransferCopyWith<Transfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransferCopyWith<$Res> {
  factory $TransferCopyWith(Transfer value, $Res Function(Transfer) then) =
      _$TransferCopyWithImpl<$Res, Transfer>;
  @useResult
  $Res call(
      {String id,
      String groupId,
      DateTime date,
      double amount,
      String sourceAssetId,
      String sourceAssetName,
      TransferDestinationType destinationType,
      String destinationId,
      String destinationName,
      String? note,
      String? concept,
      String source,
      List<BankTransferLeg> bankLegs,
      bool awaitsBankCounterpart,
      int schemaVersion,
      List<Map<String, dynamic>> migratedTransactionSnapshots});
}

/// @nodoc
class _$TransferCopyWithImpl<$Res, $Val extends Transfer>
    implements $TransferCopyWith<$Res> {
  _$TransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? date = null,
    Object? amount = null,
    Object? sourceAssetId = null,
    Object? sourceAssetName = null,
    Object? destinationType = null,
    Object? destinationId = null,
    Object? destinationName = null,
    Object? note = freezed,
    Object? concept = freezed,
    Object? source = null,
    Object? bankLegs = null,
    Object? awaitsBankCounterpart = null,
    Object? schemaVersion = null,
    Object? migratedTransactionSnapshots = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      sourceAssetId: null == sourceAssetId
          ? _value.sourceAssetId
          : sourceAssetId // ignore: cast_nullable_to_non_nullable
              as String,
      sourceAssetName: null == sourceAssetName
          ? _value.sourceAssetName
          : sourceAssetName // ignore: cast_nullable_to_non_nullable
              as String,
      destinationType: null == destinationType
          ? _value.destinationType
          : destinationType // ignore: cast_nullable_to_non_nullable
              as TransferDestinationType,
      destinationId: null == destinationId
          ? _value.destinationId
          : destinationId // ignore: cast_nullable_to_non_nullable
              as String,
      destinationName: null == destinationName
          ? _value.destinationName
          : destinationName // ignore: cast_nullable_to_non_nullable
              as String,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      concept: freezed == concept
          ? _value.concept
          : concept // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      bankLegs: null == bankLegs
          ? _value.bankLegs
          : bankLegs // ignore: cast_nullable_to_non_nullable
              as List<BankTransferLeg>,
      awaitsBankCounterpart: null == awaitsBankCounterpart
          ? _value.awaitsBankCounterpart
          : awaitsBankCounterpart // ignore: cast_nullable_to_non_nullable
              as bool,
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
      migratedTransactionSnapshots: null == migratedTransactionSnapshots
          ? _value.migratedTransactionSnapshots
          : migratedTransactionSnapshots // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TransferImplCopyWith<$Res>
    implements $TransferCopyWith<$Res> {
  factory _$$TransferImplCopyWith(
          _$TransferImpl value, $Res Function(_$TransferImpl) then) =
      __$$TransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String groupId,
      DateTime date,
      double amount,
      String sourceAssetId,
      String sourceAssetName,
      TransferDestinationType destinationType,
      String destinationId,
      String destinationName,
      String? note,
      String? concept,
      String source,
      List<BankTransferLeg> bankLegs,
      bool awaitsBankCounterpart,
      int schemaVersion,
      List<Map<String, dynamic>> migratedTransactionSnapshots});
}

/// @nodoc
class __$$TransferImplCopyWithImpl<$Res>
    extends _$TransferCopyWithImpl<$Res, _$TransferImpl>
    implements _$$TransferImplCopyWith<$Res> {
  __$$TransferImplCopyWithImpl(
      _$TransferImpl _value, $Res Function(_$TransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of Transfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? date = null,
    Object? amount = null,
    Object? sourceAssetId = null,
    Object? sourceAssetName = null,
    Object? destinationType = null,
    Object? destinationId = null,
    Object? destinationName = null,
    Object? note = freezed,
    Object? concept = freezed,
    Object? source = null,
    Object? bankLegs = null,
    Object? awaitsBankCounterpart = null,
    Object? schemaVersion = null,
    Object? migratedTransactionSnapshots = null,
  }) {
    return _then(_$TransferImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      sourceAssetId: null == sourceAssetId
          ? _value.sourceAssetId
          : sourceAssetId // ignore: cast_nullable_to_non_nullable
              as String,
      sourceAssetName: null == sourceAssetName
          ? _value.sourceAssetName
          : sourceAssetName // ignore: cast_nullable_to_non_nullable
              as String,
      destinationType: null == destinationType
          ? _value.destinationType
          : destinationType // ignore: cast_nullable_to_non_nullable
              as TransferDestinationType,
      destinationId: null == destinationId
          ? _value.destinationId
          : destinationId // ignore: cast_nullable_to_non_nullable
              as String,
      destinationName: null == destinationName
          ? _value.destinationName
          : destinationName // ignore: cast_nullable_to_non_nullable
              as String,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      concept: freezed == concept
          ? _value.concept
          : concept // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      bankLegs: null == bankLegs
          ? _value._bankLegs
          : bankLegs // ignore: cast_nullable_to_non_nullable
              as List<BankTransferLeg>,
      awaitsBankCounterpart: null == awaitsBankCounterpart
          ? _value.awaitsBankCounterpart
          : awaitsBankCounterpart // ignore: cast_nullable_to_non_nullable
              as bool,
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
      migratedTransactionSnapshots: null == migratedTransactionSnapshots
          ? _value._migratedTransactionSnapshots
          : migratedTransactionSnapshots // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$TransferImpl implements _Transfer {
  const _$TransferImpl(
      {required this.id,
      required this.groupId,
      required this.date,
      required this.amount,
      required this.sourceAssetId,
      required this.sourceAssetName,
      required this.destinationType,
      required this.destinationId,
      required this.destinationName,
      this.note,
      this.concept,
      this.source = 'manual',
      final List<BankTransferLeg> bankLegs = const <BankTransferLeg>[],
      this.awaitsBankCounterpart = false,
      this.schemaVersion = 2,
      final List<Map<String, dynamic>> migratedTransactionSnapshots =
          const <Map<String, dynamic>>[]})
      : _bankLegs = bankLegs,
        _migratedTransactionSnapshots = migratedTransactionSnapshots;

  factory _$TransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransferImplFromJson(json);

  @override
  final String id;
  @override
  final String groupId;
  @override
  final DateTime date;
  @override
  final double amount;
  @override
  final String sourceAssetId;
  @override
  final String sourceAssetName;
// Snapshot
  @override
  final TransferDestinationType destinationType;
  @override
  final String destinationId;
  @override
  final String destinationName;
// Snapshot
  @override
  final String? note;
  @override
  final String? concept;
  @override
  @JsonKey()
  final String source;
  final List<BankTransferLeg> _bankLegs;
  @override
  @JsonKey()
  List<BankTransferLeg> get bankLegs {
    if (_bankLegs is EqualUnmodifiableListView) return _bankLegs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bankLegs);
  }

  @override
  @JsonKey()
  final bool awaitsBankCounterpart;
  @override
  @JsonKey()
  final int schemaVersion;
  final List<Map<String, dynamic>> _migratedTransactionSnapshots;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get migratedTransactionSnapshots {
    if (_migratedTransactionSnapshots is EqualUnmodifiableListView)
      return _migratedTransactionSnapshots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_migratedTransactionSnapshots);
  }

  @override
  String toString() {
    return 'Transfer(id: $id, groupId: $groupId, date: $date, amount: $amount, sourceAssetId: $sourceAssetId, sourceAssetName: $sourceAssetName, destinationType: $destinationType, destinationId: $destinationId, destinationName: $destinationName, note: $note, concept: $concept, source: $source, bankLegs: $bankLegs, awaitsBankCounterpart: $awaitsBankCounterpart, schemaVersion: $schemaVersion, migratedTransactionSnapshots: $migratedTransactionSnapshots)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransferImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.sourceAssetId, sourceAssetId) ||
                other.sourceAssetId == sourceAssetId) &&
            (identical(other.sourceAssetName, sourceAssetName) ||
                other.sourceAssetName == sourceAssetName) &&
            (identical(other.destinationType, destinationType) ||
                other.destinationType == destinationType) &&
            (identical(other.destinationId, destinationId) ||
                other.destinationId == destinationId) &&
            (identical(other.destinationName, destinationName) ||
                other.destinationName == destinationName) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.concept, concept) || other.concept == concept) &&
            (identical(other.source, source) || other.source == source) &&
            const DeepCollectionEquality().equals(other._bankLegs, _bankLegs) &&
            (identical(other.awaitsBankCounterpart, awaitsBankCounterpart) ||
                other.awaitsBankCounterpart == awaitsBankCounterpart) &&
            (identical(other.schemaVersion, schemaVersion) ||
                other.schemaVersion == schemaVersion) &&
            const DeepCollectionEquality().equals(
                other._migratedTransactionSnapshots,
                _migratedTransactionSnapshots));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      groupId,
      date,
      amount,
      sourceAssetId,
      sourceAssetName,
      destinationType,
      destinationId,
      destinationName,
      note,
      concept,
      source,
      const DeepCollectionEquality().hash(_bankLegs),
      awaitsBankCounterpart,
      schemaVersion,
      const DeepCollectionEquality().hash(_migratedTransactionSnapshots));

  /// Create a copy of Transfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransferImplCopyWith<_$TransferImpl> get copyWith =>
      __$$TransferImplCopyWithImpl<_$TransferImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransferImplToJson(
      this,
    );
  }
}

abstract class _Transfer implements Transfer {
  const factory _Transfer(
          {required final String id,
          required final String groupId,
          required final DateTime date,
          required final double amount,
          required final String sourceAssetId,
          required final String sourceAssetName,
          required final TransferDestinationType destinationType,
          required final String destinationId,
          required final String destinationName,
          final String? note,
          final String? concept,
          final String source,
          final List<BankTransferLeg> bankLegs,
          final bool awaitsBankCounterpart,
          final int schemaVersion,
          final List<Map<String, dynamic>> migratedTransactionSnapshots}) =
      _$TransferImpl;

  factory _Transfer.fromJson(Map<String, dynamic> json) =
      _$TransferImpl.fromJson;

  @override
  String get id;
  @override
  String get groupId;
  @override
  DateTime get date;
  @override
  double get amount;
  @override
  String get sourceAssetId;
  @override
  String get sourceAssetName; // Snapshot
  @override
  TransferDestinationType get destinationType;
  @override
  String get destinationId;
  @override
  String get destinationName; // Snapshot
  @override
  String? get note;
  @override
  String? get concept;
  @override
  String get source;
  @override
  List<BankTransferLeg> get bankLegs;
  @override
  bool get awaitsBankCounterpart;
  @override
  int get schemaVersion;
  @override
  List<Map<String, dynamic>> get migratedTransactionSnapshots;

  /// Create a copy of Transfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransferImplCopyWith<_$TransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
