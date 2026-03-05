// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cycle_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CycleReport _$CycleReportFromJson(Map<String, dynamic> json) {
  return _CycleReport.fromJson(json);
}

/// @nodoc
mixin _$CycleReport {
  String get id => throw _privateConstructorUsedError;
  String get groupId => throw _privateConstructorUsedError;
  String get cycleId => throw _privateConstructorUsedError;
  DateTime get generatedAt => throw _privateConstructorUsedError; // AI Content
  String get aiVerdict => throw _privateConstructorUsedError; // Metrics
  double get totalIncome => throw _privateConstructorUsedError;
  double get totalExpense => throw _privateConstructorUsedError;
  double get savingsPercentage =>
      throw _privateConstructorUsedError; // Deviations (Category Name to Deviation Amount)
// Only keeping the top 3 as map or list of maps. Let's use List of Maps for clearer parsing in UI.
  List<Map<String, dynamic>> get topOverspent =>
      throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get topSaved => throw _privateConstructorUsedError;

  /// Serializes this CycleReport to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CycleReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CycleReportCopyWith<CycleReport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CycleReportCopyWith<$Res> {
  factory $CycleReportCopyWith(
          CycleReport value, $Res Function(CycleReport) then) =
      _$CycleReportCopyWithImpl<$Res, CycleReport>;
  @useResult
  $Res call(
      {String id,
      String groupId,
      String cycleId,
      DateTime generatedAt,
      String aiVerdict,
      double totalIncome,
      double totalExpense,
      double savingsPercentage,
      List<Map<String, dynamic>> topOverspent,
      List<Map<String, dynamic>> topSaved});
}

/// @nodoc
class _$CycleReportCopyWithImpl<$Res, $Val extends CycleReport>
    implements $CycleReportCopyWith<$Res> {
  _$CycleReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CycleReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? cycleId = null,
    Object? generatedAt = null,
    Object? aiVerdict = null,
    Object? totalIncome = null,
    Object? totalExpense = null,
    Object? savingsPercentage = null,
    Object? topOverspent = null,
    Object? topSaved = null,
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
      cycleId: null == cycleId
          ? _value.cycleId
          : cycleId // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      aiVerdict: null == aiVerdict
          ? _value.aiVerdict
          : aiVerdict // ignore: cast_nullable_to_non_nullable
              as String,
      totalIncome: null == totalIncome
          ? _value.totalIncome
          : totalIncome // ignore: cast_nullable_to_non_nullable
              as double,
      totalExpense: null == totalExpense
          ? _value.totalExpense
          : totalExpense // ignore: cast_nullable_to_non_nullable
              as double,
      savingsPercentage: null == savingsPercentage
          ? _value.savingsPercentage
          : savingsPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      topOverspent: null == topOverspent
          ? _value.topOverspent
          : topOverspent // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      topSaved: null == topSaved
          ? _value.topSaved
          : topSaved // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CycleReportImplCopyWith<$Res>
    implements $CycleReportCopyWith<$Res> {
  factory _$$CycleReportImplCopyWith(
          _$CycleReportImpl value, $Res Function(_$CycleReportImpl) then) =
      __$$CycleReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String groupId,
      String cycleId,
      DateTime generatedAt,
      String aiVerdict,
      double totalIncome,
      double totalExpense,
      double savingsPercentage,
      List<Map<String, dynamic>> topOverspent,
      List<Map<String, dynamic>> topSaved});
}

