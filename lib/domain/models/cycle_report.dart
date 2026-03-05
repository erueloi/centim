import 'package:freezed_annotation/freezed_annotation.dart';

part 'cycle_report.freezed.dart';
part 'cycle_report.g.dart';

@freezed
class CycleReport with _$CycleReport {
  const factory CycleReport({
    required String id,
    required String groupId,
    required String cycleId,
    required DateTime generatedAt,

    // AI Content
    required String aiVerdict,

    // Metrics
    required double totalIncome,
    required double totalExpense,
    required double savingsPercentage,

    // Deviations (Category Name to Deviation Amount)
    // Only keeping the top 3 as map or list of maps. Let's use List of Maps for clearer parsing in UI.
    @Default([]) List<Map<String, dynamic>> topOverspent,
    @Default([]) List<Map<String, dynamic>> topSaved,
  }) = _CycleReport;

  factory CycleReport.fromJson(Map<String, dynamic> json) =>
      _$CycleReportFromJson(json);
}
