// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'debt_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DebtAccount _$DebtAccountFromJson(Map<String, dynamic> json) {
  return _DebtAccount.fromJson(json);
}

/// @nodoc
mixin _$DebtAccount {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError; // ex: 'Préstec Cotxe'
  String? get bankName => throw _privateConstructorUsedError; // ex: 'CaixaBank'
  double get currentBalance =>
      throw _privateConstructorUsedError; // Capital Pendent
  double get originalAmount =>
      throw _privateConstructorUsedError; // Capital Inicial
  double get interestRate => throw _privateConstructorUsedError; // TAE/TIN
  double get monthlyInstallment =>
      throw _privateConstructorUsedError; // Quota mensual
  DateTime? get endDate => throw _privateConstructorUsedError; // Data venciment
  String? get linkedExpenseCategoryId => throw _privateConstructorUsedError;

  /// Serializes this DebtAccount to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DebtAccount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DebtAccountCopyWith<DebtAccount> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DebtAccountCopyWith<$Res> {
  factory $DebtAccountCopyWith(
    DebtAccount value,
    $Res Function(DebtAccount) then,
  ) = _$DebtAccountCopyWithImpl<$Res, DebtAccount>;
  @useResult
  $Res call({
    String id,
    String name,
    String? bankName,
    double currentBalance,
    double originalAmount,
    double interestRate,
    double monthlyInstallment,
    DateTime? endDate,
    String? linkedExpenseCategoryId,
  });
}

/// @nodoc
class _$DebtAccountCopyWithImpl<$Res, $Val extends DebtAccount>
    implements $DebtAccountCopyWith<$Res> {
  _$DebtAccountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DebtAccount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? bankName = freezed,
    Object? currentBalance = null,
    Object? originalAmount = null,
    Object? interestRate = null,
    Object? monthlyInstallment = null,
    Object? endDate = freezed,
    Object? linkedExpenseCategoryId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            bankName: freezed == bankName
                ? _value.bankName
                : bankName // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentBalance: null == currentBalance
                ? _value.currentBalance
                : currentBalance // ignore: cast_nullable_to_non_nullable
                      as double,
            originalAmount: null == originalAmount
                ? _value.originalAmount
                : originalAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            interestRate: null == interestRate
                ? _value.interestRate
                : interestRate // ignore: cast_nullable_to_non_nullable
                      as double,
            monthlyInstallment: null == monthlyInstallment
                ? _value.monthlyInstallment
                : monthlyInstallment // ignore: cast_nullable_to_non_nullable
                      as double,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            linkedExpenseCategoryId: freezed == linkedExpenseCategoryId
                ? _value.linkedExpenseCategoryId
                : linkedExpenseCategoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DebtAccountImplCopyWith<$Res>
    implements $DebtAccountCopyWith<$Res> {
  factory _$$DebtAccountImplCopyWith(
    _$DebtAccountImpl value,
    $Res Function(_$DebtAccountImpl) then,
  ) = __$$DebtAccountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? bankName,
    double currentBalance,
    double originalAmount,
    double interestRate,
    double monthlyInstallment,
    DateTime? endDate,
    String? linkedExpenseCategoryId,
  });
}

