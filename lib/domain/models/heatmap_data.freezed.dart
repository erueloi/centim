// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'heatmap_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HeatmapCell {
  double get budgeted => throw _privateConstructorUsedError;
  double get spent => throw _privateConstructorUsedError;
  double get deviation => throw _privateConstructorUsedError;

  /// Create a copy of HeatmapCell
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HeatmapCellCopyWith<HeatmapCell> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HeatmapCellCopyWith<$Res> {
  factory $HeatmapCellCopyWith(
          HeatmapCell value, $Res Function(HeatmapCell) then) =
      _$HeatmapCellCopyWithImpl<$Res, HeatmapCell>;
  @useResult
  $Res call({double budgeted, double spent, double deviation});
}

/// @nodoc
class _$HeatmapCellCopyWithImpl<$Res, $Val extends HeatmapCell>
    implements $HeatmapCellCopyWith<$Res> {
  _$HeatmapCellCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HeatmapCell
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? budgeted = null,
    Object? spent = null,
    Object? deviation = null,
  }) {
    return _then(_value.copyWith(
      budgeted: null == budgeted
          ? _value.budgeted
          : budgeted // ignore: cast_nullable_to_non_nullable
              as double,
      spent: null == spent
          ? _value.spent
          : spent // ignore: cast_nullable_to_non_nullable
              as double,
      deviation: null == deviation
          ? _value.deviation
          : deviation // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HeatmapCellImplCopyWith<$Res>
    implements $HeatmapCellCopyWith<$Res> {
  factory _$$HeatmapCellImplCopyWith(
          _$HeatmapCellImpl value, $Res Function(_$HeatmapCellImpl) then) =
      __$$HeatmapCellImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double budgeted, double spent, double deviation});
}

/// @nodoc
class __$$HeatmapCellImplCopyWithImpl<$Res>
    extends _$HeatmapCellCopyWithImpl<$Res, _$HeatmapCellImpl>
    implements _$$HeatmapCellImplCopyWith<$Res> {
  __$$HeatmapCellImplCopyWithImpl(
      _$HeatmapCellImpl _value, $Res Function(_$HeatmapCellImpl) _then)
      : super(_value, _then);

  /// Create a copy of HeatmapCell
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? budgeted = null,
    Object? spent = null,
    Object? deviation = null,
  }) {
    return _then(_$HeatmapCellImpl(
      budgeted: null == budgeted
          ? _value.budgeted
          : budgeted // ignore: cast_nullable_to_non_nullable
              as double,
      spent: null == spent
          ? _value.spent
          : spent // ignore: cast_nullable_to_non_nullable
              as double,
      deviation: null == deviation
          ? _value.deviation
          : deviation // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$HeatmapCellImpl implements _HeatmapCell {
  const _$HeatmapCellImpl(
      {required this.budgeted, required this.spent, required this.deviation});

  @override
  final double budgeted;
  @override
  final double spent;
  @override
  final double deviation;

  @override
  String toString() {
    return 'HeatmapCell(budgeted: $budgeted, spent: $spent, deviation: $deviation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HeatmapCellImpl &&
            (identical(other.budgeted, budgeted) ||
                other.budgeted == budgeted) &&
            (identical(other.spent, spent) || other.spent == spent) &&
            (identical(other.deviation, deviation) ||
                other.deviation == deviation));
  }

  @override
  int get hashCode => Object.hash(runtimeType, budgeted, spent, deviation);

  /// Create a copy of HeatmapCell
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HeatmapCellImplCopyWith<_$HeatmapCellImpl> get copyWith =>
      __$$HeatmapCellImplCopyWithImpl<_$HeatmapCellImpl>(this, _$identity);
}

abstract class _HeatmapCell implements HeatmapCell {
  const factory _HeatmapCell(
      {required final double budgeted,
      required final double spent,
      required final double deviation}) = _$HeatmapCellImpl;

  @override
  double get budgeted;
  @override
  double get spent;
  @override
  double get deviation;

  /// Create a copy of HeatmapCell
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HeatmapCellImplCopyWith<_$HeatmapCellImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$HeatmapRow {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;
  bool get isSubCategory => throw _privateConstructorUsedError;
  Map<String, HeatmapCell> get cells =>
      throw _privateConstructorUsedError; // cycleId -> cell
  bool get isExpanded => throw _privateConstructorUsedError;

  /// Create a copy of HeatmapRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HeatmapRowCopyWith<HeatmapRow> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HeatmapRowCopyWith<$Res> {
  factory $HeatmapRowCopyWith(
          HeatmapRow value, $Res Function(HeatmapRow) then) =
      _$HeatmapRowCopyWithImpl<$Res, HeatmapRow>;
  @useResult
  $Res call(
      {String id,
      String name,
      String icon,
      bool isSubCategory,
      Map<String, HeatmapCell> cells,
      bool isExpanded});
}

/// @nodoc
class _$HeatmapRowCopyWithImpl<$Res, $Val extends HeatmapRow>
    implements $HeatmapRowCopyWith<$Res> {
  _$HeatmapRowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HeatmapRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? icon = null,
    Object? isSubCategory = null,
    Object? cells = null,
    Object? isExpanded = null,
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
      isSubCategory: null == isSubCategory
          ? _value.isSubCategory
          : isSubCategory // ignore: cast_nullable_to_non_nullable
              as bool,
      cells: null == cells
          ? _value.cells
          : cells // ignore: cast_nullable_to_non_nullable
              as Map<String, HeatmapCell>,
      isExpanded: null == isExpanded
          ? _value.isExpanded
          : isExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HeatmapRowImplCopyWith<$Res>
    implements $HeatmapRowCopyWith<$Res> {
  factory _$$HeatmapRowImplCopyWith(
          _$HeatmapRowImpl value, $Res Function(_$HeatmapRowImpl) then) =
      __$$HeatmapRowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String icon,
      bool isSubCategory,
      Map<String, HeatmapCell> cells,
      bool isExpanded});
}

/// @nodoc
class __$$HeatmapRowImplCopyWithImpl<$Res>
    extends _$HeatmapRowCopyWithImpl<$Res, _$HeatmapRowImpl>
    implements _$$HeatmapRowImplCopyWith<$Res> {
  __$$HeatmapRowImplCopyWithImpl(
      _$HeatmapRowImpl _value, $Res Function(_$HeatmapRowImpl) _then)
      : super(_value, _then);

  /// Create a copy of HeatmapRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? icon = null,
    Object? isSubCategory = null,
    Object? cells = null,
    Object? isExpanded = null,
  }) {
    return _then(_$HeatmapRowImpl(
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
      isSubCategory: null == isSubCategory
          ? _value.isSubCategory
          : isSubCategory // ignore: cast_nullable_to_non_nullable
              as bool,
      cells: null == cells
          ? _value._cells
          : cells // ignore: cast_nullable_to_non_nullable
              as Map<String, HeatmapCell>,
      isExpanded: null == isExpanded
          ? _value.isExpanded
          : isExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$HeatmapRowImpl implements _HeatmapRow {
  const _$HeatmapRowImpl(
      {required this.id,
      required this.name,
      required this.icon,
      required this.isSubCategory,
      required final Map<String, HeatmapCell> cells,
      this.isExpanded = false})
      : _cells = cells;

  @override
  final String id;
  @override
  final String name;
  @override
  final String icon;
  @override
  final bool isSubCategory;
  final Map<String, HeatmapCell> _cells;
  @override
  Map<String, HeatmapCell> get cells {
    if (_cells is EqualUnmodifiableMapView) return _cells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_cells);
  }

// cycleId -> cell
  @override
  @JsonKey()
  final bool isExpanded;

  @override
  String toString() {
    return 'HeatmapRow(id: $id, name: $name, icon: $icon, isSubCategory: $isSubCategory, cells: $cells, isExpanded: $isExpanded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HeatmapRowImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.isSubCategory, isSubCategory) ||
                other.isSubCategory == isSubCategory) &&
            const DeepCollectionEquality().equals(other._cells, _cells) &&
            (identical(other.isExpanded, isExpanded) ||
                other.isExpanded == isExpanded));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, icon, isSubCategory,
      const DeepCollectionEquality().hash(_cells), isExpanded);

  /// Create a copy of HeatmapRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HeatmapRowImplCopyWith<_$HeatmapRowImpl> get copyWith =>
      __$$HeatmapRowImplCopyWithImpl<_$HeatmapRowImpl>(this, _$identity);
}

