// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Transaction {
  String? get id => throw _privateConstructorUsedError;
  String get groupId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get concept =>
      throw _privateConstructorUsedError; // Dynamic Category Fields
  String get categoryId => throw _privateConstructorUsedError;
  String get subCategoryId => throw _privateConstructorUsedError;
  String get categoryName => throw _privateConstructorUsedError; // Snapshot
  String get subCategoryName => throw _privateConstructorUsedError; // Snapshot
  String get payer => throw _privateConstructorUsedError;
  bool get isIncome =>
      throw _privateConstructorUsedError; // true = income, false = expense
  String? get savingsGoalId =>
      throw _privateConstructorUsedError; // Non-null if this transaction is paid FROM savings (or is a withdrawal)
  String? get accountId => throw _privateConstructorUsedError;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionCopyWith<Transaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionCopyWith<$Res> {
  factory $TransactionCopyWith(
          Transaction value, $Res Function(Transaction) then) =
      _$TransactionCopyWithImpl<$Res, Transaction>;
  @useResult
  $Res call(
      {String? id,
      String groupId,
      DateTime date,
      double amount,
      String concept,
      String categoryId,
      String subCategoryId,
      String categoryName,
      String subCategoryName,
      String payer,
      bool isIncome,
      String? savingsGoalId,
      String? accountId});
}

/// @nodoc
class _$TransactionCopyWithImpl<$Res, $Val extends Transaction>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? groupId = null,
    Object? date = null,
    Object? amount = null,
    Object? concept = null,
    Object? categoryId = null,
    Object? subCategoryId = null,
    Object? categoryName = null,
    Object? subCategoryName = null,
    Object? payer = null,
    Object? isIncome = null,
    Object? savingsGoalId = freezed,
    Object? accountId = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
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
      concept: null == concept
          ? _value.concept
          : concept // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      subCategoryId: null == subCategoryId
          ? _value.subCategoryId
          : subCategoryId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryName: null == categoryName
          ? _value.categoryName
          : categoryName // ignore: cast_nullable_to_non_nullable
              as String,
      subCategoryName: null == subCategoryName
          ? _value.subCategoryName
          : subCategoryName // ignore: cast_nullable_to_non_nullable
              as String,
      payer: null == payer
          ? _value.payer
          : payer // ignore: cast_nullable_to_non_nullable
              as String,
      isIncome: null == isIncome
          ? _value.isIncome
          : isIncome // ignore: cast_nullable_to_non_nullable
              as bool,
      savingsGoalId: freezed == savingsGoalId
          ? _value.savingsGoalId
          : savingsGoalId // ignore: cast_nullable_to_non_nullable
              as String?,
      accountId: freezed == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TransactionImplCopyWith<$Res>
    implements $TransactionCopyWith<$Res> {
  factory _$$TransactionImplCopyWith(
          _$TransactionImpl value, $Res Function(_$TransactionImpl) then) =
      __$$TransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? id,
      String groupId,
      DateTime date,
      double amount,
      String concept,
      String categoryId,
      String subCategoryId,
      String categoryName,
      String subCategoryName,
      String payer,
      bool isIncome,
      String? savingsGoalId,
      String? accountId});
}