/// @nodoc
class __$$DebtAccountImplCopyWithImpl<$Res>
    extends _$DebtAccountCopyWithImpl<$Res, _$DebtAccountImpl>
    implements _$$DebtAccountImplCopyWith<$Res> {
  __$$DebtAccountImplCopyWithImpl(
    _$DebtAccountImpl _value,
    $Res Function(_$DebtAccountImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DebtAccount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? bankName = freezed,
    Object? currentBalance = null,
    Object? originalAmount = null,
    Object? interestRate = null,
    Object? monthlyInstallment = null,
    Object? endDate = freezed,
    Object? linkedExpenseCategoryId = freezed,
  }) {
    return _then(
      _$DebtAccountImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        bankName: freezed == bankName
            ? _value.bankName
            : bankName // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentBalance: null == currentBalance
            ? _value.currentBalance
            : currentBalance // ignore: cast_nullable_to_non_nullable
                  as double,
        originalAmount: null == originalAmount
            ? _value.originalAmount
            : originalAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        interestRate: null == interestRate
            ? _value.interestRate
            : interestRate // ignore: cast_nullable_to_non_nullable
                  as double,
        monthlyInstallment: null == monthlyInstallment
            ? _value.monthlyInstallment
            : monthlyInstallment // ignore: cast_nullable_to_non_nullable
                  as double,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        linkedExpenseCategoryId: freezed == linkedExpenseCategoryId
            ? _value.linkedExpenseCategoryId
            : linkedExpenseCategoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DebtAccountImpl implements _DebtAccount {
  const _$DebtAccountImpl({
    required this.id,
    required this.name,
    this.bankName,
    required this.currentBalance,
    required this.originalAmount,
    required this.interestRate,
    required this.monthlyInstallment,
    this.endDate,
    this.linkedExpenseCategoryId,
  });

  factory _$DebtAccountImpl.fromJson(Map<String, dynamic> json) =>
      _$$DebtAccountImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  // ex: 'Préstec Cotxe'
  @override
  final String? bankName;
  // ex: 'CaixaBank'
  @override
  final double currentBalance;
  // Capital Pendent
  @override
  final double originalAmount;
  // Capital Inicial
  @override
  final double interestRate;
  // TAE/TIN
  @override
  final double monthlyInstallment;
  // Quota mensual
  @override
  final DateTime? endDate;
  // Data venciment
  @override
  final String? linkedExpenseCategoryId;

  @override
  String toString() {
    return 'DebtAccount(id: $id, name: $name, bankName: $bankName, currentBalance: $currentBalance, originalAmount: $originalAmount, interestRate: $interestRate, monthlyInstallment: $monthlyInstallment, endDate: $endDate, linkedExpenseCategoryId: $linkedExpenseCategoryId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DebtAccountImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.bankName, bankName) ||
                other.bankName == bankName) &&
            (identical(other.currentBalance, currentBalance) ||
                other.currentBalance == currentBalance) &&
            (identical(other.originalAmount, originalAmount) ||
                other.originalAmount == originalAmount) &&
            (identical(other.interestRate, interestRate) ||
                other.interestRate == interestRate) &&
            (identical(other.monthlyInstallment, monthlyInstallment) ||
                other.monthlyInstallment == monthlyInstallment) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(
                  other.linkedExpenseCategoryId,
                  linkedExpenseCategoryId,
                ) ||
                other.linkedExpenseCategoryId == linkedExpenseCategoryId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    bankName,
    currentBalance,
    originalAmount,
    interestRate,
    monthlyInstallment,
    endDate,
    linkedExpenseCategoryId,
  );

  /// Create a copy of DebtAccount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DebtAccountImplCopyWith<_$DebtAccountImpl> get copyWith =>
      __$$DebtAccountImplCopyWithImpl<_$DebtAccountImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DebtAccountImplToJson(this);
  }
}

abstract class _DebtAccount implements DebtAccount {
  const factory _DebtAccount({
    required final String id,
    required final String name,
    final String? bankName,
    required final double currentBalance,
    required final double originalAmount,
    required final double interestRate,
    required final double monthlyInstallment,
    final DateTime? endDate,
    final String? linkedExpenseCategoryId,
  }) = _$DebtAccountImpl;

  factory _DebtAccount.fromJson(Map<String, dynamic> json) =
      _$DebtAccountImpl.fromJson;

  @override
  String get id;
  @override
  String get name; // ex: 'Préstec Cotxe'
  @override
  String? get bankName; // ex: 'CaixaBank'
  @override
  double get currentBalance; // Capital Pendent
  @override
  double get originalAmount; // Capital Inicial
  @override
  double get interestRate; // TAE/TIN
  @override
  double get monthlyInstallment; // Quota mensual
  @override
  DateTime? get endDate; // Data venciment
  @override
  String? get linkedExpenseCategoryId;

  /// Create a copy of DebtAccount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DebtAccountImplCopyWith<_$DebtAccountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
