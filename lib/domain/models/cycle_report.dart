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
    @Default([]) List<Map<String, dynamic>> topOverspent,
    @Default([]) List<Map<String, dynamic>> topSaved,

    // Advanced Metrics
    @Default(0) int zeroExpenseDays,
    @Default(0) int totalDays,
    @Default([]) List<Map<String, dynamic>> unexpectedExpenses,
  }) = _CycleReport;

  factory CycleReport.fromJson(Map<String, dynamic> json) =>
      _$CycleReportFromJson(json);
}
