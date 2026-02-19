// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TransactionFilter {
  String? get categoryId => throw _privateConstructorUsedError;
  String? get categoryName => throw _privateConstructorUsedError;
  String? get subCategoryId => throw _privateConstructorUsedError;
  String? get subCategoryName => throw _privateConstructorUsedError;
  String? get searchQuery => throw _privateConstructorUsedError;
  bool? get isIncome =>
      throw _privateConstructorUsedError; // null = all, true = income, false = expense
  String? get payer => throw _privateConstructorUsedError;
  double? get minAmount => throw _privateConstructorUsedError;
  double? get maxAmount => throw _privateConstructorUsedError;

  /// Create a copy of TransactionFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionFilterCopyWith<TransactionFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionFilterCopyWith<$Res> {
  factory $TransactionFilterCopyWith(
    TransactionFilter value,
    $Res Function(TransactionFilter) then,
  ) = _$TransactionFilterCopyWithImpl<$Res, TransactionFilter>;
  @useResult
  $Res call({
    String? categoryId,
    String? categoryName,
    String? subCategoryId,
    String? subCategoryName,
    String? searchQuery,
    bool? isIncome,
    String? payer,
    double? minAmount,
    double? maxAmount,
  });
}

/// @nodoc
class _$TransactionFilterCopyWithImpl<$Res, $Val extends TransactionFilter>
    implements $TransactionFilterCopyWith<$Res> {
  _$TransactionFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransactionFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryId = freezed,
    Object? categoryName = freezed,
    Object? subCategoryId = freezed,
    Object? subCategoryName = freezed,
    Object? searchQuery = freezed,
    Object? isIncome = freezed,
    Object? payer = freezed,
    Object? minAmount = freezed,
    Object? maxAmount = freezed,
  }) {
    return _then(
      _value.copyWith(
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            categoryName: freezed == categoryName
                ? _value.categoryName
                : categoryName // ignore: cast_nullable_to_non_nullable
                      as String?,
            subCategoryId: freezed == subCategoryId
                ? _value.subCategoryId
                : subCategoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            subCategoryName: freezed == subCategoryName
                ? _value.subCategoryName
                : subCategoryName // ignore: cast_nullable_to_non_nullable
                      as String?,
            searchQuery: freezed == searchQuery
                ? _value.searchQuery
                : searchQuery // ignore: cast_nullable_to_non_nullable
                      as String?,
            isIncome: freezed == isIncome
                ? _value.isIncome
                : isIncome // ignore: cast_nullable_to_non_nullable
                      as bool?,
            payer: freezed == payer
                ? _value.payer
                : payer // ignore: cast_nullable_to_non_nullable
                      as String?,
            minAmount: freezed == minAmount
                ? _value.minAmount
                : minAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            maxAmount: freezed == maxAmount
                ? _value.maxAmount
                : maxAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TransactionFilterImplCopyWith<$Res>
    implements $TransactionFilterCopyWith<$Res> {
  factory _$$TransactionFilterImplCopyWith(
    _$TransactionFilterImpl value,
    $Res Function(_$TransactionFilterImpl) then,
  ) = __$$TransactionFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? categoryId,
    String? categoryName,
    String? subCategoryId,
    String? subCategoryName,
    String? searchQuery,
    bool? isIncome,
    String? payer,
    double? minAmount,
    double? maxAmount,
  });
}

/// @nodoc
class __$$TransactionFilterImplCopyWithImpl<$Res>
    extends _$TransactionFilterCopyWithImpl<$Res, _$TransactionFilterImpl>
    implements _$$TransactionFilterImplCopyWith<$Res> {
  __$$TransactionFilterImplCopyWithImpl(
    _$TransactionFilterImpl _value,
    $Res Function(_$TransactionFilterImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TransactionFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryId = freezed,
    Object? categoryName = freezed,
    Object? subCategoryId = freezed,
    Object? subCategoryName = freezed,
    Object? searchQuery = freezed,
    Object? isIncome = freezed,
    Object? payer = freezed,
    Object? minAmount = freezed,
    Object? maxAmount = freezed,
  }) {
    return _then(
      _$TransactionFilterImpl(
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        categoryName: freezed == categoryName
            ? _value.categoryName
            : categoryName // ignore: cast_nullable_to_non_nullable
                  as String?,
        subCategoryId: freezed == subCategoryId
            ? _value.subCategoryId
            : subCategoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        subCategoryName: freezed == subCategoryName
            ? _value.subCategoryName
            : subCategoryName // ignore: cast_nullable_to_non_nullable
                  as String?,
        searchQuery: freezed == searchQuery
            ? _value.searchQuery
            : searchQuery // ignore: cast_nullable_to_non_nullable
                  as String?,
        isIncome: freezed == isIncome
            ? _value.isIncome
            : isIncome // ignore: cast_nullable_to_non_nullable
                  as bool?,
        payer: freezed == payer
            ? _value.payer
            : payer // ignore: cast_nullable_to_non_nullable
                  as String?,
        minAmount: freezed == minAmount
            ? _value.minAmount
            : minAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        maxAmount: freezed == maxAmount
            ? _value.maxAmount
            : maxAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc

class _$TransactionFilterImpl implements _TransactionFilter {
  const _$TransactionFilterImpl({
    this.categoryId,
    this.categoryName,
    this.subCategoryId,
    this.subCategoryName,
    this.searchQuery,
    this.isIncome,
    this.payer,
    this.minAmount,
    this.maxAmount,
  });

  @override
  final String? categoryId;
  @override
  final String? categoryName;
  @override
  final String? subCategoryId;
  @override
  final String? subCategoryName;
  @override
  final String? searchQuery;
  @override
  final bool? isIncome;
  // null = all, true = income, false = expense
  @override
  final String? payer;
  @override
  final double? minAmount;
  @override
  final double? maxAmount;

  @override
  String toString() {
    return 'TransactionFilter(categoryId: $categoryId, categoryName: $categoryName, subCategoryId: $subCategoryId, subCategoryName: $subCategoryName, searchQuery: $searchQuery, isIncome: $isIncome, payer: $payer, minAmount: $minAmount, maxAmount: $maxAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionFilterImpl &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.subCategoryId, subCategoryId) ||
                other.subCategoryId == subCategoryId) &&
            (identical(other.subCategoryName, subCategoryName) ||
                other.subCategoryName == subCategoryName) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.isIncome, isIncome) ||
                other.isIncome == isIncome) &&
            (identical(other.payer, payer) || other.payer == payer) &&
            (identical(other.minAmount, minAmount) ||
                other.minAmount == minAmount) &&
            (identical(other.maxAmount, maxAmount) ||
                other.maxAmount == maxAmount));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    categoryId,
    categoryName,
    subCategoryId,
    subCategoryName,
    searchQuery,
    isIncome,
    payer,
    minAmount,
    maxAmount,
  );

  /// Create a copy of TransactionFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionFilterImplCopyWith<_$TransactionFilterImpl> get copyWith =>
      __$$TransactionFilterImplCopyWithImpl<_$TransactionFilterImpl>(
        this,
        _$identity,
      );
}

abstract class _TransactionFilter implements TransactionFilter {
  const factory _TransactionFilter({
    final String? categoryId,
    final String? categoryName,
    final String? subCategoryId,
    final String? subCategoryName,
    final String? searchQuery,
    final bool? isIncome,
    final String? payer,
    final double? minAmount,
    final double? maxAmount,
  }) = _$TransactionFilterImpl;

  @override
  String? get categoryId;
  @override
  String? get categoryName;
  @override
  String? get subCategoryId;
  @override
  String? get subCategoryName;
  @override
  String? get searchQuery;
  @override
  bool? get isIncome; // null = all, true = income, false = expense
  @override
  String? get payer;
  @override
  double? get minAmount;
  @override
  double? get maxAmount;

  /// Create a copy of TransactionFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionFilterImplCopyWith<_$TransactionFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
