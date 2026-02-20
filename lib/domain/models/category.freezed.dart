// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Category _$CategoryFromJson(Map<String, dynamic> json) {
  return _Category.fromJson(json);
}

/// @nodoc
mixin _$Category {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get icon =>
      throw _privateConstructorUsedError; // Emoji or IconData string
  List<SubCategory> get subcategories => throw _privateConstructorUsedError;
  TransactionType get type => throw _privateConstructorUsedError;
  int? get order => throw _privateConstructorUsedError;
  int? get color => throw _privateConstructorUsedError;

  /// Serializes this Category to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryCopyWith<Category> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryCopyWith<$Res> {
  factory $CategoryCopyWith(Category value, $Res Function(Category) then) =
      _$CategoryCopyWithImpl<$Res, Category>;
  @useResult
  $Res call(
      {String id,
      String name,
      String icon,
      List<SubCategory> subcategories,
      TransactionType type,
      int? order,
      int? color});
}

/// @nodoc
class _$CategoryCopyWithImpl<$Res, $Val extends Category>
    implements $CategoryCopyWith<$Res> {
  _$CategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? icon = null,
    Object? subcategories = null,
    Object? type = null,
    Object? order = freezed,
    Object? color = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      subcategories: null == subcategories
          ? _value.subcategories
          : subcategories // ignore: cast_nullable_to_non_nullable
              as List<SubCategory>,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TransactionType,
      order: freezed == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CategoryImplCopyWith<$Res>
    implements $CategoryCopyWith<$Res> {
  factory _$$CategoryImplCopyWith(
          _$CategoryImpl value, $Res Function(_$CategoryImpl) then) =
      __$$CategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String icon,
      List<SubCategory> subcategories,
      TransactionType type,
      int? order,
      int? color});
}

/// @nodoc
class __$$CategoryImplCopyWithImpl<$Res>
    extends _$CategoryCopyWithImpl<$Res, _$CategoryImpl>
    implements _$$CategoryImplCopyWith<$Res> {
  __$$CategoryImplCopyWithImpl(
      _$CategoryImpl _value, $Res Function(_$CategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? icon = null,
    Object? subcategories = null,
    Object? type = null,
    Object? order = freezed,
    Object? color = freezed,
  }) {
    return _then(_$CategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      subcategories: null == subcategories
          ? _value._subcategories
          : subcategories // ignore: cast_nullable_to_non_nullable
              as List<SubCategory>,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TransactionType,
      order: freezed == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryImpl implements _Category {
  const _$CategoryImpl(
      {required this.id,
      required this.name,
      required this.icon,
      final List<SubCategory> subcategories = const [],
      this.type = TransactionType.expense,
      this.order,
      this.color})
      : _subcategories = subcategories;

  factory _$CategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String icon;
// Emoji or IconData string
  final List<SubCategory> _subcategories;
// Emoji or IconData string
  @override
  @JsonKey()
  List<SubCategory> get subcategories {
    if (_subcategories is EqualUnmodifiableListView) return _subcategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subcategories);
  }

  @override
  @JsonKey()
  final TransactionType type;
  @override
  final int? order;
  @override
  final int? color;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, icon: $icon, subcategories: $subcategories, type: $type, order: $order, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            const DeepCollectionEquality()
                .equals(other._subcategories, _subcategories) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.color, color) || other.color == color));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, icon,
      const DeepCollectionEquality().hash(_subcategories), type, order, color);

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryImplCopyWith<_$CategoryImpl> get copyWith =>
      __$$CategoryImplCopyWithImpl<_$CategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryImplToJson(
      this,
    );
  }
}

abstract class _Category implements Category {
  const factory _Category(
      {required final String id,
      required final String name,
      required final String icon,
      final List<SubCategory> subcategories,
      final TransactionType type,
      final int? order,
      final int? color}) = _$CategoryImpl;

