import 'package:freezed_annotation/freezed_annotation.dart';
import 'billing_cycle.dart';
import 'category.dart';

part 'heatmap_data.freezed.dart';

@freezed
class HeatmapCell with _$HeatmapCell {
  const factory HeatmapCell({
    required double budgeted,
    required double spent,
    required double deviation,
  }) = _HeatmapCell;
}

@freezed
class HeatmapRow with _$HeatmapRow {
  const factory HeatmapRow({
    required String id,
    required String name,
    required String icon,
    required bool isSubCategory,
    required Map<String, HeatmapCell> cells, // cycleId -> cell
    @Default(false) bool isExpanded,
  }) = _HeatmapRow;
}

@freezed
class HeatmapState with _$HeatmapState {
  const factory HeatmapState({
    required List<BillingCycle> allCycles,
    required List<Category> allCategories,
    required List<HeatmapRow> visibleRows,
    required Set<String> expandedCategoryIds,
    required Set<String> selectedCycleIds,
    required Set<String> selectedCategoryIds,
    @Default(false) bool isLoading,
  }) = _HeatmapState;
}