abstract class _HeatmapRow implements HeatmapRow {
  const factory _HeatmapRow(
      {required final String id,
      required final String name,
      required final String icon,
      required final bool isSubCategory,
      required final Map<String, HeatmapCell> cells,
      final bool isExpanded}) = _$HeatmapRowImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String get icon;
  @override
  bool get isSubCategory;
  @override
  Map<String, HeatmapCell> get cells; // cycleId -> cell
  @override
  bool get isExpanded;

  /// Create a copy of HeatmapRow
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HeatmapRowImplCopyWith<_$HeatmapRowImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$HeatmapState {
  List<BillingCycle> get allCycles => throw _privateConstructorUsedError;
  List<Category> get allCategories => throw _privateConstructorUsedError;
  List<HeatmapRow> get visibleRows => throw _privateConstructorUsedError;
  Set<String> get expandedCategoryIds => throw _privateConstructorUsedError;
  Set<String> get selectedCycleIds => throw _privateConstructorUsedError;
  Set<String> get selectedCategoryIds => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of HeatmapState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HeatmapStateCopyWith<HeatmapState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HeatmapStateCopyWith<$Res> {
  factory $HeatmapStateCopyWith(
          HeatmapState value, $Res Function(HeatmapState) then) =
      _$HeatmapStateCopyWithImpl<$Res, HeatmapState>;
  @useResult
  $Res call(
      {List<BillingCycle> allCycles,
      List<Category> allCategories,
      List<HeatmapRow> visibleRows,
      Set<String> expandedCategoryIds,
      Set<String> selectedCycleIds,
      Set<String> selectedCategoryIds,
      bool isLoading});
}

/// @nodoc
class _$HeatmapStateCopyWithImpl<$Res, $Val extends HeatmapState>
    implements $HeatmapStateCopyWith<$Res> {
  _$HeatmapStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HeatmapState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allCycles = null,
    Object? allCategories = null,
    Object? visibleRows = null,
    Object? expandedCategoryIds = null,
    Object? selectedCycleIds = null,
    Object? selectedCategoryIds = null,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      allCycles: null == allCycles
          ? _value.allCycles
          : allCycles // ignore: cast_nullable_to_non_nullable
              as List<BillingCycle>,
      allCategories: null == allCategories
          ? _value.allCategories
          : allCategories // ignore: cast_nullable_to_non_nullable
              as List<Category>,
      visibleRows: null == visibleRows
          ? _value.visibleRows
          : visibleRows // ignore: cast_nullable_to_non_nullable
              as List<HeatmapRow>,
      expandedCategoryIds: null == expandedCategoryIds
          ? _value.expandedCategoryIds
          : expandedCategoryIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      selectedCycleIds: null == selectedCycleIds
          ? _value.selectedCycleIds
          : selectedCycleIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      selectedCategoryIds: null == selectedCategoryIds
          ? _value.selectedCategoryIds
          : selectedCategoryIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HeatmapStateImplCopyWith<$Res>
    implements $HeatmapStateCopyWith<$Res> {
  factory _$$HeatmapStateImplCopyWith(
          _$HeatmapStateImpl value, $Res Function(_$HeatmapStateImpl) then) =
      __$$HeatmapStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<BillingCycle> allCycles,
      List<Category> allCategories,
      List<HeatmapRow> visibleRows,
      Set<String> expandedCategoryIds,
      Set<String> selectedCycleIds,
      Set<String> selectedCategoryIds,
      bool isLoading});
}

/// @nodoc
class __$$HeatmapStateImplCopyWithImpl<$Res>
    extends _$HeatmapStateCopyWithImpl<$Res, _$HeatmapStateImpl>
    implements _$$HeatmapStateImplCopyWith<$Res> {
  __$$HeatmapStateImplCopyWithImpl(
      _$HeatmapStateImpl _value, $Res Function(_$HeatmapStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of HeatmapState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allCycles = null,
    Object? allCategories = null,
    Object? visibleRows = null,
    Object? expandedCategoryIds = null,
    Object? selectedCycleIds = null,
    Object? selectedCategoryIds = null,
    Object? isLoading = null,
  }) {
    return _then(_$HeatmapStateImpl(
      allCycles: null == allCycles
          ? _value._allCycles
          : allCycles // ignore: cast_nullable_to_non_nullable
              as List<BillingCycle>,
      allCategories: null == allCategories
          ? _value._allCategories
          : allCategories // ignore: cast_nullable_to_non_nullable
              as List<Category>,
      visibleRows: null == visibleRows
          ? _value._visibleRows
          : visibleRows // ignore: cast_nullable_to_non_nullable
              as List<HeatmapRow>,
      expandedCategoryIds: null == expandedCategoryIds
          ? _value._expandedCategoryIds
          : expandedCategoryIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      selectedCycleIds: null == selectedCycleIds
          ? _value._selectedCycleIds
          : selectedCycleIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      selectedCategoryIds: null == selectedCategoryIds
          ? _value._selectedCategoryIds
          : selectedCategoryIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$HeatmapStateImpl implements _HeatmapState {
  const _$HeatmapStateImpl(
      {required final List<BillingCycle> allCycles,
      required final List<Category> allCategories,
      required final List<HeatmapRow> visibleRows,
      required final Set<String> expandedCategoryIds,
      required final Set<String> selectedCycleIds,
      required final Set<String> selectedCategoryIds,
      this.isLoading = false})
      : _allCycles = allCycles,
        _allCategories = allCategories,
        _visibleRows = visibleRows,
        _expandedCategoryIds = expandedCategoryIds,
        _selectedCycleIds = selectedCycleIds,
        _selectedCategoryIds = selectedCategoryIds;

  final List<BillingCycle> _allCycles;
  @override
  List<BillingCycle> get allCycles {
    if (_allCycles is EqualUnmodifiableListView) return _allCycles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allCycles);
  }

  final List<Category> _allCategories;
  @override
  List<Category> get allCategories {
    if (_allCategories is EqualUnmodifiableListView) return _allCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allCategories);
  }

  final List<HeatmapRow> _visibleRows;
  @override
  List<HeatmapRow> get visibleRows {
    if (_visibleRows is EqualUnmodifiableListView) return _visibleRows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_visibleRows);
  }

  final Set<String> _expandedCategoryIds;
  @override
  Set<String> get expandedCategoryIds {
    if (_expandedCategoryIds is EqualUnmodifiableSetView)
      return _expandedCategoryIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_expandedCategoryIds);
  }

  final Set<String> _selectedCycleIds;
  @override
  Set<String> get selectedCycleIds {
    if (_selectedCycleIds is EqualUnmodifiableSetView) return _selectedCycleIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedCycleIds);
  }

