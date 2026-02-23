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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TransactionFilter {
  List<String> get categoryIds => throw _privateConstructorUsedError;
  Map<String, String> get categoryNames =>
      throw _privateConstructorUsedError; // id -> name
  List<String> get subCategoryIds => throw _privateConstructorUsedError;
  Map<String, String> get subCategoryNames =>
      throw _privateConstructorUsedError; // id -> name
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
          TransactionFilter value, $Res Function(TransactionFilter) then) =
      _$TransactionFilterCopyWithImpl<$Res, TransactionFilter>;
  @useResult
  $Res call(
      {List<String> categoryIds,
      Map<String, String> categoryNames,
      List<String> subCategoryIds,
      Map<String, String> subCategoryNames,
      String? searchQuery,
      bool? isIncome,
      String? payer,
      double? minAmount,
      double? maxAmount});
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
    Object? categoryIds = null,
    Object? categoryNames = null,
    Object? subCategoryIds = null,
    Object? subCategoryNames = null,
    Object? searchQuery = freezed,
    Object? isIncome = freezed,
    Object? payer = freezed,
    Object? minAmount = freezed,
    Object? maxAmount = freezed,
  }) {
    return _then(_value.copyWith(
      categoryIds: null == categoryIds
          ? _value.categoryIds
          : categoryIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      categoryNames: null == categoryNames
          ? _value.categoryNames
          : categoryNames // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      subCategoryIds: null == subCategoryIds
          ? _value.subCategoryIds
          : subCategoryIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      subCategoryNames: null == subCategoryNames
          ? _value.subCategoryNames
          : subCategoryNames // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TransactionFilterImplCopyWith<$Res>
    implements $TransactionFilterCopyWith<$Res> {
  factory _$$TransactionFilterImplCopyWith(_$TransactionFilterImpl value,
          $Res Function(_$TransactionFilterImpl) then) =
      __$$TransactionFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<String> categoryIds,
      Map<String, String> categoryNames,
      List<String> subCategoryIds,
      Map<String, String> subCategoryNames,
      String? searchQuery,
      bool? isIncome,
      String? payer,
      double? minAmount,
      double? maxAmount});
}

/// @nodoc
class __$$TransactionFilterImplCopyWithImpl<$Res>
    extends _$TransactionFilterCopyWithImpl<$Res, _$TransactionFilterImpl>
    implements _$$TransactionFilterImplCopyWith<$Res> {
  __$$TransactionFilterImplCopyWithImpl(_$TransactionFilterImpl _value,
      $Res Function(_$TransactionFilterImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransactionFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryIds = null,
    Object? categoryNames = null,
    Object? subCategoryIds = null,
    Object? subCategoryNames = null,
    Object? searchQuery = freezed,
    Object? isIncome = freezed,
    Object? payer = freezed,
    Object? minAmount = freezed,
    Object? maxAmount = freezed,
  }) {
    return _then(_$TransactionFilterImpl(
      categoryIds: null == categoryIds
          ? _value._categoryIds
          : categoryIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      categoryNames: null == categoryNames
          ? _value._categoryNames
          : categoryNames // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      subCategoryIds: null == subCategoryIds
          ? _value._subCategoryIds
          : subCategoryIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      subCategoryNames: null == subCategoryNames
          ? _value._subCategoryNames
          : subCategoryNames // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
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
    ));
  }
}

/// @nodoc

class _$TransactionFilterImpl implements _TransactionFilter {
  const _$TransactionFilterImpl(
      {final List<String> categoryIds = const [],
      final Map<String, String> categoryNames = const {},
      final List<String> subCategoryIds = const [],
      final Map<String, String> subCategoryNames = const {},
      this.searchQuery,
      this.isIncome,
      this.payer,
      this.minAmount,
      this.maxAmount})
      : _categoryIds = categoryIds,
        _categoryNames = categoryNames,
        _subCategoryIds = subCategoryIds,
        _subCategoryNames = subCategoryNames;

  final List<String> _categoryIds;
  @override
  @JsonKey()
  List<String> get categoryIds {
    if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categoryIds);
  }

  final Map<String, String> _categoryNames;
  @override
  @JsonKey()
  Map<String, String> get categoryNames {
    if (_categoryNames is EqualUnmodifiableMapView) return _categoryNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_categoryNames);
  }

// id -> name
  final List<String> _subCategoryIds;
// id -> name
  @override
  @JsonKey()
  List<String> get subCategoryIds {
    if (_subCategoryIds is EqualUnmodifiableListView) return _subCategoryIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subCategoryIds);
  }

  final Map<String, String> _subCategoryNames;
  @override
  @JsonKey()
  Map<String, String> get subCategoryNames {
    if (_subCategoryNames is EqualUnmodifiableMapView) return _subCategoryNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_subCategoryNames);
  }

// id -> name
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
    return 'TransactionFilter(categoryIds: $categoryIds, categoryNames: $categoryNames, subCategoryIds: $subCategoryIds, subCategoryNames: $subCategoryNames, searchQuery: $searchQuery, isIncome: $isIncome, payer: $payer, minAmount: $minAmount, maxAmount: $maxAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionFilterImpl &&
            const DeepCollectionEquality()
                .equals(other._categoryIds, _categoryIds) &&
            const DeepCollectionEquality()
                .equals(other._categoryNames, _categoryNames) &&
            const DeepCollectionEquality()
                .equals(other._subCategoryIds, _subCategoryIds) &&
            const DeepCollectionEquality()
                .equals(other._subCategoryNames, _subCategoryNames) &&
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
      const DeepCollectionEquality().hash(_categoryIds),
      const DeepCollectionEquality().hash(_categoryNames),
      const DeepCollectionEquality().hash(_subCategoryIds),
      const DeepCollectionEquality().hash(_subCategoryNames),
      searchQuery,
      isIncome,
      payer,
      minAmount,
      maxAmount);

  /// Create a copy of TransactionFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionFilterImplCopyWith<_$TransactionFilterImpl> get copyWith =>
      __$$TransactionFilterImplCopyWithImpl<_$TransactionFilterImpl>(
          this, _$identity);
}

abstract class _TransactionFilter implements TransactionFilter {
  const factory _TransactionFilter(
      {final List<String> categoryIds,
      final Map<String, String> categoryNames,
      final List<String> subCategoryIds,
      final Map<String, String> subCategoryNames,
      final String? searchQuery,
      final bool? isIncome,
      final String? payer,
      final double? minAmount,
      final double? maxAmount}) = _$TransactionFilterImpl;

  @override
  List<String> get categoryIds;
  @override
  Map<String, String> get categoryNames; // id -> name
  @override
  List<String> get subCategoryIds;
  @override
  Map<String, String> get subCategoryNames; // id -> name
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