/// @nodoc
class __$$TransactionImplCopyWithImpl<$Res>
    extends _$TransactionCopyWithImpl<$Res, _$TransactionImpl>
    implements _$$TransactionImplCopyWith<$Res> {
  __$$TransactionImplCopyWithImpl(
      _$TransactionImpl _value, $Res Function(_$TransactionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? groupId = null,
    Object? date = null,
    Object? amount = null,
    Object? concept = null,
    Object? categoryId = null,
    Object? subCategoryId = null,
    Object? categoryName = null,
    Object? subCategoryName = null,
    Object? payer = null,
    Object? isIncome = null,
    Object? savingsGoalId = freezed,
    Object? accountId = freezed,
  }) {
    return _then(_$TransactionImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
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
      concept: null == concept
          ? _value.concept
          : concept // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      subCategoryId: null == subCategoryId
          ? _value.subCategoryId
          : subCategoryId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryName: null == categoryName
          ? _value.categoryName
          : categoryName // ignore: cast_nullable_to_non_nullable
              as String,
      subCategoryName: null == subCategoryName
          ? _value.subCategoryName
          : subCategoryName // ignore: cast_nullable_to_non_nullable
              as String,
      payer: null == payer
          ? _value.payer
          : payer // ignore: cast_nullable_to_non_nullable
              as String,
      isIncome: null == isIncome
          ? _value.isIncome
          : isIncome // ignore: cast_nullable_to_non_nullable
              as bool,
      savingsGoalId: freezed == savingsGoalId
          ? _value.savingsGoalId
          : savingsGoalId // ignore: cast_nullable_to_non_nullable
              as String?,
      accountId: freezed == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$TransactionImpl implements _Transaction {
  const _$TransactionImpl(
      {this.id,
      required this.groupId,
      required this.date,
      required this.amount,
      required this.concept,
      required this.categoryId,
      required this.subCategoryId,
      required this.categoryName,
      required this.subCategoryName,
      required this.payer,
      this.isIncome = false,
      this.savingsGoalId,
      this.accountId});

  @override
  final String? id;
  @override
  final String groupId;
  @override
  final DateTime date;
  @override
  final double amount;
  @override
  final String concept;
// Dynamic Category Fields
  @override
  final String categoryId;
  @override
  final String subCategoryId;
  @override
  final String categoryName;
// Snapshot
  @override
  final String subCategoryName;
// Snapshot
  @override
  final String payer;
  @override
  @JsonKey()
  final bool isIncome;
// true = income, false = expense
  @override
  final String? savingsGoalId;
// Non-null if this transaction is paid FROM savings (or is a withdrawal)
  @override
  final String? accountId;

  @override
  String toString() {
    return 'Transaction(id: $id, groupId: $groupId, date: $date, amount: $amount, concept: $concept, categoryId: $categoryId, subCategoryId: $subCategoryId, categoryName: $categoryName, subCategoryName: $subCategoryName, payer: $payer, isIncome: $isIncome, savingsGoalId: $savingsGoalId, accountId: $accountId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.concept, concept) || other.concept == concept) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.subCategoryId, subCategoryId) ||
                other.subCategoryId == subCategoryId) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.subCategoryName, subCategoryName) ||
                other.subCategoryName == subCategoryName) &&
            (identical(other.payer, payer) || other.payer == payer) &&
            (identical(other.isIncome, isIncome) ||
                other.isIncome == isIncome) &&
            (identical(other.savingsGoalId, savingsGoalId) ||
                other.savingsGoalId == savingsGoalId) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      groupId,
      date,
      amount,
      concept,
      categoryId,
      subCategoryId,
      categoryName,
      subCategoryName,
      payer,
      isIncome,
      savingsGoalId,
      accountId);

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      __$$TransactionImplCopyWithImpl<_$TransactionImpl>(this, _$identity);
}

abstract class _Transaction implements Transaction {
  const factory _Transaction(
      {final String? id,
      required final String groupId,
      required final DateTime date,
      required final double amount,
      required final String concept,
      required final String categoryId,
      required final String subCategoryId,
      required final String categoryName,
      required final String subCategoryName,
      required final String payer,
      final bool isIncome,
      final String? savingsGoalId,
      final String? accountId}) = _$TransactionImpl;

  @override
  String? get id;
  @override
  String get groupId;
  @override
  DateTime get date;
  @override
  double get amount;
  @override
  String get concept; // Dynamic Category Fields
  @override
  String get categoryId;
  @override
  String get subCategoryId;
  @override
  String get categoryName; // Snapshot
  @override
  String get subCategoryName; // Snapshot
  @override
  String get payer;
  @override
  bool get isIncome; // true = income, false = expense
  @override
  String?
      get savingsGoalId; // Non-null if this transaction is paid FROM savings (or is a withdrawal)
  @override
  String? get accountId;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