  factory _Category.fromJson(Map<String, dynamic> json) =
      _$CategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get icon; // Emoji or IconData string
  @override
  List<SubCategory> get subcategories;
  @override
  TransactionType get type;
  @override
  int? get order;
  @override
  int? get color;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryImplCopyWith<_$CategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SubCategory _$SubCategoryFromJson(Map<String, dynamic> json) {
  return _SubCategory.fromJson(json);
}

/// @nodoc
mixin _$SubCategory {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get monthlyBudget => throw _privateConstructorUsedError;
  bool get isFixed => throw _privateConstructorUsedError;
  String? get defaultPayerId =>
      throw _privateConstructorUsedError; // Who usually pays this
  int? get paymentDay =>
      throw _privateConstructorUsedError; // Day of month (1-31) for fixed expenses
  PaymentTiming get paymentTiming => throw _privateConstructorUsedError;
  String? get linkedSavingsGoalId =>
      throw _privateConstructorUsedError; // ID of the savings goal to contribute to automatically
  String? get linkedDebtId => throw _privateConstructorUsedError;

  /// Serializes this SubCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubCategoryCopyWith<SubCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubCategoryCopyWith<$Res> {
  factory $SubCategoryCopyWith(
          SubCategory value, $Res Function(SubCategory) then) =
      _$SubCategoryCopyWithImpl<$Res, SubCategory>;
  @useResult
  $Res call(
      {String id,
      String name,
      double monthlyBudget,
      bool isFixed,
      String? defaultPayerId,
      int? paymentDay,
      PaymentTiming paymentTiming,
      String? linkedSavingsGoalId,
      String? linkedDebtId});
}

/// @nodoc
class _$SubCategoryCopyWithImpl<$Res, $Val extends SubCategory>
    implements $SubCategoryCopyWith<$Res> {
  _$SubCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? monthlyBudget = null,
    Object? isFixed = null,
    Object? defaultPayerId = freezed,
    Object? paymentDay = freezed,
    Object? paymentTiming = null,
    Object? linkedSavingsGoalId = freezed,
    Object? linkedDebtId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      monthlyBudget: null == monthlyBudget
          ? _value.monthlyBudget
          : monthlyBudget // ignore: cast_nullable_to_non_nullable
              as double,
      isFixed: null == isFixed
          ? _value.isFixed
          : isFixed // ignore: cast_nullable_to_non_nullable
              as bool,
      defaultPayerId: freezed == defaultPayerId
          ? _value.defaultPayerId
          : defaultPayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentDay: freezed == paymentDay
          ? _value.paymentDay
          : paymentDay // ignore: cast_nullable_to_non_nullable
              as int?,
      paymentTiming: null == paymentTiming
          ? _value.paymentTiming
          : paymentTiming // ignore: cast_nullable_to_non_nullable
              as PaymentTiming,
      linkedSavingsGoalId: freezed == linkedSavingsGoalId
          ? _value.linkedSavingsGoalId
          : linkedSavingsGoalId // ignore: cast_nullable_to_non_nullable
              as String?,
      linkedDebtId: freezed == linkedDebtId
          ? _value.linkedDebtId
          : linkedDebtId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SubCategoryImplCopyWith<$Res>
    implements $SubCategoryCopyWith<$Res> {
  factory _$$SubCategoryImplCopyWith(
          _$SubCategoryImpl value, $Res Function(_$SubCategoryImpl) then) =
      __$$SubCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      double monthlyBudget,
      bool isFixed,
      String? defaultPayerId,
      int? paymentDay,
      PaymentTiming paymentTiming,
      String? linkedSavingsGoalId,
      String? linkedDebtId});
}

