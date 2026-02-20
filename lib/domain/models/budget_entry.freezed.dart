// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BudgetEntry _$BudgetEntryFromJson(Map<String, dynamic> json) {
  return _BudgetEntry.fromJson(json);
}

/// @nodoc
mixin _$BudgetEntry {
  String get id => throw _privateConstructorUsedError;
  String get subCategoryId => throw _privateConstructorUsedError;
  int get year => throw _privateConstructorUsedError;
  int get month => throw _privateConstructorUsedError; // 1-12
  double get amount => throw _privateConstructorUsedError;

  /// Serializes this BudgetEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BudgetEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BudgetEntryCopyWith<BudgetEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetEntryCopyWith<$Res> {
  factory $BudgetEntryCopyWith(
          BudgetEntry value, $Res Function(BudgetEntry) then) =
      _$BudgetEntryCopyWithImpl<$Res, BudgetEntry>;
  @useResult
  $Res call(
      {String id, String subCategoryId, int year, int month, double amount});
}

/// @nodoc
class _$BudgetEntryCopyWithImpl<$Res, $Val extends BudgetEntry>
    implements $BudgetEntryCopyWith<$Res> {
  _$BudgetEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BudgetEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? subCategoryId = null,
    Object? year = null,
    Object? month = null,
    Object? amount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      subCategoryId: null == subCategoryId
          ? _value.subCategoryId
          : subCategoryId // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
              as int,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BudgetEntryImplCopyWith<$Res>
    implements $BudgetEntryCopyWith<$Res> {
  factory _$$BudgetEntryImplCopyWith(
          _$BudgetEntryImpl value, $Res Function(_$BudgetEntryImpl) then) =
      __$$BudgetEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String subCategoryId, int year, int month, double amount});
}

/// @nodoc
class __$$BudgetEntryImplCopyWithImpl<$Res>
    extends _$BudgetEntryCopyWithImpl<$Res, _$BudgetEntryImpl>
    implements _$$BudgetEntryImplCopyWith<$Res> {
  __$$BudgetEntryImplCopyWithImpl(
      _$BudgetEntryImpl _value, $Res Function(_$BudgetEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of BudgetEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? subCategoryId = null,
    Object? year = null,
    Object? month = null,
    Object? amount = null,
  }) {
    return _then(_$BudgetEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      subCategoryId: null == subCategoryId
          ? _value.subCategoryId
          : subCategoryId // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
              as int,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BudgetEntryImpl implements _BudgetEntry {
  const _$BudgetEntryImpl(
      {required this.id,
      required this.subCategoryId,
      required this.year,
      required this.month,
      required this.amount});

  factory _$BudgetEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$BudgetEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String subCategoryId;
  @override
  final int year;
  @override
  final int month;
// 1-12
  @override
  final double amount;

  @override
  String toString() {
    return 'BudgetEntry(id: $id, subCategoryId: $subCategoryId, year: $year, month: $month, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.subCategoryId, subCategoryId) ||
                other.subCategoryId == subCategoryId) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, subCategoryId, year, month, amount);

  /// Create a copy of BudgetEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetEntryImplCopyWith<_$BudgetEntryImpl> get copyWith =>
      __$$BudgetEntryImplCopyWithImpl<_$BudgetEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BudgetEntryImplToJson(
      this,
    );
  }
}

abstract class _BudgetEntry implements BudgetEntry {
  const factory _BudgetEntry(
      {required final String id,
      required final String subCategoryId,
      required final int year,
      required final int month,
      required final double amount}) = _$BudgetEntryImpl;

  factory _BudgetEntry.fromJson(Map<String, dynamic> json) =
      _$BudgetEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get subCategoryId;
  @override
  int get year;
  @override
  int get month; // 1-12
  @override
  double get amount;

  /// Create a copy of BudgetEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BudgetEntryImplCopyWith<_$BudgetEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