/// @nodoc
class __$$CycleReportImplCopyWithImpl<$Res>
    extends _$CycleReportCopyWithImpl<$Res, _$CycleReportImpl>
    implements _$$CycleReportImplCopyWith<$Res> {
  __$$CycleReportImplCopyWithImpl(
      _$CycleReportImpl _value, $Res Function(_$CycleReportImpl) _then)
      : super(_value, _then);

  /// Create a copy of CycleReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? cycleId = null,
    Object? generatedAt = null,
    Object? aiVerdict = null,
    Object? totalIncome = null,
    Object? totalExpense = null,
    Object? savingsPercentage = null,
    Object? topOverspent = null,
    Object? topSaved = null,
  }) {
    return _then(_$CycleReportImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      cycleId: null == cycleId
          ? _value.cycleId
          : cycleId // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      aiVerdict: null == aiVerdict
          ? _value.aiVerdict
          : aiVerdict // ignore: cast_nullable_to_non_nullable
              as String,
      totalIncome: null == totalIncome
          ? _value.totalIncome
          : totalIncome // ignore: cast_nullable_to_non_nullable
              as double,
      totalExpense: null == totalExpense
          ? _value.totalExpense
          : totalExpense // ignore: cast_nullable_to_non_nullable
              as double,
      savingsPercentage: null == savingsPercentage
          ? _value.savingsPercentage
          : savingsPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      topOverspent: null == topOverspent
          ? _value._topOverspent
          : topOverspent // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      topSaved: null == topSaved
          ? _value._topSaved
          : topSaved // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CycleReportImpl implements _CycleReport {
  const _$CycleReportImpl(
      {required this.id,
      required this.groupId,
      required this.cycleId,
      required this.generatedAt,
      required this.aiVerdict,
      required this.totalIncome,
      required this.totalExpense,
      required this.savingsPercentage,
      final List<Map<String, dynamic>> topOverspent = const [],
      final List<Map<String, dynamic>> topSaved = const []})
      : _topOverspent = topOverspent,
        _topSaved = topSaved;

  factory _$CycleReportImpl.fromJson(Map<String, dynamic> json) =>
      _$$CycleReportImplFromJson(json);

  @override
  final String id;
  @override
  final String groupId;
  @override
  final String cycleId;
  @override
  final DateTime generatedAt;
// AI Content
  @override
  final String aiVerdict;
// Metrics
  @override
  final double totalIncome;
  @override
  final double totalExpense;
  @override
  final double savingsPercentage;
// Deviations (Category Name to Deviation Amount)
// Only keeping the top 3 as map or list of maps. Let's use List of Maps for clearer parsing in UI.
  final List<Map<String, dynamic>> _topOverspent;
// Deviations (Category Name to Deviation Amount)
// Only keeping the top 3 as map or list of maps. Let's use List of Maps for clearer parsing in UI.
  @override
  @JsonKey()
  List<Map<String, dynamic>> get topOverspent {
    if (_topOverspent is EqualUnmodifiableListView) return _topOverspent;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topOverspent);
  }

  final List<Map<String, dynamic>> _topSaved;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get topSaved {
    if (_topSaved is EqualUnmodifiableListView) return _topSaved;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topSaved);
  }

  @override
  String toString() {
    return 'CycleReport(id: $id, groupId: $groupId, cycleId: $cycleId, generatedAt: $generatedAt, aiVerdict: $aiVerdict, totalIncome: $totalIncome, totalExpense: $totalExpense, savingsPercentage: $savingsPercentage, topOverspent: $topOverspent, topSaved: $topSaved)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CycleReportImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.cycleId, cycleId) || other.cycleId == cycleId) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt) &&
            (identical(other.aiVerdict, aiVerdict) ||
                other.aiVerdict == aiVerdict) &&
            (identical(other.totalIncome, totalIncome) ||
                other.totalIncome == totalIncome) &&
            (identical(other.totalExpense, totalExpense) ||
                other.totalExpense == totalExpense) &&
            (identical(other.savingsPercentage, savingsPercentage) ||
                other.savingsPercentage == savingsPercentage) &&
            const DeepCollectionEquality()
                .equals(other._topOverspent, _topOverspent) &&
            const DeepCollectionEquality().equals(other._topSaved, _topSaved));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      groupId,
      cycleId,
      generatedAt,
      aiVerdict,
      totalIncome,
      totalExpense,
      savingsPercentage,
      const DeepCollectionEquality().hash(_topOverspent),
      const DeepCollectionEquality().hash(_topSaved));

  /// Create a copy of CycleReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CycleReportImplCopyWith<_$CycleReportImpl> get copyWith =>
      __$$CycleReportImplCopyWithImpl<_$CycleReportImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CycleReportImplToJson(
      this,
    );
  }
}

abstract class _CycleReport implements CycleReport {
  const factory _CycleReport(
      {required final String id,
      required final String groupId,
      required final String cycleId,
      required final DateTime generatedAt,
      required final String aiVerdict,
      required final double totalIncome,
      required final double totalExpense,
      required final double savingsPercentage,
      final List<Map<String, dynamic>> topOverspent,
      final List<Map<String, dynamic>> topSaved}) = _$CycleReportImpl;

  factory _CycleReport.fromJson(Map<String, dynamic> json) =
      _$CycleReportImpl.fromJson;

  @override
  String get id;
  @override
  String get groupId;
  @override
  String get cycleId;
  @override
  DateTime get generatedAt; // AI Content
  @override
  String get aiVerdict; // Metrics
  @override
  double get totalIncome;
  @override
  double get totalExpense;
  @override
  double
      get savingsPercentage; // Deviations (Category Name to Deviation Amount)
// Only keeping the top 3 as map or list of maps. Let's use List of Maps for clearer parsing in UI.
  @override
  List<Map<String, dynamic>> get topOverspent;
  @override
  List<Map<String, dynamic>> get topSaved;

  /// Create a copy of CycleReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CycleReportImplCopyWith<_$CycleReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
