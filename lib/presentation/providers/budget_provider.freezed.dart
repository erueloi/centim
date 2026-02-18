// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SubcategoryBudgetStatus {
  SubCategory get subcategory => throw _privateConstructorUsedError;
  double get spent => throw _privateConstructorUsedError;
  double get budget => throw _privateConstructorUsedError;
  double get percentage => throw _privateConstructorUsedError;

  /// Create a copy of SubcategoryBudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubcategoryBudgetStatusCopyWith<SubcategoryBudgetStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubcategoryBudgetStatusCopyWith<$Res> {
  factory $SubcategoryBudgetStatusCopyWith(
    SubcategoryBudgetStatus value,
    $Res Function(SubcategoryBudgetStatus) then,
  ) = _$SubcategoryBudgetStatusCopyWithImpl<$Res, SubcategoryBudgetStatus>;
  @useResult
  $Res call({
    SubCategory subcategory,
    double spent,
    double budget,
    double percentage,
  });

  $SubCategoryCopyWith<$Res> get subcategory;
}

/// @nodoc
class _$SubcategoryBudgetStatusCopyWithImpl<
  $Res,
  $Val extends SubcategoryBudgetStatus
>
    implements $SubcategoryBudgetStatusCopyWith<$Res> {
  _$SubcategoryBudgetStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubcategoryBudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subcategory = null,
    Object? spent = null,
    Object? budget = null,
    Object? percentage = null,
  }) {
    return _then(
      _value.copyWith(
            subcategory: null == subcategory
                ? _value.subcategory
                : subcategory // ignore: cast_nullable_to_non_nullable
                      as SubCategory,
            spent: null == spent
                ? _value.spent
                : spent // ignore: cast_nullable_to_non_nullable
                      as double,
            budget: null == budget
                ? _value.budget
                : budget // ignore: cast_nullable_to_non_nullable
                      as double,
            percentage: null == percentage
                ? _value.percentage
                : percentage // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }

  /// Create a copy of SubcategoryBudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SubCategoryCopyWith<$Res> get subcategory {
    return $SubCategoryCopyWith<$Res>(_value.subcategory, (value) {
      return _then(_value.copyWith(subcategory: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SubcategoryBudgetStatusImplCopyWith<$Res>
    implements $SubcategoryBudgetStatusCopyWith<$Res> {
  factory _$$SubcategoryBudgetStatusImplCopyWith(
    _$SubcategoryBudgetStatusImpl value,
    $Res Function(_$SubcategoryBudgetStatusImpl) then,
  ) = __$$SubcategoryBudgetStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    SubCategory subcategory,
    double spent,
    double budget,
    double percentage,
  });

  @override
  $SubCategoryCopyWith<$Res> get subcategory;
}

/// @nodoc
class __$$SubcategoryBudgetStatusImplCopyWithImpl<$Res>
    extends
        _$SubcategoryBudgetStatusCopyWithImpl<
          $Res,
          _$SubcategoryBudgetStatusImpl
        >
    implements _$$SubcategoryBudgetStatusImplCopyWith<$Res> {
  __$$SubcategoryBudgetStatusImplCopyWithImpl(
    _$SubcategoryBudgetStatusImpl _value,
    $Res Function(_$SubcategoryBudgetStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SubcategoryBudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subcategory = null,
    Object? spent = null,
    Object? budget = null,
    Object? percentage = null,
  }) {
    return _then(
      _$SubcategoryBudgetStatusImpl(
        subcategory: null == subcategory
            ? _value.subcategory
            : subcategory // ignore: cast_nullable_to_non_nullable
                  as SubCategory,
        spent: null == spent
            ? _value.spent
            : spent // ignore: cast_nullable_to_non_nullable
                  as double,
        budget: null == budget
            ? _value.budget
            : budget // ignore: cast_nullable_to_non_nullable
                  as double,
        percentage: null == percentage
            ? _value.percentage
            : percentage // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$SubcategoryBudgetStatusImpl implements _SubcategoryBudgetStatus {
  const _$SubcategoryBudgetStatusImpl({
    required this.subcategory,
    required this.spent,
    required this.budget,
    required this.percentage,
  });

  @override
  final SubCategory subcategory;
  @override
  final double spent;
  @override
  final double budget;
  @override
  final double percentage;

  @override
  String toString() {
    return 'SubcategoryBudgetStatus(subcategory: $subcategory, spent: $spent, budget: $budget, percentage: $percentage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubcategoryBudgetStatusImpl &&
            (identical(other.subcategory, subcategory) ||
                other.subcategory == subcategory) &&
            (identical(other.spent, spent) || other.spent == spent) &&
            (identical(other.budget, budget) || other.budget == budget) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, subcategory, spent, budget, percentage);

  /// Create a copy of SubcategoryBudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubcategoryBudgetStatusImplCopyWith<_$SubcategoryBudgetStatusImpl>
  get copyWith =>
      __$$SubcategoryBudgetStatusImplCopyWithImpl<
        _$SubcategoryBudgetStatusImpl
      >(this, _$identity);
}

abstract class _SubcategoryBudgetStatus implements SubcategoryBudgetStatus {
  const factory _SubcategoryBudgetStatus({
    required final SubCategory subcategory,
    required final double spent,
    required final double budget,
    required final double percentage,
  }) = _$SubcategoryBudgetStatusImpl;

  @override
  SubCategory get subcategory;
  @override
  double get spent;
  @override
  double get budget;
  @override
  double get percentage;

  /// Create a copy of SubcategoryBudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubcategoryBudgetStatusImplCopyWith<_$SubcategoryBudgetStatusImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BudgetStatus {
  Category get category => throw _privateConstructorUsedError;
  double get spent => throw _privateConstructorUsedError;
  double get total => throw _privateConstructorUsedError;
  double get percentage => throw _privateConstructorUsedError;
  bool get isOverBudget => throw _privateConstructorUsedError;
  List<SubcategoryBudgetStatus> get subcategoryStatuses =>
      throw _privateConstructorUsedError;

  /// Create a copy of BudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BudgetStatusCopyWith<BudgetStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetStatusCopyWith<$Res> {
  factory $BudgetStatusCopyWith(
    BudgetStatus value,
    $Res Function(BudgetStatus) then,
  ) = _$BudgetStatusCopyWithImpl<$Res, BudgetStatus>;
  @useResult
  $Res call({
    Category category,
    double spent,
    double total,
    double percentage,
    bool isOverBudget,
    List<SubcategoryBudgetStatus> subcategoryStatuses,
  });

  $CategoryCopyWith<$Res> get category;
}

/// @nodoc
class _$BudgetStatusCopyWithImpl<$Res, $Val extends BudgetStatus>
    implements $BudgetStatusCopyWith<$Res> {
  _$BudgetStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? spent = null,
    Object? total = null,
    Object? percentage = null,
    Object? isOverBudget = null,
    Object? subcategoryStatuses = null,
  }) {
    return _then(
      _value.copyWith(
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as Category,
            spent: null == spent
                ? _value.spent
                : spent // ignore: cast_nullable_to_non_nullable
                      as double,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as double,
            percentage: null == percentage
                ? _value.percentage
                : percentage // ignore: cast_nullable_to_non_nullable
                      as double,
            isOverBudget: null == isOverBudget
                ? _value.isOverBudget
                : isOverBudget // ignore: cast_nullable_to_non_nullable
                      as bool,
            subcategoryStatuses: null == subcategoryStatuses
                ? _value.subcategoryStatuses
                : subcategoryStatuses // ignore: cast_nullable_to_non_nullable
                      as List<SubcategoryBudgetStatus>,
          )
          as $Val,
    );
  }

  /// Create a copy of BudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CategoryCopyWith<$Res> get category {
    return $CategoryCopyWith<$Res>(_value.category, (value) {
      return _then(_value.copyWith(category: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BudgetStatusImplCopyWith<$Res>
    implements $BudgetStatusCopyWith<$Res> {
  factory _$$BudgetStatusImplCopyWith(
    _$BudgetStatusImpl value,
    $Res Function(_$BudgetStatusImpl) then,
  ) = __$$BudgetStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Category category,
    double spent,
    double total,
    double percentage,
    bool isOverBudget,
    List<SubcategoryBudgetStatus> subcategoryStatuses,
  });

  @override
  $CategoryCopyWith<$Res> get category;
}

/// @nodoc
class __$$BudgetStatusImplCopyWithImpl<$Res>
    extends _$BudgetStatusCopyWithImpl<$Res, _$BudgetStatusImpl>
    implements _$$BudgetStatusImplCopyWith<$Res> {
  __$$BudgetStatusImplCopyWithImpl(
    _$BudgetStatusImpl _value,
    $Res Function(_$BudgetStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? spent = null,
    Object? total = null,
    Object? percentage = null,
    Object? isOverBudget = null,
    Object? subcategoryStatuses = null,
  }) {
    return _then(
      _$BudgetStatusImpl(
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as Category,
        spent: null == spent
            ? _value.spent
            : spent // ignore: cast_nullable_to_non_nullable
                  as double,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as double,
        percentage: null == percentage
            ? _value.percentage
            : percentage // ignore: cast_nullable_to_non_nullable
                  as double,
        isOverBudget: null == isOverBudget
            ? _value.isOverBudget
            : isOverBudget // ignore: cast_nullable_to_non_nullable
                  as bool,
        subcategoryStatuses: null == subcategoryStatuses
            ? _value._subcategoryStatuses
            : subcategoryStatuses // ignore: cast_nullable_to_non_nullable
                  as List<SubcategoryBudgetStatus>,
      ),
    );
  }
}

/// @nodoc

class _$BudgetStatusImpl implements _BudgetStatus {
  const _$BudgetStatusImpl({
    required this.category,
    required this.spent,
    required this.total,
    required this.percentage,
    required this.isOverBudget,
    final List<SubcategoryBudgetStatus> subcategoryStatuses = const [],
  }) : _subcategoryStatuses = subcategoryStatuses;

  @override
  final Category category;
  @override
  final double spent;
  @override
  final double total;
  @override
  final double percentage;
  @override
  final bool isOverBudget;
  final List<SubcategoryBudgetStatus> _subcategoryStatuses;
  @override
  @JsonKey()
  List<SubcategoryBudgetStatus> get subcategoryStatuses {
    if (_subcategoryStatuses is EqualUnmodifiableListView)
      return _subcategoryStatuses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subcategoryStatuses);
  }

  @override
  String toString() {
    return 'BudgetStatus(category: $category, spent: $spent, total: $total, percentage: $percentage, isOverBudget: $isOverBudget, subcategoryStatuses: $subcategoryStatuses)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetStatusImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.spent, spent) || other.spent == spent) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            (identical(other.isOverBudget, isOverBudget) ||
                other.isOverBudget == isOverBudget) &&
            const DeepCollectionEquality().equals(
              other._subcategoryStatuses,
              _subcategoryStatuses,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    category,
    spent,
    total,
    percentage,
    isOverBudget,
    const DeepCollectionEquality().hash(_subcategoryStatuses),
  );

  /// Create a copy of BudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetStatusImplCopyWith<_$BudgetStatusImpl> get copyWith =>
      __$$BudgetStatusImplCopyWithImpl<_$BudgetStatusImpl>(this, _$identity);
}

abstract class _BudgetStatus implements BudgetStatus {
  const factory _BudgetStatus({
    required final Category category,
    required final double spent,
    required final double total,
    required final double percentage,
    required final bool isOverBudget,
    final List<SubcategoryBudgetStatus> subcategoryStatuses,
  }) = _$BudgetStatusImpl;

  @override
  Category get category;
  @override
  double get spent;
  @override
  double get total;
  @override
  double get percentage;
  @override
  bool get isOverBudget;
  @override
  List<SubcategoryBudgetStatus> get subcategoryStatuses;

  /// Create a copy of BudgetStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BudgetStatusImplCopyWith<_$BudgetStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ZeroBudgetSummary {
  double get totalIncome => throw _privateConstructorUsedError;
  double get totalExpenses => throw _privateConstructorUsedError;
  double get remainder => throw _privateConstructorUsedError;

  /// Create a copy of ZeroBudgetSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ZeroBudgetSummaryCopyWith<ZeroBudgetSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ZeroBudgetSummaryCopyWith<$Res> {
  factory $ZeroBudgetSummaryCopyWith(
    ZeroBudgetSummary value,
    $Res Function(ZeroBudgetSummary) then,
  ) = _$ZeroBudgetSummaryCopyWithImpl<$Res, ZeroBudgetSummary>;
  @useResult
  $Res call({double totalIncome, double totalExpenses, double remainder});
}

/// @nodoc
class _$ZeroBudgetSummaryCopyWithImpl<$Res, $Val extends ZeroBudgetSummary>
    implements $ZeroBudgetSummaryCopyWith<$Res> {
  _$ZeroBudgetSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ZeroBudgetSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalIncome = null,
    Object? totalExpenses = null,
    Object? remainder = null,
  }) {
    return _then(
      _value.copyWith(
            totalIncome: null == totalIncome
                ? _value.totalIncome
                : totalIncome // ignore: cast_nullable_to_non_nullable
                      as double,
            totalExpenses: null == totalExpenses
                ? _value.totalExpenses
                : totalExpenses // ignore: cast_nullable_to_non_nullable
                      as double,
            remainder: null == remainder
                ? _value.remainder
                : remainder // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ZeroBudgetSummaryImplCopyWith<$Res>
    implements $ZeroBudgetSummaryCopyWith<$Res> {
  factory _$$ZeroBudgetSummaryImplCopyWith(
    _$ZeroBudgetSummaryImpl value,
    $Res Function(_$ZeroBudgetSummaryImpl) then,
  ) = __$$ZeroBudgetSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double totalIncome, double totalExpenses, double remainder});
}

/// @nodoc
class __$$ZeroBudgetSummaryImplCopyWithImpl<$Res>
    extends _$ZeroBudgetSummaryCopyWithImpl<$Res, _$ZeroBudgetSummaryImpl>
    implements _$$ZeroBudgetSummaryImplCopyWith<$Res> {
  __$$ZeroBudgetSummaryImplCopyWithImpl(
    _$ZeroBudgetSummaryImpl _value,
    $Res Function(_$ZeroBudgetSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ZeroBudgetSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalIncome = null,
    Object? totalExpenses = null,
    Object? remainder = null,
  }) {
    return _then(
      _$ZeroBudgetSummaryImpl(
        totalIncome: null == totalIncome
            ? _value.totalIncome
            : totalIncome // ignore: cast_nullable_to_non_nullable
                  as double,
        totalExpenses: null == totalExpenses
            ? _value.totalExpenses
            : totalExpenses // ignore: cast_nullable_to_non_nullable
                  as double,
        remainder: null == remainder
            ? _value.remainder
            : remainder // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$ZeroBudgetSummaryImpl implements _ZeroBudgetSummary {
  const _$ZeroBudgetSummaryImpl({
    required this.totalIncome,
    required this.totalExpenses,
    required this.remainder,
  });

  @override
  final double totalIncome;
  @override
  final double totalExpenses;
  @override
  final double remainder;

  @override
  String toString() {
    return 'ZeroBudgetSummary(totalIncome: $totalIncome, totalExpenses: $totalExpenses, remainder: $remainder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ZeroBudgetSummaryImpl &&
            (identical(other.totalIncome, totalIncome) ||
                other.totalIncome == totalIncome) &&
            (identical(other.totalExpenses, totalExpenses) ||
                other.totalExpenses == totalExpenses) &&
            (identical(other.remainder, remainder) ||
                other.remainder == remainder));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, totalIncome, totalExpenses, remainder);

  /// Create a copy of ZeroBudgetSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ZeroBudgetSummaryImplCopyWith<_$ZeroBudgetSummaryImpl> get copyWith =>
      __$$ZeroBudgetSummaryImplCopyWithImpl<_$ZeroBudgetSummaryImpl>(
        this,
        _$identity,
      );
}

abstract class _ZeroBudgetSummary implements ZeroBudgetSummary {
  const factory _ZeroBudgetSummary({
    required final double totalIncome,
    required final double totalExpenses,
    required final double remainder,
  }) = _$ZeroBudgetSummaryImpl;

  @override
  double get totalIncome;
  @override
  double get totalExpenses;
  @override
  double get remainder;

  /// Create a copy of ZeroBudgetSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ZeroBudgetSummaryImplCopyWith<_$ZeroBudgetSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