/// @nodoc
class __$$SubCategoryImplCopyWithImpl<$Res>
    extends _$SubCategoryCopyWithImpl<$Res, _$SubCategoryImpl>
    implements _$$SubCategoryImplCopyWith<$Res> {
  __$$SubCategoryImplCopyWithImpl(
      _$SubCategoryImpl _value, $Res Function(_$SubCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? monthlyBudget = null,
    Object? isFixed = null,
    Object? defaultPayerId = freezed,
    Object? paymentDay = freezed,
    Object? paymentTiming = null,
    Object? linkedSavingsGoalId = freezed,
    Object? linkedDebtId = freezed,
  }) {
    return _then(_$SubCategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      monthlyBudget: null == monthlyBudget
          ? _value.monthlyBudget
          : monthlyBudget // ignore: cast_nullable_to_non_nullable
              as double,
      isFixed: null == isFixed
          ? _value.isFixed
          : isFixed // ignore: cast_nullable_to_non_nullable
              as bool,
      defaultPayerId: freezed == defaultPayerId
          ? _value.defaultPayerId
          : defaultPayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentDay: freezed == paymentDay
          ? _value.paymentDay
          : paymentDay // ignore: cast_nullable_to_non_nullable
              as int?,
      paymentTiming: null == paymentTiming
          ? _value.paymentTiming
          : paymentTiming // ignore: cast_nullable_to_non_nullable
              as PaymentTiming,
      linkedSavingsGoalId: freezed == linkedSavingsGoalId
          ? _value.linkedSavingsGoalId
          : linkedSavingsGoalId // ignore: cast_nullable_to_non_nullable
              as String?,
      linkedDebtId: freezed == linkedDebtId
          ? _value.linkedDebtId
          : linkedDebtId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SubCategoryImpl implements _SubCategory {
  const _$SubCategoryImpl(
      {required this.id,
      required this.name,
      required this.monthlyBudget,
      this.isFixed = false,
      this.defaultPayerId,
      this.paymentDay,
      this.paymentTiming = PaymentTiming.specificDay,
      this.linkedSavingsGoalId,
      this.linkedDebtId});

  factory _$SubCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubCategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double monthlyBudget;
  @override
  @JsonKey()
  final bool isFixed;
  @override
  final String? defaultPayerId;
// Who usually pays this
  @override
  final int? paymentDay;
// Day of month (1-31) for fixed expenses
  @override
  @JsonKey()
  final PaymentTiming paymentTiming;
  @override
  final String? linkedSavingsGoalId;
// ID of the savings goal to contribute to automatically
  @override
  final String? linkedDebtId;

  @override
  String toString() {
    return 'SubCategory(id: $id, name: $name, monthlyBudget: $monthlyBudget, isFixed: $isFixed, defaultPayerId: $defaultPayerId, paymentDay: $paymentDay, paymentTiming: $paymentTiming, linkedSavingsGoalId: $linkedSavingsGoalId, linkedDebtId: $linkedDebtId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.monthlyBudget, monthlyBudget) ||
                other.monthlyBudget == monthlyBudget) &&
            (identical(other.isFixed, isFixed) || other.isFixed == isFixed) &&
            (identical(other.defaultPayerId, defaultPayerId) ||
                other.defaultPayerId == defaultPayerId) &&
            (identical(other.paymentDay, paymentDay) ||
                other.paymentDay == paymentDay) &&
            (identical(other.paymentTiming, paymentTiming) ||
                other.paymentTiming == paymentTiming) &&
            (identical(other.linkedSavingsGoalId, linkedSavingsGoalId) ||
                other.linkedSavingsGoalId == linkedSavingsGoalId) &&
            (identical(other.linkedDebtId, linkedDebtId) ||
                other.linkedDebtId == linkedDebtId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      monthlyBudget,
      isFixed,
      defaultPayerId,
      paymentDay,
      paymentTiming,
      linkedSavingsGoalId,
      linkedDebtId);

  /// Create a copy of SubCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubCategoryImplCopyWith<_$SubCategoryImpl> get copyWith =>
      __$$SubCategoryImplCopyWithImpl<_$SubCategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubCategoryImplToJson(
      this,
    );
  }
}

abstract class _SubCategory implements SubCategory {
  const factory _SubCategory(
      {required final String id,
      required final String name,
      required final double monthlyBudget,
      final bool isFixed,
      final String? defaultPayerId,
      final int? paymentDay,
      final PaymentTiming paymentTiming,
      final String? linkedSavingsGoalId,
      final String? linkedDebtId}) = _$SubCategoryImpl;

  factory _SubCategory.fromJson(Map<String, dynamic> json) =
      _$SubCategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get monthlyBudget;
  @override
  bool get isFixed;
  @override
  String? get defaultPayerId; // Who usually pays this
  @override
  int? get paymentDay; // Day of month (1-31) for fixed expenses
  @override
  PaymentTiming get paymentTiming;
  @override
  String?
      get linkedSavingsGoalId; // ID of the savings goal to contribute to automatically
  @override
  String? get linkedDebtId;

  /// Create a copy of SubCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubCategoryImplCopyWith<_$SubCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
