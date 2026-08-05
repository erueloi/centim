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
    @Default(0.0) double savedThisCycle,
    @Default(0.0) double withdrawnThisCycle,
    @Default(0.0) double netSaved,
    @Default(0.0) double personalTransferIncome,

    // Deviations (Category Name to Deviation Amount)
    @Default([]) List<Map<String, dynamic>> topOverspent,
    @Default([]) List<Map<String, dynamic>> topSaved,

    // Advanced Metrics
    @Default(0) int zeroExpenseDays,
    @Default(0) int totalDays,
    @Default([]) List<Map<String, dynamic>> unexpectedExpenses,

    // Fonts utilitzades per comprovar si el snapshot continua vigent.
    DateTime? generatedForStartDate,
    DateTime? generatedForEndDate,
    @Default('') String sourceFingerprint,
    @Default(0) int reportSchemaVersion,
    @Default(0) int ledgerSchemaVersion,

    // Camp llegat, conservat perquè els documents antics continuïn llegint-se.
    @Default(0) int schemaVersion,
  }) = _CycleReport;

  factory CycleReport.fromJson(Map<String, dynamic> json) =>
      _$CycleReportFromJson(json);
}