  final Set<String> _selectedCategoryIds;
  @override
  Set<String> get selectedCategoryIds {
    if (_selectedCategoryIds is EqualUnmodifiableSetView)
      return _selectedCategoryIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedCategoryIds);
  }

  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'HeatmapState(allCycles: $allCycles, allCategories: $allCategories, visibleRows: $visibleRows, expandedCategoryIds: $expandedCategoryIds, selectedCycleIds: $selectedCycleIds, selectedCategoryIds: $selectedCategoryIds, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HeatmapStateImpl &&
            const DeepCollectionEquality()
                .equals(other._allCycles, _allCycles) &&
            const DeepCollectionEquality()
                .equals(other._allCategories, _allCategories) &&
            const DeepCollectionEquality()
                .equals(other._visibleRows, _visibleRows) &&
            const DeepCollectionEquality()
                .equals(other._expandedCategoryIds, _expandedCategoryIds) &&
            const DeepCollectionEquality()
                .equals(other._selectedCycleIds, _selectedCycleIds) &&
            const DeepCollectionEquality()
                .equals(other._selectedCategoryIds, _selectedCategoryIds) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_allCycles),
      const DeepCollectionEquality().hash(_allCategories),
      const DeepCollectionEquality().hash(_visibleRows),
      const DeepCollectionEquality().hash(_expandedCategoryIds),
      const DeepCollectionEquality().hash(_selectedCycleIds),
      const DeepCollectionEquality().hash(_selectedCategoryIds),
      isLoading);

  /// Create a copy of HeatmapState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HeatmapStateImplCopyWith<_$HeatmapStateImpl> get copyWith =>
      __$$HeatmapStateImplCopyWithImpl<_$HeatmapStateImpl>(this, _$identity);
}

abstract class _HeatmapState implements HeatmapState {
  const factory _HeatmapState(
      {required final List<BillingCycle> allCycles,
      required final List<Category> allCategories,
      required final List<HeatmapRow> visibleRows,
      required final Set<String> expandedCategoryIds,
      required final Set<String> selectedCycleIds,
      required final Set<String> selectedCategoryIds,
      final bool isLoading}) = _$HeatmapStateImpl;

  @override
  List<BillingCycle> get allCycles;
  @override
  List<Category> get allCategories;
  @override
  List<HeatmapRow> get visibleRows;
  @override
  Set<String> get expandedCategoryIds;
  @override
  Set<String> get selectedCycleIds;
  @override
  Set<String> get selectedCategoryIds;
  @override
  bool get isLoading;

  /// Create a copy of HeatmapState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HeatmapStateImplCopyWith<_$HeatmapStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
