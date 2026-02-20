// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'household_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HouseholdGroup _$HouseholdGroupFromJson(Map<String, dynamic> json) {
  return _HouseholdGroup.fromJson(json);
}

/// @nodoc
mixin _$HouseholdGroup {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<String> get memberIds => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get inviteCode => throw _privateConstructorUsedError;
  double get totalAssets => throw _privateConstructorUsedError;

  /// Serializes this HouseholdGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HouseholdGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HouseholdGroupCopyWith<HouseholdGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HouseholdGroupCopyWith<$Res> {
  factory $HouseholdGroupCopyWith(
          HouseholdGroup value, $Res Function(HouseholdGroup) then) =
      _$HouseholdGroupCopyWithImpl<$Res, HouseholdGroup>;
  @useResult
  $Res call(
      {String id,
      String name,
      List<String> memberIds,
      String ownerId,
      String inviteCode,
      double totalAssets});
}

/// @nodoc
class _$HouseholdGroupCopyWithImpl<$Res, $Val extends HouseholdGroup>
    implements $HouseholdGroupCopyWith<$Res> {
  _$HouseholdGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HouseholdGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? memberIds = null,
    Object? ownerId = null,
    Object? inviteCode = null,
    Object? totalAssets = null,
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
      memberIds: null == memberIds
          ? _value.memberIds
          : memberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      inviteCode: null == inviteCode
          ? _value.inviteCode
          : inviteCode // ignore: cast_nullable_to_non_nullable
              as String,
      totalAssets: null == totalAssets
          ? _value.totalAssets
          : totalAssets // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HouseholdGroupImplCopyWith<$Res>
    implements $HouseholdGroupCopyWith<$Res> {
  factory _$$HouseholdGroupImplCopyWith(_$HouseholdGroupImpl value,
          $Res Function(_$HouseholdGroupImpl) then) =
      __$$HouseholdGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      List<String> memberIds,
      String ownerId,
      String inviteCode,
      double totalAssets});
}

/// @nodoc
class __$$HouseholdGroupImplCopyWithImpl<$Res>
    extends _$HouseholdGroupCopyWithImpl<$Res, _$HouseholdGroupImpl>
    implements _$$HouseholdGroupImplCopyWith<$Res> {
  __$$HouseholdGroupImplCopyWithImpl(
      _$HouseholdGroupImpl _value, $Res Function(_$HouseholdGroupImpl) _then)
      : super(_value, _then);

  /// Create a copy of HouseholdGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? memberIds = null,
    Object? ownerId = null,
    Object? inviteCode = null,
    Object? totalAssets = null,
  }) {
    return _then(_$HouseholdGroupImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      memberIds: null == memberIds
          ? _value._memberIds
          : memberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      inviteCode: null == inviteCode
          ? _value.inviteCode
          : inviteCode // ignore: cast_nullable_to_non_nullable
              as String,
      totalAssets: null == totalAssets
          ? _value.totalAssets
          : totalAssets // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HouseholdGroupImpl implements _HouseholdGroup {
  const _$HouseholdGroupImpl(
      {required this.id,
      required this.name,
      required final List<String> memberIds,
      required this.ownerId,
      required this.inviteCode,
      this.totalAssets = 0.0})
      : _memberIds = memberIds;

  factory _$HouseholdGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$HouseholdGroupImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final List<String> _memberIds;
  @override
  List<String> get memberIds {
    if (_memberIds is EqualUnmodifiableListView) return _memberIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_memberIds);
  }

  @override
  final String ownerId;
  @override
  final String inviteCode;
  @override
  @JsonKey()
  final double totalAssets;

  @override
  String toString() {
    return 'HouseholdGroup(id: $id, name: $name, memberIds: $memberIds, ownerId: $ownerId, inviteCode: $inviteCode, totalAssets: $totalAssets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HouseholdGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality()
                .equals(other._memberIds, _memberIds) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.totalAssets, totalAssets) ||
                other.totalAssets == totalAssets));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      const DeepCollectionEquality().hash(_memberIds),
      ownerId,
      inviteCode,
      totalAssets);

  /// Create a copy of HouseholdGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HouseholdGroupImplCopyWith<_$HouseholdGroupImpl> get copyWith =>
      __$$HouseholdGroupImplCopyWithImpl<_$HouseholdGroupImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HouseholdGroupImplToJson(
      this,
    );
  }
}

abstract class _HouseholdGroup implements HouseholdGroup {
  const factory _HouseholdGroup(
      {required final String id,
      required final String name,
      required final List<String> memberIds,
      required final String ownerId,
      required final String inviteCode,
      final double totalAssets}) = _$HouseholdGroupImpl;

  factory _HouseholdGroup.fromJson(Map<String, dynamic> json) =
      _$HouseholdGroupImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  List<String> get memberIds;
  @override
  String get ownerId;
  @override
  String get inviteCode;
  @override
  double get totalAssets;

  /// Create a copy of HouseholdGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HouseholdGroupImplCopyWith<_$HouseholdGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
